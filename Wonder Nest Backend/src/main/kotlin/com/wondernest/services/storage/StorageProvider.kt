package com.wondernest.services.storage

import kotlinx.datetime.Instant
import java.io.InputStream

/**
 * Storage provider interface for file operations
 */
interface StorageProvider {
    suspend fun upload(
        fileName: String,
        contentType: String,
        inputStream: InputStream,
        metadata: Map<String, String> = emptyMap()
    ): StorageResult
    
    suspend fun download(key: String): ByteArray?
    
    suspend fun getPresignedUrl(key: String, expirationSeconds: Int = 3600): String?
    
    suspend fun delete(key: String): Boolean
    
    suspend fun exists(key: String): Boolean
    
    suspend fun getMetadata(key: String): FileMetadata?
    
    suspend fun listFiles(prefix: String? = null, maxResults: Int = 100): List<FileMetadata>
}

/**
 * Result of a storage operation
 */
data class StorageResult(
    val key: String,
    val url: String? = null,
    val size: Long,
    val contentType: String,
    val metadata: Map<String, String> = emptyMap()
)

/**
 * File metadata
 */
data class FileMetadata(
    val key: String,
    val size: Long,
    val contentType: String,
    val lastModified: Instant,
    val metadata: Map<String, String> = emptyMap()
)

/**
 * Storage exception
 */
class StorageException(message: String, cause: Throwable? = null) : Exception(message, cause)