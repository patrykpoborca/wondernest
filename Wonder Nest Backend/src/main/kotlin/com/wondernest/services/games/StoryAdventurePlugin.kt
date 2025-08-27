package com.wondernest.services.games

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.datetime.Clock
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import kotlinx.serialization.json.int
import kotlinx.serialization.json.long
import org.jetbrains.exposed.sql.transactions.transaction
import org.jetbrains.exposed.sql.upsert
import com.wondernest.data.database.table.SimpleGameData
import java.util.UUID

/**
 * Story Adventure Plugin - Unified interface for all Story Adventure functionality
 * This plugin implements the proper WonderNest plugin architecture pattern
 * following the hybrid approach:
 * - Child data: Stored in games.simple_game_data with JSONB
 * - Platform features: Dedicated tables (story_templates, marketplace_*, etc.)
 * 
 * Data Keys Used:
 * - "story_instance:{templateId}" - Active reading sessions
 * - "story_history" - Completed stories aggregate
 * - "vocabulary_progress" - Word learning and mastery data
 * - "reading_analytics" - Aggregated analytics and metrics
 * - "preferences" - Child-specific game settings
 */
class StoryAdventurePlugin {
    
    private val gameType = "story-adventure"
    private val templateService = StoryTemplateService()
    private val instanceService = StoryInstanceService() 
    private val vocabularyService = VocabularyService()
    
    // =============================================================================
    // PLUGIN INTERFACE METHODS
    // =============================================================================
    
    /**
     * Initialize Story Adventure for a child
     * Sets up default preferences and creates initial data structure
     */
    fun initializeForChild(childId: UUID): StoryAdventureResult = transaction {
        try {
            val now = Clock.System.now()
            
            // Initialize default preferences
            val defaultPreferences = mapOf(
                "autoNarration" to JsonPrimitive(true),
                "narrationSpeed" to JsonPrimitive(1.0), // 1.0 = normal speed
                "vocabularyHints" to JsonPrimitive(true),
                "comprehensionQuizzes" to JsonPrimitive(true),
                "readingTimer" to JsonPrimitive(false),
                "difficulty" to JsonPrimitive("adaptive"), // adaptive, easy, medium, hard
                "fontSize" to JsonPrimitive("medium"), // small, medium, large
                "theme" to JsonPrimitive("default"), // default, high_contrast, dyslexia_friendly
                "soundEffects" to JsonPrimitive(true),
                "parentalControls" to JsonObject(mapOf(
                    "allowMarketplacePurchases" to JsonPrimitive(false),
                    "requireParentForNewStories" to JsonPrimitive(true),
                    "maxDailyReadingTime" to JsonPrimitive(60) // minutes
                ))
            )
            
            SimpleGameData.upsert(
                keys = arrayOf(SimpleGameData.childId, SimpleGameData.gameType, SimpleGameData.dataKey)
            ) {
                it[SimpleGameData.childId] = childId
                it[SimpleGameData.gameType] = gameType
                it[SimpleGameData.dataKey] = "preferences"
                it[SimpleGameData.dataValue] = defaultPreferences
                it[SimpleGameData.createdAt] = now
                it[SimpleGameData.updatedAt] = now
            }
            
            // Initialize empty vocabulary progress
            val emptyVocabularyData = mapOf(
                "words" to JsonObject(emptyMap()),
                "totalWords" to JsonPrimitive(0),
                "masteredWords" to JsonPrimitive(0),
                "averageMasteryLevel" to JsonPrimitive(0.0),
                "lastUpdated" to JsonPrimitive(now.epochSeconds)
            )
            
            SimpleGameData.upsert(
                keys = arrayOf(SimpleGameData.childId, SimpleGameData.gameType, SimpleGameData.dataKey)
            ) {
                it[SimpleGameData.childId] = childId
                it[SimpleGameData.gameType] = gameType
                it[SimpleGameData.dataKey] = "vocabulary_progress"
                it[SimpleGameData.dataValue] = emptyVocabularyData
                it[SimpleGameData.createdAt] = now
                it[SimpleGameData.updatedAt] = now
            }
            
            // Initialize empty story history
            val emptyHistoryData = mapOf(
                "completedStories" to JsonArray(emptyList()),
                "totalCompletedStories" to JsonPrimitive(0),
                "totalReadingTime" to JsonPrimitive(0),
                "lastUpdated" to JsonPrimitive(now.epochSeconds)
            )
            
            SimpleGameData.upsert(
                keys = arrayOf(SimpleGameData.childId, SimpleGameData.gameType, SimpleGameData.dataKey)
            ) {
                it[SimpleGameData.childId] = childId
                it[SimpleGameData.gameType] = gameType
                it[SimpleGameData.dataKey] = "story_history"
                it[SimpleGameData.dataValue] = emptyHistoryData
                it[SimpleGameData.createdAt] = now
                it[SimpleGameData.updatedAt] = now
            }
            
            StoryAdventureResult.success("Story Adventure initialized for child", mapOf(
                "childId" to JsonPrimitive(childId.toString()),
                "gameType" to JsonPrimitive(gameType),
                "initializedAt" to JsonPrimitive(now.toString())
            ))
            
        } catch (e: Exception) {
            StoryAdventureResult.failure("Failed to initialize Story Adventure: ${e.message}")
        }
    }
    
