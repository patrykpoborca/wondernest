package com.wondernest.api.games

import com.wondernest.services.games.*
import com.wondernest.services.games.SaveGameDataRequest as ServiceSaveGameDataRequest
import com.wondernest.services.games.UpdateGameDataRequest as ServiceUpdateGameDataRequest
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.auth.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import java.util.UUID

/**
 * Enhanced game routes following proper GameRegistry architecture
 * Replaces SimpleGameData approach with proper GameRegistry → ChildGameInstances → ChildGameData flow
 */
fun Route.enhancedGameRoutes() {
    val gameRegistryService = GameRegistryService()
    val childGameInstanceService = ChildGameInstanceService()
    val gameDataService = GameDataService()
    
    route("/games") {
        authenticate("auth-jwt") {
            
            // =============================================================================
            // GAME REGISTRY ENDPOINTS
            // =============================================================================
            
            // Get all active games
            get {
                try {
                    val games = gameRegistryService.getAllActiveGames()
                    call.respond(GamesListResponse(success = true, games = games))
                } catch (e: Exception) {
                    call.respond(HttpStatusCode.InternalServerError, "Failed to get games: ${e.message}")
                }
            }
            
            // Get game by key
            get("/{gameKey}") {
                val gameKey = call.parameters["gameKey"] ?: return@get call.respond(HttpStatusCode.BadRequest, "Game key required")
                
                try {
                    val game = gameRegistryService.getGameByKey(gameKey)
                    if (game != null) {
                        call.respond(game)
                    } else {
                        call.respond(HttpStatusCode.NotFound, "Game not found")
                    }
                } catch (e: Exception) {
                    call.respond(HttpStatusCode.InternalServerError, "Failed to get game: ${e.message}")
                }
            }
            
            // Get game types
            get("/types") {
                try {
                    val gameTypes = gameRegistryService.getAllGameTypes()
                    call.respond(GameTypesResponse(success = true, gameTypes = gameTypes))
                } catch (e: Exception) {
                    call.respond(HttpStatusCode.InternalServerError, "Failed to get game types: ${e.message}")
                }
            }
            
            // Get game categories  
            get("/categories") {
                try {
                    val categories = gameRegistryService.getAllGameCategories()
                    call.respond(GameCategoriesResponse(success = true, categories = categories))
                } catch (e: Exception) {
                    call.respond(HttpStatusCode.InternalServerError, "Failed to get categories: ${e.message}")
                }
            }
            
            // =============================================================================
            // CHILD GAME INSTANCE ENDPOINTS
            // =============================================================================
            
            // Get or create child game instance
            post("/children/{childId}/instances/{gameKey}") {
                val childId = call.parameters["childId"]?.let { 
                    try { UUID.fromString(it) } 
                    catch (e: IllegalArgumentException) { null }
                } ?: return@post call.respond(HttpStatusCode.BadRequest, "Invalid child ID format")
                
                val gameKey = call.parameters["gameKey"] ?: return@post call.respond(HttpStatusCode.BadRequest, "Game key required")
                
                try {
                    // Get game from registry
                    val game = gameRegistryService.getGameByKey(gameKey)
                        ?: return@post call.respond(HttpStatusCode.NotFound, "Game '$gameKey' not found")
                    
                    // Get or create instance
                    val instance = childGameInstanceService.getOrCreateInstance(childId, UUID.fromString(game.id))
                    
                    call.respond(CreateInstanceResponse(
                        success = true,
                        message = "Game instance ready",
                        instance = instance
                    ))
                    
                } catch (e: Exception) {
                    call.respond(HttpStatusCode.InternalServerError, "Failed to create instance: ${e.message}")
                }
            }
            
            // Get child's game instances
            get("/children/{childId}/instances") {
                val childId = call.parameters["childId"]?.let { 
                    try { UUID.fromString(it) } 
                    catch (e: IllegalArgumentException) { null }
                } ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid child ID format")
                
                try {
                    val instances = childGameInstanceService.getInstancesForChild(childId)
                    call.respond(InstancesListResponse(success = true, instances = instances))
                } catch (e: Exception) {
                    call.respond(HttpStatusCode.InternalServerError, "Failed to get instances: ${e.message}")
                }
            }
            
            // Update instance settings
            put("/children/{childId}/instances/{gameKey}/settings") {
                val childId = call.parameters["childId"]?.let { 
                    try { UUID.fromString(it) } 
                    catch (e: IllegalArgumentException) { null }
                } ?: return@put call.respond(HttpStatusCode.BadRequest, "Invalid child ID format")
                
                val gameKey = call.parameters["gameKey"] ?: return@put call.respond(HttpStatusCode.BadRequest, "Game key required")
                
                val request = try {
                    call.receive<UpdateInstanceSettingsRequest>()
                } catch (e: Exception) {
                    return@put call.respond(HttpStatusCode.BadRequest, "Invalid request body: ${e.message}")
                }
                
                try {
                    val instance = childGameInstanceService.getInstanceByChildAndGameKey(childId, gameKey)
                        ?: return@put call.respond(HttpStatusCode.NotFound, "Game instance not found")
                    
                    val success = childGameInstanceService.updateInstanceSettings(
                        UUID.fromString(instance.id), 
                        request.settings
                    )
                    
                    if (success) {
                        call.respond(OperationResponse(true, "Settings updated successfully"))
                    } else {
                        call.respond(HttpStatusCode.InternalServerError, "Failed to update settings")
                    }
                } catch (e: Exception) {
                    call.respond(HttpStatusCode.InternalServerError, "Failed to update settings: ${e.message}")
                }
            }
            
            // =============================================================================
            // GAME DATA ENDPOINTS (NEW PROPER ARCHITECTURE)
            // =============================================================================
            
            // Save or update game data
            put("/children/{childId}/data") {
                val childId = call.parameters["childId"]?.let { 
                    try { UUID.fromString(it) } 
                    catch (e: IllegalArgumentException) { null }
                } ?: return@put call.respond(HttpStatusCode.BadRequest, "Invalid child ID format")
                
                val request = try {
                    call.receive<ServiceSaveGameDataRequest>()
                } catch (e: Exception) {
                    return@put call.respond(HttpStatusCode.BadRequest, "Invalid request body: ${e.message}")
                }
                
                try {
                    // Use saveGameData which creates instance if needed, then updates
                    val result = gameDataService.saveGameData(
                        childId = childId,
                        gameKey = request.gameKey,
                        dataKey = request.dataKey,
                        dataValue = request.dataValue
                    )
                    
                    if (result.success) {
                        call.respond(HttpStatusCode.OK, EnhancedGameDataResponse(
                            success = true,
                            message = result.message,
                            childId = childId.toString(),
                            gameKey = request.gameKey,
                            dataKey = request.dataKey,
                            data = result.data
                        ))
                    } else {
                        call.respond(HttpStatusCode.BadRequest, result.message)
                    }
                    
                } catch (e: Exception) {
                    call.respond(HttpStatusCode.InternalServerError, "Failed to save game data: ${e.message}")
                }
            }
            
            // Get game data for child
            get("/children/{childId}/data") {
                val childId = call.parameters["childId"]?.let { 
                    try { UUID.fromString(it) } 
                    catch (e: IllegalArgumentException) { null }
                } ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid child ID format")
                
                val gameKey = call.request.queryParameters["gameKey"]
                val dataKey = call.request.queryParameters["dataKey"]
                
                if (gameKey == null) {
                    return@get call.respond(HttpStatusCode.BadRequest, "gameKey parameter required")
                }
                
                try {
                    val gameDataList = gameDataService.getGameData(childId, gameKey, dataKey)
                    call.respond(EnhancedLoadGameDataResponse(success = true, gameData = gameDataList))
                    
                } catch (e: Exception) {
                    call.respond(HttpStatusCode.InternalServerError, "Failed to load game data: ${e.message}")
                }
            }
            
            // Get specific game data item
            get("/children/{childId}/data/{gameKey}/{dataKey}") {
                val childId = call.parameters["childId"]?.let { 
                    try { UUID.fromString(it) } 
                    catch (e: IllegalArgumentException) { null }
                } ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid child ID format")
                
                val gameKey = call.parameters["gameKey"] ?: return@get call.respond(HttpStatusCode.BadRequest, "Game key required")
                val dataKey = call.parameters["dataKey"] ?: return@get call.respond(HttpStatusCode.BadRequest, "Data key required")
                
                try {
                    val gameDataList = gameDataService.getGameData(childId, gameKey, dataKey)
                    
                    if (gameDataList.isNotEmpty()) {
                        call.respond(gameDataList.first())
                    } else {
                        call.respond(HttpStatusCode.NotFound, "Game data not found")
                    }
                    
                } catch (e: Exception) {
                    call.respond(HttpStatusCode.InternalServerError, "Failed to load game data: ${e.message}")
                }
            }
            
            // Delete specific game data
            delete("/children/{childId}/data/{gameKey}/{dataKey}") {
                val childId = call.parameters["childId"]?.let { 
                    try { UUID.fromString(it) } 
                    catch (e: IllegalArgumentException) { null }
                } ?: return@delete call.respond(HttpStatusCode.BadRequest, "Invalid child ID format")
                
                val gameKey = call.parameters["gameKey"] ?: return@delete call.respond(HttpStatusCode.BadRequest, "Game key required")
                val dataKey = call.parameters["dataKey"] ?: return@delete call.respond(HttpStatusCode.BadRequest, "Data key required")
                
                try {
                    val result = gameDataService.deleteGameData(childId, gameKey, dataKey)
                    
                    if (result.success) {
                        call.respond(EnhancedGameDataResponse(
                            success = true,
                            message = result.message,
                            childId = childId.toString(),
                            gameKey = gameKey,
                            dataKey = dataKey,
                            data = null
                        ))
                    } else {
                        call.respond(HttpStatusCode.NotFound, result.message)
                    }
                    
                } catch (e: Exception) {
                    call.respond(HttpStatusCode.InternalServerError, "Failed to delete game data: ${e.message}")
                }
            }
            
            // Delete all game data for a child and game
            delete("/children/{childId}/data/{gameKey}") {
                val childId = call.parameters["childId"]?.let { 
                    try { UUID.fromString(it) } 
                    catch (e: IllegalArgumentException) { null }
                } ?: return@delete call.respond(HttpStatusCode.BadRequest, "Invalid child ID format")
                
                val gameKey = call.parameters["gameKey"] ?: return@delete call.respond(HttpStatusCode.BadRequest, "Game key required")
                
                try {
                    val result = gameDataService.deleteAllGameData(childId, gameKey)
                    
                    call.respond(EnhancedGameDataResponse(
                        success = true,
                        message = result.message,
                        childId = childId.toString(),
                        gameKey = gameKey,
                        dataKey = null,
                        data = null
                    ))
                    
                } catch (e: Exception) {
                    call.respond(HttpStatusCode.InternalServerError, "Failed to delete game data: ${e.message}")
                }
            }
            
            // Get child's active games
            get("/children/{childId}/active") {
                val childId = call.parameters["childId"]?.let { 
                    try { UUID.fromString(it) } 
                    catch (e: IllegalArgumentException) { null }
                } ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid child ID format")
                
                try {
                    val activeGames = gameDataService.getChildActiveGames(childId)
                    call.respond(ActiveGamesResponse(success = true, activeGames = activeGames))
                } catch (e: Exception) {
                    call.respond(HttpStatusCode.InternalServerError, "Failed to get active games: ${e.message}")
                }
            }
        }
    }
}

