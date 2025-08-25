package com.wondernest.services.games

import com.wondernest.data.database.table.*
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.datetime.Clock
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.transactions.transaction
import java.util.UUID

/**
 * Service for managing child game instances
 * Handles creating, retrieving, and updating child-specific game instances
 */
class ChildGameInstanceService {
    
    /**
     * Get or create a child game instance for a specific game
     * If instance doesn't exist, creates one with default settings
     */
    fun getOrCreateInstance(childId: UUID, gameId: UUID): ChildGameInstanceInfo = transaction {
        // Check if instance already exists
        val existingInstance = ChildGameInstances
            .select { (ChildGameInstances.childId eq childId) and (ChildGameInstances.gameId eq gameId) }
            .singleOrNull()
        
        if (existingInstance != null) {
            // Return existing instance
            ChildGameInstanceInfo(
                id = existingInstance[ChildGameInstances.id].toString(),
                childId = existingInstance[ChildGameInstances.childId].toString(),
                gameId = existingInstance[ChildGameInstances.gameId].toString(),
                settings = Json.parseToJsonElement(Json.encodeToString(existingInstance[ChildGameInstances.settings])),
                preferences = Json.parseToJsonElement(Json.encodeToString(existingInstance[ChildGameInstances.preferences])),
                isUnlocked = existingInstance[ChildGameInstances.isUnlocked],
                totalPlayTimeMinutes = existingInstance[ChildGameInstances.totalPlayTimeMinutes],
                sessionCount = existingInstance[ChildGameInstances.sessionCount],
                lastPlayedAt = existingInstance[ChildGameInstances.lastPlayedAt]?.toString(),
                createdAt = existingInstance[ChildGameInstances.createdAt].toString(),
                updatedAt = existingInstance[ChildGameInstances.updatedAt].toString()
            )
        } else {
            // Create new instance with default settings
            val now = Clock.System.now()
            val newInstanceId = ChildGameInstances.insertAndGetId {
                it[ChildGameInstances.childId] = childId
                it[ChildGameInstances.gameId] = gameId
                it[ChildGameInstances.settings] = mapOf<String, String>()
                it[ChildGameInstances.preferences] = mapOf<String, String>()
                it[ChildGameInstances.isUnlocked] = true
                it[ChildGameInstances.totalPlayTimeMinutes] = 0
                it[ChildGameInstances.sessionCount] = 0
                it[ChildGameInstances.lastPlayedAt] = null
                it[ChildGameInstances.createdAt] = now
                it[ChildGameInstances.updatedAt] = now
            }
            
            ChildGameInstanceInfo(
                id = newInstanceId.value.toString(),
                childId = childId.toString(),
                gameId = gameId.toString(),
                settings = Json.parseToJsonElement("{}"),
                preferences = Json.parseToJsonElement("{}"),
                isUnlocked = true,
                totalPlayTimeMinutes = 0,
                sessionCount = 0,
                lastPlayedAt = null,
                createdAt = now.toString(),
                updatedAt = now.toString()
            )
        }
    }
    
    /**
     * Get child game instance by ID
     */
    fun getInstance(instanceId: UUID): ChildGameInstanceInfo? = transaction {
        ChildGameInstances.select { ChildGameInstances.id eq instanceId }
            .singleOrNull()?.let { row ->
                ChildGameInstanceInfo(
                    id = row[ChildGameInstances.id].toString(),
                    childId = row[ChildGameInstances.childId].toString(),
                    gameId = row[ChildGameInstances.gameId].toString(),
                    settings = Json.parseToJsonElement(Json.encodeToString(row[ChildGameInstances.settings])),
                    preferences = Json.parseToJsonElement(Json.encodeToString(row[ChildGameInstances.preferences])),
                    isUnlocked = row[ChildGameInstances.isUnlocked],
                    totalPlayTimeMinutes = row[ChildGameInstances.totalPlayTimeMinutes],
                    sessionCount = row[ChildGameInstances.sessionCount],
                    lastPlayedAt = row[ChildGameInstances.lastPlayedAt]?.toString(),
                    createdAt = row[ChildGameInstances.createdAt].toString(),
                    updatedAt = row[ChildGameInstances.updatedAt].toString()
                )
            }
    }
    
    /**
     * Get all game instances for a child
     */
    fun getInstancesForChild(childId: UUID): List<ChildGameInstanceInfo> = transaction {
        ChildGameInstances.select { ChildGameInstances.childId eq childId }
            .orderBy(ChildGameInstances.lastPlayedAt to SortOrder.DESC_NULLS_LAST)
            .map { row ->
                ChildGameInstanceInfo(
                    id = row[ChildGameInstances.id].toString(),
                    childId = row[ChildGameInstances.childId].toString(),
                    gameId = row[ChildGameInstances.gameId].toString(),
                    settings = Json.parseToJsonElement(Json.encodeToString(row[ChildGameInstances.settings])),
                    preferences = Json.parseToJsonElement(Json.encodeToString(row[ChildGameInstances.preferences])),
                    isUnlocked = row[ChildGameInstances.isUnlocked],
                    totalPlayTimeMinutes = row[ChildGameInstances.totalPlayTimeMinutes],
                    sessionCount = row[ChildGameInstances.sessionCount],
                    lastPlayedAt = row[ChildGameInstances.lastPlayedAt]?.toString(),
                    createdAt = row[ChildGameInstances.createdAt].toString(),
                    updatedAt = row[ChildGameInstances.updatedAt].toString()
                )
            }
    }
    
