package com.wondernest.domain.model.games

import kotlinx.datetime.Instant
import kotlinx.serialization.Contextual
import kotlinx.serialization.Serializable
import java.util.UUID

// =============================================================================
// CORE GAME MODELS
// =============================================================================

@Serializable
data class GameType(
    @Contextual val id: UUID = UUID.randomUUID(),
    val name: String,
    val description: String,
    val defaultSchema: GameDataSchema,
    val createdAt: Instant
)

@Serializable
data class GameCategory(
    @Contextual val id: UUID = UUID.randomUUID(),
    val name: String,
    @Contextual val parentCategoryId: UUID? = null,
    val iconUrl: String? = null,
    val sortOrder: Int = 0,
    val isActive: Boolean = true,
    val createdAt: Instant
)

@Serializable
data class GameRegistry(
    @Contextual val id: UUID = UUID.randomUUID(),
    val gameKey: String,
    val displayName: String,
    val description: String,
    val version: String = "1.0.0",
    @Contextual val gameTypeId: UUID,
    @Contextual val categoryId: UUID? = null,
    val minAgeMonths: Int = 24,
    val maxAgeMonths: Int = 144,
    val configuration: GameConfiguration,
    val defaultSettings: GameSettings,
    val implementationType: ImplementationType = ImplementationType.NATIVE,
    val entryPoint: String? = null,
    val resourceBundleUrl: String? = null,
    val contentRating: String = "everyone",
    val safetyReviewed: Boolean = false,
    val safetyReviewedAt: Instant? = null,
    @Contextual val safetyReviewerId: UUID? = null,
    val isActive: Boolean = false,
    val isPremium: Boolean = false,
    val releaseDate: Instant? = null,
    val sunsetDate: Instant? = null,
    val tags: List<String> = emptyList(),
    val keywords: List<String> = emptyList(),
    val educationalObjectives: List<String> = emptyList(),
    val skillsDeveloped: List<String> = emptyList(),
    val createdAt: Instant,
    val updatedAt: Instant
)

// =============================================================================
// CHILD GAME INSTANCES
// =============================================================================

@Serializable
data class ChildGameInstance(
    @Contextual val id: UUID = UUID.randomUUID(),
    @Contextual val childId: UUID,
    @Contextual val gameId: UUID,
    val settings: GameSettings,
    val preferences: GamePreferences,
    val isUnlocked: Boolean = true,
    val unlockedAt: Instant? = null,
    val firstPlayedAt: Instant? = null,
    val lastPlayedAt: Instant? = null,
    val totalPlayTimeMinutes: Int = 0,
    val sessionCount: Int = 0,
    val isFavorite: Boolean = false,
    val isCompleted: Boolean = false,
    val completionPercentage: Double = 0.0,
    val createdAt: Instant,
    val updatedAt: Instant
)

@Serializable
data class ChildGameData(
    @Contextual val id: UUID = UUID.randomUUID(),
    @Contextual val childGameInstanceId: UUID,
    val dataKey: String,
    val dataVersion: Int = 1,
    val dataValue: GameDataValue,
    val createdAt: Instant,
    val updatedAt: Instant
)

// =============================================================================
// GAME SESSIONS
// =============================================================================

@Serializable
data class GameSession(
    @Contextual val id: UUID = UUID.randomUUID(),
    @Contextual val childGameInstanceId: UUID,
    val startedAt: Instant,
    val endedAt: Instant? = null,
    val durationMinutes: Int? = null,
    val deviceType: String? = null,
    val appVersion: String? = null,
    val gameVersion: String? = null,
    val sessionData: SessionMetrics = SessionMetrics(),
    val events: List<GameEvent> = emptyList(),
    val createdAt: Instant
)

@Serializable
data class GameEvent(
    val type: String,
    val timestamp: Instant,
    val data: Map<String, String> = emptyMap()
) {
    companion object
}

// =============================================================================
// ACHIEVEMENTS
// =============================================================================

