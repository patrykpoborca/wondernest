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
import kotlinx.serialization.json.double
import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.transactions.transaction
import org.jetbrains.exposed.sql.upsert
import com.wondernest.data.database.table.SimpleGameData
import java.util.UUID

/**
 * Service for managing vocabulary progress and learning analytics using plugin architecture
 * Now stores data in games.simple_game_data with game_type = 'story-adventure'
 * Follows WonderNest's plugin pattern for child vocabulary data storage
 */
class VocabularyService {
    
    private val gameType = "story-adventure"
    
    /**
     * Record a vocabulary word encounter during story reading
     * Updates vocabulary progress in games.simple_game_data
     */
    fun recordWordEncounter(
        childId: UUID,
        word: String,
        templateId: UUID?,
        interactionType: WordInteractionType = WordInteractionType.ENCOUNTERED
    ): VocabularyResult = transaction {
        try {
            val now = Clock.System.now()
            
            // Get existing vocabulary progress for this child
            val existingProgress = SimpleGameData.select {
                (SimpleGameData.childId eq childId) and
                (SimpleGameData.gameType eq gameType) and
                (SimpleGameData.dataKey eq "vocabulary_progress")
            }.singleOrNull()
            
            val currentData = existingProgress?.get(SimpleGameData.dataValue) ?: mapOf()
            val currentWords = (currentData["words"] as? JsonObject)?.toMap() ?: mapOf()
            
            // Get current word progress or create new
            val existingWordData = (currentWords[word] as? JsonObject)?.toMap() ?: mapOf()
            
            // Calculate new values based on interaction type
            val encounters = (existingWordData["encounters"]?.jsonPrimitive?.int ?: 0) + 1
            val correctUses = existingWordData["correctUses"]?.jsonPrimitive?.int ?: 0
            val incorrectUses = existingWordData["incorrectUses"]?.jsonPrimitive?.int ?: 0
            val definitionViewedCount = existingWordData["definitionViewedCount"]?.jsonPrimitive?.int ?: 0
            val pronunciationPlayedCount = existingWordData["pronunciationPlayedCount"]?.jsonPrimitive?.int ?: 0
            val firstEncountered = existingWordData["firstEncountered"] ?: JsonPrimitive(now.epochSeconds)
            
            // Update counters based on interaction type
            val newCorrectUses = if (interactionType == WordInteractionType.CORRECT) correctUses + 1 else correctUses
            val newIncorrectUses = if (interactionType == WordInteractionType.INCORRECT) incorrectUses + 1 else incorrectUses
            val newDefinitionCount = if (interactionType == WordInteractionType.DEFINITION) definitionViewedCount + 1 else definitionViewedCount
            val newPronunciationCount = if (interactionType == WordInteractionType.PRONUNCIATION) pronunciationPlayedCount + 1 else pronunciationPlayedCount
            
            // Calculate mastery level (0-100 based on accuracy and encounters)
            val totalInteractions = newCorrectUses + newIncorrectUses
            val accuracy = if (totalInteractions > 0) (newCorrectUses.toDouble() / totalInteractions) * 100 else 0.0
            val masteryLevel = kotlin.math.min(100, (accuracy * 0.7 + encounters * 5).toInt()) // Cap at 100
            
            val masteredAt = if (masteryLevel >= 80 && (existingWordData["masteredAt"] as? JsonNull) != null) {
                JsonPrimitive(now.epochSeconds)
            } else {
                existingWordData["masteredAt"] ?: JsonNull
            }
            
            // Update word progress
            val updatedWordData = mapOf(
                "encounters" to JsonPrimitive(encounters),
                "correctUses" to JsonPrimitive(newCorrectUses),
                "incorrectUses" to JsonPrimitive(newIncorrectUses),
                "masteryLevel" to JsonPrimitive(masteryLevel),
                "lastSeenIn" to JsonPrimitive(templateId?.toString() ?: ""),
                "definitionViewedCount" to JsonPrimitive(newDefinitionCount),
                "pronunciationPlayedCount" to JsonPrimitive(newPronunciationCount),
                "firstEncountered" to firstEncountered,
                "lastEncountered" to JsonPrimitive(now.epochSeconds),
                "masteredAt" to masteredAt
            )
            
            // Update the words collection
            val updatedWords = currentWords.toMutableMap().apply {
                put(word, JsonObject(updatedWordData))
            }
            
            // Calculate overall stats
            val allWords = updatedWords.values.map { it as JsonObject }
            val totalWords = allWords.size
            val masteredWords = allWords.count { 
                (it.toMap()["masteryLevel"]?.jsonPrimitive?.int ?: 0) >= 80 
            }
            val averageMasteryLevel = if (allWords.isNotEmpty()) {
                allWords.map { 
                    it.toMap()["masteryLevel"]?.jsonPrimitive?.int ?: 0 
                }.average()
            } else 0.0
            
            // Create updated vocabulary progress data
            val updatedProgressData = mapOf(
                "words" to JsonObject(updatedWords.mapValues { it.value }),
                "totalWords" to JsonPrimitive(totalWords),
                "masteredWords" to JsonPrimitive(masteredWords),
                "averageMasteryLevel" to JsonPrimitive(averageMasteryLevel),
                "lastUpdated" to JsonPrimitive(now.epochSeconds)
            )
            
            // Store/update in simple_game_data
            SimpleGameData.upsert(
                keys = arrayOf(SimpleGameData.childId, SimpleGameData.gameType, SimpleGameData.dataKey)
            ) {
                it[SimpleGameData.childId] = childId
                it[SimpleGameData.gameType] = gameType
                it[SimpleGameData.dataKey] = "vocabulary_progress"
                it[SimpleGameData.dataValue] = updatedProgressData
                it[SimpleGameData.createdAt] = existingProgress?.get(SimpleGameData.createdAt) ?: now
                it[SimpleGameData.updatedAt] = now
            }
            
            // Create response object
            val progress = VocabularyProgress(
                childId = childId.toString(),
                word = word,
                encounters = encounters,
                correctUses = newCorrectUses,
                incorrectUses = newIncorrectUses,
                masteryLevel = masteryLevel,
                lastSeenIn = templateId?.toString(),
                definitionViewedCount = newDefinitionCount,
                pronunciationPlayedCount = newPronunciationCount,
                firstEncountered = Instant.fromEpochMilliseconds(firstEncountered.jsonPrimitive.long).toString(),
                lastEncountered = now.toString(),
                masteredAt = if (masteredAt !is kotlinx.serialization.json.JsonNull) {
                    Instant.fromEpochMilliseconds(masteredAt.jsonPrimitive.long).toString()
                } else null
            )
            
            VocabularyResult.success("Vocabulary encounter recorded", progress)
            
        } catch (e: Exception) {
            VocabularyResult.failure("Failed to record vocabulary encounter: ${e.message}")
        }
    }
    
