package com.wondernest.services.games

import com.wondernest.domain.model.games.*
import com.wondernest.domain.repository.games.*
import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import kotlinx.serialization.Contextual
import kotlinx.serialization.Serializable
import java.util.UUID

// =============================================================================
// CORE GAME SERVICE
// =============================================================================

interface GameService {
    suspend fun getAvailableGames(childId: UUID, ageMonths: Int): List<GameRegistry>
    suspend fun getChildGameInstances(childId: UUID): List<ChildGameInstance>
    suspend fun getGameInstance(childId: UUID, gameId: UUID): ChildGameInstance?
    suspend fun createGameInstance(childId: UUID, gameId: UUID, initialSettings: GameSettings?): ChildGameInstance
    suspend fun updateGameSettings(childId: UUID, gameId: UUID, settings: GameSettings): ChildGameInstance
    suspend fun updateGameData(childId: UUID, gameId: UUID, dataUpdates: Map<String, GameDataValue>, sessionId: UUID?): Boolean
    suspend fun markAsFavorite(childId: UUID, gameId: UUID, isFavorite: Boolean): Boolean
}

class GameServiceImpl(
    private val gameRegistryRepo: GameRegistryRepository,
    private val instanceRepo: ChildGameInstanceRepository,
    private val dataRepo: GameDataRepository,
    private val sessionRepo: GameSessionRepository
) : GameService {
    
    override suspend fun getAvailableGames(childId: UUID, ageMonths: Int): List<GameRegistry> {
        // Get all active games suitable for child's age
        val allGames = gameRegistryRepo.findAll(isActive = true)
        return allGames.filter { game ->
            ageMonths >= game.minAgeMonths && ageMonths <= game.maxAgeMonths
        }
    }
    
    override suspend fun getChildGameInstances(childId: UUID): List<ChildGameInstance> {
        return instanceRepo.findByChild(childId)
    }
    
    override suspend fun getGameInstance(childId: UUID, gameId: UUID): ChildGameInstance? {
        return instanceRepo.findByChildAndGame(childId, gameId)
    }
    
    override suspend fun createGameInstance(
        childId: UUID, 
        gameId: UUID, 
        initialSettings: GameSettings?
    ): ChildGameInstance {
        // Check if instance already exists
        val existing = instanceRepo.findByChildAndGame(childId, gameId)
        if (existing != null) {
            return existing
        }
        
        // Get game registry for default settings
        val game = gameRegistryRepo.findById(gameId)
            ?: throw GameNotFoundException("Game not found: $gameId")
        
        // Create new instance
        val instance = ChildGameInstance(
            childId = childId,
            gameId = gameId,
            settings = initialSettings ?: game.defaultSettings,
            preferences = GamePreferences(),
            isUnlocked = true,
            unlockedAt = Clock.System.now(),
            createdAt = Clock.System.now(),
            updatedAt = Clock.System.now()
        )
        
        return instanceRepo.create(instance)
    }
    
    override suspend fun updateGameSettings(
        childId: UUID, 
        gameId: UUID, 
        settings: GameSettings
    ): ChildGameInstance {
        val instance = instanceRepo.findByChildAndGame(childId, gameId)
            ?: throw GameInstanceNotFoundException("Game instance not found")
        
        val updated = instance.copy(
            settings = settings,
            updatedAt = Clock.System.now()
        )
        
        return instanceRepo.update(updated)
    }
    
    override suspend fun updateGameData(
        childId: UUID,
        gameId: UUID,
        dataUpdates: Map<String, GameDataValue>,
        sessionId: UUID?
    ): Boolean {
        val instance = instanceRepo.findByChildAndGame(childId, gameId)
            ?: throw GameInstanceNotFoundException("Game instance not found")
        
        // Update all data keys
        val success = dataRepo.batchUpdate(instance.id, dataUpdates)
        
        // Record in session if provided
        if (sessionId != null && success) {
            val event = GameEvent(
                type = "data_update",
                timestamp = Clock.System.now(),
                data = mapOf("keys_updated" to dataUpdates.keys.joinToString(","))
            )
            sessionRepo.addEvent(sessionId, event)
        }
        
        return success
    }
    
    override suspend fun markAsFavorite(childId: UUID, gameId: UUID, isFavorite: Boolean): Boolean {
        val instance = instanceRepo.findByChildAndGame(childId, gameId)
            ?: return false
        
        val updated = instance.copy(
            isFavorite = isFavorite,
            updatedAt = Clock.System.now()
        )
        
        instanceRepo.update(updated)
        return true
    }
}