@Serializable
data class Achievement(
    @Contextual val id: UUID = UUID.randomUUID(),
    @Contextual val gameId: UUID,
    val achievementKey: String,
    val name: String,
    val description: String,
    val iconUrl: String? = null,
    val criteria: AchievementCriteria,
    val points: Int = 10,
    val category: String? = null,
    val rarity: AchievementRarity = AchievementRarity.COMMON,
    val sortOrder: Int = 0,
    val isSecret: Boolean = false,
    val isActive: Boolean = true,
    val createdAt: Instant
)

@Serializable
data class ChildAchievement(
    @Contextual val id: UUID = UUID.randomUUID(),
    @Contextual val childGameInstanceId: UUID,
    @Contextual val achievementId: UUID,
    val unlockedAt: Instant,
    @Contextual val gameSessionId: UUID? = null,
    val createdAt: Instant
)

// =============================================================================
// ASSETS
// =============================================================================

@Serializable
data class GameAsset(
    @Contextual val id: UUID = UUID.randomUUID(),
    val assetType: String, // 'sticker', 'background', 'sound', 'sprite'
    val assetCategory: String? = null,
    val name: String,
    val url: String? = null,
    val thumbnailUrl: String? = null,
    val metadata: Map<String, String> = emptyMap(),
    val isPremium: Boolean = false,
    val wonderCoinPrice: Int = 0,
    val minAgeMonths: Int = 0,
    val maxAgeMonths: Int = 999,
    val createdAt: Instant
)

@Serializable
data class GameAssetLink(
    @Contextual val gameId: UUID,
    @Contextual val assetId: UUID,
    val usageContext: Map<String, String> = emptyMap(),
    val isStarter: Boolean = false,
    val unlockRequirement: Map<String, String>? = null
)

// =============================================================================
// PARENT APPROVALS
// =============================================================================

@Serializable
data class ParentApproval(
    @Contextual val id: UUID = UUID.randomUUID(),
    @Contextual val childId: UUID,
    @Contextual val gameId: UUID? = null,
    val approvalType: String, // 'custom_content', 'premium_purchase', 'sharing'
    val requestContext: String? = null,
    val requestData: Map<String, String>,
    val status: ApprovalStatus = ApprovalStatus.PENDING,
    @Contextual val parentId: UUID? = null,
    val reviewedAt: Instant? = null,
    val rejectionReason: String? = null,
    val expiresAt: Instant,
    val createdAt: Instant
)

// =============================================================================
// VIRTUAL CURRENCY
// =============================================================================

@Serializable
data class VirtualCurrency(
    @Contextual val id: UUID = UUID.randomUUID(),
    @Contextual val childId: UUID,
    val balance: Int = 0,
    val totalEarned: Int = 0,
    val totalSpent: Int = 0,
    val lastUpdated: Instant
)

@Serializable
data class CurrencyTransaction(
    @Contextual val id: UUID = UUID.randomUUID(),
    @Contextual val childId: UUID,
    val amount: Int,
    val transactionType: TransactionType,
    val source: String? = null,
    val description: String? = null,
    val createdAt: Instant
)

// =============================================================================
// ANALYTICS
// =============================================================================

@Serializable
data class DailyGameMetrics(
    @Contextual val id: UUID = UUID.randomUUID(),
    @Contextual val childId: UUID,
    @Contextual val gameId: UUID,
    val date: String, // ISO date string
    val playTimeMinutes: Int = 0,
    val sessionsCount: Int = 0,
    val achievementsUnlocked: Int = 0,
    val metrics: Map<String, String> = emptyMap(),
    val createdAt: Instant
)

// =============================================================================
// DATA VALUE TYPES
// =============================================================================

@Serializable
sealed class GameDataValue {
    @Serializable
    data class StringValue(val value: String) : GameDataValue()
    
    @Serializable
    data class IntValue(val value: Int) : GameDataValue()
    
    @Serializable
    data class BooleanValue(val value: Boolean) : GameDataValue()
    
