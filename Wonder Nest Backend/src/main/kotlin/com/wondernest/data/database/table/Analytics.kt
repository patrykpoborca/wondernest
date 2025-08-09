package com.wondernest.data.database.table

import org.jetbrains.exposed.dao.id.UUIDTable
import org.jetbrains.exposed.sql.kotlin.datetime.CurrentTimestamp
import org.jetbrains.exposed.sql.kotlin.datetime.timestamp
import org.jetbrains.exposed.sql.kotlin.datetime.date
import org.jetbrains.exposed.sql.json.jsonb
import org.jetbrains.exposed.sql.*
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.math.BigDecimal

enum class EventType { APP_OPEN, CONTENT_VIEW, AUDIO_SESSION_START, USER_INTERACTION, MILESTONE_ACHIEVED }

@Serializable
data class DeviceInfo(
    val platform: String = "android",
    val version: String = "1.0.0",
    val model: String = "unknown"
)

@Serializable
data class EventProperties(
    val contentId: String? = null,
    val sessionDuration: Int? = null,
    val interactionType: String? = null,
    val milestoneType: String? = null
)

// Daily aggregated metrics per child
object DailyChildMetrics : UUIDTable("daily_child_metrics") {
    val childId = reference("child_id", ChildProfiles)
    val date = date("date")
    
    // Speech and language metrics
    val totalWords = integer("total_words").default(0)
    val uniqueWords = integer("unique_words").default(0)
    val conversationTurns = integer("conversation_turns").default(0)
    val audioSessionCount = integer("audio_session_count").default(0)
    val totalAudioDurationMinutes = integer("total_audio_duration_minutes").default(0)
    
    // Content engagement metrics
    val contentSessions = integer("content_sessions").default(0)
    val totalScreenTimeMinutes = integer("total_screen_time_minutes").default(0)
    val educationalContentMinutes = integer("educational_content_minutes").default(0)
    val completedContentCount = integer("completed_content_count").default(0)
    
    // Development indicators
    val vocabularyDiversityScore = decimal("vocabulary_diversity_score", 4, 2).nullable()
    val engagementScore = decimal("engagement_score", 3, 2).nullable()
    val milestoneAchievements = integer("milestone_achievements").default(0)
    
    // Behavioral patterns
    val mostActiveHour = integer("most_active_hour").nullable() // 0-23
    val preferredContentTypes = text("preferred_content_types").default("[]") // JSON array as text
    
    val createdAt = timestamp("created_at").defaultExpression(CurrentTimestamp())
    
    init {
        uniqueIndex(childId, date)
    }
}

// Development milestones tracking
object Milestones : UUIDTable("milestones") {
    val childId = reference("child_id", ChildProfiles)
    
    val milestoneType = varchar("milestone_type", 100) // language, motor, social, cognitive
    val milestoneName = varchar("milestone_name", 200)
    val description = text("description").nullable()
    
    // Age expectations
    val typicalAgeMonthsMin = integer("typical_age_months_min")
    val typicalAgeMonthsMax = integer("typical_age_months_max")
    
    // Achievement tracking
    val achieved = bool("achieved").default(false)
    val achievedAt = timestamp("achieved_at").nullable()
    val childAgeMonthsAtAchievement = integer("child_age_months_at_achievement").nullable()
    
    // Evidence and notes
    val evidenceSource = varchar("evidence_source", 100).nullable() // app_data, parent_report, professional_assessment
    val confidenceLevel = decimal("confidence_level", 3, 2).default(BigDecimal.ZERO) // 0-1 confidence in achievement
    val parentNotes = text("parent_notes").nullable()
    
    val createdAt = timestamp("created_at").defaultExpression(CurrentTimestamp())
    val updatedAt = timestamp("updated_at").defaultExpression(CurrentTimestamp())
}

// Usage analytics and events
object Events : UUIDTable("events") {
    val userId = reference("user_id", Users).nullable()
    val childId = reference("child_id", ChildProfiles).nullable()
    val sessionId = uuid("session_id").nullable()
    
    // Event details
    val eventType = enumerationByName<EventType>("event_type", 30)
    val eventName = varchar("event_name", 100)
    val eventProperties = jsonb<EventProperties>("event_properties", Json.Default, EventProperties.serializer()).default(EventProperties())
    
    // Context
    val timestamp = timestamp("timestamp").defaultExpression(CurrentTimestamp())
    val deviceInfo = jsonb<DeviceInfo>("device_info", Json.Default, DeviceInfo.serializer()).default(DeviceInfo())
    val appVersion = varchar("app_version", 50).nullable()
    
    // Privacy-safe location data
    val country = varchar("country", 2).nullable() // ISO country code only
    val timezone = varchar("timezone", 50).nullable()
}