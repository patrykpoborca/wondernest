package com.wondernest.data.database.table

import org.jetbrains.exposed.dao.id.UUIDTable
import org.jetbrains.exposed.sql.ReferenceOption
import org.jetbrains.exposed.sql.Table
import org.jetbrains.exposed.sql.kotlin.datetime.timestamp
import org.jetbrains.exposed.sql.kotlin.datetime.date
import org.jetbrains.exposed.sql.json.jsonb
import kotlinx.serialization.json.Json
import kotlinx.serialization.encodeToString
import kotlinx.serialization.decodeFromString
import java.util.UUID

// =============================================================================
// GAME REGISTRY TABLES
// =============================================================================

object GameTypes : UUIDTable("game_types", "games") {
    val name = varchar("name", 100).uniqueIndex()
    val description = text("description")
    val defaultSchema = jsonb<Map<String, Any>>("default_schema",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    )
    val createdAt = timestamp("created_at")
}

object GameCategories : UUIDTable("game_categories", "games") {
    val name = varchar("name", 100).uniqueIndex()
    val parentCategoryId = reference("parent_category_id", GameCategories, onDelete = ReferenceOption.SET_NULL).nullable()
    val iconUrl = varchar("icon_url", 500).nullable()
    val sortOrder = integer("sort_order").default(0)
    val isActive = bool("is_active").default(true)
    val createdAt = timestamp("created_at")
}

object GameRegistry : UUIDTable("game_registry", "games") {
    val gameKey = varchar("game_key", 100).uniqueIndex()
    val displayName = varchar("display_name", 200)
    val description = text("description")
    val version = varchar("version", 20).default("1.0.0")
    
    // Game metadata
    val gameTypeId = reference("game_type_id", GameTypes, onDelete = ReferenceOption.RESTRICT)
    val categoryId = reference("category_id", GameCategories, onDelete = ReferenceOption.SET_NULL).nullable()
    
    // Age targeting
    val minAgeMonths = integer("min_age_months").default(24)
    val maxAgeMonths = integer("max_age_months").default(144)
    
    // Configuration
    val configuration = jsonb<Map<String, Any>>("configuration",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    )
    val defaultSettings = jsonb<Map<String, Any>>("default_settings",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    )
    
    // Implementation
    val implementationType = varchar("implementation_type", 20).default("native")
    val entryPoint = varchar("entry_point", 500).nullable()
    val resourceBundleUrl = varchar("resource_bundle_url", 500).nullable()
    
    // Content safety
    val contentRating = varchar("content_rating", 20).default("everyone")
    val safetyReviewed = bool("safety_reviewed").default(false)
    val safetyReviewedAt = timestamp("safety_reviewed_at").nullable()
    val safetyReviewerId = reference("safety_reviewer_id", Users, onDelete = ReferenceOption.SET_NULL).nullable()
    
    // Availability
    val isActive = bool("is_active").default(false)
    val isPremium = bool("is_premium").default(false)
    val releaseDate = timestamp("release_date").nullable()
    val sunsetDate = timestamp("sunset_date").nullable()
    
    // Metadata
    val tags = jsonb<List<String>>("tags",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    )
    val keywords = jsonb<List<String>>("keywords",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    )
    val educationalObjectives = jsonb<List<String>>("educational_objectives",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    )
    val skillsDeveloped = jsonb<List<String>>("skills_developed",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    )
    
    val createdAt = timestamp("created_at")
    val updatedAt = timestamp("updated_at")
}

// =============================================================================
// CHILD GAME INSTANCES
// =============================================================================

object ChildGameInstances : UUIDTable("child_game_instances", "games") {
    val childId = reference("child_id", ChildProfiles, onDelete = ReferenceOption.CASCADE)
    val gameId = reference("game_id", GameRegistry, onDelete = ReferenceOption.CASCADE)
    
    // Instance configuration
    val settings = jsonb<Map<String, Any>>("settings",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    )
    val preferences = jsonb<Map<String, Any>>("preferences",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    )
    
    // Progress tracking
    val isUnlocked = bool("is_unlocked").default(true)
    val unlockedAt = timestamp("unlocked_at").nullable()
    val firstPlayedAt = timestamp("first_played_at").nullable()
    val lastPlayedAt = timestamp("last_played_at").nullable()
    
