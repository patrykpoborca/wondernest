package com.wondernest.domain.repository.games

import com.wondernest.domain.model.games.*
import java.util.UUID

// =============================================================================
// GAME REGISTRY REPOSITORY
// =============================================================================

interface GameRegistryRepository {
    suspend fun findById(id: UUID): GameRegistry?
    suspend fun findByKey(gameKey: String): GameRegistry?
    suspend fun findAll(isActive: Boolean? = null): List<GameRegistry>
    suspend fun findByAgeRange(ageMonths: Int): List<GameRegistry>
    suspend fun findByCategory(categoryId: UUID): List<GameRegistry>
    suspend fun save(game: GameRegistry): GameRegistry
    suspend fun update(game: GameRegistry): GameRegistry
    suspend fun delete(id: UUID): Boolean
}

// =============================================================================
// CHILD GAME INSTANCE REPOSITORY
// =============================================================================

interface ChildGameInstanceRepository {
    suspend fun findById(id: UUID): ChildGameInstance?
    suspend fun findByChildAndGame(childId: UUID, gameId: UUID): ChildGameInstance?
    suspend fun findByChild(childId: UUID): List<ChildGameInstance>
    suspend fun findFavorites(childId: UUID): List<ChildGameInstance>
    suspend fun create(instance: ChildGameInstance): ChildGameInstance
    suspend fun update(instance: ChildGameInstance): ChildGameInstance
    suspend fun updateProgress(
        instanceId: UUID, 
        completionPercentage: Double,
        playTimeMinutes: Int
    ): Boolean
    suspend fun delete(id: UUID): Boolean
}

// =============================================================================
// GAME DATA REPOSITORY
// =============================================================================

interface GameDataRepository {
    suspend fun get(instanceId: UUID, dataKey: String): ChildGameData?
    suspend fun getAll(instanceId: UUID): List<ChildGameData>
    suspend fun save(data: ChildGameData): ChildGameData
    suspend fun update(instanceId: UUID, dataKey: String, value: GameDataValue): Boolean
    suspend fun batchUpdate(instanceId: UUID, updates: Map<String, GameDataValue>): Boolean
    suspend fun delete(instanceId: UUID, dataKey: String): Boolean
    suspend fun deleteAll(instanceId: UUID): Boolean
}

// =============================================================================
// GAME SESSION REPOSITORY
// =============================================================================

interface GameSessionRepository {
    suspend fun findById(id: UUID): GameSession?
    suspend fun findByInstance(instanceId: UUID, limit: Int = 50): List<GameSession>
    suspend fun findActive(instanceId: UUID): GameSession?
    suspend fun create(session: GameSession): GameSession
    suspend fun update(session: GameSession): GameSession
    suspend fun end(sessionId: UUID, metrics: SessionMetrics): GameSession?
    suspend fun addEvent(sessionId: UUID, event: GameEvent): Boolean
    suspend fun getSessionStats(childId: UUID, startDate: String, endDate: String): SessionStats
}

// =============================================================================
// ACHIEVEMENT REPOSITORY
// =============================================================================

interface AchievementRepository {
    suspend fun findById(id: UUID): Achievement?
    suspend fun findByGame(gameId: UUID): List<Achievement>
    suspend fun findByKey(gameId: UUID, achievementKey: String): Achievement?
    suspend fun create(achievement: Achievement): Achievement
    suspend fun update(achievement: Achievement): Achievement
    suspend fun delete(id: UUID): Boolean
    
    // Child achievements
    suspend fun getUnlocked(instanceId: UUID): List<ChildAchievement>
    suspend fun unlock(instanceId: UUID, achievementId: UUID, sessionId: UUID?): ChildAchievement
    suspend fun isUnlocked(instanceId: UUID, achievementId: UUID): Boolean
    suspend fun getProgress(instanceId: UUID): Map<UUID, AchievementProgress>
}

// =============================================================================
// ASSET REPOSITORY
// =============================================================================

interface GameAssetRepository {
    suspend fun findById(id: UUID): GameAsset?
    suspend fun findByType(assetType: String): List<GameAsset>
    suspend fun findByGame(gameId: UUID): List<GameAsset>
    suspend fun create(asset: GameAsset): GameAsset
    suspend fun linkToGame(gameId: UUID, assetId: UUID, context: GameAssetLink): Boolean
    suspend fun unlinkFromGame(gameId: UUID, assetId: UUID): Boolean
    suspend fun getStarterAssets(gameId: UUID): List<GameAsset>
}

// =============================================================================
// PARENT APPROVAL REPOSITORY
// =============================================================================

interface ParentApprovalRepository {
    suspend fun findById(id: UUID): ParentApproval?
    suspend fun findPending(childId: UUID): List<ParentApproval>
    suspend fun findByParent(parentId: UUID): List<ParentApproval>
    suspend fun create(approval: ParentApproval): ParentApproval
    suspend fun approve(id: UUID, parentId: UUID): Boolean
    suspend fun reject(id: UUID, parentId: UUID, reason: String): Boolean
    suspend fun expirePending(): Int // Returns count of expired approvals
}

// =============================================================================
// VIRTUAL CURRENCY REPOSITORY
// =============================================================================

interface VirtualCurrencyRepository {
    suspend fun getBalance(childId: UUID): VirtualCurrency?
    suspend fun createAccount(childId: UUID): VirtualCurrency
    suspend fun addCurrency(childId: UUID, amount: Int, source: String, description: String): Boolean
    suspend fun spendCurrency(childId: UUID, amount: Int, source: String, description: String): Boolean
    suspend fun getTransactionHistory(childId: UUID, limit: Int = 50): List<CurrencyTransaction>
    suspend fun refund(transactionId: UUID): Boolean
}

// =============================================================================
// ANALYTICS REPOSITORY
// =============================================================================

interface GameAnalyticsRepository {
    suspend fun recordMetrics(metrics: DailyGameMetrics): Boolean
    suspend fun getMetrics(childId: UUID, gameId: UUID?, startDate: String, endDate: String): List<DailyGameMetrics>
    suspend fun getAggregatedMetrics(childId: UUID, period: String): AggregatedMetrics
    suspend fun getGameInsights(childId: UUID, gameId: UUID): GameInsights
    suspend fun getCrossGameInsights(childId: UUID): CrossGameInsights
}

// =============================================================================
// SUPPORTING DATA CLASSES
// =============================================================================

data class SessionStats(
    val totalSessions: Int,
    val totalPlayTimeMinutes: Int,
    val averageSessionMinutes: Double,
    val uniqueGamesPlayed: Int,
    val achievementsUnlocked: Int
)

data class AchievementProgress(
    val achievementId: UUID,
    val currentValue: Int,
    val targetValue: Int,
    val percentage: Double
)

data class AggregatedMetrics(
    val period: String,
    val totalPlayTimeMinutes: Int,
    val sessionsCount: Int,
    val uniqueGamesCount: Int,
    val achievementsCount: Int,
    val favoriteGame: String?,
    val skillProgress: Map<String, Double>
)

data class GameInsights(
    val gameId: UUID,
    val engagementScore: Double,
    val progressionRate: Double,
    val strengthAreas: List<String>,
    val improvementAreas: List<String>,
    val recommendations: List<String>
)

data class CrossGameInsights(
    val learningStyle: String,
    val preferredGameTypes: List<String>,
    val skillDevelopment: Map<String, Double>,
    val socialEngagement: Double,
    val creativityScore: Double,
    val problemSolvingScore: Double
)