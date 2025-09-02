package com.wondernest.server.service

import com.wondernest.server.domain.model.*
import com.wondernest.server.data.database.table.TagTables
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.SqlExpressionBuilder.inList
import org.jetbrains.exposed.sql.transactions.transaction
import org.jetbrains.exposed.dao.id.EntityID
import java.util.UUID
import kotlinx.datetime.Instant
import org.slf4j.LoggerFactory

class FileTagService {
    private val logger = LoggerFactory.getLogger(FileTagService::class.java)
    
    /**
     * Add tags to a file
     */
    fun addTagsToFile(fileId: UUID, tags: List<String>, userId: UUID): List<FileTag> {
        return transaction {
            
            val addedTags = mutableListOf<FileTag>()
            
            tags.forEach { tagName ->
                val normalizedTag = tagName.lowercase().trim()
                
                // Get or create tag
                val tagId = TagTables.Tags.select { 
                    TagTables.Tags.name eq normalizedTag 
                }.firstOrNull()?.get(TagTables.Tags.id)
                    ?: TagTables.Tags.insertAndGetId {
                        it[name] = normalizedTag
                    }
                
                // Link tag to file
                try {
                    TagTables.FileTags.insert {
                        it[file_id] = fileId
                        it[tag_id] = tagId
                        it[created_by] = userId
                    }
                    
                    // Get the tag details
                    val tag = TagTables.Tags.select { 
                        TagTables.Tags.id eq tagId 
                    }.first().let { row ->
                        FileTag(
                            id = row[TagTables.Tags.id].value,
                            name = row[TagTables.Tags.name],
                            usageCount = row[TagTables.Tags.usage_count],
                            createdAt = row[TagTables.Tags.created_at]
                        )
                    }
                    addedTags.add(tag)
                } catch (e: Exception) {
                    // Tag already linked to file, skip
                    logger.debug("Tag $normalizedTag already linked to file $fileId")
                }
            }
            
            addedTags
        }
    }
    
    /**
     * Remove tags from a file
     */
    fun removeTagsFromFile(fileId: UUID, tags: List<String>): Boolean {
        return transaction {
            
            val tagIds = TagTables.Tags.select { 
                TagTables.Tags.name inList tags.map { it.lowercase().trim() } 
            }.map { it[TagTables.Tags.id] }
            
            TagTables.FileTags.deleteWhere {
                (TagTables.FileTags.file_id eq fileId) and
                (TagTables.FileTags.tag_id inList tagIds)
            } > 0
        }
    }
    
    /**
     * Get tags for a file
     */
    fun getFileTags(fileId: UUID): List<FileTag> {
        return transaction {
            
            TagTables.FileTags
                .innerJoin(TagTables.Tags)
                .select { TagTables.FileTags.file_id eq fileId }
                .map { row ->
                    FileTag(
                        id = row[TagTables.Tags.id].value,
                        name = row[TagTables.Tags.name],
                        usageCount = row[TagTables.Tags.usage_count],
                        createdAt = row[TagTables.Tags.created_at]
                    )
                }
        }
    }
    
    /**
     * Search files by tags
     */
    fun searchFilesByTags(request: TagSearchRequest): List<UploadedFileResponse> {
        return transaction {
            val normalizedTags = request.tags.map { it.lowercase().trim() }
            
            // Get tag IDs for the given tag names
            val tagIds = TagTables.Tags
                .select { TagTables.Tags.name inList normalizedTags }
                .map { it[TagTables.Tags.id] }
            
            if (tagIds.isEmpty()) {
                return@transaction emptyList()
            }
            
            // Get file IDs that have the tags
            val fileQuery = TagTables.FileTags
                .slice(TagTables.FileTags.file_id)
                .select { TagTables.FileTags.tag_id inList tagIds }
                .groupBy(TagTables.FileTags.file_id)
            
            val fileIds = if (request.matchAll) {
                // For AND mode, file must have all tags
                fileQuery
                    .having { TagTables.FileTags.file_id.count() eq tagIds.size.toLong() }
                    .map { it[TagTables.FileTags.file_id] }
            } else {
                // For OR mode, file must have at least one tag
                fileQuery.map { it[TagTables.FileTags.file_id] }
            }
            
            // For now, return empty list as we need to integrate with actual file table
            // This would need to join with the uploaded_files table which needs to be defined
            logger.info("Found ${fileIds.size} files matching tags: $normalizedTags")
            
            // TODO: Join with uploaded_files table and return actual file data
            emptyList()
        }
    }
    
    /**
     * Get tag suggestions based on partial input
     */
    fun getTagSuggestions(prefix: String, limit: Int = 10): List<TagSuggestion> {
        return transaction {
            
            TagTables.Tags
                .select { 
                    TagTables.Tags.name like "${prefix.lowercase()}%" 
                }
                .orderBy(TagTables.Tags.usage_count to SortOrder.DESC)
                .limit(limit)
                .map { row ->
                    TagSuggestion(
                        tag = row[TagTables.Tags.name],
                        usageCount = row[TagTables.Tags.usage_count],
                        isPopular = row[TagTables.Tags.usage_count] > 10
                    )
                }
        }
    }
    
    /**
     * Get popular tags
     */
    fun getPopularTags(limit: Int = 20): List<TagSuggestion> {
        return transaction {
            
            TagTables.Tags
                .selectAll()
                .orderBy(TagTables.Tags.usage_count to SortOrder.DESC)
                .limit(limit)
                .map { row ->
                    TagSuggestion(
                        tag = row[TagTables.Tags.name],
                        usageCount = row[TagTables.Tags.usage_count],
                        isPopular = true
                    )
                }
        }
    }
    
    /**
     * Validate tags meet requirements
     */
    fun validateTags(tags: List<String>, isSystemImage: Boolean = false): ValidationResult {
        if (!isSystemImage && tags.size < 2) {
            return ValidationResult(
                isValid = false,
                errors = listOf("At least 2 tags are required")
            )
        }
        
        val errors = mutableListOf<String>()
        tags.forEach { tag ->
            if (tag.isBlank()) {
                errors.add("Tags cannot be blank")
            }
            if (tag.length > 50) {
                errors.add("Tag '$tag' exceeds 50 characters")
            }
            if (!tag.matches(Regex("^[a-zA-Z0-9-_]+$"))) {
                errors.add("Tag '$tag' contains invalid characters")
            }
        }
        
        return ValidationResult(
            isValid = errors.isEmpty(),
            errors = errors
        )
    }
}

data class ValidationResult(
    val isValid: Boolean,
    val errors: List<String> = emptyList()
)