    // Statistics
    val totalPlayTimeMinutes = integer("total_play_time_minutes").default(0)
    val sessionCount = integer("session_count").default(0)
    
    // Status
    val isFavorite = bool("is_favorite").default(false)
    val isCompleted = bool("is_completed").default(false)
    val completionPercentage = decimal("completion_percentage", 5, 2).default(java.math.BigDecimal.ZERO)
    
    val createdAt = timestamp("created_at")
    val updatedAt = timestamp("updated_at")
    
    init {
        uniqueIndex(childId, gameId)
    }
}

object ChildGameData : UUIDTable("child_game_data", "games") {
    val childGameInstanceId = reference("child_game_instance_id", ChildGameInstances, onDelete = ReferenceOption.CASCADE)
    val dataKey = varchar("data_key", 200)
    val dataVersion = integer("data_version").default(1)
    val dataValue = jsonb<Map<String, Any>>("data_value",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    )
    val createdAt = timestamp("created_at")
    val updatedAt = timestamp("updated_at")
    
    init {
        uniqueIndex(childGameInstanceId, dataKey)
    }
}

// =============================================================================
// GAME SESSIONS
// =============================================================================

object GameSessions : UUIDTable("game_sessions", "games") {
    val childGameInstanceId = reference("child_game_instance_id", ChildGameInstances, onDelete = ReferenceOption.CASCADE)
    
    // Session timing
    val startedAt = timestamp("started_at")
    val endedAt = timestamp("ended_at").nullable()
    val durationMinutes = integer("duration_minutes").nullable()
    
    // Session context
    val deviceType = varchar("device_type", 50).nullable()
    val appVersion = varchar("app_version", 50).nullable()
    val gameVersion = varchar("game_version", 20).nullable()
    
    // Metrics
    val sessionData = jsonb<Map<String, Any>>("session_data",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    )
    val events = jsonb<List<Map<String, Any>>>("events",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    )
    
    val createdAt = timestamp("created_at")
}

// =============================================================================
// ACHIEVEMENTS SYSTEM
// =============================================================================

object Achievements : UUIDTable("achievements", "games") {
    val gameId = reference("game_id", GameRegistry, onDelete = ReferenceOption.CASCADE)
    
    val achievementKey = varchar("achievement_key", 200)
    val name = varchar("name", 200)
    val description = text("description")
    val iconUrl = varchar("icon_url", 500).nullable()
    
    // Unlock criteria
    val criteria = jsonb<Map<String, Any>>("criteria",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    )
    val points = integer("points").default(10)
    
    // Display
    val category = varchar("category", 100).nullable()
    val rarity = varchar("rarity", 20).default("common")
    val sortOrder = integer("sort_order").default(0)
    val isSecret = bool("is_secret").default(false)
    val isActive = bool("is_active").default(true)
    
    val createdAt = timestamp("created_at")
    
    init {
        uniqueIndex(gameId, achievementKey)
    }
}

object ChildAchievements : UUIDTable("child_achievements", "games") {
    val childGameInstanceId = reference("child_game_instance_id", ChildGameInstances, onDelete = ReferenceOption.CASCADE)
    val achievementId = reference("achievement_id", Achievements, onDelete = ReferenceOption.CASCADE)
    
    val unlockedAt = timestamp("unlocked_at")
    val gameSessionId = reference("game_session_id", GameSessions, onDelete = ReferenceOption.SET_NULL).nullable()
    
    val createdAt = timestamp("created_at")
    
    init {
        uniqueIndex(childGameInstanceId, achievementId)
    }
}

// =============================================================================
// SHARED ASSET SYSTEM
// =============================================================================

object GameAssets : UUIDTable("game_assets", "games") {
    val assetType = varchar("asset_type", 50) // 'sticker', 'background', 'sound', 'sprite'
    val assetCategory = varchar("asset_category", 100).nullable()
    val name = varchar("name", 200)
    
    // Asset data
    val url = varchar("url", 500).nullable()
    val thumbnailUrl = varchar("thumbnail_url", 500).nullable()
    val metadata = jsonb<Map<String, Any>>("metadata",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    )
    
    // Monetization
    val isPremium = bool("is_premium").default(false)
    val wonderCoinPrice = integer("wonder_coin_price").default(0)
    
    // Age targeting
    val minAgeMonths = integer("min_age_months").default(0)
    val maxAgeMonths = integer("max_age_months").default(999)
    
