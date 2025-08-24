package com.wondernest.api.games

import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.auth.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.serialization.Serializable
import kotlinx.serialization.Contextual
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.jsonObject
import kotlinx.datetime.Clock
import java.util.UUID
import com.wondernest.data.database.table.*
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.statements.api.ExposedBlob
import org.jetbrains.exposed.sql.transactions.transaction
import org.jetbrains.exposed.sql.upsert

/**
 * Simple game data persistence routes using the SimpleGameData table
 * Perfect for games like sticker books that need to save project data
 */
fun Route.gameDataRoutes() {
    route("/games") {
        authenticate("auth-jwt") {
            
            // =============================================================================
            // SAVE GAME DATA
            // =============================================================================
            
            // Save or update game data for a child
            put("/children/{childId}/data") {
                val childId = call.parameters["childId"]?.let { 
                    try { UUID.fromString(it) } 
                    catch (e: IllegalArgumentException) { null }
                } ?: return@put call.respond(HttpStatusCode.BadRequest, "Invalid child ID format")
                
                val request = try {
                    call.receive<SaveGameDataRequest>()
                } catch (e: Exception) {
                    return@put call.respond(HttpStatusCode.BadRequest, "Invalid request body: ${e.message}")
                }
                
                try {
                    // Validate child exists
                    val childExists = transaction {
                        ChildProfiles.select { ChildProfiles.id eq childId }.count() > 0
                    }
                    
                    if (!childExists) {
                        return@put call.respond(HttpStatusCode.NotFound, "Child not found")
                    }
                    
                    val now = Clock.System.now()
                    
                    // Insert or update game data using SimpleGameData for now
                    val result = transaction {
                        SimpleGameData.upsert(
                            keys = arrayOf(SimpleGameData.childId, SimpleGameData.gameType, SimpleGameData.dataKey)
                        ) {
                            it[SimpleGameData.childId] = childId
                            it[SimpleGameData.gameType] = request.gameType
                            it[SimpleGameData.dataKey] = request.dataKey
                            it[SimpleGameData.dataValue] = request.dataValue
                            it[SimpleGameData.updatedAt] = now
                            it[SimpleGameData.createdAt] = now // Will be ignored for updates due to ON CONFLICT
                        }
                    }
                    
                    call.respond(HttpStatusCode.OK, GameDataResponse(
                        success = true,
                        message = "Game data saved successfully",
                        childId = childId.toString(),
                        gameType = request.gameType,
                        dataKey = request.dataKey
                    ))
                    
                } catch (e: Exception) {
                    call.respond(HttpStatusCode.InternalServerError, "Failed to save game data: ${e.message}")
                }
            }
            
            // =============================================================================
            // LOAD GAME DATA
            // =============================================================================
            
            // Get all game data for a child
            get("/children/{childId}/data") {
                val childId = call.parameters["childId"]?.let { 
                    try { UUID.fromString(it) } 
                    catch (e: IllegalArgumentException) { null }
                } ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid child ID format")
                
                val gameType = call.request.queryParameters["gameType"]
                val dataKey = call.request.queryParameters["dataKey"]
                
                try {
                    val gameDataList = transaction {
                        var query = SimpleGameData.select { SimpleGameData.childId eq childId }
                        
                        // Apply optional filters
                        if (!gameType.isNullOrBlank()) {
                            query = query.andWhere { SimpleGameData.gameType eq gameType }
                        }
                        if (!dataKey.isNullOrBlank()) {
                            query = query.andWhere { SimpleGameData.dataKey eq dataKey }
                        }
                        
                        query.orderBy(SimpleGameData.updatedAt, SortOrder.DESC)
                            .map { row ->
                                GameDataItem(
                                    id = row[SimpleGameData.id].toString(),
                                    childId = row[SimpleGameData.childId].toString(),
                                    gameType = row[SimpleGameData.gameType],
                                    dataKey = row[SimpleGameData.dataKey],
                                    dataValue = row[SimpleGameData.dataValue],
                                    createdAt = row[SimpleGameData.createdAt].toString(),
                                    updatedAt = row[SimpleGameData.updatedAt].toString()
                                )
                            }
                    }
                    
                    call.respond(LoadGameDataResponse(
                        success = true,
                        gameData = gameDataList
                    ))
                    
                } catch (e: Exception) {
                    call.respond(HttpStatusCode.InternalServerError, "Failed to load game data: ${e.message}")
                }
            }
            
            // Get specific game data item
            get("/children/{childId}/data/{gameType}/{dataKey}") {
                val childId = call.parameters["childId"]?.let { 
                    try { UUID.fromString(it) } 
                    catch (e: IllegalArgumentException) { null }
                } ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid child ID format")
                
                val gameType = call.parameters["gameType"] ?: return@get call.respond(HttpStatusCode.BadRequest, "Game type required")
                val dataKey = call.parameters["dataKey"] ?: return@get call.respond(HttpStatusCode.BadRequest, "Data key required")
                
                try {
                    val gameData = transaction {
                        SimpleGameData.select { 
                            (SimpleGameData.childId eq childId) and 
                            (SimpleGameData.gameType eq gameType) and 
                            (SimpleGameData.dataKey eq dataKey)
                        }.singleOrNull()?.let { row ->
                            GameDataItem(
                                id = row[SimpleGameData.id].toString(),
                                childId = row[SimpleGameData.childId].toString(),
                                gameType = row[SimpleGameData.gameType],
                                dataKey = row[SimpleGameData.dataKey],
                                dataValue = row[SimpleGameData.dataValue],
                                createdAt = row[SimpleGameData.createdAt].toString(),
                                updatedAt = row[SimpleGameData.updatedAt].toString()
                            )
                        }
                    }
                    
                    if (gameData != null) {
                        call.respond(gameData)
                    } else {
                        call.respond(HttpStatusCode.NotFound, "Game data not found")
                    }
                    
                } catch (e: Exception) {
                    call.respond(HttpStatusCode.InternalServerError, "Failed to load game data: ${e.message}")
                }
            }
            
            // =============================================================================
            // DELETE GAME DATA
            // =============================================================================
            
            // Delete specific game data
            delete("/children/{childId}/data/{gameType}/{dataKey}") {
                val childId = call.parameters["childId"]?.let { 
                    try { UUID.fromString(it) } 
                    catch (e: IllegalArgumentException) { null }
                } ?: return@delete call.respond(HttpStatusCode.BadRequest, "Invalid child ID format")
                
                val gameType = call.parameters["gameType"] ?: return@delete call.respond(HttpStatusCode.BadRequest, "Game type required")
                val dataKey = call.parameters["dataKey"] ?: return@delete call.respond(HttpStatusCode.BadRequest, "Data key required")
                
                try {
                    val deletedCount = transaction {
                        SimpleGameData.deleteWhere { 
                            (SimpleGameData.childId eq childId) and 
                            (SimpleGameData.gameType eq gameType) and 
                            (SimpleGameData.dataKey eq dataKey)
                        }
                    }
                    
                    if (deletedCount > 0) {
                        call.respond(GameDataResponse(
                            success = true,
                            message = "Game data deleted successfully",
                            childId = childId.toString(),
                            gameType = gameType,
                            dataKey = dataKey
                        ))
                    } else {
                        call.respond(HttpStatusCode.NotFound, "Game data not found")
                    }
                    
                } catch (e: Exception) {
                    call.respond(HttpStatusCode.InternalServerError, "Failed to delete game data: ${e.message}")
                }
            }
            
            // Delete all game data for a child and game type
            delete("/children/{childId}/data/{gameType}") {
                val childId = call.parameters["childId"]?.let { 
                    try { UUID.fromString(it) } 
                    catch (e: IllegalArgumentException) { null }
                } ?: return@delete call.respond(HttpStatusCode.BadRequest, "Invalid child ID format")
                
                val gameType = call.parameters["gameType"] ?: return@delete call.respond(HttpStatusCode.BadRequest, "Game type required")
                
                try {
                    val deletedCount = transaction {
                        SimpleGameData.deleteWhere { 
                            (SimpleGameData.childId eq childId) and 
                            (SimpleGameData.gameType eq gameType)
                        }
                    }
                    
                    call.respond(GameDataResponse(
                        success = true,
                        message = "Deleted $deletedCount game data items",
                        childId = childId.toString(),
                        gameType = gameType,
                        dataKey = null
                    ))
                    
                } catch (e: Exception) {
                    call.respond(HttpStatusCode.InternalServerError, "Failed to delete game data: ${e.message}")
                }
            }
        }
    }
}

// =============================================================================
// REQUEST/RESPONSE MODELS
// =============================================================================

@Serializable
data class SaveGameDataRequest(
    val gameType: String,
    val dataKey: String,
    @Contextual val dataValue: Map<String, JsonElement>
)

@Serializable
data class GameDataResponse(
    val success: Boolean,
    val message: String,
    val childId: String,
    val gameType: String,
    val dataKey: String?
)

@Serializable
data class GameDataItem(
    val id: String,
    val childId: String,
    val gameType: String,
    val dataKey: String,
    @Contextual val dataValue: Map<String, JsonElement>,
    val createdAt: String,
    val updatedAt: String
)

@Serializable
data class LoadGameDataResponse(
    val success: Boolean,
    val gameData: List<GameDataItem>
)