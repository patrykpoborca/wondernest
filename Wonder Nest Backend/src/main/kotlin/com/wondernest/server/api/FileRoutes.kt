package com.wondernest.server.api

import com.wondernest.data.database.table.UploadedFiles
import com.wondernest.data.database.table.Users
import com.wondernest.data.database.table.ChildProfiles
import com.wondernest.server.data.database.table.TagTables
import com.wondernest.server.domain.model.*
import com.wondernest.server.service.FileTagService
import com.wondernest.server.utils.respondError
import com.wondernest.server.utils.respondSuccess
import io.ktor.http.*
import io.ktor.http.content.*
import io.ktor.server.application.*
import io.ktor.server.auth.*
import io.ktor.server.auth.jwt.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.datetime.Clock
import kotlinx.serialization.Serializable
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.transactions.transaction
import org.slf4j.LoggerFactory
import java.io.File
import java.util.*

private val logger = LoggerFactory.getLogger("FileRoutes")
private val fileTagService = FileTagService()

fun Route.fileRoutes() {
    authenticate("auth-jwt") {
        route("/api/v2/files") {
            // Upload file with tags
            post("/upload") {
                val principal = call.principal<JWTPrincipal>()
                val userId = principal?.payload?.getClaim("userId")?.asString()?.let { UUID.fromString(it) }
                    ?: return@post call.respondError(HttpStatusCode.Unauthorized, "Invalid token")

                val multipart = call.receiveMultipart()
                var fileName = ""
                var fileBytes = ByteArray(0)
                var originalName = ""
                var mimeType = ""
                var category = "content"
                var isPublic = false
                var childId: UUID? = null
                var tags = listOf<String>()

                multipart.forEachPart { part ->
                    when (part) {
                        is PartData.FileItem -> {
                            fileName = part.originalFileName as String
                            originalName = fileName
                            fileBytes = part.streamProvider().readBytes()
                            mimeType = part.contentType?.toString() ?: "application/octet-stream"
                        }
                        is PartData.FormItem -> {
                            when (part.name) {
                                "category" -> category = part.value
                                "isPublic" -> isPublic = part.value.toBoolean()
                                "childId" -> childId = part.value.takeIf { it.isNotBlank() }?.let { UUID.fromString(it) }
                                "tags" -> tags = part.value.split(",").map { it.trim() }.filter { it.isNotEmpty() }
                            }
                        }
                        else -> {}
                    }
                    part.dispose()
                }

                // Validate tags
                val validationResult = fileTagService.validateTags(tags, isSystemImage = false)
                if (!validationResult.isValid) {
                    return@post call.respondError(
                        HttpStatusCode.BadRequest,
                        validationResult.errors.joinToString(", ")
                    )
                }

                // Save file to disk (simplified for example)
                val fileId = UUID.randomUUID()
                val uploadDir = File("uploads/${userId}")
                uploadDir.mkdirs()
                val savedFile = File(uploadDir, "${fileId}_${fileName}")
                savedFile.writeBytes(fileBytes)

                // Save file metadata to database
                val fileResponse = transaction {
                    val insertedId = UploadedFiles.insertAndGetId {
                        it[UploadedFiles.userId] = userId!!
                        it[UploadedFiles.childId] = childId
                        it[UploadedFiles.fileKey] = "${userId}/${savedFile.name}"
                        it[UploadedFiles.originalName] = originalName
                        it[UploadedFiles.mimeType] = mimeType
                        it[UploadedFiles.fileSize] = fileBytes.size.toLong()
                        it[UploadedFiles.url] = "/uploads/${userId}/${savedFile.name}"
                        it[UploadedFiles.category] = category
                        it[UploadedFiles.isPublic] = isPublic
                        it[UploadedFiles.isDeleted] = false
                        it[UploadedFiles.uploadedAt] = Clock.System.now()
                        it[UploadedFiles.metadata] = mapOf("tags" to tags.joinToString(","))
                    }

                    // Add tags to the file
                    val addedTags = if (tags.isNotEmpty()) {
                        fileTagService.addTagsToFile(insertedId.value, tags, userId)
                    } else {
                        emptyList()
                    }

                    UploadedFileResponse(
                        id = insertedId.value,
                        originalName = originalName,
                        mimeType = mimeType,
                        fileSize = fileBytes.size.toLong(),
                        category = category,
                        tags = addedTags.map { it.name },
                        tagCount = addedTags.size,
                        url = "/uploads/${userId}/${savedFile.name}",
                        uploadedAt = Clock.System.now()
                    )
                }

                call.respondSuccess(fileResponse)
            }

            // Get user files with tags
            get {
                val principal = call.principal<JWTPrincipal>()
                val userId = principal?.payload?.getClaim("userId")?.asString()?.let { UUID.fromString(it) }
                    ?: return@get call.respondError(HttpStatusCode.Unauthorized, "Invalid token")

                val category = call.request.queryParameters["category"]

                val files = transaction {
                    val query = UploadedFiles
                        .select { 
                            (UploadedFiles.userId eq userId) and
                            (UploadedFiles.isDeleted eq false)
                        }
                    
                    if (category != null && category != "all") {
                        query.andWhere { UploadedFiles.category eq category }
                    }

                    query.map { row ->
                        val fileId = row[UploadedFiles.id].value
                        val tags = fileTagService.getFileTags(fileId)
                        
                        // Check usage in stories
                        val usageCount = getFileUsageCount(fileId)
                        
                        UploadedFileResponse(
                            id = fileId,
                            originalName = row[UploadedFiles.originalName],
                            mimeType = row[UploadedFiles.mimeType],
                            fileSize = row[UploadedFiles.fileSize],
                            category = row[UploadedFiles.category],
                            tags = tags.map { it.name },
                            tagCount = tags.size,
                            url = row[UploadedFiles.url],
                            uploadedAt = row[UploadedFiles.uploadedAt],
                            metadata = row[UploadedFiles.metadata]
                        )
                    }
                }

                call.respondSuccess(files)
            }

            // Check file usage
            get("/{fileId}/usage") {
                val principal = call.principal<JWTPrincipal>()
                val userId = principal?.payload?.getClaim("userId")?.asString()?.let { UUID.fromString(it) }
                    ?: return@get call.respondError(HttpStatusCode.Unauthorized, "Invalid token")

                val fileId = call.parameters["fileId"]?.let { UUID.fromString(it) }
                    ?: return@get call.respondError(HttpStatusCode.BadRequest, "Invalid file ID")

                val usage = transaction {
                    // Check if file exists and belongs to user
                    val file = UploadedFiles
                        .select { 
                            (UploadedFiles.id eq fileId) and
                            (UploadedFiles.userId eq userId)
                        }
                        .firstOrNull()
                        ?: return@transaction null

                    // Get stories using this file
                    val usedInStories = getStoriesUsingFile(fileId)
                    
                    FileUsageResponse(
                        fileId = fileId.toString(),
                        usageCount = usedInStories.size,
                        usedInStories = usedInStories
                    )
                }

                if (usage == null) {
                    return@get call.respondError(HttpStatusCode.NotFound, "File not found")
                }

                call.respondSuccess(usage)
            }

            // Delete file with soft delete option
            delete("/{fileId}") {
                val principal = call.principal<JWTPrincipal>()
                val userId = principal?.payload?.getClaim("userId")?.asString()?.let { UUID.fromString(it) }
                    ?: return@delete call.respondError(HttpStatusCode.Unauthorized, "Invalid token")

                val fileId = call.parameters["fileId"]?.let { UUID.fromString(it) }
                    ?: return@delete call.respondError(HttpStatusCode.BadRequest, "Invalid file ID")

                val softDelete = call.request.queryParameters["softDelete"]?.toBoolean() ?: false

                val result = transaction {
                    // Check if file exists and belongs to user
                    val file = UploadedFiles
                        .select { 
                            (UploadedFiles.id eq fileId) and
                            (UploadedFiles.userId eq userId)
                        }
                        .firstOrNull()
                        ?: return@transaction false

                    if (softDelete) {
                        // Soft delete - mark as deleted but keep file for existing stories
                        UploadedFiles.update({ 
                            UploadedFiles.id eq fileId 
                        }) {
                            it[isDeleted] = true
                            it[deletedAt] = Clock.System.now()
                        }
                        logger.info("Soft deleted file $fileId for user $userId")
                    } else {
                        // Hard delete - check if file is not in use
                        val usageCount = getFileUsageCount(fileId)
                        if (usageCount > 0) {
                            // File is in use, force soft delete instead
                            UploadedFiles.update({ 
                                UploadedFiles.id eq fileId 
                            }) {
                                it[isDeleted] = true
                                it[deletedAt] = Clock.System.now()
                            }
                            logger.info("File $fileId is in use, performed soft delete instead")
                        } else {
                            // Actually delete the file
                            val filePath = file[UploadedFiles.fileKey]
                            
                            // Remove tags
                            TagTables.FileTags.deleteWhere {
                                TagTables.FileTags.file_id eq fileId
                            }
                            
                            // Delete from database
                            UploadedFiles.deleteWhere {
                                UploadedFiles.id eq fileId
                            }
                            
                            // Delete physical file
                            try {
                                File(filePath).delete()
                            } catch (e: Exception) {
                                logger.error("Failed to delete physical file: $filePath", e)
                            }
                            
                            logger.info("Hard deleted file $fileId for user $userId")
                        }
                    }
                    true
                }

                if (!result) {
                    return@delete call.respondError(HttpStatusCode.NotFound, "File not found")
                }

                call.respondSuccess(mapOf("message" to "File deleted successfully"))
            }
        }
    }
}

// Helper function to get file usage count in stories
private fun getFileUsageCount(fileId: UUID): Int {
    // This would query the stories tables to count usage
    // For now, return 0 as stories table integration is pending
    return 0
}

// Helper function to get stories using a file
private fun getStoriesUsingFile(fileId: UUID): List<String> {
    // This would query the stories tables to find usage
    // For now, return empty list as stories table integration is pending
    return emptyList()
}

@Serializable
data class FileUsageResponse(
    val fileId: String,
    val usageCount: Int,
    val usedInStories: List<String>
)