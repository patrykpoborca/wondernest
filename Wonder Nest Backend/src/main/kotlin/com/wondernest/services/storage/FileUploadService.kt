package com.wondernest.services.storage

import com.wondernest.data.database.table.UploadedFiles
import com.wondernest.domain.model.FileCategory
import com.wondernest.domain.model.UploadedFile
import com.wondernest.domain.model.User
import kotlinx.coroutines.Dispatchers
import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import mu.KotlinLogging
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.transactions.experimental.newSuspendedTransaction
import java.io.InputStream
import java.util.UUID

private val logger = KotlinLogging.logger {}

/**
 * Service for handling file uploads and management
 */
class FileUploadService(
    private val storageProvider: StorageProvider,
    private val validationService: FileValidationService
) {
    
    /**
     * Upload a file for a user
     */
    suspend fun uploadFile(
        user: User,
        fileName: String,
        contentType: String,
        inputStream: InputStream,
        category: FileCategory = FileCategory.CONTENT,
        childId: UUID? = null,
        isPublic: Boolean = false,
        metadata: Map<String, String> = emptyMap()
    ): UploadedFile {
        // Get file size
        val fileSize = inputStream.available().toLong()
        
        // Validate file
        val validationResult = validationService.validateFile(fileName, contentType, fileSize)
        if (!validationResult.isValid) {
            throw IllegalArgumentException(validationResult.error ?: "File validation failed")
        }
        
        // Validate file content (magic bytes)
        if (inputStream.markSupported()) {
            inputStream.mark(16)
            if (!validationService.validateFileContent(inputStream, contentType)) {
                throw IllegalArgumentException("File content does not match declared content type")
            }
            inputStream.reset()
        }
        
        // Upload to storage provider
        val storageResult = storageProvider.upload(
            fileName = fileName,
            contentType = contentType,
            inputStream = inputStream,
            metadata = metadata + mapOf(
                "userId" to user.id.toString(),
                "category" to category.toDbValue()
            )
        )
        
        // Save to database
        return newSuspendedTransaction(Dispatchers.IO) {
            val uploadedFileId = UploadedFiles.insertAndGetId {
                it[userId] = user.id
                it[this.childId] = childId
                it[fileKey] = storageResult.key
                it[originalName] = fileName
                it[mimeType] = contentType
                it[this.fileSize] = storageResult.size
                it[storageProvider] = "local"
                it[url] = storageResult.url
                it[this.isPublic] = isPublic
                it[this.category] = category.toDbValue()
                it[this.metadata] = Json.encodeToString(metadata)
                it[uploadedAt] = Clock.System.now()
            }
            
            UploadedFile(
                id = uploadedFileId.value,
                userId = user.id,
                childId = childId,
                fileKey = storageResult.key,
                originalName = fileName,
                mimeType = contentType,
                fileSize = storageResult.size,
                storageProvider = "local",
                url = storageResult.url,
                isPublic = isPublic,
                category = category,
                metadata = metadata,
                uploadedAt = Clock.System.now()
            )
        }
    }
    
    /**
     * Get file metadata
     */
    suspend fun getFile(fileId: UUID, userId: UUID): UploadedFile? {
        return newSuspendedTransaction(Dispatchers.IO) {
            UploadedFiles
                .select { 
                    (UploadedFiles.id eq fileId) and 
                    (UploadedFiles.userId eq userId) and
                    (UploadedFiles.deletedAt.isNull())
                }
                .singleOrNull()
                ?.let { row ->
                    UploadedFile(
                        id = row[UploadedFiles.id].value,
                        userId = row[UploadedFiles.userId],
                        childId = row[UploadedFiles.childId],
                        fileKey = row[UploadedFiles.fileKey],
                        originalName = row[UploadedFiles.originalName],
                        mimeType = row[UploadedFiles.mimeType],
                        fileSize = row[UploadedFiles.fileSize],
                        storageProvider = row[UploadedFiles.storageProvider],
                        url = row[UploadedFiles.url],
                        isPublic = row[UploadedFiles.isPublic],
                        category = FileCategory.fromString(row[UploadedFiles.category]),
                        metadata = try {
                            Json.decodeFromString<Map<String, String>>(row[UploadedFiles.metadata])
                        } catch (e: Exception) {
                            emptyMap()
                        },
                        uploadedAt = row[UploadedFiles.uploadedAt],
                        accessedAt = row[UploadedFiles.accessedAt],
                        deletedAt = row[UploadedFiles.deletedAt]
                    )
                }
        }
    }
    
    /**
     * Download a file
     */
    suspend fun downloadFile(fileId: UUID, userId: UUID): ByteArray? {
        val file = getFile(fileId, userId) ?: return null
        
        // Update accessed timestamp
        newSuspendedTransaction(Dispatchers.IO) {
            UploadedFiles.update({ UploadedFiles.id eq fileId }) {
                it[accessedAt] = Clock.System.now()
            }
        }
        
        return storageProvider.download(file.fileKey)
    }
    
    /**
     * Delete a file (soft delete)
     */
    suspend fun deleteFile(fileId: UUID, userId: UUID): Boolean {
        return newSuspendedTransaction(Dispatchers.IO) {
            val updated = UploadedFiles.update({ 
                (UploadedFiles.id eq fileId) and 
                (UploadedFiles.userId eq userId) and
                (UploadedFiles.deletedAt.isNull())
            }) {
                it[deletedAt] = Clock.System.now()
            }
            
            if (updated > 0) {
                // Optionally delete from storage provider
                val file = getFile(fileId, userId)
                file?.let {
                    storageProvider.delete(it.fileKey)
                }
                true
            } else {
                false
            }
        }
    }
    
    /**
     * List user's files
     */
    suspend fun listUserFiles(
        userId: UUID,
        category: FileCategory? = null,
        childId: UUID? = null,
        limit: Int = 100,
        offset: Int = 0
    ): List<UploadedFile> {
        return newSuspendedTransaction(Dispatchers.IO) {
            var query = UploadedFiles.select { 
                (UploadedFiles.userId eq userId) and 
                (UploadedFiles.deletedAt.isNull())
            }
            
            category?.let {
                query = query.andWhere { UploadedFiles.category eq it.toDbValue() }
            }
            
            childId?.let {
                query = query.andWhere { UploadedFiles.childId eq it }
            }
            
            query
                .orderBy(UploadedFiles.uploadedAt, SortOrder.DESC)
                .limit(limit, offset.toLong())
                .map { row ->
                    UploadedFile(
                        id = row[UploadedFiles.id].value,
                        userId = row[UploadedFiles.userId],
                        childId = row[UploadedFiles.childId],
                        fileKey = row[UploadedFiles.fileKey],
                        originalName = row[UploadedFiles.originalName],
                        mimeType = row[UploadedFiles.mimeType],
                        fileSize = row[UploadedFiles.fileSize],
                        storageProvider = row[UploadedFiles.storageProvider],
                        url = row[UploadedFiles.url],
                        isPublic = row[UploadedFiles.isPublic],
                        category = FileCategory.fromString(row[UploadedFiles.category]),
                        metadata = try {
                            Json.decodeFromString<Map<String, String>>(row[UploadedFiles.metadata])
                        } catch (e: Exception) {
                            emptyMap()
                        },
                        uploadedAt = row[UploadedFiles.uploadedAt],
                        accessedAt = row[UploadedFiles.accessedAt],
                        deletedAt = row[UploadedFiles.deletedAt]
                    )
                }
        }
    }
    
    /**
     * Get a presigned URL for direct upload/download
     */
    suspend fun getPresignedUrl(fileId: UUID, userId: UUID, expirationSeconds: Int = 3600): String? {
        val file = getFile(fileId, userId) ?: return null
        return storageProvider.getPresignedUrl(file.fileKey, expirationSeconds)
    }
}