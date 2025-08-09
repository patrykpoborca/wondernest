package com.wondernest.data.database.table

import org.jetbrains.exposed.dao.id.UUIDTable
import org.jetbrains.exposed.sql.kotlin.datetime.CurrentTimestamp
import org.jetbrains.exposed.sql.kotlin.datetime.timestamp
import org.jetbrains.exposed.sql.json.jsonb
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.encodeToString
import kotlinx.serialization.decodeFromString
import java.math.BigDecimal

enum class ContentType { VIDEO, GAME, BOOK, ACTIVITY, SONG, STORY }
enum class ContentStatus { PENDING_REVIEW, APPROVED, REJECTED, ARCHIVED }

@Serializable
data class ContentMetadata(
    val resolution: String? = null,
    val fileSizeBytes: Long? = null,
    val format: String? = null,
    val subtitlesAvailable: Boolean = false,
    val accessibilityFeatures: List<String> = emptyList()
)

@Serializable
data class InteractionEvent(
    val timestamp: Long,
    val eventType: String, // pause, play, skip, replay, etc.
    val position: Int? = null // For video/audio content
)

object Categories : UUIDTable("categories") {
    val parentId = reference("parent_id", Categories).nullable()
    val name = varchar("name", 100)
    val slug = varchar("slug", 100).uniqueIndex()
    val description = text("description").nullable()
    val iconUrl = varchar("icon_url", 500).nullable()
    val sortOrder = integer("sort_order").default(0)
    
    val isActive = bool("is_active").default(true)
    val createdAt = timestamp("created_at").defaultExpression(CurrentTimestamp())
    val updatedAt = timestamp("updated_at").defaultExpression(CurrentTimestamp())
}

object Creators : UUIDTable("creators") {
    val name = varchar("name", 200)
    val slug = varchar("slug", 200).uniqueIndex()
    val description = text("description").nullable()
    val websiteUrl = varchar("website_url", 500).nullable()
    val logoUrl = varchar("logo_url", 500).nullable()
    
    // Verification status
    val isVerified = bool("is_verified").default(false)
    val verifiedAt = timestamp("verified_at").nullable()
    
    // Contact and legal
    val contactEmail = varchar("contact_email", 255).nullable()
    val legalEntity = varchar("legal_entity", 300).nullable()
    val contentAgreementSigned = bool("content_agreement_signed").default(false)
    
    val createdAt = timestamp("created_at").defaultExpression(CurrentTimestamp())
    val updatedAt = timestamp("updated_at").defaultExpression(CurrentTimestamp())
}

object ContentItems : UUIDTable("content_items") {
    val externalId = varchar("external_id", 255).nullable()
    val creatorId = reference("creator_id", Creators).nullable()
    
    // Basic content information
    val title = varchar("title", 300)
    val description = text("description").nullable()
    val contentType = enumerationByName<ContentType>("content_type", 20)
    val language = varchar("language", 10).default("en")
    
    // Content URLs and metadata
    val primaryUrl = varchar("primary_url", 1000)
    val thumbnailUrl = varchar("thumbnail_url", 500).nullable()
    val posterUrl = varchar("poster_url", 500).nullable()
    val durationSeconds = integer("duration_seconds").nullable()
    val fileSizeBytes = long("file_size_bytes").nullable()
    
    // Age and educational targeting
    val minAgeMonths = integer("min_age_months")
    val maxAgeMonths = integer("max_age_months")
    val educationalGoals = jsonb<List<String>>("educational_goals",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    ).default(emptyList())
    val learningObjectives = jsonb<List<String>>("learning_objectives",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    ).default(emptyList())
    val skillsDeveloped = jsonb<List<String>>("skills_developed",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    ).default(emptyList())
    
    // Content ratings and safety
    val safetyScore = decimal("safety_score", 3, 2).default(BigDecimal.ZERO)
    val educationalValueScore = decimal("educational_value_score", 3, 2).default(BigDecimal.ZERO)
    val engagementScore = decimal("engagement_score", 3, 2).default(BigDecimal.ZERO)
    
    // Review and publication
    val status = enumerationByName<ContentStatus>("status", 20).default(ContentStatus.PENDING_REVIEW)
    val reviewedBy = reference("reviewed_by", Users).nullable()
    val reviewedAt = timestamp("reviewed_at").nullable()
    val publishedAt = timestamp("published_at").nullable()
    
    // Metadata and search
    val tags = jsonb<List<String>>("tags",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    ).default(emptyList())
    val keywords = jsonb<List<String>>("keywords",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    ).default(emptyList())
    val metadata = jsonb<ContentMetadata>("metadata",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    ).default(ContentMetadata())
    
    // Analytics
    val viewCount = integer("view_count").default(0)
    val likeCount = integer("like_count").default(0)
    val shareCount = integer("share_count").default(0)
    val averageRating = decimal("average_rating", 3, 2).nullable()
    val totalRatings = integer("total_ratings").default(0)
    
    val createdAt = timestamp("created_at").defaultExpression(CurrentTimestamp())
    val updatedAt = timestamp("updated_at").defaultExpression(CurrentTimestamp())
    val archivedAt = timestamp("archived_at").nullable()
}

object ItemCategories : org.jetbrains.exposed.sql.Table("item_categories") {
    val contentId = reference("content_id", ContentItems)
    val categoryId = reference("category_id", Categories)
    val isPrimary = bool("is_primary").default(false)
    val createdAt = timestamp("created_at").defaultExpression(CurrentTimestamp())
    
    override val primaryKey = PrimaryKey(contentId, categoryId)
}

// Partitioned table for content engagement
object ContentEngagement : UUIDTable("content_engagement") {
    val childId = reference("child_id", ChildProfiles)
    val contentId = reference("content_id", ContentItems)
    
    // Engagement details
    val startedAt = timestamp("started_at").defaultExpression(CurrentTimestamp())
    val endedAt = timestamp("ended_at").nullable()
    val durationSeconds = integer("duration_seconds").nullable()
    val completionPercentage = decimal("completion_percentage", 5, 2).default(BigDecimal.ZERO)
    
    // Interaction tracking
    val pauseCount = integer("pause_count").default(0)
    val skipCount = integer("skip_count").default(0)
    val replayCount = integer("replay_count").default(0)
    val interactionEvents = jsonb<List<InteractionEvent>>("interaction_events",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    ).default(emptyList())
    
    // Quality metrics
    val enjoyedRating = integer("enjoyed_rating").nullable() // 1-5 rating
    
    // Session context
    val sessionId = uuid("session_id").nullable()
    val deviceType = varchar("device_type", 50).nullable()
    val locationContext = varchar("location_context", 100).nullable()
    
    val createdAt = timestamp("created_at").defaultExpression(CurrentTimestamp())
}