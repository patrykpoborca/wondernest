package com.wondernest.services.games

import kotlinx.serialization.Serializable
import kotlinx.serialization.Contextual
import kotlinx.serialization.json.JsonElement
import kotlinx.datetime.Clock
import org.jetbrains.exposed.sql.transactions.transaction
import java.util.UUID

/**
 * Service for managing story reading instances
 * Simplified implementation for initial Story Adventure support
 */
class StoryInstanceService {
    
    private val templateService = StoryTemplateService()
    
    /**
     * Start a new story reading session for a child
     */
    fun startStoryInstance(request: StartStoryInstanceRequest): StoryInstanceResult = transaction {
        try {
            // Verify template exists
            val template = templateService.getTemplateById(request.templateId)
                ?: return@transaction StoryInstanceResult.failure("Story template not found")
            
            val instance = StoryInstance(
                id = UUID.randomUUID().toString(),
                childId = request.childId.toString(),
                templateId = request.templateId.toString(),
                templateTitle = template.title,
                status = "in_progress",
                currentPage = 1,
                totalPages = template.pageCount,
                customizations = request.customizations,
                readingMode = request.readingMode,
                audioEnabled = request.audioEnabled,
                progressData = kotlinx.serialization.json.JsonObject(emptyMap()),
                vocabularyInteractions = kotlinx.serialization.json.JsonObject(emptyMap()),
                comprehensionAnswers = kotlinx.serialization.json.JsonObject(emptyMap()),
                startedAt = Clock.System.now().toString(),
                lastAccessedAt = Clock.System.now().toString(),
                completedAt = null,
                totalReadingTime = 0,
                readingSpeedWpm = 0,
                comprehensionScore = 0,
                vocabularyScore = 0
            )
            
            StoryInstanceResult.success("Story reading session started", instance)
            
        } catch (e: Exception) {
            StoryInstanceResult.failure("Failed to start story session: ${e.message}")
        }
    }
    
    /**
     * Update reading progress for a story instance
     */
    fun updateProgress(instanceId: UUID, request: UpdateProgressRequest): StoryInstanceResult = transaction {
        try {
            // For now, create a mock updated instance
            val instance = StoryInstance(
                id = instanceId.toString(),
                childId = UUID.randomUUID().toString(),
                templateId = UUID.randomUUID().toString(),
                templateTitle = "Mock Template",
                status = "in_progress",
                currentPage = request.currentPage,
                totalPages = 10,
                customizations = request.customizations,
                readingMode = "self_paced",
                audioEnabled = true,
                progressData = request.progressData,
                vocabularyInteractions = request.vocabularyInteractions,
                comprehensionAnswers = request.comprehensionAnswers,
                startedAt = Clock.System.now().toString(),
                lastAccessedAt = Clock.System.now().toString(),
                completedAt = null,
                totalReadingTime = request.totalReadingTime,
                readingSpeedWpm = request.readingSpeedWpm ?: 0,
                comprehensionScore = request.comprehensionScore ?: 0,
                vocabularyScore = request.vocabularyScore ?: 0
            )
            
            StoryInstanceResult.success("Progress updated successfully", instance)
            
        } catch (e: Exception) {
            StoryInstanceResult.failure("Failed to update progress: ${e.message}")
        }
    }
    
    /**
     * Complete a story reading session
     */
    fun completeStoryInstance(instanceId: UUID, request: CompleteStoryRequest): StoryInstanceResult = transaction {
        try {
            val instance = StoryInstance(
                id = instanceId.toString(),
                childId = UUID.randomUUID().toString(),
                templateId = UUID.randomUUID().toString(),
                templateTitle = "Mock Template",
                status = "completed",
                currentPage = 10,
                totalPages = 10,
                customizations = kotlinx.serialization.json.JsonObject(emptyMap()),
                readingMode = "self_paced",
                audioEnabled = true,
                progressData = kotlinx.serialization.json.JsonObject(emptyMap()),
                vocabularyInteractions = kotlinx.serialization.json.JsonObject(emptyMap()),
                comprehensionAnswers = kotlinx.serialization.json.JsonObject(emptyMap()),
                startedAt = Clock.System.now().toString(),
                lastAccessedAt = Clock.System.now().toString(),
                completedAt = Clock.System.now().toString(),
                totalReadingTime = request.totalReadingTime,
                readingSpeedWpm = request.readingSpeedWpm ?: 0,
                comprehensionScore = request.comprehensionScore ?: 0,
                vocabularyScore = request.vocabularyScore ?: 0
            )
            
            StoryInstanceResult.success("Story completed successfully", instance)
            
        } catch (e: Exception) {
            StoryInstanceResult.failure("Failed to complete story: ${e.message}")
        }
    }
    
