package com.wondernest.data.database.table

import org.jetbrains.exposed.dao.id.UUIDTable
import org.jetbrains.exposed.sql.kotlin.datetime.CurrentTimestamp
import org.jetbrains.exposed.sql.kotlin.datetime.timestamp
import org.jetbrains.exposed.sql.json.jsonb
import org.jetbrains.exposed.sql.kotlin.datetime.time
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.encodeToString
import kotlinx.serialization.decodeFromString
import java.math.BigDecimal

enum class SafetyRating { SAFE, CAUTION, UNSAFE, UNKNOWN }
enum class ActionType { CREATE, UPDATE, DELETE, VIEW, LOGIN, LOGOUT }

@Serializable
data class TimeRange(
    val startHour: Int = 9,
    val startMinute: Int = 0,
    val endHour: Int = 17,
    val endMinute: Int = 0
)

// Content safety reviews
object ContentReviews : UUIDTable("content_reviews") {
    val contentId = reference("content_id", ContentItems)
    val reviewedBy = reference("reviewed_by", Users).nullable()
    
    // Review details
    val safetyRating = enumerationByName<SafetyRating>("safety_rating", 20)
    val ageAppropriate = bool("age_appropriate")
    val educationalValue = bool("educational_value")
    
    // Specific safety checks
    val containsAdvertising = bool("contains_advertising").default(false)
    val containsInappropriateLanguage = bool("contains_inappropriate_language").default(false)
    val containsViolence = bool("contains_violence").default(false)
    val containsScaryContent = bool("contains_scary_content").default(false)
    val dataCollectionConcerns = bool("data_collection_concerns").default(false)
    
    // Review notes and actions
    val reviewerNotes = text("reviewer_notes").nullable()
    val actionTaken = varchar("action_taken", 100).nullable() // approved, rejected, flagged_for_modification
    
    val reviewedAt = timestamp("reviewed_at").defaultExpression(CurrentTimestamp())
    
    // Review confidence and source
    val confidenceLevel = decimal("confidence_level", 3, 2).default(BigDecimal.ONE) // Human=1.0, AI varies
    val reviewSource = varchar("review_source", 50).default("human") // human, ai, automated
}

// Parental control settings per child
object ParentalControls : UUIDTable("parental_controls") {
    val childId = reference("child_id", ChildProfiles)
    
    // Time controls
    val maxDailyScreenTimeMinutes = integer("max_daily_screen_time_minutes").default(60)
    val allowedTimeRanges = jsonb<List<TimeRange>>("allowed_time_ranges",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    ).default(emptyList())
    val bedtimeRestrictionEnabled = bool("bedtime_restriction_enabled").default(true)
    val quietHoursStart = time("quiet_hours_start").nullable()
    val quietHoursEnd = time("quiet_hours_end").nullable()
    
    // Content controls
    val blockedCategories = jsonb<List<String>>("blocked_categories",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    ).default(emptyList()) // UUIDs as strings
    val blockedContent = jsonb<List<String>>("blocked_content",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    ).default(emptyList()) // UUIDs as strings
    val allowedContentOnly = bool("allowed_content_only").default(false) // Whitelist mode
    val requireParentApproval = bool("require_parent_approval").default(false)
    
    // Safety settings
    val maxAgeRatingMonths = integer("max_age_rating_months").nullable() // Override default age matching
    val educationalContentOnly = bool("educational_content_only").default(false)
    val blockUserGeneratedContent = bool("block_user_generated_content").default(true)
    
    // Audio monitoring controls
    val audioMonitoringEnabled = bool("audio_monitoring_enabled").default(true)
    val shareDataWithProfessionals = bool("share_data_with_professionals").default(false)
    val includeInResearch = bool("include_in_research").default(false)
    
    val createdAt = timestamp("created_at").defaultExpression(CurrentTimestamp())
    val updatedAt = timestamp("updated_at").defaultExpression(CurrentTimestamp())
    
    init {
        uniqueIndex(childId)
    }
}