// =============================================================================
// GAME SESSION SERVICE
// =============================================================================

interface GameSessionService {
    suspend fun startSession(childId: UUID, gameId: UUID, deviceInfo: DeviceInfo?): GameSession
    suspend fun updateSession(sessionId: UUID, metrics: SessionMetrics): GameSession
    suspend fun endSession(sessionId: UUID, finalMetrics: SessionMetrics): GameSession
    suspend fun getSessionHistory(childId: UUID, gameId: UUID, limit: Int = 50): List<GameSession>
    suspend fun recordEvent(sessionId: UUID, eventType: String, eventData: Map<String, String>): Boolean
}

class GameSessionServiceImpl(
    private val sessionRepo: GameSessionRepository,
    private val instanceRepo: ChildGameInstanceRepository,
    private val analyticsRepo: GameAnalyticsRepository
) : GameSessionService {
    
    override suspend fun startSession(
        childId: UUID,
        gameId: UUID,
        deviceInfo: DeviceInfo?
    ): GameSession {
        val instance = instanceRepo.findByChildAndGame(childId, gameId)
            ?: throw GameInstanceNotFoundException("Game instance not found")
        
        // End any active sessions
        sessionRepo.findActive(instance.id)?.let { activeSession ->
            endSession(activeSession.id, activeSession.sessionData)
        }
        
        // Create new session
        val session = GameSession(
            childGameInstanceId = instance.id,
            startedAt = Clock.System.now(),
            deviceType = deviceInfo?.deviceType,
            appVersion = deviceInfo?.appVersion,
            gameVersion = deviceInfo?.gameVersion,
            createdAt = Clock.System.now()
        )
        
        // Update instance last played
        instanceRepo.update(instance.copy(
            firstPlayedAt = instance.firstPlayedAt ?: Clock.System.now(),
            lastPlayedAt = Clock.System.now(),
            sessionCount = instance.sessionCount + 1
        ))
        
        return sessionRepo.create(session)
    }
    
    override suspend fun updateSession(sessionId: UUID, metrics: SessionMetrics): GameSession {
        val session = sessionRepo.findById(sessionId)
            ?: throw SessionNotFoundException("Session not found: $sessionId")
        
        val updated = session.copy(sessionData = metrics)
        return sessionRepo.update(updated)
    }
    
    override suspend fun endSession(sessionId: UUID, finalMetrics: SessionMetrics): GameSession {
        val session = sessionRepo.findById(sessionId)
            ?: throw SessionNotFoundException("Session not found: $sessionId")
        
        val duration = (Clock.System.now() - session.startedAt).inWholeMinutes.toInt()
        
        val ended = sessionRepo.end(sessionId, finalMetrics)
            ?: throw SessionNotFoundException("Failed to end session")
        
        // Update instance play time
        val instance = instanceRepo.findById(session.childGameInstanceId)
        instance?.let {
            instanceRepo.updateProgress(
                instanceId = it.id,
                completionPercentage = it.completionPercentage,
                playTimeMinutes = it.totalPlayTimeMinutes + duration
            )
        }
        
        // Record daily metrics
        recordDailyMetrics(session.childGameInstanceId, duration, finalMetrics)
        
        return ended
    }
    
    override suspend fun getSessionHistory(childId: UUID, gameId: UUID, limit: Int): List<GameSession> {
        val instance = instanceRepo.findByChildAndGame(childId, gameId)
            ?: return emptyList()
        
        return sessionRepo.findByInstance(instance.id, limit)
    }
    
    override suspend fun recordEvent(sessionId: UUID, eventType: String, eventData: Map<String, String>): Boolean {
        val event = GameEvent(
            type = eventType,
            timestamp = Clock.System.now(),
            data = eventData
        )
        return sessionRepo.addEvent(sessionId, event)
    }
    
    private suspend fun recordDailyMetrics(instanceId: UUID, duration: Int, metrics: SessionMetrics) {
        // Implementation for recording daily metrics
        // This would aggregate data for analytics
    }
}

// =============================================================================
// ACHIEVEMENT SERVICE
// =============================================================================

interface AchievementService {
    suspend fun checkAchievements(childId: UUID, gameId: UUID, gameData: Map<String, GameDataValue>): List<UnlockedAchievement>
    suspend fun getChildAchievements(childId: UUID, gameId: UUID?): List<ChildAchievement>
    suspend fun getAvailableAchievements(gameId: UUID): List<Achievement>
    suspend fun unlockAchievement(instanceId: UUID, achievementId: UUID, sessionId: UUID?): ChildAchievement
}

