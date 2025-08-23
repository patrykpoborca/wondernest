package com.wondernest.api.games

import com.wondernest.domain.model.games.*
import com.wondernest.services.games.*
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.auth.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.datetime.Clock
import kotlinx.serialization.Contextual
import kotlinx.serialization.Serializable
import org.koin.ktor.ext.inject
import java.util.UUID

fun Route.stickerGameRoutes() {
    val gameService by inject<GameService>()
    val sessionService by inject<GameSessionService>()
    val achievementService by inject<AchievementService>()
    val stickerGameService by inject<StickerGameService>()
    
    route("/api/v1/games/sticker") {
        authenticate("auth-jwt") {
            // =============================================================================
            // STICKER GAME INITIALIZATION
            // =============================================================================
            
            // Initialize sticker game for a child
            post("/children/{childId}/initialize") {
                val childId = call.parameters["childId"]?.let { UUID.fromString(it) }
                    ?: return@post call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                
                val request = call.receiveNullable<InitializeStickerGameRequest>()
                
                val gameInstance = stickerGameService.initializeStickerGame(
                    childId = childId,
                    ageMonths = request?.ageMonths ?: 60
                )
                
                call.respond(HttpStatusCode.Created, StickerGameInitResponse(
                    gameInstance = gameInstance,
                    availableStickerSets = stickerGameService.getAvailableStickerSets(childId),
                    unlockedAchievements = achievementService.getChildAchievements(childId, gameInstance.gameId)
                ))
            }
            
            // =============================================================================
            // STICKER SETS AND COLLECTIONS
            // =============================================================================
            
            // Get available sticker sets for child's age
            get("/children/{childId}/sticker-sets") {
                val childId = call.parameters["childId"]?.let { UUID.fromString(it) }
                    ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                
                val theme = call.request.queryParameters["theme"]
                val availableSets = stickerGameService.getAvailableStickerSets(childId, theme)
                
                call.respond(StickerSetsResponse(stickerSets = availableSets))
            }
            
            // Get child's unlocked sticker collections
            get("/children/{childId}/collections") {
                val childId = call.parameters["childId"]?.let { UUID.fromString(it) }
                    ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                
                val collections = stickerGameService.getChildStickerCollections(childId)
                call.respond(StickerCollectionsResponse(collections = collections))
            }
            
            // Unlock a sticker set for child
            post("/children/{childId}/collections/{stickerSetId}/unlock") {
                val childId = call.parameters["childId"]?.let { UUID.fromString(it) }
                    ?: return@post call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                val stickerSetId = call.parameters["stickerSetId"]?.let { UUID.fromString(it) }
                    ?: return@post call.respond(HttpStatusCode.BadRequest, "Invalid sticker set ID")
                
                val success = stickerGameService.unlockStickerSet(childId, stickerSetId)
                if (success) {
                    call.respond(SuccessResponse(success = true, message = "Sticker set unlocked"))
                } else {
                    call.respond(HttpStatusCode.BadRequest, "Failed to unlock sticker set")
                }
            }
            
            // =============================================================================
            // STICKER BOOK PROJECTS
            // =============================================================================
            
            // Get child's sticker book projects
            get("/children/{childId}/projects") {
                val childId = call.parameters["childId"]?.let { UUID.fromString(it) }
                    ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                
                val projects = stickerGameService.getChildProjects(childId)
                call.respond(StickerProjectsResponse(projects = projects))
            }
            
            // Create new sticker book project
            post("/children/{childId}/projects") {
                val childId = call.parameters["childId"]?.let { UUID.fromString(it) }
                    ?: return@post call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                
                val request = call.receive<CreateProjectRequest>()
                
                val project = stickerGameService.createProject(
                    childId = childId,
                    projectName = request.name,
                    creationMode = request.mode,
                    templateId = request.templateId
                )
                
                call.respond(HttpStatusCode.Created, project)
            }
            
            // Get specific project
            get("/children/{childId}/projects/{projectId}") {
                val childId = call.parameters["childId"]?.let { UUID.fromString(it) }
                    ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                val projectId = call.parameters["projectId"]?.let { UUID.fromString(it) }
                    ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid project ID")
                
                val project = stickerGameService.getProject(childId, projectId)
                if (project != null) {
                    call.respond(project)
                } else {
                    call.respond(HttpStatusCode.NotFound, "Project not found")
                }
            }
            
            // Update project data
            put("/children/{childId}/projects/{projectId}") {
                val childId = call.parameters["childId"]?.let { UUID.fromString(it) }
                    ?: return@put call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                val projectId = call.parameters["projectId"]?.let { UUID.fromString(it) }
                    ?: return@put call.respond(HttpStatusCode.BadRequest, "Invalid project ID")
                
                val request = call.receive<UpdateProjectRequest>()
                
                val updated = stickerGameService.updateProject(
                    childId = childId,
                    projectId = projectId,
                    projectData = request.projectData,
                    sessionId = request.sessionId
                )
                
                if (updated != null) {
                    call.respond(updated)
                } else {
                    call.respond(HttpStatusCode.NotFound, "Project not found")
                }
            }
            
            // Delete project
            delete("/children/{childId}/projects/{projectId}") {
                val childId = call.parameters["childId"]?.let { UUID.fromString(it) }
                    ?: return@delete call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                val projectId = call.parameters["projectId"]?.let { UUID.fromString(it) }
                    ?: return@delete call.respond(HttpStatusCode.BadRequest, "Invalid project ID")
                
                val success = stickerGameService.deleteProject(childId, projectId)
                if (success) {
                    call.respond(SuccessResponse(success = true))
                } else {
                    call.respond(HttpStatusCode.NotFound, "Project not found")
                }
            }
            
            // =============================================================================
            // GAME TEMPLATES
            // =============================================================================
            
            // Get available game templates
            get("/templates") {
                val ageMonths = call.request.queryParameters["age"]?.toIntOrNull() ?: 60
                val difficulty = call.request.queryParameters["difficulty"]?.toIntOrNull()
                
                val templates = stickerGameService.getGameTemplates(ageMonths, difficulty)
                call.respond(GameTemplatesResponse(templates = templates))
            }
            
            // =============================================================================
            // ANALYTICS AND PROGRESS
            // =============================================================================
            
            // Record sticker interaction
            post("/children/{childId}/interactions") {
                val childId = call.parameters["childId"]?.let { UUID.fromString(it) }
                    ?: return@post call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                
                val request = call.receive<RecordInteractionRequest>()
                
                val success = stickerGameService.recordInteraction(
                    childId = childId,
                    projectId = request.projectId,
                    sessionId = request.sessionId,
                    interactionType = request.interactionType,
                    interactionData = request.interactionData
                )
                
                call.respond(SuccessResponse(success = success))
            }
            
            // Get child's sticker game progress
            get("/children/{childId}/progress") {
                val childId = call.parameters["childId"]?.let { UUID.fromString(it) }
                    ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                
                val progress = stickerGameService.getChildProgress(childId)
                call.respond(progress)
            }
            
            // Export project
            post("/children/{childId}/projects/{projectId}/export") {
                val childId = call.parameters["childId"]?.let { UUID.fromString(it) }
                    ?: return@post call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                val projectId = call.parameters["projectId"]?.let { UUID.fromString(it) }
                    ?: return@post call.respond(HttpStatusCode.BadRequest, "Invalid project ID")
                
                val request = call.receive<ExportProjectRequest>()
                
                val exportData = stickerGameService.exportProject(
                    childId = childId,
                    projectId = projectId,
                    format = request.format,
                    options = request.options
                )
                
                if (exportData != null) {
                    call.respond(ExportResponse(
                        downloadUrl = exportData.downloadUrl,
                        fileName = exportData.fileName,
                        fileSize = exportData.fileSize
                    ))
                } else {
                    call.respond(HttpStatusCode.InternalServerError, "Export failed")
                }
            }
        }
    }
}

