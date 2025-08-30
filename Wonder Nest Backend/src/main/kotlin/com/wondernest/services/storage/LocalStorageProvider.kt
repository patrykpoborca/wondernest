package com.wondernest.services.storage

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import mu.KotlinLogging
import java.io.File
import java.io.InputStream
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.Paths
import java.nio.file.StandardCopyOption
import java.util.UUID

private val logger = KotlinLogging.logger {}

/**
 * Local file system storage provider for development
 */
class LocalStorageProvider(
    private val basePath: String = "./uploads",
    private val baseUrl: String = "http://localhost:8080"
) : StorageProvider {
    
    private val rootPath: Path = Paths.get(basePath).toAbsolutePath()
    
    init {
        // Ensure base directory exists
        if (!Files.exists(rootPath)) {
            Files.createDirectories(rootPath)
            logger.info { "Created upload directory: $rootPath" }
        }
    }
    
    override suspend fun upload(
        fileName: String,
        contentType: String,
        inputStream: InputStream,
        metadata: Map<String, String>
    ): StorageResult = withContext(Dispatchers.IO) {
        try {
            val key = generateKey(fileName)
            val filePath = rootPath.resolve(key)
            
            // Ensure parent directories exist
            Files.createDirectories(filePath.parent)
            
            // Copy input stream to file
            val size = inputStream.use { stream ->
                Files.copy(stream, filePath, StandardCopyOption.REPLACE_EXISTING)
            }
            
            // Save metadata as JSON file
            saveMetadata(key, contentType, metadata)
            
            logger.info { "File uploaded locally: $key ($size bytes)" }
            
            StorageResult(
                key = key,
                url = "$baseUrl/files/$key",
                size = size,
                contentType = contentType,
                metadata = metadata
            )
        } catch (e: Exception) {
            logger.error(e) { "Failed to upload file: $fileName" }
            throw StorageException("Failed to upload file: ${e.message}", e)
        }
    }
    
    override suspend fun download(key: String): ByteArray? = withContext(Dispatchers.IO) {
        try {
            val filePath = rootPath.resolve(key)
            if (Files.exists(filePath)) {
                Files.readAllBytes(filePath)
            } else {
                logger.warn { "File not found: $key" }
                null
            }
        } catch (e: Exception) {
            logger.error(e) { "Failed to download file: $key" }
            null
        }
    }
    
    override suspend fun getPresignedUrl(key: String, expirationSeconds: Int): String? {
        // For local storage, just return the direct URL
        return if (exists(key)) {
            "$baseUrl/files/$key"
        } else {
            null
        }
    }
    
    override suspend fun delete(key: String): Boolean = withContext(Dispatchers.IO) {
        try {
            val filePath = rootPath.resolve(key)
            val metadataPath = rootPath.resolve("$key.metadata")
            
            var deleted = false
            if (Files.exists(filePath)) {
                Files.delete(filePath)
                deleted = true
            }
            if (Files.exists(metadataPath)) {
                Files.delete(metadataPath)
            }
            
            if (deleted) {
                logger.info { "File deleted: $key" }
            }
            deleted
        } catch (e: Exception) {
            logger.error(e) { "Failed to delete file: $key" }
            false
        }
    }
    
    override suspend fun exists(key: String): Boolean = withContext(Dispatchers.IO) {
        Files.exists(rootPath.resolve(key))
    }
    
    override suspend fun getMetadata(key: String): FileMetadata? = withContext(Dispatchers.IO) {
        try {
            val filePath = rootPath.resolve(key)
            if (!Files.exists(filePath)) {
                return@withContext null
            }
            
            val metadataPath = rootPath.resolve("$key.metadata")
            val metadata = if (Files.exists(metadataPath)) {
                val content = Files.readString(metadataPath)
                parseMetadata(content)
            } else {
                emptyMap()
            }
            
            val size = Files.size(filePath)
            val lastModified = Files.getLastModifiedTime(filePath)
            FileMetadata(
                key = key,
                size = size,
                contentType = metadata["contentType"] ?: "application/octet-stream",
                lastModified = Instant.fromEpochMilliseconds(lastModified.toMillis()),
                metadata = metadata
            )
        } catch (e: Exception) {
            logger.error(e) { "Failed to get metadata for file: $key" }
            null
        }
    }
    
    override suspend fun listFiles(prefix: String?, maxResults: Int): List<FileMetadata> = withContext(Dispatchers.IO) {
        try {
            val files = mutableListOf<FileMetadata>()
            val paths = Files.walk(rootPath)
                .filter { Files.isRegularFile(it) }
                .filter { !it.fileName.toString().endsWith(".metadata") }
                .filter { path ->
                    prefix?.let { p ->
                        rootPath.relativize(path).toString().startsWith(p)
                    } ?: true
                }
                .limit(maxResults.toLong())
                .toList()
            
            for (path in paths) {
                val key = rootPath.relativize(path).toString()
                getMetadata(key)?.let { files.add(it) }
            }
            files
        } catch (e: Exception) {
            logger.error(e) { "Failed to list files with prefix: $prefix" }
            emptyList()
        }
    }
    
    private fun generateKey(fileName: String): String {
        val uuid = UUID.randomUUID().toString()
        val extension = fileName.substringAfterLast(".", "")
        val timestamp = Clock.System.now().epochSeconds
        
        return if (extension.isNotEmpty()) {
            "uploads/$timestamp/$uuid.$extension"
        } else {
            "uploads/$timestamp/$uuid"
        }
    }
    
    private suspend fun saveMetadata(key: String, contentType: String, metadata: Map<String, String>) = withContext(Dispatchers.IO) {
        try {
            val metadataPath = rootPath.resolve("$key.metadata")
            Files.createDirectories(metadataPath.parent)
            
            val allMetadata = metadata + mapOf("contentType" to contentType)
            val content = allMetadata.entries.joinToString("\n") { "${it.key}=${it.value}" }
            Files.writeString(metadataPath, content)
        } catch (e: Exception) {
            logger.warn(e) { "Failed to save metadata for: $key" }
        }
    }
    
    private fun parseMetadata(content: String): Map<String, String> {
        return content.lines()
            .filter { it.contains("=") }
            .associate { line ->
                val parts = line.split("=", limit = 2)
                parts[0] to (parts.getOrNull(1) ?: "")
            }
    }
}