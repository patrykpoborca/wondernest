package com.wondernest.api.games

import com.wondernest.domain.model.games.*
import com.wondernest.services.games.*
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.auth.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.datetime.Instant
import kotlinx.serialization.Contextual
import kotlinx.serialization.Serializable
import org.koin.ktor.ext.inject
import java.util.UUID

fun Route.gameRoutes() {
    val gameService by inject<GameService>()
    val sessionService by inject<GameSessionService>()
    val achievementService by inject<AchievementService>()
    
    route("/api/v1/games") {
        authenticate("auth-jwt") {
            // =============================================================================
            // GAME DISCOVERY
            // =============================================================================
            
            // Get available games for a child
            get("/children/{childId}/available") {
                val childId = call.parameters["childId"]?.let { UUID.fromString(it) }
                    ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                
                val ageMonths = call.request.queryParameters["age"]?.toIntOrNull() ?: 60
                
                val games = gameService.getAvailableGames(childId, ageMonths)
                call.respond(GameListResponse(games = games))
            }
            
            // =============================================================================
            // GAME INSTANCES
            // =============================================================================
            
            // Get child's game instances
            get("/children/{childId}/instances") {
                val childId = call.parameters["childId"]?.let { UUID.fromString(it) }
                    ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                
                val instances = gameService.getChildGameInstances(childId)
                call.respond(InstanceListResponse(instances = instances))
            }
            
            // Get specific game instance
            get("/children/{childId}/instances/{gameId}") {
                val childId = call.parameters["childId"]?.let { UUID.fromString(it) }
                    ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                val gameId = call.parameters["gameId"]?.let { UUID.fromString(it) }
                    ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid game ID")
                
                val instance = gameService.getGameInstance(childId, gameId)
                if (instance != null) {
                    call.respond(instance)
                } else {
                    call.respond(HttpStatusCode.NotFound, "Game instance not found")
                }
            }
            
            // Create or unlock game instance
            post("/children/{childId}/instances/{gameId}") {
                val childId = call.parameters["childId"]?.let { UUID.fromString(it) }
                    ?: return@post call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                val gameId = call.parameters["gameId"]?.let { UUID.fromString(it) }
                    ?: return@post call.respond(HttpStatusCode.BadRequest, "Invalid game ID")
                
                val request = call.receiveNullable<CreateInstanceRequest>()
                
                val instance = gameService.createGameInstance(
                    childId = childId,
                    gameId = gameId,
                    initialSettings = request?.settings
                )
                
                call.respond(HttpStatusCode.Created, instance)
            }
            
            // Update game settings
            patch("/children/{childId}/instances/{gameId}/settings") {
                val childId = call.parameters["childId"]?.let { UUID.fromString(it) }
                    ?: return@patch call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                val gameId = call.parameters["gameId"]?.let { UUID.fromString(it) }
                    ?: return@patch call.respond(HttpStatusCode.BadRequest, "Invalid game ID")
                
                val settings = call.receive<GameSettings>()
                
                val updated = gameService.updateGameSettings(childId, gameId, settings)
                call.respond(updated)
            }
            
            // =============================================================================
            // GAME DATA MANAGEMENT
            // =============================================================================
            
            route("/children/{childId}/instances/{gameId}/data") {
                // Get specific data key
                get("/{dataKey}") {
                    val childId = call.parameters["childId"]?.let { UUID.fromString(it) }
                        ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                    val gameId = call.parameters["gameId"]?.let { UUID.fromString(it) }
                        ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid game ID")
                    val dataKey = call.parameters["dataKey"]
                        ?: return@get call.respond(HttpStatusCode.BadRequest, "Missing data key")
                    
                    // Implementation would fetch data from repository
                    call.respond(HttpStatusCode.OK)
                }
                
                // Update specific data key
                put("/{dataKey}") {
                    val childId = call.parameters["childId"]?.let { UUID.fromString(it) }
                        ?: return@put call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                    val gameId = call.parameters["gameId"]?.let { UUID.fromString(it) }
                        ?: return@put call.respond(HttpStatusCode.BadRequest, "Invalid game ID")
                    val dataKey = call.parameters["dataKey"]
                        ?: return@put call.respond(HttpStatusCode.BadRequest, "Missing data key")
                    
                    val request = call.receive<UpdateDataRequest>()
                    
                    val success = gameService.updateGameData(
                        childId = childId,
                        gameId = gameId,
                        dataUpdates = mapOf(dataKey to request.value),
                        sessionId = request.sessionId
                    )
                    
                    if (success) {
                        call.respond(HttpStatusCode.OK, SuccessResponse(success = true))
                    } else {
                        call.respond(HttpStatusCode.InternalServerError, "Failed to update data")
                    }
                }
            }
            
            // =============================================================================
            // GAME SESSIONS
            // =============================================================================
            
            route("/children/{childId}/instances/{gameId}/sessions") {
                // Start new session
                post("/start") {
                    val childId = call.parameters["childId"]?.let { UUID.fromString(it) }
                        ?: return@post call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                    val gameId = call.parameters["gameId"]?.let { UUID.fromString(it) }
                        ?: return@post call.respond(HttpStatusCode.BadRequest, "Invalid game ID")
                    
                    val request = call.receiveNullable<StartSessionRequest>()
                    
                    val session = sessionService.startSession(
                        childId = childId,
                        gameId = gameId,
                        deviceInfo = request?.deviceInfo
                    )
                    
                    call.respond(HttpStatusCode.Created, SessionResponse(
                        sessionId = session.id,
                        startedAt = session.startedAt
                    ))
                }
                
                // Update session
                patch("/{sessionId}") {
                    val sessionId = call.parameters["sessionId"]?.let { UUID.fromString(it) }
                        ?: return@patch call.respond(HttpStatusCode.BadRequest, "Invalid session ID")
                    
                    val metrics = call.receive<SessionMetrics>()
                    
                    val updated = sessionService.updateSession(sessionId, metrics)
                    call.respond(updated)
                }
                
                // End session
                post("/{sessionId}/end") {
                    val sessionId = call.parameters["sessionId"]?.let { UUID.fromString(it) }
                        ?: return@post call.respond(HttpStatusCode.BadRequest, "Invalid session ID")
                    
                    val request = call.receive<EndSessionRequest>()
                    
                    val ended = sessionService.endSession(sessionId, request.finalMetrics)
                    call.respond(ended)
                }
                
                // Get session history
                get {
                    val childId = call.parameters["childId"]?.let { UUID.fromString(it) }
                        ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                    val gameId = call.parameters["gameId"]?.let { UUID.fromString(it) }
                        ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid game ID")
                    
                    val limit = call.request.queryParameters["limit"]?.toIntOrNull() ?: 50
                    
                    val sessions = sessionService.getSessionHistory(childId, gameId, limit)
                    call.respond(SessionListResponse(sessions = sessions))
                }
            }
            
            // =============================================================================
            // ACHIEVEMENTS
            // =============================================================================
            
            route("/children/{childId}/achievements") {
                // Get all achievements for child
                get {
                    val childId = call.parameters["childId"]?.let { UUID.fromString(it) }
                        ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                    
                    val achievements = achievementService.getChildAchievements(childId, null)
                    call.respond(AchievementListResponse(achievements = achievements))
                }
                
                // Get achievements for specific game
                get("/games/{gameId}") {
                    val childId = call.parameters["childId"]?.let { UUID.fromString(it) }
                        ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                    val gameId = call.parameters["gameId"]?.let { UUID.fromString(it) }
                        ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid game ID")
                    
                    val achievements = achievementService.getChildAchievements(childId, gameId)
                    val available = achievementService.getAvailableAchievements(gameId)
                    
                    call.respond(GameAchievementsResponse(
                        unlocked = achievements,
                        available = available
                    ))
                }
                
                // Check for new achievements
                post("/check") {
                    val childId = call.parameters["childId"]?.let { UUID.fromString(it) }
                        ?: return@post call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                    
                    val request = call.receive<CheckAchievementsRequest>()
                    
                    val unlocked = achievementService.checkAchievements(
                        childId = childId,
                        gameId = request.gameId,
                        gameData = request.gameData
                    )
                    
                    call.respond(UnlockedAchievementsResponse(
                        newAchievements = unlocked
                    ))
                }
            }
        }
    }
}