// =============================================================================
// REQUEST/RESPONSE MODELS FOR STICKER GAME
// =============================================================================

@Serializable
data class InitializeStickerGameRequest(
    val ageMonths: Int? = null
)

@Serializable
data class StickerGameInitResponse(
    val gameInstance: ChildGameInstance,
    val availableStickerSets: List<StickerSet>,
    val unlockedAchievements: List<ChildAchievement>
)

@Serializable
data class StickerSet(
    @Contextual val id: UUID,
    val name: String,
    val theme: String,
    val description: String,
    val stickerData: List<StickerData>,
    val isPremium: Boolean = false,
    val minAgeMonths: Int,
    val maxAgeMonths: Int,
    val isUnlocked: Boolean = false
)

@Serializable
data class StickerData(
    val id: String,
    val name: String,
    val emoji: String,
    val category: String,
    val metadata: Map<String, String> = emptyMap()
)

@Serializable
data class StickerSetsResponse(
    val stickerSets: List<StickerSet>
)

@Serializable
data class ChildStickerCollection(
    @Contextual val id: UUID,
    @Contextual val childId: UUID,
    @Contextual val stickerSetId: UUID,
    val stickerSet: StickerSet,
    val unlockedAt: String,
    val isFavorite: Boolean = false,
    val usageCount: Int = 0
)