    /**
     * Get story instance by ID
     */
    fun getInstanceById(instanceId: UUID): StoryInstance? = transaction {
        // Return mock instance
        StoryInstance(
            id = instanceId.toString(),
            childId = UUID.randomUUID().toString(),
            templateId = UUID.randomUUID().toString(),
            templateTitle = "Mock Template",
            status = "in_progress",
            currentPage = 5,
            totalPages = 10,
            customizations = kotlinx.serialization.json.JsonObject(emptyMap()),
            readingMode = "self_paced",
            audioEnabled = true,
            progressData = kotlinx.serialization.json.JsonObject(emptyMap()),
            vocabularyInteractions = kotlinx.serialization.json.JsonObject(emptyMap()),
            comprehensionAnswers = kotlinx.serialization.json.JsonObject(emptyMap()),
            startedAt = Clock.System.now().toString(),
            lastAccessedAt = Clock.System.now().toString(),
            completedAt = null,
            totalReadingTime = 300,
            readingSpeedWpm = 50,
            comprehensionScore = 85,
            vocabularyScore = 90
        )
    }
    
    /**
     * Get all story instances for a child
     */
    fun getInstancesByChild(
        childId: UUID, 
        status: String? = null, 
        templateId: UUID? = null
    ): List<StoryInstance> = transaction {
        // Return mock data
        listOf(
            StoryInstance(
                id = UUID.randomUUID().toString(),
                childId = childId.toString(),
                templateId = UUID.randomUUID().toString(),
                templateTitle = "Welcome to Story Adventure",
                status = "completed",
                currentPage = 5,
                totalPages = 5,
                customizations = kotlinx.serialization.json.JsonObject(emptyMap()),
                readingMode = "self_paced",
                audioEnabled = true,
                progressData = kotlinx.serialization.json.JsonObject(emptyMap()),
                vocabularyInteractions = kotlinx.serialization.json.JsonObject(emptyMap()),
                comprehensionAnswers = kotlinx.serialization.json.JsonObject(emptyMap()),
                startedAt = Clock.System.now().toString(),
                lastAccessedAt = Clock.System.now().toString(),
                completedAt = Clock.System.now().toString(),
                totalReadingTime = 180,
                readingSpeedWpm = 40,
                comprehensionScore = 95,
                vocabularyScore = 88
            )
        )
    }
    
    /**
     * Delete/abandon story instance
     */
    fun abandonStoryInstance(instanceId: UUID): StoryInstanceResult = transaction {
        StoryInstanceResult.success("Story instance abandoned", null)
    }
}

// Data models for StoryInstanceService

@Serializable
data class StoryInstance(
    val id: String,
    val childId: String,
    val templateId: String,
    val templateTitle: String,
    val status: String,
    val currentPage: Int,
    val totalPages: Int,
    val customizations: JsonElement,
    val readingMode: String,
    val audioEnabled: Boolean,
    val progressData: JsonElement,
    val vocabularyInteractions: JsonElement,
    val comprehensionAnswers: JsonElement,
    val startedAt: String,
    val lastAccessedAt: String,
    val completedAt: String?,
    val totalReadingTime: Int,
    val readingSpeedWpm: Int,
    val comprehensionScore: Int,
    val vocabularyScore: Int
)

@Serializable
data class StoryInstanceResult(
    val success: Boolean,
    val message: String,
    val data: StoryInstance?
) {
    companion object {
        fun success(message: String, data: StoryInstance?): StoryInstanceResult {
            return StoryInstanceResult(true, message, data)
        }
        
        fun failure(message: String): StoryInstanceResult {
            return StoryInstanceResult(false, message, null)
        }
    }
}

// Request models
@Serializable
data class StartStoryInstanceRequest(
    @Contextual val childId: UUID,
    @Contextual val templateId: UUID,
    val customizations: JsonElement,
    val readingMode: String = "self_paced",
    val audioEnabled: Boolean = true
)

@Serializable
data class UpdateProgressRequest(
    val currentPage: Int,
    val customizations: JsonElement,
    val progressData: JsonElement,
    val vocabularyInteractions: JsonElement,
    val comprehensionAnswers: JsonElement,
    val totalReadingTime: Int,
    val readingSpeedWpm: Int? = null,
    val comprehensionScore: Int? = null,
    val vocabularyScore: Int? = null
)

@Serializable
data class CompleteStoryRequest(
    val totalReadingTime: Int,
    val readingSpeedWpm: Int? = null,
    val comprehensionScore: Int? = null,
    val vocabularyScore: Int? = null,
    val rating: Int? = null,
    val feedback: String? = null
)