    /**
     * Get all child data for Story Adventure
     * Returns consolidated view of all child-specific data
     */
    fun getChildData(childId: UUID): StoryAdventureChildData? = transaction {
        try {
            // Get all data for this child and game type
            val allData = SimpleGameData.select {
                (SimpleGameData.childId eq childId) and
                (SimpleGameData.gameType eq gameType)
            }.associate { row ->
                row[SimpleGameData.dataKey] to row[SimpleGameData.dataValue]
            }
            
            if (allData.isEmpty()) return@transaction null
            
            // Parse preferences
            val preferences = allData["preferences"] ?: mapOf()
            
            // Parse vocabulary progress
            val vocabData = allData["vocabulary_progress"] ?: mapOf()
            val totalWords = (vocabData["totalWords"] as? JsonPrimitive)?.int ?: 0
            val masteredWords = (vocabData["masteredWords"] as? JsonPrimitive)?.int ?: 0
            
            // Parse story history
            val historyData = allData["story_history"] ?: mapOf()
            val completedStories = (historyData["totalCompletedStories"] as? JsonPrimitive)?.int ?: 0
            val totalReadingTime = (historyData["totalReadingTime"] as? JsonPrimitive)?.int ?: 0
            
            // Get active story instances
            val activeInstances = allData.filterKeys { it.startsWith("story_instance:") }
            
            StoryAdventureChildData(
                childId = childId.toString(),
                preferences = preferences,
                vocabularyStats = mapOf(
                    "totalWords" to JsonPrimitive(totalWords),
                    "masteredWords" to JsonPrimitive(masteredWords)
                ),
                readingStats = mapOf(
                    "completedStories" to JsonPrimitive(completedStories),
                    "totalReadingTime" to JsonPrimitive(totalReadingTime)
                ),
                activeStoryCount = activeInstances.size,
                lastActivity = allData.values.mapNotNull { data ->
                    (data["lastUpdated"] as? JsonPrimitive)?.long
                }.maxOrNull()?.let { kotlinx.datetime.Instant.fromEpochMilliseconds(it).toString() }
            )
            
        } catch (e: Exception) {
            null
        }
    }
    
    /**
     * Update child preferences for Story Adventure
     */
    fun updatePreferences(childId: UUID, preferences: Map<String, JsonElement>): StoryAdventureResult = transaction {
        try {
            val now = Clock.System.now()
            
            SimpleGameData.update(
                where = {
                    (SimpleGameData.childId eq childId) and
                    (SimpleGameData.gameType eq gameType) and
                    (SimpleGameData.dataKey eq "preferences")
                }
            ) {
                it[SimpleGameData.dataValue] = preferences
                it[SimpleGameData.updatedAt] = now
            }
            
            StoryAdventureResult.success("Preferences updated successfully", preferences)
            
        } catch (e: Exception) {
            StoryAdventureResult.failure("Failed to update preferences: ${e.message}")
        }
    }
    