    /**
     * Get vocabulary progress for a specific word and child
     */
    fun getWordProgress(childId: UUID, word: String): VocabularyProgress? = transaction {
        try {
            val data = SimpleGameData.select {
                (SimpleGameData.childId eq childId) and
                (SimpleGameData.gameType eq gameType) and
                (SimpleGameData.dataKey eq "vocabulary_progress")
            }.singleOrNull()
            
            if (data != null) {
                val progressData = data[SimpleGameData.dataValue]
                val wordsData = progressData["words"] as? JsonObject
                val wordData = wordsData?.get(word) as? JsonObject
                
                if (wordData != null) {
                    createVocabularyProgressFromData(wordData.toMap(), childId.toString(), word)
                } else null
            } else null
        } catch (e: Exception) {
            null
        }
    }
    
    /**
     * Get all vocabulary progress for a child
     */
    fun getChildVocabularyProgress(
        childId: UUID,
        masteryLevel: Int? = null,
        limit: Int = 100,
        offset: Int = 0
    ): List<VocabularyProgress> = transaction {
        try {
            val data = SimpleGameData.select {
                (SimpleGameData.childId eq childId) and
                (SimpleGameData.gameType eq gameType) and
                (SimpleGameData.dataKey eq "vocabulary_progress")
            }.singleOrNull()
            
            if (data != null) {
                val progressData = data[SimpleGameData.dataValue]
                val wordsData = progressData["words"] as? JsonObject
                
                if (wordsData != null) {
                    val results = wordsData.toMap().mapNotNull { (word, wordDataElement) ->
                        val wordData = (wordDataElement as? JsonObject)?.toMap()
                        if (wordData != null) {
                            createVocabularyProgressFromData(wordData, childId.toString(), word)
                        } else null
                    }
                    
                    // Apply mastery level filter
                    val filtered = if (masteryLevel != null) {
                        results.filter { it.masteryLevel >= masteryLevel }
                    } else results
                    
                    // Apply pagination
                    filtered.drop(offset).take(limit)
                } else emptyList()
            } else emptyList()
        } catch (e: Exception) {
            emptyList()
        }
    }
    