    /**
     * Update instance settings
     */
    fun updateInstanceSettings(instanceId: UUID, settings: Map<String, JsonElement>): Boolean = transaction {
        val settingsMap = settings.mapValues { (_, value) -> value.toString() }
        val updateCount = ChildGameInstances.update({ ChildGameInstances.id eq instanceId }) {
            it[ChildGameInstances.settings] = settingsMap
            it[ChildGameInstances.updatedAt] = Clock.System.now()
        }
        updateCount > 0
    }
    
    /**
     * Update instance preferences
     */
    fun updateInstancePreferences(instanceId: UUID, preferences: Map<String, JsonElement>): Boolean = transaction {
        val preferencesMap = preferences.mapValues { (_, value) -> value.toString() }
        val updateCount = ChildGameInstances.update({ ChildGameInstances.id eq instanceId }) {
            it[ChildGameInstances.preferences] = preferencesMap
            it[ChildGameInstances.updatedAt] = Clock.System.now()
        }
        updateCount > 0
    }
    
    /**
     * Update play time and last played timestamp
     */
    fun updatePlayTime(instanceId: UUID, additionalMinutes: Int): Boolean = transaction {
        val now = Clock.System.now()
        
        // Get current values first
        val currentRecord = ChildGameInstances.select { ChildGameInstances.id eq instanceId }.singleOrNull()
        
        if (currentRecord != null) {
            val currentPlayTime = currentRecord[ChildGameInstances.totalPlayTimeMinutes]
            val currentSessionCount = currentRecord[ChildGameInstances.sessionCount]
            
            val updateCount = ChildGameInstances.update({ ChildGameInstances.id eq instanceId }) {
                it[ChildGameInstances.totalPlayTimeMinutes] = currentPlayTime + additionalMinutes
                it[ChildGameInstances.sessionCount] = currentSessionCount + 1
                it[ChildGameInstances.lastPlayedAt] = now
                it[ChildGameInstances.updatedAt] = now
            }
            updateCount > 0
        } else {
            false
        }
    }
    
    /**
     * Check if a child has access to a specific game
     */
    fun hasGameAccess(childId: UUID, gameId: UUID): Boolean = transaction {
        ChildGameInstances.select { 
            (ChildGameInstances.childId eq childId) and 
            (ChildGameInstances.gameId eq gameId) and 
            (ChildGameInstances.isUnlocked eq true) 
        }.count() > 0
    }
    
    /**
     * Get instance by child ID and game key (convenience method)
     */
    fun getInstanceByChildAndGameKey(childId: UUID, gameKey: String): ChildGameInstanceInfo? = transaction {
        ChildGameInstances.join(GameRegistry, JoinType.INNER) { 
            ChildGameInstances.gameId eq GameRegistry.id 
        }.select {
            (ChildGameInstances.childId eq childId) and (GameRegistry.gameKey eq gameKey)
        }.singleOrNull()?.let { row ->
            ChildGameInstanceInfo(
                id = row[ChildGameInstances.id].toString(),
                childId = row[ChildGameInstances.childId].toString(),
                gameId = row[ChildGameInstances.gameId].toString(),
                settings = Json.parseToJsonElement(Json.encodeToString(row[ChildGameInstances.settings])),
                preferences = Json.parseToJsonElement(Json.encodeToString(row[ChildGameInstances.preferences])),
                isUnlocked = row[ChildGameInstances.isUnlocked],
                totalPlayTimeMinutes = row[ChildGameInstances.totalPlayTimeMinutes],
                sessionCount = row[ChildGameInstances.sessionCount],
                lastPlayedAt = row[ChildGameInstances.lastPlayedAt]?.toString(),
                createdAt = row[ChildGameInstances.createdAt].toString(),
                updatedAt = row[ChildGameInstances.updatedAt].toString()
            )
        }
    }
}

// Data model for ChildGameInstanceService responses
@Serializable
data class ChildGameInstanceInfo(
    val id: String,
    val childId: String,
    val gameId: String,
    val settings: JsonElement,
    val preferences: JsonElement,
    val isUnlocked: Boolean,
    val totalPlayTimeMinutes: Int,
    val sessionCount: Int,
    val lastPlayedAt: String?,
    val createdAt: String,
    val updatedAt: String
)

// Request models for updating instances
@Serializable
data class UpdateInstanceSettingsRequest(
    val settings: Map<String, JsonElement>
)

@Serializable  
data class UpdateInstancePreferencesRequest(
    val preferences: Map<String, JsonElement>
)

@Serializable
data class UpdatePlayTimeRequest(
    val additionalMinutes: Int
)