    /**
     * Generate child progress report
     * Combines data from all sources to create comprehensive report
     */
    fun generateProgressReport(childId: UUID): StoryAdventureProgressReport? = transaction {
        try {
            val childData = getChildData(childId) ?: return@transaction null
            val vocabStats = vocabularyService.getVocabularyStats(childId)
            val storyHistory = instanceService.getInstancesByChild(childId, status = "completed")
            val activeStories = instanceService.getInstancesByChild(childId, status = "in_progress")
            
            // Calculate reading level progression
            val readingLevelProgression = calculateReadingLevelProgression(storyHistory)
            
            // Calculate engagement metrics
            val engagementMetrics = calculateEngagementMetrics(childId)
            
            // Get achievement recommendations
            val achievements = generateAchievementRecommendations(vocabStats, storyHistory.size)
            
            StoryAdventureProgressReport(
                childId = childId.toString(),
                generatedAt = Clock.System.now().toString(),
                vocabularyProgress = StoryAdventureVocabularyReport(
                    totalWords = vocabStats.totalWords,
                    masteredWords = vocabStats.masteredWords,
                    learningWords = vocabStats.learningWords,
                    difficultWords = vocabStats.difficultWords,
                    averageMastery = vocabStats.averageMastery,
                    recentlyMastered = vocabStats.recentWords.filter { it.masteryLevel >= 80 }.take(5)
                ),
                readingProgress = StoryAdventureReadingReport(
                    storiesCompleted = storyHistory.size,
                    storiesInProgress = activeStories.size,
                    totalReadingTime = storyHistory.sumOf { it.totalReadingTime },
                    averageComprehension = storyHistory.map { it.comprehensionScore }.average().takeIf { !it.isNaN() } ?: 0.0,
                    averageReadingSpeed = storyHistory.map { it.readingSpeedWpm }.average().takeIf { !it.isNaN() } ?: 0.0,
                    readingLevelProgression = readingLevelProgression
                ),
                engagementMetrics = engagementMetrics,
                achievementRecommendations = achievements,
                parentRecommendations = generateParentRecommendations(vocabStats, storyHistory)
            )
            
        } catch (e: Exception) {
            null
        }
    }
    
    /**
     * Clean up child data (COPPA compliance)
     * Removes all child-specific data while preserving aggregated analytics
     */
    fun cleanupChildData(childId: UUID): StoryAdventureResult = transaction {
        try {
            // Archive key metrics before deletion for aggregated analytics
            val childData = getChildData(childId)
            if (childData != null) {
                // Store anonymized metrics for platform analytics
                archiveAnonymizedMetrics(childData)
            }
            
            // Delete all child-specific data
            val deletedCount = SimpleGameData.deleteWhere {
                (SimpleGameData.childId eq childId) and
                (SimpleGameData.gameType eq gameType)
            }
            
            StoryAdventureResult.success("Child data cleanup completed", mapOf(
                "deletedRecords" to JsonPrimitive(deletedCount),
                "childId" to JsonPrimitive(childId.toString())
            ))
            
        } catch (e: Exception) {
            StoryAdventureResult.failure("Failed to cleanup child data: ${e.message}")
        }
    }
    
    // =============================================================================
    // CONVENIENCE METHODS (Delegate to specialized services)
    // =============================================================================
    
    /**
     * Start a new story reading session
     * Delegates to StoryInstanceService
     */
    fun startStory(childId: UUID, templateId: UUID, customizations: JsonElement = JsonObject(emptyMap())): StoryInstanceResult {
        return instanceService.startStoryInstance(
            StartStoryInstanceRequest(childId, templateId, customizations)
        )
    }
    
    /**
     * Record vocabulary encounter
     * Delegates to VocabularyService
     */
    fun recordVocabularyEncounter(childId: UUID, word: String, templateId: UUID?, interactionType: WordInteractionType): VocabularyResult {
        return vocabularyService.recordWordEncounter(childId, word, templateId, interactionType)
    }
    
    /**
     * Get available story templates
     * Delegates to StoryTemplateService
     */
    fun getAvailableTemplates(ageGroup: String? = null, difficulty: String? = null): List<StoryTemplate> {
        return templateService.searchTemplates(SearchStoryTemplatesRequest(
            ageGroup = ageGroup,
            difficulty = difficulty
        ))
    }
    
    // =============================================================================
    // PRIVATE HELPER METHODS
    // =============================================================================
    
    private fun calculateReadingLevelProgression(completedStories: List<StoryInstance>): List<String> {
        // Simple progression based on completed stories and comprehension scores
        return when {
            completedStories.size >= 20 && completedStories.map { it.comprehensionScore }.average() >= 85 -> listOf("fluent")
            completedStories.size >= 10 && completedStories.map { it.comprehensionScore }.average() >= 70 -> listOf("developing", "fluent")
            else -> listOf("emerging", "developing")
        }
    }
    
