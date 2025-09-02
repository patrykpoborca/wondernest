package com.wondernest.data.database.table

import kotlinx.serialization.encodeToString
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json
import org.jetbrains.exposed.dao.id.UUIDTable
import org.jetbrains.exposed.sql.Column
import org.jetbrains.exposed.sql.ReferenceOption
import org.jetbrains.exposed.sql.Table
import org.jetbrains.exposed.sql.kotlin.datetime.timestamp
import org.jetbrains.exposed.sql.json.jsonb
import java.math.BigDecimal
import java.time.Instant
import java.util.UUID

object ContentPackCategoriesTable : UUIDTable("content_pack_categories") {
    val name = varchar("name", 100).uniqueIndex()
    val description = text("description").nullable()
    val displayOrder = integer("display_order").default(0)
    val iconUrl = text("icon_url").nullable()
    val colorHex = varchar("color_hex", 7).nullable()
    val isActive = bool("is_active").default(true)
    val ageMin = integer("age_min").default(3)
    val ageMax = integer("age_max").default(12)
    val createdAt = timestamp("created_at")
    val updatedAt = timestamp("updated_at")
}

object ContentPacksTable : UUIDTable("content_packs") {
    val name = varchar("name", 200)
    val description = text("description").nullable()
    val shortDescription = varchar("short_description", 500).nullable()
    val packType = enumerationByName("pack_type", 50, ContentPackType::class)
    val categoryId = reference("category_id", ContentPackCategoriesTable, onDelete = ReferenceOption.SET_NULL).nullable()
    
    // Pricing and availability
    val priceCents = integer("price_cents").default(0)
    val isFree = bool("is_free").default(false)
    val isFeatured = bool("is_featured").default(false)
    val isPremium = bool("is_premium").default(false)
    
    // Age and educational info
    val ageMin = integer("age_min").default(3)
    val ageMax = integer("age_max").default(12)
    val educationalGoals = jsonb<List<String>>("educational_goals", { Json.encodeToString(it) }, { Json.decodeFromString(it) }).nullable()
    val curriculumTags = jsonb<List<String>>("curriculum_tags", { Json.encodeToString(it) }, { Json.decodeFromString(it) }).nullable()
    
    // Visual and metadata
    val thumbnailUrl = text("thumbnail_url").nullable()
    val previewUrls = jsonb<List<String>>("preview_urls", { Json.encodeToString(it) }, { Json.decodeFromString(it) }).nullable()
    val bannerImageUrl = text("banner_image_url").nullable()
    val colorPalette = jsonb<Map<String, String>>("color_palette", { Json.encodeToString(it) }, { Json.decodeFromString(it) }).nullable()
    val artStyle = varchar("art_style", 100).nullable()
    val moodTags = jsonb<List<String>>("mood_tags", { Json.encodeToString(it) }, { Json.decodeFromString(it) }).nullable()
    
    // Technical metadata
    val totalAssets = integer("total_assets").default(0)
    val fileSizeBytes = long("file_size_bytes").default(0)
    val supportedPlatforms = jsonb<List<String>>("supported_platforms", { Json.encodeToString(it) }, { Json.decodeFromString(it) }).default(listOf("ios", "android", "web"))
    val minAppVersion = varchar("min_app_version", 20).nullable()
    val performanceTier = varchar("performance_tier", 20).default("standard")
    
    // Status and timestamps
    val status = varchar("status", 50).default("draft")
    val publishedAt = timestamp("published_at").nullable()
    val createdAt = timestamp("created_at")
    val updatedAt = timestamp("updated_at")
    val createdBy = uuid("created_by").nullable()
    
    // Search and discovery
    val searchKeywords = text("search_keywords").nullable()
    val popularityScore = decimal("popularity_score", 5, 2).default(BigDecimal("0.00"))
    val downloadCount = long("download_count").default(0)
    val ratingAverage = decimal("rating_average", 3, 2).default(BigDecimal("0.00"))
    val ratingCount = integer("rating_count").default(0)
}

object ContentPackAssetsTable : UUIDTable("content_pack_assets") {
    val packId = reference("pack_id", ContentPacksTable, onDelete = ReferenceOption.CASCADE)
    
    // Basic asset info
    val name = varchar("name", 200)
    val description = text("description").nullable()
    val assetType = enumerationByName("asset_type", 50, MediaType::class)
    val fileUrl = text("file_url")
    val thumbnailUrl = text("thumbnail_url").nullable()
    
    // File technical details
    val fileFormat = varchar("file_format", 20).nullable()
    val fileSizeBytes = integer("file_size_bytes").nullable()
    val dimensionsWidth = integer("dimensions_width").nullable()
    val dimensionsHeight = integer("dimensions_height").nullable()
    val durationSeconds = decimal("duration_seconds", 8, 2).nullable()
    val frameRate = integer("frame_rate").nullable()
    
    // Creative metadata
    val tags = jsonb<List<String>>("tags", { Json.encodeToString(it) }, { Json.decodeFromString(it) }).nullable()
    val colorPalette = jsonb<Map<String, String>>("color_palette", { Json.encodeToString(it) }, { Json.decodeFromString(it) }).nullable()
    val transparencySupport = bool("transparency_support").default(false)
    val loopPoints = jsonb<Map<String, Int>>("loop_points", { Json.encodeToString(it) }, { Json.decodeFromString(it) }).nullable()
    
    // Interactive properties
    val interactionConfig = jsonb<Map<String, String>>("interaction_config", { Json.encodeToString(it) }, { Json.decodeFromString(it) }).nullable()
    val animationTriggers = jsonb<List<String>>("animation_triggers", { Json.encodeToString(it) }, { Json.decodeFromString(it) }).nullable()
    