// =============================================================================
// REQUEST/RESPONSE MODELS
// =============================================================================

@Serializable
data class GameListResponse(
    val games: List<GameRegistry>
)

@Serializable
data class InstanceListResponse(
    val instances: List<ChildGameInstance>
)

@Serializable
data class CreateInstanceRequest(
    val settings: GameSettings? = null
)

@Serializable
data class UpdateDataRequest(
    val value: GameDataValue,
    @Contextual val sessionId: UUID? = null
)

@Serializable
data class StartSessionRequest(
    val deviceInfo: DeviceInfo? = null
)

@Serializable
data class SessionResponse(
    @Contextual val sessionId: UUID,
    val startedAt: Instant
)

@Serializable
data class EndSessionRequest(
    val finalMetrics: SessionMetrics
)

@Serializable
data class SessionListResponse(
    val sessions: List<GameSession>
)

@Serializable
data class CheckAchievementsRequest(
    @Contextual val gameId: UUID,
    val gameData: Map<String, GameDataValue>
)

@Serializable
data class AchievementListResponse(
    val achievements: List<ChildAchievement>
)

@Serializable
data class GameAchievementsResponse(
    val unlocked: List<ChildAchievement>,
    val available: List<Achievement>
)

@Serializable
data class UnlockedAchievementsResponse(
    val newAchievements: List<UnlockedAchievement>
)

@Serializable
data class SuccessResponse(
    val success: Boolean,
    val message: String? = null
)