    private fun calculateEngagementMetrics(childId: UUID): Map<String, JsonElement> = transaction {
        // Calculate engagement based on reading frequency, session duration, etc.
        val recentActivity = SimpleGameData.select {
            (SimpleGameData.childId eq childId) and
            (SimpleGameData.gameType eq gameType)
        }.map { it[SimpleGameData.updatedAt] }
        
        mapOf(
            "totalSessions" to JsonPrimitive(recentActivity.size),
            "lastActive" to JsonPrimitive(
                recentActivity.maxOrNull()?.toString() ?: ""
            ),
            "engagementScore" to JsonPrimitive(
                kotlin.math.min(100, recentActivity.size * 10) // Simple engagement calculation
            )
        )
    }
    
    private fun generateAchievementRecommendations(vocabStats: VocabularyStats, completedStories: Int): List<String> {
        val recommendations = mutableListOf<String>()
        
        if (vocabStats.masteredWords >= 25) recommendations.add("Word Master - 25+ words mastered")
        if (vocabStats.masteredWords >= 50) recommendations.add("Vocabulary Champion - 50+ words mastered")
        if (completedStories >= 5) recommendations.add("Story Explorer - 5+ stories completed")
        if (completedStories >= 10) recommendations.add("Reading Hero - 10+ stories completed")
        if (vocabStats.averageMastery >= 80) recommendations.add("Learning Excellence - High average mastery")
        
        return recommendations
    }
    
    private fun generateParentRecommendations(vocabStats: VocabularyStats, completedStories: List<StoryInstance>): List<String> {
        val recommendations = mutableListOf<String>()
        
        if (vocabStats.difficultWords > 5) {
            recommendations.add("Consider practicing difficult words together during reading time")
        }
        
        if (completedStories.map { it.comprehensionScore }.average() < 60) {
            recommendations.add("Ask more questions about the stories to improve comprehension")
        }
        
        if (completedStories.map { it.readingSpeedWpm }.average() < 50) {
            recommendations.add("Regular reading practice will help improve reading fluency")
        }
        
        recommendations.add("Celebrate reading achievements to maintain motivation")
        
        return recommendations
    }
    
    private fun archiveAnonymizedMetrics(childData: StoryAdventureChildData) {
        // Store anonymized metrics for platform analytics
        // This would typically go to a separate analytics table
        // For now, we'll just log that archiving occurred
        // Real implementation would store anonymized aggregate data
    }
}

// =============================================================================
// DATA MODELS FOR STORY ADVENTURE PLUGIN
// =============================================================================

@Serializable
data class StoryAdventureResult(
    val success: Boolean,
    val message: String,
    val data: Map<String, JsonElement>?
) {
    companion object {
        fun success(message: String, data: Map<String, JsonElement>?): StoryAdventureResult {
            return StoryAdventureResult(true, message, data)
        }
        
        fun failure(message: String): StoryAdventureResult {
            return StoryAdventureResult(false, message, null)
        }
    }
}

@Serializable
data class StoryAdventureChildData(
    val childId: String,
    val preferences: Map<String, JsonElement>,
    val vocabularyStats: Map<String, JsonElement>,
    val readingStats: Map<String, JsonElement>,
    val activeStoryCount: Int,
    val lastActivity: String?
)

@Serializable
data class StoryAdventureProgressReport(
    val childId: String,
    val generatedAt: String,
    val vocabularyProgress: StoryAdventureVocabularyReport,
    val readingProgress: StoryAdventureReadingReport,
    val engagementMetrics: Map<String, JsonElement>,
    val achievementRecommendations: List<String>,
    val parentRecommendations: List<String>
)

@Serializable
data class StoryAdventureVocabularyReport(
    val totalWords: Int,
    val masteredWords: Int,
    val learningWords: Int,
    val difficultWords: Int,
    val averageMastery: Double,
    val recentlyMastered: List<RecentWord>
)

@Serializable
data class StoryAdventureReadingReport(
    val storiesCompleted: Int,
    val storiesInProgress: Int,
    val totalReadingTime: Int,
    val averageComprehension: Double,
    val averageReadingSpeed: Double,
    val readingLevelProgression: List<String>
)