    /**
     * Get vocabulary statistics for a child
     */
    fun getVocabularyStats(childId: UUID): VocabularyStats = transaction {
        try {
            val data = SimpleGameData.select {
                (SimpleGameData.childId eq childId) and
                (SimpleGameData.gameType eq gameType) and
                (SimpleGameData.dataKey eq "vocabulary_progress")
            }.singleOrNull()
            
            if (data != null) {
                val progressData = data[SimpleGameData.dataValue]
                val totalWords = progressData["totalWords"]?.jsonPrimitive?.int ?: 0
                val masteredWords = progressData["masteredWords"]?.jsonPrimitive?.int ?: 0
                val averageMastery = progressData["averageMasteryLevel"]?.jsonPrimitive?.double ?: 0.0
                
                val wordsData = progressData["words"] as? JsonObject
                val learningWords = if (wordsData != null) {
                    wordsData.toMap().count { (_, wordDataElement) ->
                        val wordData = (wordDataElement as? JsonObject)?.toMap()
                        val masteryLevel = wordData?.get("masteryLevel")?.jsonPrimitive?.int ?: 0
                        masteryLevel in 30..79
                    }
                } else 0
                
                val difficultWords = totalWords - masteredWords - learningWords
                
                // Get recent words (last encountered)
                val recentWords = if (wordsData != null) {
                    wordsData.toMap().map { (word, wordDataElement) ->
                        val wordData = (wordDataElement as? JsonObject)?.toMap()
                        val masteryLevel = wordData?.get("masteryLevel")?.jsonPrimitive?.int ?: 0
                        val lastEncountered = wordData?.get("lastEncountered")?.jsonPrimitive?.long ?: 0L
                        Triple(word, masteryLevel, lastEncountered)
                    }.sortedByDescending { it.third }.take(5).map { (word, mastery, timestamp) ->
                        RecentWord(word, mastery, Instant.fromEpochMilliseconds(timestamp).toString())
                    }
                } else emptyList()
                
                VocabularyStats(
                    totalWords = totalWords,
                    masteredWords = masteredWords,
                    learningWords = learningWords,
                    difficultWords = difficultWords,
                    averageMastery = averageMastery,
                    totalEncounters = 0, // Could calculate if needed
                    recentWords = recentWords
                )
            } else {
                VocabularyStats(0, 0, 0, 0, 0.0, 0, emptyList())
            }
        } catch (e: Exception) {
            VocabularyStats(0, 0, 0, 0, 0.0, 0, emptyList())
        }
    }
    
    /**
     * Get words that need more practice (low mastery level)
     */
    fun getWordsNeedingPractice(childId: UUID, limit: Int = 20): List<VocabularyProgress> = transaction {
        try {
            val allProgress = getChildVocabularyProgress(childId, limit = Int.MAX_VALUE)
            allProgress.filter { it.masteryLevel < 60 }
                .sortedBy { it.masteryLevel }
                .take(limit)
        } catch (e: Exception) {
            emptyList()
        }
    }
    
    /**
     * Mark word as mastered
     */
    fun markWordAsMastered(childId: UUID, word: String): VocabularyResult = transaction {
        try {
            // Use recordWordEncounter with multiple correct interactions to boost mastery
            recordWordEncounter(childId, word, null, WordInteractionType.CORRECT)
            
            // Then manually set mastery level to 100
            val data = SimpleGameData.select {
                (SimpleGameData.childId eq childId) and
                (SimpleGameData.gameType eq gameType) and
                (SimpleGameData.dataKey eq "vocabulary_progress")
            }.singleOrNull()
            
            if (data != null) {
                val currentData = data[SimpleGameData.dataValue]
                val currentWords = (currentData["words"] as? JsonObject)?.toMutableMap() ?: mutableMapOf()
                val wordData = (currentWords[word] as? JsonObject)?.toMutableMap() ?: mutableMapOf()
                
                val now = Clock.System.now()
                wordData["masteryLevel"] = JsonPrimitive(100)
                wordData["masteredAt"] = JsonPrimitive(now.epochSeconds)
                currentWords[word] = JsonObject(wordData.mapValues { it.value })
                
                val updatedData = currentData.toMutableMap().apply {
                    put("words", JsonObject(currentWords.mapValues { it.value }))
                    put("lastUpdated", JsonPrimitive(now.epochSeconds))
                    // Recalculate mastered words count
                    val masteredCount = currentWords.values.count { 
                        val wordMap = (it as JsonObject).toMap()
                        (wordMap["masteryLevel"]?.jsonPrimitive?.int ?: 0) >= 80
                    }
                    put("masteredWords", JsonPrimitive(masteredCount))
                }
                
                SimpleGameData.update(
                    where = { 
                        (SimpleGameData.childId eq childId) and 
                        (SimpleGameData.gameType eq gameType) and 
                        (SimpleGameData.dataKey eq "vocabulary_progress")
                    }
                ) {
                    it[SimpleGameData.dataValue] = updatedData
                    it[SimpleGameData.updatedAt] = now
                }
                
                val progress = createVocabularyProgressFromData(wordData.mapValues { it.value }, childId.toString(), word)
                VocabularyResult.success("Word marked as mastered", progress)
            } else {
                VocabularyResult.failure("No vocabulary data found for child")
            }
        } catch (e: Exception) {
            VocabularyResult.failure("Failed to mark word as mastered: ${e.message}")
        }
    }
    