// =============================================================================
// RESPONSE MODELS FOR ENHANCED GAME ROUTES
// =============================================================================

@Serializable
data class GamesListResponse(
    val success: Boolean,
    val games: List<GameInfo>
)

@Serializable
data class GameTypesResponse(
    val success: Boolean,
    val gameTypes: List<GameTypeInfo>
)

@Serializable
data class GameCategoriesResponse(
    val success: Boolean,
    val categories: List<GameCategoryInfo>
)

@Serializable
data class CreateInstanceResponse(
    val success: Boolean,
    val message: String,
    val instance: ChildGameInstanceInfo
)

@Serializable
data class InstancesListResponse(
    val success: Boolean,
    val instances: List<ChildGameInstanceInfo>
)

@Serializable
data class OperationResponse(
    val success: Boolean,
    val message: String
)

@Serializable
data class EnhancedGameDataResponse(
    val success: Boolean,
    val message: String,
    val childId: String,
    val gameKey: String,
    val dataKey: String?,
    val data: GameDataInfo?
)

@Serializable
data class EnhancedLoadGameDataResponse(
    val success: Boolean,
    val gameData: List<GameDataInfo>
)

@Serializable
data class ActiveGamesResponse(
    val success: Boolean,
    val activeGames: List<ChildActiveGameInfo>
)