package com.wondernest.services.games

import kotlinx.serialization.Serializable
import kotlinx.serialization.Contextual
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.int
import kotlinx.serialization.json.long
import kotlinx.serialization.json.boolean
import kotlinx.serialization.json.Json
import kotlinx.serialization.encodeToString
import kotlinx.serialization.decodeFromString
import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.transactions.transaction
import org.jetbrains.exposed.sql.upsert
import com.wondernest.data.database.table.SimpleGameData
import java.util.UUID

/**
 * Service for managing story reading instances using plugin architecture
 * Now stores data in games.simple_game_data with game_type = 'story-adventure'
 * Follows WonderNest's plugin pattern for child data storage
 */
class StoryInstanceService {
    
    private val templateService = StoryTemplateService()
    private val gameType = "story-adventure"

    /**
     * Start a new story reading session for a child
     * Stores data in games.simple_game_data using plugin architecture
     */
    fun startStoryInstance(request: StartStoryInstanceRequest): StoryInstanceResult = transaction {
        try {
            // Verify template exists
            val template = templateService.getTemplateById(request.templateId)
                ?: return@transaction StoryInstanceResult.failure("Story template not found")
            
            val instanceId = UUID.randomUUID().toString()
            val now = Clock.System.now()
            val dataKey = "story_instance:${request.templateId}"
            
            // Create instance data structure
            val instanceData = mapOf(
                "instanceId" to JsonPrimitive(instanceId),
                "templateId" to JsonPrimitive(request.templateId.toString()),
                "templateTitle" to JsonPrimitive(template.title),
                "status" to JsonPrimitive("in_progress"),
                "currentPage" to JsonPrimitive(1),
                "totalPages" to JsonPrimitive(template.pageCount),
                "customizations" to request.customizations,
                "readingMode" to JsonPrimitive(request.readingMode),
                "audioEnabled" to JsonPrimitive(request.audioEnabled),
                "progressData" to JsonObject(emptyMap()),
                "vocabularyInteractions" to JsonObject(emptyMap()),
                "comprehensionAnswers" to JsonObject(emptyMap()),
                "startedAt" to JsonPrimitive(now.epochSeconds),
                "lastAccessedAt" to JsonPrimitive(now.epochSeconds),
                "completedAt" to JsonNull,
                "totalReadingTime" to JsonPrimitive(0),
                "readingSpeedWpm" to JsonPrimitive(0),
                "comprehensionScore" to JsonPrimitive(0),
                "vocabularyScore" to JsonPrimitive(0)
            )
            
            // Store in simple_game_data using UPSERT
            SimpleGameData.upsert(
                keys = arrayOf(SimpleGameData.childId, SimpleGameData.gameType, SimpleGameData.dataKey)
            ) {
                it[SimpleGameData.childId] = request.childId
                it[SimpleGameData.gameType] = gameType
                it[SimpleGameData.dataKey] = dataKey
                it[SimpleGameData.dataValue] = instanceData
                it[SimpleGameData.createdAt] = now
                it[SimpleGameData.updatedAt] = now
            }
            
            // Create StoryInstance response object
            val instance = StoryInstance(
                id = instanceId,
                childId = request.childId.toString(),
                templateId = request.templateId.toString(),
                templateTitle = template.title,
                status = "in_progress",
                currentPage = 1,
                totalPages = template.pageCount,
                customizations = request.customizations,
                readingMode = request.readingMode,
                audioEnabled = request.audioEnabled,
                progressData = JsonObject(emptyMap()),
                vocabularyInteractions = JsonObject(emptyMap()),
                comprehensionAnswers = JsonObject(emptyMap()),
                startedAt = now.toString(),
                lastAccessedAt = now.toString(),
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
     * Updates data in games.simple_game_data using plugin architecture
     */
    fun updateProgress(instanceId: UUID, request: UpdateProgressRequest): StoryInstanceResult = transaction {
        try {
            // First, find the existing instance by searching for instanceId in JSONB
            val existingData = SimpleGameData.select {
                (SimpleGameData.gameType eq gameType) and
                (SimpleGameData.dataKey like "story_instance:%")
            }.singleOrNull { row ->
                val data = row[SimpleGameData.dataValue]
                (data["instanceId"] as? JsonPrimitive)?.content == instanceId.toString()
            }
            
            if (existingData == null) {
                return@transaction StoryInstanceResult.failure("Story instance not found")
            }
            
            val childId = existingData[SimpleGameData.childId]
            val dataKey = existingData[SimpleGameData.dataKey]
            val currentData = existingData[SimpleGameData.dataValue]
            val now = Clock.System.now()
            
            // Update the instance data
            val updatedData = currentData.toMutableMap().apply {
                put("currentPage", JsonPrimitive(request.currentPage))
                put("customizations", request.customizations)
                put("progressData", request.progressData)
                put("vocabularyInteractions", request.vocabularyInteractions)
                put("comprehensionAnswers", request.comprehensionAnswers)
                put("totalReadingTime", JsonPrimitive(request.totalReadingTime))
                put("lastAccessedAt", JsonPrimitive(now.epochSeconds))
                request.readingSpeedWpm?.let { put("readingSpeedWpm", JsonPrimitive(it)) }
                request.comprehensionScore?.let { put("comprehensionScore", JsonPrimitive(it)) }
                request.vocabularyScore?.let { put("vocabularyScore", JsonPrimitive(it)) }
            }
            
            // Update in database
            SimpleGameData.update(
                where = { 
                    (SimpleGameData.childId eq childId) and 
                    (SimpleGameData.gameType eq gameType) and 
                    (SimpleGameData.dataKey eq dataKey)
                }
            ) {
                it[SimpleGameData.dataValue] = updatedData
                it[SimpleGameData.updatedAt] = now
            }
            
            // Create response instance
            val instance = createStoryInstanceFromData(updatedData, childId.toString())
            
            StoryInstanceResult.success("Progress updated successfully", instance)
            
        } catch (e: Exception) {
            StoryInstanceResult.failure("Failed to update progress: ${e.message}")
        }
    }

    /**
     * Complete a story reading session
     * Updates status to completed and moves to story_history
     */
    fun completeStoryInstance(instanceId: UUID, request: CompleteStoryRequest): StoryInstanceResult = transaction {
        try {
            // Find the existing instance
            val existingData = SimpleGameData.select {
                (SimpleGameData.gameType eq gameType) and
                (SimpleGameData.dataKey like "story_instance:%")
            }.singleOrNull { row ->
                val data = row[SimpleGameData.dataValue]
                (data["instanceId"] as? JsonPrimitive)?.content == instanceId.toString()
            }
            
            if (existingData == null) {
                return@transaction StoryInstanceResult.failure("Story instance not found")
            }
            
            val childId = existingData[SimpleGameData.childId]
            val dataKey = existingData[SimpleGameData.dataKey]
            val currentData = existingData[SimpleGameData.dataValue]
            val now = Clock.System.now()
            
            // Update the instance data to completed status
            val completedData = currentData.toMutableMap().apply {
                put("status", JsonPrimitive("completed"))
                put("completedAt", JsonPrimitive(now.epochSeconds))
                put("totalReadingTime", JsonPrimitive(request.totalReadingTime))
                put("lastAccessedAt", JsonPrimitive(now.epochSeconds))
                request.readingSpeedWpm?.let { put("readingSpeedWpm", JsonPrimitive(it)) }
                request.comprehensionScore?.let { put("comprehensionScore", JsonPrimitive(it)) }
                request.vocabularyScore?.let { put("vocabularyScore", JsonPrimitive(it)) }
                request.rating?.let { put("rating", JsonPrimitive(it)) }
                request.feedback?.let { put("feedback", JsonPrimitive(it)) }
            }
            
            // Update the instance
            SimpleGameData.update(
                where = { 
                    (SimpleGameData.childId eq childId) and 
                    (SimpleGameData.gameType eq gameType) and 
                    (SimpleGameData.dataKey eq dataKey)
                }
            ) {
                it[SimpleGameData.dataValue] = completedData
                it[SimpleGameData.updatedAt] = now
            }
            
            // Add to story history
            updateStoryHistory(childId, completedData)
            
            val instance = createStoryInstanceFromData(completedData, childId.toString())
            
            StoryInstanceResult.success("Story completed successfully", instance)
            
        } catch (e: Exception) {
            StoryInstanceResult.failure("Failed to complete story: ${e.message}")
        }
    }

    /**
     * Get story instance by ID
     * Searches in games.simple_game_data for the instance
     */
    fun getInstanceById(instanceId: UUID): StoryInstance? = transaction {
        try {
            val data = SimpleGameData.select {
                (SimpleGameData.gameType eq gameType) and
                (SimpleGameData.dataKey like "story_instance:%")
            }.singleOrNull { row ->
                val dataValue = row[SimpleGameData.dataValue]
                (dataValue["instanceId"] as? JsonPrimitive)?.content == instanceId.toString()
            }
            
            if (data != null) {
                createStoryInstanceFromData(data[SimpleGameData.dataValue], data[SimpleGameData.childId].toString())
            } else {
                null
            }
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Get all story instances for a child
     * Searches in games.simple_game_data for child's story instances
     */
    fun getInstancesByChild(
        childId: UUID, 
        status: String? = null, 
        templateId: UUID? = null
    ): List<StoryInstance> = transaction {
        try {
            val query = SimpleGameData.select {
                (SimpleGameData.childId eq childId) and
                (SimpleGameData.gameType eq gameType) and
                (SimpleGameData.dataKey like "story_instance:%")
            }
            
            val results = query.map { row ->
                val data = row[SimpleGameData.dataValue]
                createStoryInstanceFromData(data, childId.toString())
            }
            
            // Apply filters
            results.filter { instance ->
                val statusMatch = status == null || instance.status == status
                val templateMatch = templateId == null || instance.templateId == templateId.toString()
                statusMatch && templateMatch
            }
            
        } catch (e: Exception) {
            emptyList()
        }
    }

    /**
     * Delete/abandon story instance
     * Removes from games.simple_game_data
     */
    fun abandonStoryInstance(instanceId: UUID): StoryInstanceResult = transaction {
        try {
            // Find the record to delete first
            val recordToDelete = SimpleGameData.select {
                (SimpleGameData.gameType eq gameType) and
                (SimpleGameData.dataKey like "story_instance:%")
            }.singleOrNull { row ->
                val data = row[SimpleGameData.dataValue]
                (data["instanceId"] as? JsonPrimitive)?.content == instanceId.toString()
            }
            
            val deleted = if (recordToDelete != null) {
                SimpleGameData.deleteWhere {
                    SimpleGameData.id eq recordToDelete[SimpleGameData.id]
                }
            } else 0
            
            if (deleted > 0) {
                StoryInstanceResult.success("Story instance abandoned", null)
            } else {
                StoryInstanceResult.failure("Story instance not found")
            }
        } catch (e: Exception) {
            StoryInstanceResult.failure("Failed to abandon story instance: ${e.message}")
        }
    }
    
    /**
     * Helper function to create StoryInstance from JSONB data
     */
    private fun createStoryInstanceFromData(data: Map<String, JsonElement>, childId: String): StoryInstance {
        return StoryInstance(
            id = (data["instanceId"] as? JsonPrimitive)?.content ?: "",
            childId = childId,
            templateId = (data["templateId"] as? JsonPrimitive)?.content ?: "",
            templateTitle = (data["templateTitle"] as? JsonPrimitive)?.content ?: "",
            status = (data["status"] as? JsonPrimitive)?.content ?: "in_progress",
            currentPage = (data["currentPage"] as? JsonPrimitive)?.int ?: 1,
            totalPages = (data["totalPages"] as? JsonPrimitive)?.int ?: 0,
            customizations = data["customizations"] ?: JsonObject(emptyMap()),
            readingMode = (data["readingMode"] as? JsonPrimitive)?.content ?: "self_paced",
            audioEnabled = (data["audioEnabled"] as? JsonPrimitive)?.boolean ?: true,
            progressData = data["progressData"] ?: JsonObject(emptyMap()),
            vocabularyInteractions = data["vocabularyInteractions"] ?: JsonObject(emptyMap()),
            comprehensionAnswers = data["comprehensionAnswers"] ?: JsonObject(emptyMap()),
            startedAt = (data["startedAt"] as? JsonPrimitive)?.long?.let { Instant.fromEpochSeconds(it).toString() } ?: "",
            lastAccessedAt = (data["lastAccessedAt"] as? JsonPrimitive)?.long?.let { Instant.fromEpochSeconds(it).toString() } ?: "",
            completedAt = data["completedAt"]?.takeIf { it !is JsonNull }?.let { (it as? JsonPrimitive)?.long?.let { Instant.fromEpochSeconds(it).toString() } },
            totalReadingTime = (data["totalReadingTime"] as? JsonPrimitive)?.int ?: 0,
            readingSpeedWpm = (data["readingSpeedWpm"] as? JsonPrimitive)?.int ?: 0,
            comprehensionScore = (data["comprehensionScore"] as? JsonPrimitive)?.int ?: 0,
            vocabularyScore = (data["vocabularyScore"] as? JsonPrimitive)?.int ?: 0
        )
    }
    
    /**
     * Helper function to update story history when a story is completed
     */
    private fun updateStoryHistory(childId: UUID, completedStoryData: Map<String, kotlinx.serialization.json.JsonElement>) {
        // Get existing story history or create new
        val existingHistory = SimpleGameData.select {
            (SimpleGameData.childId eq childId) and
            (SimpleGameData.gameType eq gameType) and
            (SimpleGameData.dataKey eq "story_history")
        }.singleOrNull()
        
        val now = Clock.System.now()
        val completedStory = mapOf(
            "templateId" to (completedStoryData["templateId"] ?: JsonPrimitive("")),
            "completedAt" to (completedStoryData["completedAt"] ?: JsonPrimitive(now.epochSeconds)),
            "totalReadingTime" to (completedStoryData["totalReadingTime"] ?: JsonPrimitive(0)),
            "comprehensionScore" to (completedStoryData["comprehensionScore"] ?: JsonPrimitive(0)),
            "vocabularyScore" to (completedStoryData["vocabularyScore"] ?: JsonPrimitive(0)),
            "readingSpeedWpm" to (completedStoryData["readingSpeedWpm"] ?: JsonPrimitive(0))
        )
        
        if (existingHistory != null) {
            // Update existing history
            val currentHistory = existingHistory[SimpleGameData.dataValue]
            val completedStories = (currentHistory["completedStories"] as? JsonArray)?.toMutableList() ?: mutableListOf()
            completedStories.add(0, JsonObject(completedStory)) // Add to beginning
            
            val updatedHistory = currentHistory.toMutableMap().apply {
                put("completedStories", JsonArray(completedStories))
                put("totalCompletedStories", JsonPrimitive(completedStories.size))
                put("lastUpdated", JsonPrimitive(now.epochSeconds))
            }
            
            SimpleGameData.update(
                where = { 
                    (SimpleGameData.childId eq childId) and 
                    (SimpleGameData.gameType eq gameType) and 
                    (SimpleGameData.dataKey eq "story_history")
                }
            ) {
                it[SimpleGameData.dataValue] = updatedHistory
                it[SimpleGameData.updatedAt] = now
            }
        } else {
            // Create new history
            val newHistory = mapOf(
                "completedStories" to JsonArray(listOf(JsonObject(completedStory))),
                "totalCompletedStories" to JsonPrimitive(1),
                "totalReadingTime" to (completedStoryData["totalReadingTime"] ?: JsonPrimitive(0)),
                "lastUpdated" to JsonPrimitive(now.epochSeconds)
            )
            
            SimpleGameData.insert {
                it[SimpleGameData.childId] = childId
                it[SimpleGameData.gameType] = gameType
                it[SimpleGameData.dataKey] = "story_history"
                it[SimpleGameData.dataValue] = newHistory
                it[SimpleGameData.createdAt] = now
                it[SimpleGameData.updatedAt] = now
            }
        }
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