package com.wondernest.services.games

import com.wondernest.data.database.table.*
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.datetime.Clock
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.SqlExpressionBuilder.inList
import org.jetbrains.exposed.sql.transactions.transaction
import java.util.UUID

/**
 * Service for managing game data operations
 * Handles all game data CRUD operations following proper GameRegistry architecture
 */
class GameDataService {
    
    private val childGameInstanceService = ChildGameInstanceService()
    private val gameRegistryService = GameRegistryService()
    
    /**
     * Save or update game data for a child
     * Automatically creates game instance if it doesn't exist
     */
    fun saveGameData(
        childId: UUID,
        gameKey: String,
        dataKey: String,
        dataValue: Map<String, JsonElement>
    ): GameDataOperationResult = transaction {
        
        // Get the game from registry
        val game = gameRegistryService.getGameByKey(gameKey)
            ?: return@transaction GameDataOperationResult.failure("Game '$gameKey' not found in registry")
        
        // Get or create child game instance
        val instance = childGameInstanceService.getOrCreateInstance(childId, UUID.fromString(game.id))
        val instanceId = UUID.fromString(instance.id)
        
        // Save the data
        val now = Clock.System.now()
        val dataId = ChildGameData.insertAndGetId {
            it[ChildGameData.childGameInstanceId] = instanceId
            it[ChildGameData.dataKey] = dataKey
            it[ChildGameData.dataVersion] = 1
            it[ChildGameData.dataValue] = dataValue.mapValues { (_, value) -> value.toString() }
            it[ChildGameData.createdAt] = now
            it[ChildGameData.updatedAt] = now
        }
        
        // Update instance last played time
        childGameInstanceService.updatePlayTime(instanceId, 0) // Just update timestamp
        
        GameDataOperationResult.success(
            "Game data saved successfully",
            GameDataInfo(
                id = dataId.value.toString(),
                instanceId = instance.id,
                childId = childId.toString(),
                gameKey = gameKey,
                dataKey = dataKey,
                dataValue = dataValue,
                dataVersion = 1,
                createdAt = now.toString(),
                updatedAt = now.toString()
            )
        )
    }
    
    /**
     * Update existing game data
     */
    fun updateGameData(
        childId: UUID,
        gameKey: String,
        dataKey: String,
        dataValue: Map<String, JsonElement>
    ): GameDataOperationResult = transaction {
        
        // Get the game and instance
        val game = gameRegistryService.getGameByKey(gameKey)
            ?: return@transaction GameDataOperationResult.failure("Game '$gameKey' not found in registry")
        
        val instance = childGameInstanceService.getInstanceByChildAndGameKey(childId, gameKey)
            ?: return@transaction GameDataOperationResult.failure("Child does not have access to game '$gameKey'")
        
        // Find existing data entry
        val existingData = ChildGameData.join(ChildGameInstances, JoinType.INNER) {
            ChildGameData.childGameInstanceId eq ChildGameInstances.id
        }.select {
            (ChildGameInstances.childId eq childId) and
            (ChildGameData.dataKey eq dataKey)
        }.singleOrNull()
        
        if (existingData != null) {
            // Update existing data
            val now = Clock.System.now()
            val currentVersion = existingData[ChildGameData.dataVersion]
            
            ChildGameData.update({ ChildGameData.id eq existingData[ChildGameData.id] }) {
                it[ChildGameData.dataValue] = dataValue.mapValues { (_, value) -> value.toString() }
                it[ChildGameData.dataVersion] = currentVersion + 1
                it[ChildGameData.updatedAt] = now
            }
            
            // Update instance timestamp
            childGameInstanceService.updatePlayTime(UUID.fromString(instance.id), 0)
            
            GameDataOperationResult.success(
                "Game data updated successfully",
                GameDataInfo(
                    id = existingData[ChildGameData.id].toString(),
                    instanceId = instance.id,
                    childId = childId.toString(),
                    gameKey = gameKey,
                    dataKey = dataKey,
                    dataValue = dataValue,
                    dataVersion = currentVersion + 1,
                    createdAt = existingData[ChildGameData.createdAt].toString(),
                    updatedAt = now.toString()
                )
            )
        } else {
            // Create new data entry
            return@transaction saveGameData(childId, gameKey, dataKey, dataValue)
        }
    }
    
    /**
     * Get game data for a child and game
     */
    fun getGameData(childId: UUID, gameKey: String, dataKey: String? = null): List<GameDataInfo> = transaction {
        val query = ChildGameData.join(ChildGameInstances, JoinType.INNER) {
            ChildGameData.childGameInstanceId eq ChildGameInstances.id
        }.join(GameRegistry, JoinType.INNER) {
            ChildGameInstances.gameId eq GameRegistry.id
        }.select {
            (ChildGameInstances.childId eq childId) and (GameRegistry.gameKey eq gameKey)
        }
        
        val filteredQuery = if (dataKey != null) {
            query.andWhere { ChildGameData.dataKey eq dataKey }
        } else {
            query
        }
        
        filteredQuery.orderBy(ChildGameData.updatedAt to SortOrder.DESC)
            .map { row ->
                @Suppress("UNCHECKED_CAST")
                val dataValueMap = (row[ChildGameData.dataValue] as Map<String, Any>).mapValues { (_, value) ->
                    Json.parseToJsonElement(value.toString())
                }
                
                GameDataInfo(
                    id = row[ChildGameData.id].toString(),
                    instanceId = row[ChildGameData.childGameInstanceId].toString(),
                    childId = childId.toString(),
                    gameKey = gameKey,
                    dataKey = row[ChildGameData.dataKey],
                    dataValue = dataValueMap,
                    dataVersion = row[ChildGameData.dataVersion],
                    createdAt = row[ChildGameData.createdAt].toString(),
                    updatedAt = row[ChildGameData.updatedAt].toString()
                )
            }
    }
    
