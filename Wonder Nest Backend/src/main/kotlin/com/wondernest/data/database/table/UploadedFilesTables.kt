package com.wondernest.data.database.table

import org.jetbrains.exposed.dao.id.UUIDTable
import org.jetbrains.exposed.sql.Column
import org.jetbrains.exposed.sql.ReferenceOption
import org.jetbrains.exposed.sql.kotlin.datetime.timestamp
import org.jetbrains.exposed.sql.json.jsonb
import kotlinx.serialization.json.Json
import kotlinx.serialization.encodeToString
import kotlinx.serialization.decodeFromString
import java.util.UUID

/**
 * Table for tracking uploaded files
 */
object UploadedFiles : UUIDTable("core.uploaded_files") {
    val userId: Column<UUID> = uuid("user_id").references(Users.id, onDelete = ReferenceOption.CASCADE)
    val childId: Column<UUID?> = uuid("child_id").references(ChildProfiles.id, onDelete = ReferenceOption.CASCADE).nullable()
    
    // File information
    val fileKey = varchar("file_key", 500).uniqueIndex()
    val originalName = varchar("original_name", 255)
    val mimeType = varchar("mime_type", 100)
    val fileSize = long("file_size")
    val storageProvider = varchar("storage_provider", 50).default("local")
    
    // URL and access
    val url = text("url").nullable()
    val isPublic = bool("is_public").default(false)
    
    // Categorization
    val category = varchar("category", 50).default("content")
    
    // Metadata (stored as JSONB)
    val metadata = jsonb<Map<String, String>>("metadata",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    )
    
    // Timestamps
    val uploadedAt = timestamp("uploaded_at")
    val accessedAt = timestamp("accessed_at").nullable()
    val deletedAt = timestamp("deleted_at").nullable()
}