    // Ordering and grouping
    val displayOrder = integer("display_order").default(0)
    val groupName = varchar("group_name", 100).nullable()
    
    // Status
    val isActive = bool("is_active").default(true)
    val createdAt = timestamp("created_at")
    val updatedAt = timestamp("updated_at")
}

object UserPackOwnershipTable : UUIDTable("user_pack_ownership") {
    val userId = uuid("user_id")
    val packId = reference("pack_id", ContentPacksTable)
    val childId = uuid("child_id").nullable()
    
    // Purchase/acquisition info
    val acquiredAt = timestamp("acquired_at")
    val acquisitionType = varchar("acquisition_type", 50).default("purchase")
    val purchasePriceCents = integer("purchase_price_cents").default(0)
    val transactionId = varchar("transaction_id", 100).nullable()
    
    // Download and usage
    val downloadStatus = varchar("download_status", 50).default("pending")
    val downloadProgress = integer("download_progress").default(0)
    val downloadedAt = timestamp("downloaded_at").nullable()
    val lastUsedAt = timestamp("last_used_at").nullable()
    val usageCount = integer("usage_count").default(0)
    
    // Preferences
    val isFavorite = bool("is_favorite").default(false)
    val isHidden = bool("is_hidden").default(false)
    val customTags = jsonb<List<String>>("custom_tags", { Json.encodeToString(it) }, { Json.decodeFromString(it) }).nullable()
    
    init {
        uniqueIndex(userId, packId, childId)
    }
}

object ContentPackUsageTable : UUIDTable("content_pack_usage") {
    val userId = uuid("user_id")
    val childId = uuid("child_id").nullable()
    val packId = reference("pack_id", ContentPacksTable)
    val assetId = reference("asset_id", ContentPackAssetsTable, onDelete = ReferenceOption.SET_NULL).nullable()
    
    // Usage context
    val usedInFeature = varchar("used_in_feature", 100).nullable()
    val sessionId = uuid("session_id").nullable()
    val usageDurationSeconds = integer("usage_duration_seconds").nullable()
    
    // Metadata
    val usedAt = timestamp("used_at")
    val usageMetadata = jsonb<Map<String, String>>("usage_metadata", { Json.encodeToString(it) }, { Json.decodeFromString(it) }).nullable()
}

object ContentPackCollectionsTable : UUIDTable("content_pack_collections") {
    val name = varchar("name", 200)
    val description = text("description").nullable()
    val collectionType = varchar("collection_type", 50).default("bundle")
    
    // Pricing and availability
    val priceCents = integer("price_cents").default(0)
    val discountPercentage = integer("discount_percentage").default(0)
    
    // Visual
    val thumbnailUrl = text("thumbnail_url").nullable()
    val bannerImageUrl = text("banner_image_url").nullable()
    
    // Status
    val isActive = bool("is_active").default(true)
    val isFeatured = bool("is_featured").default(false)
    val availableFrom = timestamp("available_from").nullable()
    val availableUntil = timestamp("available_until").nullable()
    
    val createdAt = timestamp("created_at")
    val updatedAt = timestamp("updated_at")
}

object ContentPackCollectionItemsTable : UUIDTable("content_pack_collection_items") {
    val collectionId = reference("collection_id", ContentPackCollectionsTable, onDelete = ReferenceOption.CASCADE)
    val packId = reference("pack_id", ContentPacksTable, onDelete = ReferenceOption.CASCADE)
    val displayOrder = integer("display_order").default(0)
    val addedAt = timestamp("added_at")
    
    init {
        uniqueIndex(collectionId, packId)
    }
}

object ContentPackReviewsTable : UUIDTable("content_pack_reviews") {
    val packId = reference("pack_id", ContentPacksTable)
    val userId = uuid("user_id") // Parent/guardian only
    
    // Review content
    val rating = integer("rating")
    val reviewText = text("review_text").nullable()
    val reviewTitle = varchar("review_title", 200).nullable()
    
    // Helpful metrics
    val helpfulCount = integer("helpful_count").default(0)
    val notHelpfulCount = integer("not_helpful_count").default(0)
    
    // Child context (anonymous)
    val childAgeRange = varchar("child_age_range", 10).nullable()
    val usedFeatures = jsonb<List<String>>("used_features", { Json.encodeToString(it) }, { Json.decodeFromString(it) }).nullable()
    
    // Moderation
    val isApproved = bool("is_approved").default(false)
    val isFeatured = bool("is_featured").default(false)
    val moderatedAt = timestamp("moderated_at").nullable()
    val moderatedBy = uuid("moderated_by").nullable()
    
    val createdAt = timestamp("created_at")
    val updatedAt = timestamp("updated_at")
    
    init {
        uniqueIndex(packId, userId)
    }
}

// Enums for content pack system
enum class ContentPackType {
    CHARACTER_BUNDLE,
    BACKDROP_COLLECTION,
    STICKER_PACK,
    SOUND_EFFECTS,
    MUSIC_COLLECTION,
    VOICE_PACK,
    EMOJI_PACK,
    SPRITE_SHEET,
    INTERACTIVE_OBJECTS,
    PARTICLE_EFFECTS,
    TEXTURE_PACK,
    ANIMATION_BUNDLE,
    EDUCATIONAL_THEME
}

enum class MediaType {
    IMAGE_STATIC,
    IMAGE_ANIMATED,
    SPRITE_SHEET,
    VECTOR_ANIMATION,
    AUDIO_SOUND,
    AUDIO_MUSIC,
    AUDIO_VOICE,
    VIDEO_SHORT,
    INTERACTIVE_OBJECT,
    PARTICLE_SYSTEM,
    TEXTURE_3D,
    MODEL_3D,
    FONT_CUSTOM
}