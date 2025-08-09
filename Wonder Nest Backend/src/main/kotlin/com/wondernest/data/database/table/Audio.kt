package com.wondernest.data.database.table

import org.jetbrains.exposed.dao.id.UUIDTable
import org.jetbrains.exposed.sql.kotlin.datetime.CurrentTimestamp
import org.jetbrains.exposed.sql.kotlin.datetime.timestamp
import java.math.BigDecimal

enum class SessionStatus { RECORDING, PROCESSING, COMPLETED, FAILED }

// Audio recording sessions (metadata only, no actual audio)
object AudioSessions : UUIDTable("audio_sessions") {
    val childId = reference("child_id", ChildProfiles)
    
    // Session timing
    val startedAt = timestamp("started_at")
    val endedAt = timestamp("ended_at").nullable()
    val durationSeconds = integer("duration_seconds").nullable()
    
    // Processing status
    val status = enumerationByName<SessionStatus>("status", 20).default(SessionStatus.RECORDING)
    val processingStartedAt = timestamp("processing_started_at").nullable()
    val processingCompletedAt = timestamp("processing_completed_at").nullable()
    val processingError = text("processing_error").nullable()
    
    // Session context
    val location = varchar("location", 100).nullable() // home, car, playground
    val backgroundNoiseLevel = varchar("background_noise_level", 20).nullable() // quiet, moderate, noisy
    val deviceId = varchar("device_id", 255).nullable()
    val appVersion = varchar("app_version", 50).nullable()
    
    // Quality indicators
    val audioQualityScore = decimal("audio_quality_score", 3, 2).nullable() // 0-1 quality rating
    val validSpeechPercentage = decimal("valid_speech_percentage", 5, 2).nullable() // % of session with valid speech
    
    // Privacy compliance
    val consentConfirmed = bool("consent_confirmed").default(true)
    val parentPresent = bool("parent_present").default(true)
    
    val createdAt = timestamp("created_at").defaultExpression(CurrentTimestamp())
}

// Speech analysis metrics (aggregated from on-device processing)
object SpeechMetrics : UUIDTable("speech_metrics") {
    val sessionId = reference("session_id", AudioSessions)
    val childId = reference("child_id", ChildProfiles)
    
    // Time segment (metrics calculated for 5-minute segments)
    val startTime = timestamp("start_time")
    val endTime = timestamp("end_time")
    
    // Word and speech metrics (privacy-safe aggregations)
    val wordCount = integer("word_count").default(0)
    val uniqueWordCount = integer("unique_word_count").default(0)
    val averageWordLength = decimal("average_word_length", 4, 2).default(BigDecimal.ZERO)
    val longestUtteranceWords = integer("longest_utterance_words").default(0)
    
    // Conversation dynamics
    val conversationTurns = integer("conversation_turns").default(0)
    val childInitiatedTurns = integer("child_initiated_turns").default(0)
    val adultInitiatedTurns = integer("adult_initiated_turns").default(0)
    val averageResponseTimeMs = integer("average_response_time_ms").nullable()
    
    // Speech quality indicators
    val clarityScore = decimal("clarity_score", 3, 2).nullable() // 0-1 speech clarity
    val confidenceScore = decimal("confidence_score", 3, 2).nullable() // ML model confidence
    val backgroundSpeechDetected = bool("background_speech_detected").default(false)
    val overlappingSpeechPercentage = decimal("overlapping_speech_percentage", 5, 2).default(BigDecimal.ZERO)
    
    // Emotional and engagement indicators
    val positiveAffectDetected = bool("positive_affect_detected").nullable()
    val engagementLevel = varchar("engagement_level", 20).nullable() // low, medium, high
    val excitementIndicators = integer("excitement_indicators").default(0) // laughing, exclamations
    
    val createdAt = timestamp("created_at").defaultExpression(CurrentTimestamp())
}