@Serializable
data class StickerCollectionsResponse(
    val collections: List<ChildStickerCollection>
)

@Serializable
data class StickerBookProject(
    @Contextual val id: UUID,
    @Contextual val childGameInstanceId: UUID,
    val projectName: String,
    val description: String? = null,
    val creationMode: String, // 'infinite_canvas' or 'flip_book'
    val projectData: @Contextual Map<String, Any>,
    val thumbnailUrl: String? = null,
    val isCompleted: Boolean = false,
    val isShared: Boolean = false,
    val createdAt: String,
    val lastModified: String
)

@Serializable
data class StickerProjectsResponse(
    val projects: List<StickerBookProject>
)

@Serializable
data class CreateProjectRequest(
    val name: String,
    val mode: String, // 'infinite_canvas' or 'flip_book'
    @Contextual val templateId: UUID? = null,
    val description: String? = null
)

@Serializable
data class UpdateProjectRequest(
    val projectData: @Contextual Map<String, Any>,
    @Contextual val sessionId: UUID? = null
)

@Serializable
data class GameTemplate(
    @Contextual val id: UUID,
    val title: String,
    val description: String,
    val backgroundImageUrl: String? = null,
    val stickerSetIds: List<String>,
    val targetAgeMin: Int,
    val targetAgeMax: Int,
    val difficultyLevel: Int,
    val templateData: @Contextual Map<String, Any>
)

@Serializable
data class GameTemplatesResponse(
    val templates: List<GameTemplate>
)

@Serializable
data class RecordInteractionRequest(
    @Contextual val projectId: UUID,
    @Contextual val sessionId: UUID,
    val interactionType: String,
    val interactionData: @Contextual Map<String, Any>
)

@Serializable
data class StickerGameProgress(
    val totalProjects: Int,
    val completedProjects: Int,
    val totalPlayTimeMinutes: Int,
    val unlockedStickerSets: Int,
    val totalStickersUsed: Int,
    val achievementsUnlocked: Int,
    val favoriteTheme: String? = null,
    val skillMetrics: Map<String, Double> = emptyMap()
)

@Serializable
data class ExportProjectRequest(
    val format: String, // 'png', 'pdf', 'json'
    val options: @Contextual Map<String, Any> = emptyMap()
)

@Serializable
data class ExportData(
    val downloadUrl: String,
    val fileName: String,
    val fileSize: Long
)

@Serializable
data class ExportResponse(
    val downloadUrl: String,
    val fileName: String,
    val fileSize: Long
)