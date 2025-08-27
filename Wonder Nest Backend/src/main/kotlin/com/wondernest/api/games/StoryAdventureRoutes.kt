package com.wondernest.api.games

import com.wondernest.services.games.*
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
 * Story Adventure API routes for interactive storytelling feature
 * REFACTORED: Now follows WonderNest plugin architecture
 * - Child data uses /api/v2/games/children/{childId}/data with game_type='story-adventure'
 * - Platform features (templates, marketplace) keep custom routes
 * - Backwards compatible during transition period
 */
fun Route.storyAdventureRoutes() {
    route("/api/v2/games/story-adventure") {
        
        val templateService = StoryTemplateService()
        val instanceService = StoryInstanceService()
        val vocabularyService = VocabularyService()
        val storyPlugin = StoryAdventurePlugin()
        
        authenticate("auth-jwt") {
            
            // =============================================================================
            // STORY TEMPLATES
            // =============================================================================
            
            // Get available story templates for a child
            get("/templates") {
                val childId = call.parameters["childId"]?.let {
                    try { UUID.fromString(it) }
                    catch (e: IllegalArgumentException) { null }
                } ?: return@get call.respond(HttpStatusCode.BadRequest, "Missing or invalid childId parameter")
                
                val ageGroup = call.parameters["ageGroup"]
                val difficulty = call.parameters["difficulty"]
                val category = call.parameters["category"]
                val includeMarketplace = call.parameters["includeMarketplace"]?.toBoolean()
                val limit = call.parameters["limit"]?.toIntOrNull() ?: 20
                val offset = call.parameters["offset"]?.toIntOrNull() ?: 0
                
                try {
                    val request = SearchStoryTemplatesRequest(
                        ageGroup = ageGroup,
                        difficulty = difficulty,
                        category = category,
                        includeMarketplace = includeMarketplace,
                        limit = limit,
                        offset = offset
                    )
                    
                    val templates = templateService.searchTemplates(request)
                    
                    call.respond(HttpStatusCode.OK, mapOf(
                        "templates" to templates,
                        "totalCount" to templates.size,
                        "hasMore" to (templates.size == limit)
                    ))
                    
                } catch (e: Exception) {
                    call.application.log.error("Error fetching story templates", e)
                    call.respond(HttpStatusCode.InternalServerError, mapOf(
                        "error" to "Failed to fetch story templates"
                    ))
                }
            }
            
            // Get detailed story template by ID
            get("/templates/{templateId}") {
                val templateId = call.parameters["templateId"]?.let {
                    try { UUID.fromString(it) }
                    catch (e: IllegalArgumentException) { null }
                } ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid template ID")
                
                try {
                    val template = templateService.getTemplateById(templateId)
                    if (template != null) {
                        call.respond(HttpStatusCode.OK, template)
                    } else {
                        call.respond(HttpStatusCode.NotFound, mapOf(
                            "error" to "Story template not found"
                        ))
                    }
                } catch (e: Exception) {
                    call.application.log.error("Error fetching story template", e)
                    call.respond(HttpStatusCode.InternalServerError, mapOf(
                        "error" to "Failed to fetch story template"
                    ))
                }
            }
            
            // Create new story template (Parent Only - requires PIN)
            post("/templates") {
                val request = try {
                    call.receive<CreateStoryTemplateApiRequest>()
                } catch (e: Exception) {
                    return@post call.respond(HttpStatusCode.BadRequest, "Invalid request body")
                }
                
                try {
                    val createRequest = CreateStoryTemplateRequest(
                        title = request.title,
                        description = request.description,
                        creatorId = request.creatorId?.let { UUID.fromString(it) },
                        ageGroup = request.ageGroup,
                        difficulty = request.difficulty,
                        content = request.content,
                        vocabularyWords = request.vocabularyWords,
                        pageCount = request.pageCount,
                        estimatedReadTime = request.estimatedReadTime,
                        language = request.language,
                        version = request.version,
                        isPremium = request.isPremium,
                        isMarketplace = request.isMarketplace,
                        isActive = request.isActive,
                        isPrivate = request.isPrivate,
                        educationalGoals = request.educationalGoals,
                        themes = request.themes,
                        tags = request.tags
                    )
                    
                    val result = templateService.createTemplate(createRequest)
                    
                    if (result.success) {
                        call.respond(HttpStatusCode.Created, result)
                    } else {
                        call.respond(HttpStatusCode.BadRequest, result)
                    }
                    
                } catch (e: Exception) {
                    call.application.log.error("Error creating story template", e)
                    call.respond(HttpStatusCode.InternalServerError, mapOf(
                        "error" to "Failed to create story template"
                    ))
                }
            }
            
            // Update story template (Parent Only)
            put("/templates/{templateId}") {
                val templateId = call.parameters["templateId"]?.let {
                    try { UUID.fromString(it) }
                    catch (e: IllegalArgumentException) { null }
                } ?: return@put call.respond(HttpStatusCode.BadRequest, "Invalid template ID")
                
                val request = try {
                    call.receive<UpdateStoryTemplateApiRequest>()
                } catch (e: Exception) {
                    return@put call.respond(HttpStatusCode.BadRequest, "Invalid request body")
                }
                
                try {
                    val updateRequest = UpdateStoryTemplateRequest(
                        title = request.title,
                        description = request.description,
                        ageGroup = request.ageGroup,
                        difficulty = request.difficulty,
                        content = request.content,
                        vocabularyWords = request.vocabularyWords,
                        pageCount = request.pageCount,
                        estimatedReadTime = request.estimatedReadTime,
                        language = request.language,
                        version = request.version,
                        isPremium = request.isPremium,
                        isMarketplace = request.isMarketplace,
                        isActive = request.isActive,
                        isPrivate = request.isPrivate,
                        educationalGoals = request.educationalGoals,
                        themes = request.themes,
                        tags = request.tags
                    )
                    
                    val result = templateService.updateTemplate(templateId, updateRequest)
                    
                    if (result.success) {
                        call.respond(HttpStatusCode.OK, result)
                    } else {
                        call.respond(HttpStatusCode.BadRequest, result)
                    }
                    
                } catch (e: Exception) {
                    call.application.log.error("Error updating story template", e)
                    call.respond(HttpStatusCode.InternalServerError, mapOf(
                        "error" to "Failed to update story template"
                    ))
                }
            }
            
            // Delete story template (Parent Only)
            delete("/templates/{templateId}") {
                val templateId = call.parameters["templateId"]?.let {
                    try { UUID.fromString(it) }
                    catch (e: IllegalArgumentException) { null }
                } ?: return@delete call.respond(HttpStatusCode.BadRequest, "Invalid template ID")
                
                // TODO: Get creator ID from JWT token for authorization
                val creatorId: UUID? = null // Extract from JWT
                
                try {
                    val result = templateService.deleteTemplate(templateId, creatorId)
                    
                    if (result.success) {
                        call.respond(HttpStatusCode.OK, result)
                    } else {
                        call.respond(HttpStatusCode.BadRequest, result)
                    }
                    
                } catch (e: Exception) {
                    call.application.log.error("Error deleting story template", e)
                    call.respond(HttpStatusCode.InternalServerError, mapOf(
                        "error" to "Failed to delete story template"
                    ))
                }
            }
            
            // =============================================================================
            // CHILD DATA ROUTES - REFACTORED TO PLUGIN ARCHITECTURE
            // =============================================================================
            
            // Get all child data for Story Adventure (NEW UNIFIED ENDPOINT)
            get("/children/{childId}/data") {
                val childId = call.parameters["childId"]?.let {
                    try { UUID.fromString(it) }
                    catch (e: IllegalArgumentException) { null }
                } ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                
                try {
                    val childData = storyPlugin.getChildData(childId)
                    if (childData != null) {
                        call.respond(HttpStatusCode.OK, childData)
                    } else {
                        call.respond(HttpStatusCode.NotFound, mapOf(
                            "error" to "No Story Adventure data found for child"
                        ))
                    }
                } catch (e: Exception) {
                    call.application.log.error("Error fetching child data", e)
                    call.respond(HttpStatusCode.InternalServerError, mapOf(
                        "error" to "Failed to fetch child data"
                    ))
                }
            }
            
            // Initialize Story Adventure for a child (NEW)
            post("/children/{childId}/initialize") {
                val childId = call.parameters["childId"]?.let {
                    try { UUID.fromString(it) }
                    catch (e: IllegalArgumentException) { null }
                } ?: return@post call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                
                try {
                    val result = storyPlugin.initializeForChild(childId)
                    if (result.success) {
                        call.respond(HttpStatusCode.Created, result)
                    } else {
                        call.respond(HttpStatusCode.BadRequest, result)
                    }
                } catch (e: Exception) {
                    call.application.log.error("Error initializing Story Adventure", e)
                    call.respond(HttpStatusCode.InternalServerError, mapOf(
                        "error" to "Failed to initialize Story Adventure"
                    ))
                }
            }
            
            // Update child preferences (NEW)
            put("/children/{childId}/preferences") {
                val childId = call.parameters["childId"]?.let {
                    try { UUID.fromString(it) }
                    catch (e: IllegalArgumentException) { null }
                } ?: return@put call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                
                val preferences = try {
                    call.receive<Map<String, JsonElement>>()
                } catch (e: Exception) {
                    return@put call.respond(HttpStatusCode.BadRequest, "Invalid request body")
                }
                
                try {
                    val result = storyPlugin.updatePreferences(childId, preferences)
                    if (result.success) {
                        call.respond(HttpStatusCode.OK, result)
                    } else {
                        call.respond(HttpStatusCode.BadRequest, result)
                    }
                } catch (e: Exception) {
                    call.application.log.error("Error updating preferences", e)
                    call.respond(HttpStatusCode.InternalServerError, mapOf(
                        "error" to "Failed to update preferences"
                    ))
                }
            }
            
            // Generate progress report (NEW)
            get("/children/{childId}/progress-report") {
                val childId = call.parameters["childId"]?.let {
                    try { UUID.fromString(it) }
                    catch (e: IllegalArgumentException) { null }
                } ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                
                try {
                    val report = storyPlugin.generateProgressReport(childId)
                    if (report != null) {
                        call.respond(HttpStatusCode.OK, report)
                    } else {
                        call.respond(HttpStatusCode.NotFound, mapOf(
                            "error" to "No progress data found for child"
                        ))
                    }
                } catch (e: Exception) {
                    call.application.log.error("Error generating progress report", e)
                    call.respond(HttpStatusCode.InternalServerError, mapOf(
                        "error" to "Failed to generate progress report"
                    ))
                }
            }
            
            // =============================================================================
            // BACKWARDS COMPATIBLE ROUTES (DEPRECATED - Use /children/{childId}/data)
            // =============================================================================
            
            // Get all story instances for a child (DEPRECATED)
            get("/instances/{childId}") {
                val childId = call.parameters["childId"]?.let {
                    try { UUID.fromString(it) }
                    catch (e: IllegalArgumentException) { null }
                } ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                
                val status = call.parameters["status"]
                val templateId = call.parameters["templateId"]?.let {
                    try { UUID.fromString(it) }
                    catch (e: IllegalArgumentException) { null }
                }
                
                try {
                    val instances = instanceService.getInstancesByChild(childId, status, templateId)
                    call.respond(HttpStatusCode.OK, mapOf("instances" to instances))
                    
                } catch (e: Exception) {
                    call.application.log.error("Error fetching story instances", e)
                    call.respond(HttpStatusCode.InternalServerError, mapOf(
                        "error" to "Failed to fetch story instances"
                    ))
                }
            }
            
            // Start a new reading session (DEPRECATED - Use plugin methods)
            post("/instances/{childId}/start") {
                val childId = call.parameters["childId"]?.let {
                    try { UUID.fromString(it) }
                    catch (e: IllegalArgumentException) { null }
                } ?: return@post call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                
                val request = try {
                    call.receive<StartStoryApiRequest>()
                } catch (e: Exception) {
                    return@post call.respond(HttpStatusCode.BadRequest, "Invalid request body")
                }
                
                try {
                    val startRequest = StartStoryInstanceRequest(
                        childId = childId,
                        templateId = UUID.fromString(request.templateId),
                        customizations = request.customizations,
                        readingMode = request.readingMode,
                        audioEnabled = request.audioEnabled
                    )
                    
                    // Use plugin method for better integration
                    val result = storyPlugin.startStory(childId, UUID.fromString(request.templateId), request.customizations)
                    
                    if (result.success) {
                        call.respond(HttpStatusCode.Created, result)
                    } else {
                        call.respond(HttpStatusCode.BadRequest, result)
                    }
                    
                } catch (e: Exception) {
                    call.application.log.error("Error starting story instance", e)
                    call.respond(HttpStatusCode.InternalServerError, mapOf(
                        "error" to "Failed to start story instance"
                    ))
                }
            }
            
            // Update reading progress (DEPRECATED - Use direct data updates)
            put("/instances/{instanceId}/progress") {
                val instanceId = call.parameters["instanceId"]?.let {
                    try { UUID.fromString(it) }
                    catch (e: IllegalArgumentException) { null }
                } ?: return@put call.respond(HttpStatusCode.BadRequest, "Invalid instance ID")
                
                val request = try {
                    call.receive<UpdateProgressRequest>()
                } catch (e: Exception) {
                    return@put call.respond(HttpStatusCode.BadRequest, "Invalid request body")
                }
                
                try {
                    val result = instanceService.updateProgress(instanceId, request)
                    
                    if (result.success) {
                        call.respond(HttpStatusCode.OK, result)
                    } else {
                        call.respond(HttpStatusCode.BadRequest, result)
                    }
                    
                } catch (e: Exception) {
                    call.application.log.error("Error updating story progress", e)
                    call.respond(HttpStatusCode.InternalServerError, mapOf(
                        "error" to "Failed to update story progress"
                    ))
                }
            }
            
            // Complete story reading session (DEPRECATED)
            post("/instances/{instanceId}/complete") {
                val instanceId = call.parameters["instanceId"]?.let {
                    try { UUID.fromString(it) }
                    catch (e: IllegalArgumentException) { null }
                } ?: return@post call.respond(HttpStatusCode.BadRequest, "Invalid instance ID")
                
                val request = try {
                    call.receive<CompleteStoryRequest>()
                } catch (e: Exception) {
                    return@post call.respond(HttpStatusCode.BadRequest, "Invalid request body")
                }
                
                try {
                    val result = instanceService.completeStoryInstance(instanceId, request)
                    
                    if (result.success) {
                        call.respond(HttpStatusCode.OK, result)
                    } else {
                        call.respond(HttpStatusCode.BadRequest, result)
                    }
                    
                } catch (e: Exception) {
                    call.application.log.error("Error completing story", e)
                    call.respond(HttpStatusCode.InternalServerError, mapOf(
                        "error" to "Failed to complete story"
                    ))
                }
            }
            
            // =============================================================================
            // VOCABULARY TRACKING
            // =============================================================================
            
            // Record vocabulary word encounter (DEPRECATED - Use plugin methods)
            post("/vocabulary/{childId}/encounter") {
                val childId = call.parameters["childId"]?.let {
                    try { UUID.fromString(it) }
                    catch (e: IllegalArgumentException) { null }
                } ?: return@post call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                
                val request = try {
                    call.receive<VocabularyEncounterApiRequest>()
                } catch (e: Exception) {
                    return@post call.respond(HttpStatusCode.BadRequest, "Invalid request body")
                }
                
                try {
                    val interactionType = when (request.interactionType.lowercase()) {
                        "correct" -> WordInteractionType.CORRECT
                        "incorrect" -> WordInteractionType.INCORRECT
                        "definition" -> WordInteractionType.DEFINITION
                        "pronunciation" -> WordInteractionType.PRONUNCIATION
                        else -> WordInteractionType.ENCOUNTERED
                    }
                    
                    val templateId = request.templateId?.let { UUID.fromString(it) }
                    
                    // Use plugin method for better integration
                    val result = storyPlugin.recordVocabularyEncounter(childId, request.word, templateId, interactionType)
                    
                    if (result.success) {
                        call.respond(HttpStatusCode.OK, result)
                    } else {
                        call.respond(HttpStatusCode.BadRequest, result)
                    }
                    
                } catch (e: Exception) {
                    call.application.log.error("Error recording vocabulary encounter", e)
                    call.respond(HttpStatusCode.InternalServerError, mapOf(
                        "error" to "Failed to record vocabulary encounter"
                    ))
                }
            }
            
            // Get vocabulary progress for a child (DEPRECATED - Use /children/{childId}/data)
            get("/vocabulary/{childId}/progress") {
                val childId = call.parameters["childId"]?.let {
                    try { UUID.fromString(it) }
                    catch (e: IllegalArgumentException) { null }
                } ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                
                val masteryLevel = call.parameters["masteryLevel"]?.toIntOrNull()
                val limit = call.parameters["limit"]?.toIntOrNull() ?: 100
                val offset = call.parameters["offset"]?.toIntOrNull() ?: 0
                
                try {
                    val progress = vocabularyService.getChildVocabularyProgress(
                        childId, masteryLevel, limit, offset
                    )
                    call.respond(HttpStatusCode.OK, mapOf("vocabulary" to progress))
                    
                } catch (e: Exception) {
                    call.application.log.error("Error fetching vocabulary progress", e)
                    call.respond(HttpStatusCode.InternalServerError, mapOf(
                        "error" to "Failed to fetch vocabulary progress"
                    ))
                }
            }
            
            // Get vocabulary statistics for a child (DEPRECATED - Use progress report)
            get("/vocabulary/{childId}/stats") {
                val childId = call.parameters["childId"]?.let {
                    try { UUID.fromString(it) }
                    catch (e: IllegalArgumentException) { null }
                } ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                
                try {
                    val stats = vocabularyService.getVocabularyStats(childId)
                    call.respond(HttpStatusCode.OK, stats)
                    
                } catch (e: Exception) {
                    call.application.log.error("Error fetching vocabulary stats", e)
                    call.respond(HttpStatusCode.InternalServerError, mapOf(
                        "error" to "Failed to fetch vocabulary stats"
                    ))
                }
            }
            
            // Get words needing practice (DEPRECATED)
            get("/vocabulary/{childId}/practice") {
                val childId = call.parameters["childId"]?.let {
                    try { UUID.fromString(it) }
                    catch (e: IllegalArgumentException) { null }
                } ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid child ID")
                
                val limit = call.parameters["limit"]?.toIntOrNull() ?: 20
                
                try {
                    val words = vocabularyService.getWordsNeedingPractice(childId, limit)
                    call.respond(HttpStatusCode.OK, mapOf("words" to words))
                    
                } catch (e: Exception) {
                    call.application.log.error("Error fetching words needing practice", e)
                    call.respond(HttpStatusCode.InternalServerError, mapOf(
                        "error" to "Failed to fetch words needing practice"
                    ))
                }
            }
        }
    }
}