    @Serializable
    data class ListValue(val value: List<String>) : GameDataValue()
    
    @Serializable
    data class MapValue(val value: Map<String, String>) : GameDataValue()
    
    @Serializable
    data class JsonValue(val value: String) : GameDataValue() // Raw JSON string
    
    companion object
}

// =============================================================================
// CONFIGURATION TYPES
// =============================================================================

@Serializable
data class GameConfiguration(
    val features: Map<String, String> = emptyMap(),
    val limits: Map<String, Int> = emptyMap(),
    val customSettings: Map<String, String> = emptyMap()
) {
    companion object
}

@Serializable
data class GameSettings(
    val soundEnabled: Boolean = true,
    val animationsEnabled: Boolean = true,
    val autoSave: Boolean = true,
    val tutorialCompleted: Boolean = false,
    val difficulty: String = "normal",
    val customSettings: Map<String, String> = emptyMap()
) {
    companion object
}

@Serializable
data class GamePreferences(
    val theme: String = "default",
    val sortOrder: String = "newest_first",
    val displayMode: String = "grid",
    val customPreferences: Map<String, String> = emptyMap()
) {
    companion object
}

@Serializable
data class GameDataSchema(
    val requiredKeys: List<String> = emptyList(),
    val optionalKeys: List<String> = emptyList(),
    val keyTypes: Map<String, String> = emptyMap()
)

@Serializable
data class SessionMetrics(
    val clickCount: Int = 0,
    val errorCount: Int = 0,
    val hintCount: Int = 0,
    val scoreEarned: Int = 0,
    val itemsCollected: Int = 0,
    val customMetrics: Map<String, Int> = emptyMap()
) {
    companion object
}

@Serializable
data class AchievementCriteria(
    val type: String, // 'score_threshold', 'items_collected', 'time_played', etc.
    val threshold: Int,
    val conditions: Map<String, String> = emptyMap()
) {
    companion object
}

// =============================================================================
// ENUMS
// =============================================================================

@Serializable
enum class ImplementationType {
    NATIVE,
    WEB,
    HYBRID
}

@Serializable
enum class AchievementRarity {
    COMMON,
    UNCOMMON,
    RARE,
    EPIC,
    LEGENDARY
}

@Serializable
enum class ApprovalStatus {
    PENDING,
    APPROVED,
    REJECTED
}

@Serializable
enum class TransactionType {
    EARNED,
    SPENT,
    BONUS,
    REFUND
}

// =============================================================================
// STICKER BOOK SPECIFIC MODELS (POC)
// =============================================================================

@Serializable
data class StickerBook(
    val id: String,
    val title: String,
    val canvasMode: String, // 'infinite_canvas' or 'flip_book'
    val createdAt: Instant,
    val pages: List<StickerPage> = emptyList()
)

@Serializable
data class StickerPage(
    val id: String,
    val pageNumber: Int = 1,
    val elements: List<PageElement> = emptyList()
)

@Serializable
sealed class PageElement {
    abstract val id: String
    abstract val x: Double
    abstract val y: Double
    
    @Serializable
    data class StickerElement(
        override val id: String,
        override val x: Double,
        override val y: Double,
        val stickerId: String,
        val scale: Double = 1.0,
        val rotation: Double = 0.0
    ) : PageElement()
    
    @Serializable
    data class DrawingElement(
        override val id: String,
        override val x: Double,
        override val y: Double,
        val pathData: String,
        val color: String,
        val strokeWidth: Float
    ) : PageElement()
    
    @Serializable
    data class TextElement(
        override val id: String,
        override val x: Double,
        override val y: Double,
        val text: String,
        val fontSize: Float,
        val color: String
    ) : PageElement()
}

@Serializable
data class StickerCollection(
    val ownedPacks: List<String> = emptyList(),
    val customStickers: List<CustomSticker> = emptyList()
)

@Serializable
data class CustomSticker(
    val id: String,
    val imageUrl: String,
    val createdAt: Instant,
    val approved: Boolean = false
)