class AchievementServiceImpl(
    private val achievementRepo: AchievementRepository,
    private val instanceRepo: ChildGameInstanceRepository,
    private val currencyRepo: VirtualCurrencyRepository
) : AchievementService {
    
    override suspend fun checkAchievements(
        childId: UUID,
        gameId: UUID,
        gameData: Map<String, GameDataValue>
    ): List<UnlockedAchievement> {
        val instance = instanceRepo.findByChildAndGame(childId, gameId)
            ?: return emptyList()
        
        val achievements = achievementRepo.findByGame(gameId)
        val unlocked = achievementRepo.getUnlocked(instance.id)
        val unlockedIds = unlocked.map { it.achievementId }.toSet()
        
        val newlyUnlocked = mutableListOf<UnlockedAchievement>()
        
        for (achievement in achievements) {
            if (achievement.id in unlockedIds) continue
            
            if (checkCriteria(achievement.criteria, gameData)) {
                val childAchievement = achievementRepo.unlock(instance.id, achievement.id, null)
                
                // Award points as Wonder Coins
                if (achievement.points > 0) {
                    currencyRepo.addCurrency(
                        childId = childId,
                        amount = achievement.points,
                        source = "achievement:${achievement.id}",
                        description = "Achievement: ${achievement.name}"
                    )
                }
                
                newlyUnlocked.add(UnlockedAchievement(
                    achievement = achievement,
                    unlockedAt = childAchievement.unlockedAt,
                    rewardPoints = achievement.points
                ))
            }
        }
        
        return newlyUnlocked
    }
    
    override suspend fun getChildAchievements(childId: UUID, gameId: UUID?): List<ChildAchievement> {
        val instances = if (gameId != null) {
            listOfNotNull(instanceRepo.findByChildAndGame(childId, gameId))
        } else {
            instanceRepo.findByChild(childId)
        }
        
        return instances.flatMap { instance ->
            achievementRepo.getUnlocked(instance.id)
        }
    }
    
    override suspend fun getAvailableAchievements(gameId: UUID): List<Achievement> {
        return achievementRepo.findByGame(gameId)
    }
    
    override suspend fun unlockAchievement(
        instanceId: UUID,
        achievementId: UUID,
        sessionId: UUID?
    ): ChildAchievement {
        return achievementRepo.unlock(instanceId, achievementId, sessionId)
    }
    
    private fun checkCriteria(criteria: AchievementCriteria, gameData: Map<String, GameDataValue>): Boolean {
        // Implement criteria checking logic based on type
        return when (criteria.type) {
            "score_threshold" -> checkScoreThreshold(criteria, gameData)
            "items_collected" -> checkItemsCollected(criteria, gameData)
            "time_played" -> checkTimePlayed(criteria, gameData)
            else -> false
        }
    }
    
    private fun checkScoreThreshold(criteria: AchievementCriteria, gameData: Map<String, GameDataValue>): Boolean {
        val score = (gameData["score"] as? GameDataValue.IntValue)?.value ?: 0
        return score >= criteria.threshold
    }
    
    private fun checkItemsCollected(criteria: AchievementCriteria, gameData: Map<String, GameDataValue>): Boolean {
        val items = (gameData["items_collected"] as? GameDataValue.IntValue)?.value ?: 0
        return items >= criteria.threshold
    }
    
    private fun checkTimePlayed(criteria: AchievementCriteria, gameData: Map<String, GameDataValue>): Boolean {
        val minutes = (gameData["play_time_minutes"] as? GameDataValue.IntValue)?.value ?: 0
        return minutes >= criteria.threshold
    }
}

// =============================================================================
// SUPPORTING CLASSES
// =============================================================================

@Serializable
data class DeviceInfo(
    val deviceType: String,
    val appVersion: String,
    val gameVersion: String
)

@Serializable
data class UnlockedAchievement(
    val achievement: Achievement,
    @Contextual val unlockedAt: Instant,
    val rewardPoints: Int
)

// =============================================================================
// EXCEPTIONS
// =============================================================================

class GameNotFoundException(message: String) : Exception(message)
class GameInstanceNotFoundException(message: String) : Exception(message)
class SessionNotFoundException(message: String) : Exception(message)
class InsufficientCurrencyException(message: String) : Exception(message)