// API Request models

@Serializable
data class CreateStoryTemplateApiRequest(
    val title: String,
    val description: String,
    val creatorId: String?,
    val ageGroup: String,
    val difficulty: String,
    val content: JsonElement,
    val vocabularyWords: List<String>,
    val pageCount: Int,
    val estimatedReadTime: Int,
    val language: String = "en",
    val version: String = "1.0.0",
    val isPremium: Boolean = false,
    val isMarketplace: Boolean = false,
    val isActive: Boolean = true,
    val isPrivate: Boolean = false,
    val educationalGoals: List<String> = emptyList(),
    val themes: List<String> = emptyList(),
    val tags: List<String> = emptyList()
)

@Serializable
data class UpdateStoryTemplateApiRequest(
    val title: String,
    val description: String,
    val ageGroup: String,
    val difficulty: String,
    val content: JsonElement,
    val vocabularyWords: List<String>,
    val pageCount: Int,
    val estimatedReadTime: Int,
    val language: String,
    val version: String,
    val isPremium: Boolean,
    val isMarketplace: Boolean,
    val isActive: Boolean,
    val isPrivate: Boolean,
    val educationalGoals: List<String>,
    val themes: List<String>,
    val tags: List<String>
)

@Serializable
data class StartStoryApiRequest(
    val templateId: String,
    val customizations: JsonElement,
    val readingMode: String = "self_paced",
    val audioEnabled: Boolean = true
)

@Serializable
data class VocabularyEncounterApiRequest(
    val word: String,
    val templateId: String?,
    val interactionType: String = "encountered"
)