package com.wondernest.services.storage

import io.ktor.server.application.*
import mu.KotlinLogging
import java.io.InputStream

private val logger = KotlinLogging.logger {}

/**
 * Service for validating uploaded files
 */
class FileValidationService(
    private val application: Application
) {
    private val config = application.environment.config
    
    // Default max file size: 10MB
    private val maxFileSize: Long = try {
        config.property("storage.max-file-size").getString().toLong()
    } catch (e: Exception) {
        10 * 1024 * 1024 // 10MB default
    }
    
    // Allowed MIME types
    private val allowedMimeTypes: Set<String> = try {
        config.property("storage.allowed-mime-types").getString()
            .split(",")
            .map { it.trim() }
            .toSet()
    } catch (e: Exception) {
        // Default allowed types
        setOf(
            "image/jpeg",
            "image/png",
            "image/gif",
            "image/webp",
            "application/pdf",
            "video/mp4",
            "video/webm",
            "audio/mpeg",
            "audio/wav"
        )
    }
    
    /**
     * Validate file before upload
     */
    fun validateFile(
        fileName: String,
        contentType: String,
        fileSize: Long
    ): ValidationResult {
        // Check file size
        if (fileSize > maxFileSize) {
            return ValidationResult(
                isValid = false,
                error = "File size exceeds maximum allowed size of ${maxFileSize / (1024 * 1024)}MB"
            )
        }
        
        // Check MIME type
        if (!allowedMimeTypes.contains(contentType)) {
            return ValidationResult(
                isValid = false,
                error = "File type '$contentType' is not allowed"
            )
        }
        
        // Check file extension matches content type
        val extension = fileName.substringAfterLast(".", "").lowercase()
        if (!isExtensionValidForContentType(extension, contentType)) {
            return ValidationResult(
                isValid = false,
                error = "File extension does not match content type"
            )
        }
        
        return ValidationResult(isValid = true)
    }
    
    /**
     * Check if file content matches declared content type (magic bytes check)
     */
    fun validateFileContent(inputStream: InputStream, contentType: String): Boolean {
        return try {
            val magicBytes = ByteArray(16)
            val bytesRead = inputStream.read(magicBytes)
            inputStream.reset() // Reset stream for actual upload
            
            if (bytesRead < 4) {
                return false
            }
            
            when (contentType) {
                "image/jpeg" -> {
                    // JPEG magic bytes: FF D8 FF
                    magicBytes[0] == 0xFF.toByte() && 
                    magicBytes[1] == 0xD8.toByte() && 
                    magicBytes[2] == 0xFF.toByte()
                }
                "image/png" -> {
                    // PNG magic bytes: 89 50 4E 47
                    magicBytes[0] == 0x89.toByte() && 
                    magicBytes[1] == 0x50.toByte() && 
                    magicBytes[2] == 0x4E.toByte() && 
                    magicBytes[3] == 0x47.toByte()
                }
                "image/gif" -> {
                    // GIF magic bytes: 47 49 46 38 (GIF8)
                    magicBytes[0] == 0x47.toByte() && 
                    magicBytes[1] == 0x49.toByte() && 
                    magicBytes[2] == 0x46.toByte() && 
                    magicBytes[3] == 0x38.toByte()
                }
                "application/pdf" -> {
                    // PDF magic bytes: 25 50 44 46 (%PDF)
                    magicBytes[0] == 0x25.toByte() && 
                    magicBytes[1] == 0x50.toByte() && 
                    magicBytes[2] == 0x44.toByte() && 
                    magicBytes[3] == 0x46.toByte()
                }
                else -> {
                    // For other types, skip magic byte validation
                    true
                }
            }
        } catch (e: Exception) {
            logger.error(e) { "Error validating file content" }
            false
        }
    }
    
    private fun isExtensionValidForContentType(extension: String, contentType: String): Boolean {
        return when (contentType) {
            "image/jpeg" -> extension in listOf("jpg", "jpeg")
            "image/png" -> extension == "png"
            "image/gif" -> extension == "gif"
            "image/webp" -> extension == "webp"
            "application/pdf" -> extension == "pdf"
            "video/mp4" -> extension == "mp4"
            "video/webm" -> extension == "webm"
            "audio/mpeg" -> extension in listOf("mp3", "mpeg")
            "audio/wav" -> extension == "wav"
            else -> true // Allow unknown types
        }
    }
    
    data class ValidationResult(
        val isValid: Boolean,
        val error: String? = null
    )
}