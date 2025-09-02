package com.wondernest.server.domain.model

import kotlinx.serialization.Serializable
import kotlinx.serialization.Contextual
import kotlinx.datetime.Instant
import kotlinx.datetime.Clock
import java.util.UUID

/**
 * Domain model for file tags
 */
@Serializable
data class FileTag(
    @Contextual val id: UUID = UUID.randomUUID(),
    val name: String,
    val usageCount: Int = 0,
    @Contextual val createdAt: Instant = Clock.System.now()
) {
    init {
        require(name.isNotBlank()) { "Tag name cannot be blank" }
        require(name.length <= 50) { "Tag name cannot exceed 50 characters" }
        require(name.matches(Regex("^[a-zA-Z0-9-_]+$"))) { 
            "Tag name can only contain letters, numbers, hyphens and underscores" 
        }
    }
}

/**
 * Request model for uploading files with tags
 */
@Serializable
data class FileUploadRequest(
    val fileName: String,
    val contentType: String,
    val category: String,
    val tags: List<String>,
    @Contextual val childId: UUID? = null,
    val isPublic: Boolean = false,
    val isSystemImage: Boolean = false
) {
    init {
        require(tags.size >= 2 || isSystemImage) { 
            "Files must have at least 2 tags (system images excluded)" 
        }
        tags.forEach { tag ->
            require(tag.isNotBlank()) { "Tags cannot be blank" }
            require(tag.length <= 50) { "Tag cannot exceed 50 characters" }
            require(tag.matches(Regex("^[a-zA-Z0-9-_]+$"))) { 
                "Tag '$tag' contains invalid characters" 
            }
        }
    }
}

/**
 * Response model for uploaded files with tags
 */
@Serializable
data class UploadedFileResponse(
    @Contextual val id: UUID,
    val originalName: String,
    val mimeType: String,
    val fileSize: Long,
    val category: String,
    val tags: List<String>,
    val tagCount: Int,
    val url: String?,
    @Contextual val uploadedAt: Instant,
    val isSystemImage: Boolean = false,
    val metadata: Map<String, String>? = null
)

/**
 * Tag suggestion response
 */
@Serializable
data class TagSuggestion(
    val tag: String,
    val usageCount: Int,
    val isPopular: Boolean = false
)

/**
 * Request for searching files by tags
 */
@Serializable
data class TagSearchRequest(
    val tags: List<String>,
    val matchAll: Boolean = false, // true = AND, false = OR
    val category: String? = null,
    @Contextual val childId: UUID? = null,
    val limit: Int = 50,
    val offset: Int = 0
)