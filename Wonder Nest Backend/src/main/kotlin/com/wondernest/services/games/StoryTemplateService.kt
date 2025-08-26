package com.wondernest.services.games

import kotlinx.serialization.Serializable
import kotlinx.serialization.Contextual
import kotlinx.serialization.json.JsonElement
import kotlinx.datetime.Clock
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.transactions.transaction
import java.util.UUID

/**
 * Service for managing story template operations
 * Uses simplified approach with direct SQL for games schema access
 */
class StoryTemplateService {
    
    /**
     * Get story template by ID (simplified version)
     */
    fun getTemplateById(templateId: UUID): StoryTemplate? = transaction {
        // For now, return a mock template - will implement proper SQL later
        StoryTemplate(
            id = templateId.toString(),
            title = "Mock Template",
            description = "This is a mock template for testing",
            creatorId = null,
            ageGroup = "6-8",
            difficulty = "developing",
            content = kotlinx.serialization.json.JsonObject(emptyMap()),
            vocabularyWords = listOf("test", "mock"),
            pageCount = 10,
            estimatedReadTime = 5,
            language = "en",
            version = "1.0.0",
            isPremium = false,
            isMarketplace = false,
            isActive = true,
            isPrivate = false,
            educationalGoals = listOf("vocabulary"),
            themes = listOf("test"),
            tags = listOf("mock"),
            createdAt = Clock.System.now().toString(),
            updatedAt = Clock.System.now().toString()
        )
    }
    
    /**
     * Search story templates (simplified version)
     */
    fun searchTemplates(request: SearchStoryTemplatesRequest): List<StoryTemplate> = transaction {
        // For now, return mock data from database seed
        // In a real implementation, this would query the games.story_templates table
        
        val mockTemplates = listOf(
            StoryTemplate(
                id = UUID.randomUUID().toString(),
                title = "Welcome to Story Adventure",
                description = "Your very first interactive story adventure!",
                creatorId = null,
                ageGroup = "3-5",
                difficulty = "emerging",
                content = kotlinx.serialization.json.JsonObject(emptyMap()),
                vocabularyWords = listOf("adventure", "welcome", "story"),
                pageCount = 5,
                estimatedReadTime = 3,
                language = "en",
                version = "1.0.0",
                isPremium = false,
                isMarketplace = false,
                isActive = true,
                isPrivate = false,
                educationalGoals = listOf("vocabulary", "reading engagement"),
                themes = listOf("welcome", "introduction"),
                tags = listOf("beginner", "introduction", "system"),
                createdAt = Clock.System.now().toString(),
                updatedAt = Clock.System.now().toString()
            )
        )
        
        mockTemplates
    }
    
    /**
     * Create story template (simplified stub)
     */
    fun createTemplate(request: CreateStoryTemplateRequest): StoryTemplateResult = transaction {
        try {
            val template = StoryTemplate(
                id = UUID.randomUUID().toString(),
                title = request.title,
                description = request.description,
                creatorId = request.creatorId?.toString(),
                ageGroup = request.ageGroup,
                difficulty = request.difficulty,
                content = request.content,
                vocabularyWords = request.vocabularyWords,
                pageCount = request.pageCount,
                estimatedReadTime = request.estimatedReadTime,
                language = request.language,
                version = request.version,
                isPremium = request.isPremium,
                isMarketplace = request.isMarketplace,
                isActive = request.isActive,
                isPrivate = request.isPrivate,
                educationalGoals = request.educationalGoals,
                themes = request.themes,
                tags = request.tags,
                createdAt = Clock.System.now().toString(),
                updatedAt = Clock.System.now().toString()
            )
            
            StoryTemplateResult.success("Story template created successfully", template)
        } catch (e: Exception) {
            StoryTemplateResult.failure("Failed to create story template: ${e.message}")
        }
    }
    
    /**
     * Update story template (simplified stub)
     */
    fun updateTemplate(templateId: UUID, request: UpdateStoryTemplateRequest): StoryTemplateResult = transaction {
        StoryTemplateResult.failure("Update not implemented yet")
    }
    
    /**
     * Delete story template (simplified stub)
     */
    fun deleteTemplate(templateId: UUID, creatorId: UUID? = null): StoryTemplateResult = transaction {
        StoryTemplateResult.failure("Delete not implemented yet")
    }
    
    /**
     * Get templates by creator (simplified stub)
     */
    fun getTemplatesByCreator(creatorId: UUID, includePrivate: Boolean = true): List<StoryTemplate> = transaction {
        emptyList()
    }
}

// Data models for StoryTemplateService

@Serializable
data class StoryTemplate(
    val id: String,
    val title: String,
    val description: String,
    val creatorId: String?,
    val ageGroup: String,
    val difficulty: String,
    val content: JsonElement,
    val vocabularyWords: List<String>,
    val pageCount: Int,
    val estimatedReadTime: Int,
    val language: String,
    val version: String,
    val isPremium: Boolean,
    val isMarketplace: Boolean,
    val isActive: Boolean,
    val isPrivate: Boolean,
    val educationalGoals: List<String>,
    val themes: List<String>,
    val tags: List<String>,
    val createdAt: String,
    val updatedAt: String
)

@Serializable
data class StoryTemplateResult(
    val success: Boolean,
    val message: String,
    val data: StoryTemplate?
) {
    companion object {
        fun success(message: String, data: StoryTemplate?): StoryTemplateResult {
            return StoryTemplateResult(true, message, data)
        }
        
        fun failure(message: String): StoryTemplateResult {
            return StoryTemplateResult(false, message, null)
        }
    }
}

// Request models
@Serializable
data class CreateStoryTemplateRequest(
    val title: String,
    val description: String,
    @Contextual val creatorId: UUID?,
    val ageGroup: String,
    val difficulty: String,
    val content: JsonElement,
    val vocabularyWords: List<String>,
    val pageCount: Int,
    val estimatedReadTime: Int,
    val language: String = "en",
    val version: String = "1.0.0",
    val isPremium: Boolean = false,
    val isMarketplace: Boolean = false,
    val isActive: Boolean = true,
    val isPrivate: Boolean = false,
    val educationalGoals: List<String> = emptyList(),
    val themes: List<String> = emptyList(),
    val tags: List<String> = emptyList()
)

@Serializable
data class UpdateStoryTemplateRequest(
    val title: String,
    val description: String,
    val ageGroup: String,
    val difficulty: String,
    val content: JsonElement,
    val vocabularyWords: List<String>,
    val pageCount: Int,
    val estimatedReadTime: Int,
    val language: String,
    val version: String,
    val isPremium: Boolean,
    val isMarketplace: Boolean,
    val isActive: Boolean,
    val isPrivate: Boolean,
    val educationalGoals: List<String>,
    val themes: List<String>,
    val tags: List<String>
)

@Serializable
data class SearchStoryTemplatesRequest(
    val ageGroup: String? = null,
    val difficulty: String? = null,
    val category: String? = null,
    val includeMarketplace: Boolean? = null,
    @Contextual val creatorId: UUID? = null,
    val limit: Int = 20,
    val offset: Int = 0
)