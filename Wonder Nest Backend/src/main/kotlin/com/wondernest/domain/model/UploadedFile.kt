package com.wondernest.domain.model

import kotlinx.datetime.Instant
import kotlinx.serialization.Serializable
import java.util.UUID

/**
 * Domain model for uploaded files
 */
data class UploadedFile(
    val id: UUID,
    val userId: UUID,
    val childId: UUID? = null,
    val fileKey: String,
    val originalName: String,
    val mimeType: String,
    val fileSize: Long,
    val storageProvider: String,
    val url: String? = null,
    val isPublic: Boolean = false,
    val category: FileCategory,
    val metadata: Map<String, String> = emptyMap(),
    val uploadedAt: Instant,
    val accessedAt: Instant? = null,
    val deletedAt: Instant? = null
)

/**
 * File category enumeration
 */
enum class FileCategory {
    PROFILE_PICTURE,
    CONTENT,
    DOCUMENT,
    GAME_ASSET,
    ARTWORK;
    
    companion object {
        fun fromString(value: String): FileCategory {
            return when (value.lowercase()) {
                "profile_picture" -> PROFILE_PICTURE
                "content" -> CONTENT
                "document" -> DOCUMENT
                "game_asset" -> GAME_ASSET
                "artwork" -> ARTWORK
                else -> CONTENT
            }
        }
    }
    
    fun toDbValue(): String {
        return when (this) {
            PROFILE_PICTURE -> "profile_picture"
            CONTENT -> "content"
            DOCUMENT -> "document"
            GAME_ASSET -> "game_asset"
            ARTWORK -> "artwork"
        }
    }
}

/**
 * DTO for file upload response
 */
@Serializable
data class UploadedFileDto(
    val id: String,
    val originalName: String,
    val mimeType: String,
    val fileSize: Long,
    val category: String,
    val url: String? = null,
    val uploadedAt: String,
    val metadata: Map<String, String> = emptyMap()
)