    val createdAt = timestamp("created_at")
}

object GameAssetRegistry : Table("games.game_asset_registry") {
    val gameId = reference("game_id", GameRegistry, onDelete = ReferenceOption.CASCADE)
    val assetId = reference("asset_id", GameAssets, onDelete = ReferenceOption.CASCADE)
    val usageContext = jsonb<Map<String, Any>>("usage_context",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    ).nullable()
    val isStarter = bool("is_starter").default(false)
    val unlockRequirement = jsonb<Map<String, Any>>("unlock_requirement",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    ).nullable()
    
    override val primaryKey = PrimaryKey(gameId, assetId)
}

// =============================================================================
// PARENT APPROVAL SYSTEM
// =============================================================================

object ParentApprovals : UUIDTable("parent_approvals", "games") {
    val childId = reference("child_id", ChildProfiles, onDelete = ReferenceOption.CASCADE)
    val gameId = reference("game_id", GameRegistry, onDelete = ReferenceOption.SET_NULL).nullable()
    
    // Request details
    val approvalType = varchar("approval_type", 100) // 'custom_content', 'premium_purchase', 'sharing'
    val requestContext = varchar("request_context", 500).nullable()
    val requestData = jsonb<Map<String, Any>>("request_data",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    )
    
    // Approval status
    val status = varchar("status", 20).default("pending") // 'pending', 'approved', 'rejected'
    val parentId = reference("parent_id", Users, onDelete = ReferenceOption.SET_NULL).nullable()
    val reviewedAt = timestamp("reviewed_at").nullable()
    val rejectionReason = text("rejection_reason").nullable()
    
    // Auto-expiry
    val expiresAt = timestamp("expires_at")
    
    val createdAt = timestamp("created_at")
}

// =============================================================================
// VIRTUAL CURRENCY
// =============================================================================

object VirtualCurrency : UUIDTable("virtual_currency", "games") {
    val childId = reference("child_id", ChildProfiles, onDelete = ReferenceOption.CASCADE).uniqueIndex()
    val balance = integer("balance").default(0)
    val totalEarned = integer("total_earned").default(0)
    val totalSpent = integer("total_spent").default(0)
    val lastUpdated = timestamp("last_updated")
}

object CurrencyTransactions : UUIDTable("currency_transactions", "games") {
    val childId = reference("child_id", ChildProfiles, onDelete = ReferenceOption.CASCADE)
    val amount = integer("amount")
    val transactionType = varchar("transaction_type", 50) // 'earned', 'spent', 'bonus', 'refund'
    val sourceReference = varchar("source", 100).nullable() // game_id, achievement_id, purchase_id
    val description = text("description").nullable()
    val createdAt = timestamp("created_at")
}

// =============================================================================
// ANALYTICS
// =============================================================================

object DailyGameMetrics : UUIDTable("daily_game_metrics", "games") {
    val childId = reference("child_id", ChildProfiles, onDelete = ReferenceOption.CASCADE)
    val gameId = reference("game_id", GameRegistry, onDelete = ReferenceOption.SET_NULL).nullable()
    val date = date("date")
    
    // Metrics
    val playTimeMinutes = integer("play_time_minutes").default(0)
    val sessionsCount = integer("sessions_count").default(0)
    val achievementsUnlocked = integer("achievements_unlocked").default(0)
    val metrics = jsonb<Map<String, Any>>("metrics",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    )
    
    val createdAt = timestamp("created_at")
    
    init {
        uniqueIndex(childId, gameId, date)
    }
}

// =============================================================================
// SIMPLIFIED GAME DATA (for sticker book and similar games that don't need full game registry)
// =============================================================================

object SimpleGameData : UUIDTable("simple_game_data", "games") {
    val childId = uuid("child_id") // Direct child_id reference without foreign key constraint for flexibility
    val gameType = varchar("game_type", 100) // e.g., "sticker_book", "drawing", etc.
    val dataKey = varchar("data_key", 200) // e.g., "sticker_project_123", "drawing_456"
    val dataValue = jsonb<Map<String, kotlinx.serialization.json.JsonElement>>("data_value",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    )
    val createdAt = timestamp("created_at")
    val updatedAt = timestamp("updated_at")
    
    init {
        uniqueIndex(childId, gameType, dataKey)
    }
}