    /**
     * Helper function to create VocabularyProgress from JSONB data
     */
    private fun createVocabularyProgressFromData(
        data: Map<String, JsonElement>, 
        childId: String, 
        word: String
    ): VocabularyProgress {
        return VocabularyProgress(
            childId = childId,
            word = word,
            encounters = data["encounters"]?.jsonPrimitive?.int ?: 0,
            correctUses = data["correctUses"]?.jsonPrimitive?.int ?: 0,
            incorrectUses = data["incorrectUses"]?.jsonPrimitive?.int ?: 0,
            masteryLevel = data["masteryLevel"]?.jsonPrimitive?.int ?: 0,
            lastSeenIn = data["lastSeenIn"]?.jsonPrimitive?.content,
            definitionViewedCount = data["definitionViewedCount"]?.jsonPrimitive?.int ?: 0,
            pronunciationPlayedCount = data["pronunciationPlayedCount"]?.jsonPrimitive?.int ?: 0,
            firstEncountered = data["firstEncountered"]?.jsonPrimitive?.long?.let { 
                Instant.fromEpochMilliseconds(it).toString()
            } ?: "",
            lastEncountered = data["lastEncountered"]?.jsonPrimitive?.long?.let { 
                Instant.fromEpochMilliseconds(it).toString()
            } ?: "",
            masteredAt = data["masteredAt"]?.takeIf { it !is JsonNull }?.let { 
                (it as? JsonPrimitive)?.long?.let { Instant.fromEpochSeconds(it).toString() }
            }
        )
    }
}

// Data models and enums for VocabularyService

enum class WordInteractionType {
    ENCOUNTERED,    // Just saw the word
    CORRECT,        // Used word correctly
    INCORRECT,      // Used word incorrectly  
    DEFINITION,     // Viewed word definition
    PRONUNCIATION   // Played word pronunciation
}

@Serializable
data class VocabularyProgress(
    val childId: String,
    val word: String,
    val encounters: Int,
    val correctUses: Int,
    val incorrectUses: Int,
    val masteryLevel: Int,
    val lastSeenIn: String?,
    val definitionViewedCount: Int,
    val pronunciationPlayedCount: Int,
    val firstEncountered: String,
    val lastEncountered: String,
    val masteredAt: String?
)

@Serializable
data class VocabularyStats(
    val totalWords: Int,
    val masteredWords: Int,
    val learningWords: Int,
    val difficultWords: Int,
    val averageMastery: Double,
    val totalEncounters: Int,
    val recentWords: List<RecentWord> = emptyList()
)

@Serializable
data class RecentWord(
    val word: String,
    val masteryLevel: Int,
    val lastEncountered: String
)

@Serializable
data class VocabularyResult(
    val success: Boolean,
    val message: String,
    val data: VocabularyProgress?
) {
    companion object {
        fun success(message: String, data: VocabularyProgress?): VocabularyResult {
            return VocabularyResult(true, message, data)
        }
        
        fun failure(message: String): VocabularyResult {
            return VocabularyResult(false, message, null)
        }
    }
}

// Request models
@Serializable
data class RecordWordEncounterRequest(
    @Contextual val childId: UUID,
    val word: String,
    @Contextual val templateId: UUID?,
    val interactionType: String = "encountered" // "encountered", "correct", "incorrect", "definition", "pronunciation"
)