    /**
     * Delete specific game data
     */
    fun deleteGameData(childId: UUID, gameKey: String, dataKey: String): GameDataOperationResult = transaction {
        // First find the game data IDs to delete
        val dataIds = ChildGameData.join(ChildGameInstances, JoinType.INNER) {
            ChildGameData.childGameInstanceId eq ChildGameInstances.id
        }.join(GameRegistry, JoinType.INNER) {
            ChildGameInstances.gameId eq GameRegistry.id
        }.slice(ChildGameData.id).select {
            (ChildGameInstances.childId eq childId) and
            (GameRegistry.gameKey eq gameKey) and
            (ChildGameData.dataKey eq dataKey)
        }.map { it[ChildGameData.id] }
        
        val deletedCount = if (dataIds.isNotEmpty()) {
            ChildGameData.deleteWhere { ChildGameData.id.inList(dataIds) }
        } else {
            0
        }
        
        if (deletedCount > 0) {
            GameDataOperationResult.success("Game data deleted successfully", null)
        } else {
            GameDataOperationResult.failure("Game data not found")
        }
    }
    
    /**
     * Delete all game data for a child and game
     */
    fun deleteAllGameData(childId: UUID, gameKey: String): GameDataOperationResult = transaction {
        // First find the game data IDs to delete
        val dataIds = ChildGameData.join(ChildGameInstances, JoinType.INNER) {
            ChildGameData.childGameInstanceId eq ChildGameInstances.id
        }.join(GameRegistry, JoinType.INNER) {
            ChildGameInstances.gameId eq GameRegistry.id
        }.slice(ChildGameData.id).select {
            (ChildGameInstances.childId eq childId) and (GameRegistry.gameKey eq gameKey)
        }.map { it[ChildGameData.id] }
        
        val deletedCount = if (dataIds.isNotEmpty()) {
            ChildGameData.deleteWhere { ChildGameData.id.inList(dataIds) }
        } else {
            0
        }
        
        GameDataOperationResult.success("Deleted $deletedCount game data items", null)
    }
    
    /**
     * Get all games a child has data for
     */
    fun getChildActiveGames(childId: UUID): List<ChildActiveGameInfo> = transaction {
        ChildGameData.join(ChildGameInstances, JoinType.INNER) {
            ChildGameData.childGameInstanceId eq ChildGameInstances.id
        }.join(GameRegistry, JoinType.INNER) {
            ChildGameInstances.gameId eq GameRegistry.id
        }.slice(
            GameRegistry.gameKey,
            GameRegistry.displayName,
            ChildGameInstances.totalPlayTimeMinutes,
            ChildGameInstances.lastPlayedAt,
            ChildGameData.updatedAt.max()
        ).select {
            ChildGameInstances.childId eq childId
        }.groupBy(
            GameRegistry.gameKey,
            GameRegistry.displayName,
            ChildGameInstances.totalPlayTimeMinutes,
            ChildGameInstances.lastPlayedAt
        ).orderBy(ChildGameData.updatedAt.max() to SortOrder.DESC)
            .map { row ->
                ChildActiveGameInfo(
                    gameKey = row[GameRegistry.gameKey],
                    displayName = row[GameRegistry.displayName],
                    totalPlayTimeMinutes = row[ChildGameInstances.totalPlayTimeMinutes],
                    lastPlayedAt = row[ChildGameInstances.lastPlayedAt]?.toString(),
                    lastDataUpdate = row[ChildGameData.updatedAt.max()]?.toString()
                )
            }
    }
}

// Data models for GameDataService
@Serializable
data class GameDataInfo(
    val id: String,
    val instanceId: String,
    val childId: String,
    val gameKey: String,
    val dataKey: String,
    val dataValue: Map<String, JsonElement>,
    val dataVersion: Int,
    val createdAt: String,
    val updatedAt: String
)

@Serializable
data class ChildActiveGameInfo(
    val gameKey: String,
    val displayName: String,
    val totalPlayTimeMinutes: Int,
    val lastPlayedAt: String?,
    val lastDataUpdate: String?
)

@Serializable
data class GameDataOperationResult(
    val success: Boolean,
    val message: String,
    val data: GameDataInfo?
) {
    companion object {
        fun success(message: String, data: GameDataInfo?): GameDataOperationResult {
            return GameDataOperationResult(true, message, data)
        }
        
        fun failure(message: String): GameDataOperationResult {
            return GameDataOperationResult(false, message, null)
        }
    }
}

// Request models
@Serializable
data class SaveGameDataRequest(
    val gameKey: String,
    val dataKey: String,
    val dataValue: Map<String, JsonElement>
)

@Serializable
data class UpdateGameDataRequest(
    val gameKey: String,
    val dataKey: String,
    val dataValue: Map<String, JsonElement>
)