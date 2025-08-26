package com.wondernest.services.games

import kotlinx.serialization.Serializable
import kotlinx.serialization.Contextual
import kotlinx.datetime.Clock
import org.jetbrains.exposed.sql.transactions.transaction
import java.util.UUID

/**
 * Service for managing vocabulary progress and learning analytics
 * Simplified implementation for initial Story Adventure support
 */
class VocabularyService {
    
    /**
     * Record a vocabulary word encounter during story reading
     */
    fun recordWordEncounter(
        childId: UUID,
        word: String,
        templateId: UUID?,
        interactionType: WordInteractionType = WordInteractionType.ENCOUNTERED
    ): VocabularyResult = transaction {
        try {
            // For now, return a mock vocabulary progress entry
            val progress = VocabularyProgress(
                childId = childId.toString(),
                word = word,
                encounters = 1,
                correctUses = if (interactionType == WordInteractionType.CORRECT) 1 else 0,
                incorrectUses = if (interactionType == WordInteractionType.INCORRECT) 1 else 0,
                masteryLevel = 25,
                lastSeenIn = templateId?.toString(),
                definitionViewedCount = if (interactionType == WordInteractionType.DEFINITION) 1 else 0,
                pronunciationPlayedCount = if (interactionType == WordInteractionType.PRONUNCIATION) 1 else 0,
                firstEncountered = Clock.System.now().toString(),
                lastEncountered = Clock.System.now().toString(),
                masteredAt = null
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
        // Return mock progress
        VocabularyProgress(
            childId = childId.toString(),
            word = word,
            encounters = 5,
            correctUses = 4,
            incorrectUses = 1,
            masteryLevel = 75,
            lastSeenIn = UUID.randomUUID().toString(),
            definitionViewedCount = 2,
            pronunciationPlayedCount = 3,
            firstEncountered = Clock.System.now().toString(),
            lastEncountered = Clock.System.now().toString(),
            masteredAt = null
        )
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
        // Return mock data
        listOf(
            VocabularyProgress(
                childId = childId.toString(),
                word = "adventure",
                encounters = 8,
                correctUses = 7,
                incorrectUses = 1,
                masteryLevel = 85,
                lastSeenIn = UUID.randomUUID().toString(),
                definitionViewedCount = 3,
                pronunciationPlayedCount = 4,
                firstEncountered = Clock.System.now().toString(),
                lastEncountered = Clock.System.now().toString(),
                masteredAt = null
            ),
            VocabularyProgress(
                childId = childId.toString(),
                word = "magical",
                encounters = 3,
                correctUses = 2,
                incorrectUses = 1,
                masteryLevel = 60,
                lastSeenIn = UUID.randomUUID().toString(),
                definitionViewedCount = 1,
                pronunciationPlayedCount = 2,
                firstEncountered = Clock.System.now().toString(),
                lastEncountered = Clock.System.now().toString(),
                masteredAt = null
            )
        )
    }
    
    /**
     * Get vocabulary statistics for a child
     */
    fun getVocabularyStats(childId: UUID): VocabularyStats = transaction {
        // Return mock statistics
        VocabularyStats(
            totalWords = 45,
            masteredWords = 12,
            learningWords = 25,
            difficultWords = 8,
            averageMastery = 72.5,
            totalEncounters = 234,
            recentWords = listOf(
                RecentWord("adventure", 85, Clock.System.now().toString()),
                RecentWord("magical", 60, Clock.System.now().toString()),
                RecentWord("explore", 45, Clock.System.now().toString())
            )
        )
    }
    
    /**
     * Get words that need more practice (low mastery level)
     */
    fun getWordsNeedingPractice(childId: UUID, limit: Int = 20): List<VocabularyProgress> = transaction {
        // Return mock data for words needing practice
        listOf(
            VocabularyProgress(
                childId = childId.toString(),
                word = "difficult",
                encounters = 6,
                correctUses = 2,
                incorrectUses = 4,
                masteryLevel = 35,
                lastSeenIn = UUID.randomUUID().toString(),
                definitionViewedCount = 5,
                pronunciationPlayedCount = 3,
                firstEncountered = Clock.System.now().toString(),
                lastEncountered = Clock.System.now().toString(),
                masteredAt = null
            )
        )
    }
    
    /**
     * Mark word as mastered
     */
    fun markWordAsMastered(childId: UUID, word: String): VocabularyResult = transaction {
        try {
            val progress = VocabularyProgress(
                childId = childId.toString(),
                word = word,
                encounters = 10,
                correctUses = 9,
                incorrectUses = 1,
                masteryLevel = 100,
                lastSeenIn = UUID.randomUUID().toString(),
                definitionViewedCount = 5,
                pronunciationPlayedCount = 4,
                firstEncountered = Clock.System.now().toString(),
                lastEncountered = Clock.System.now().toString(),
                masteredAt = Clock.System.now().toString()
            )
            
            VocabularyResult.success("Word marked as mastered", progress)
            
        } catch (e: Exception) {
            VocabularyResult.failure("Failed to mark word as mastered: ${e.message}")
        }
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