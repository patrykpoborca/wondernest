package com.wondernest.server.data.database.table

import org.jetbrains.exposed.dao.id.UUIDTable
import org.jetbrains.exposed.sql.ReferenceOption
import org.jetbrains.exposed.sql.kotlin.datetime.timestamp
import org.jetbrains.exposed.sql.kotlin.datetime.CurrentTimestamp

/**
 * Database tables for tag system
 */
object TagTables {
    
    /**
     * Tags table for storing unique tags
     */
    object Tags : UUIDTable("content.tags") {
        val name = varchar("name", 50).uniqueIndex()
        val usage_count = integer("usage_count").default(0)
        val created_at = timestamp("created_at").defaultExpression(CurrentTimestamp())
    }
    
    /**
     * Junction table for file-tag relationships
     */
    object FileTags : UUIDTable("content.file_tags") {
        val file_id = uuid("file_id")
        val tag_id = reference("tag_id", Tags.id, onDelete = ReferenceOption.CASCADE)
        val created_at = timestamp("created_at").defaultExpression(CurrentTimestamp())
        val created_by = uuid("created_by").nullable() // Reference to core.users
        
        init {
            uniqueIndex(file_id, tag_id)
            index(false, file_id)
            index(false, tag_id)
        }
    }
}