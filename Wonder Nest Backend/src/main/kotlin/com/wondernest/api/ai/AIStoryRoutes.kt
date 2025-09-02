package com.wondernest.api.ai

import com.wondernest.api.extractUser
import com.wondernest.services.ai.*
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.auth.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.serialization.Contextual
import kotlinx.serialization.Serializable
import mu.KotlinLogging
import org.koin.ktor.ext.inject
import java.util.*

private val logger = KotlinLogging.logger {}

@Serializable
data class ErrorResponse(
    val error: String,
    val code: String? = null
)

fun Route.aiStoryRoutes() {
    val llmService by inject<LLMService>()
    
    route("/api/v2/ai") {
        authenticate("auth-jwt") {
            
            // Generate a new story using AI
            post("/stories/generate") {
                try {
                    val user = call.extractUser()
                    logger.info { "AI story generation request from user: ${user.id}" }
                    
                    val request = call.receive<AIStoryGenerationRequest>()
                    
                    // Validate request
                    if (request.prompt.isBlank()) {
                        call.respond(HttpStatusCode.BadRequest, ErrorResponse("Prompt cannot be empty"))
                        return@post
                    }
                    
                    if (request.targetAge !in listOf("3-5", "6-8", "9-12", "13+")) {
                        call.respond(HttpStatusCode.BadRequest, ErrorResponse("Invalid target age range"))
                        return@post
                    }
                    
                    // Convert to service request
                    val storyRequest = StoryGenerationRequest(
                        prompt = request.prompt,
                        imageDescriptions = emptyList(), // Will be populated from image analysis
                        targetAge = request.targetAge,
                        theme = request.theme,
                        educationalGoals = request.educationalGoals,
                        contentSafetyLevel = when (request.contentSafetyLevel) {
                            "strict" -> ContentSafetyLevel.STRICT
                            "moderate" -> ContentSafetyLevel.MODERATE
                            "permissive" -> ContentSafetyLevel.PERMISSIVE
                            else -> ContentSafetyLevel.STRICT
                        },
                        maxTokens = request.maxTokens ?: 4000,
                        temperature = request.temperature ?: 0.7
                    )
                    
                    // Analyze images if provided
                    if (request.imageIds.isNotEmpty()) {
                        when (val imageAnalysisResult = llmService.analyzeImages(request.imageIds)) {
                            is ImageAnalysisResult.Success -> {
                                // Add image descriptions to story request
                                val descriptions = imageAnalysisResult.analyses.values.map { it.description }
                                storyRequest.copy(imageDescriptions = descriptions)
                            }
                            is ImageAnalysisResult.Failed -> {
                                call.respond(
                                    HttpStatusCode.BadRequest, 
                                    ErrorResponse("Image analysis failed: ${imageAnalysisResult.error}")
                                )
                                return@post
                            }
                        }
                    }
                    
                    // Generate the story
                    val result = llmService.generateStory(
                        parentId = user.id,
                        childId = request.childId,
                        familyId = UUID.randomUUID(), // TODO: Get actual family ID from user
                        request = storyRequest
                    )
                    
                    when (result) {
                        is StoryGenerationResult.Success -> {
                            call.respond(HttpStatusCode.OK, AIStoryGenerationResponse(
                                success = true,
                                generationId = result.generationId,
                                storyId = result.storyId,
                                content = result.content,
                                safetyScores = result.safetyScores,
                                qualityMetrics = result.qualityMetrics,
                                cost = result.cost,
                                processingTimeMs = result.processingTimeMs,
                                status = "completed"
                            ))
                        }
                        
                        is StoryGenerationResult.Failed -> {
                            val statusCode = if (result.retryable) HttpStatusCode.ServiceUnavailable else HttpStatusCode.BadRequest
                            call.respond(statusCode, AIStoryGenerationResponse(
                                success = false,
                                generationId = result.generationId,
                                error = result.error,
                                retryable = result.retryable,
                                status = "failed"
                            ))
                        }
                        
                        is StoryGenerationResult.SafetyViolation -> {
                            call.respond(HttpStatusCode.BadRequest, AIStoryGenerationResponse(
                                success = false,
                                generationId = result.generationId,
                                error = result.message,
                                safetyScores = result.safetyScores,
                                status = "safety_violation"
                            ))
                        }
                        
                        is StoryGenerationResult.QuotaExceeded -> {
                            call.respond(HttpStatusCode.TooManyRequests, AIStoryGenerationResponse(
                                success = false,
                                generationId = result.generationId,
                                error = result.message,
                                status = "quota_exceeded"
                            ))
                        }
                    }
                    
                } catch (e: Exception) {
                    logger.error(e) { "Error processing AI story generation request" }
                    call.respond(HttpStatusCode.InternalServerError, 
                        ErrorResponse("Internal server error occurred"))
                }
            }
            
            // Get generation status
            get("/stories/status/{generationId}") {
                try {
                    val user = call.extractUser()
                    val generationId = call.parameters["generationId"]?.let { UUID.fromString(it) }
                        ?: return@get call.respond(HttpStatusCode.BadRequest, ErrorResponse("Invalid generation ID"))
                    
                    // In a real implementation, this would query the database
                    // For now, return a placeholder response
                    call.respond(HttpStatusCode.OK, AIStoryStatusResponse(
                        generationId = generationId,
                        status = "completed",
                        progress = 100,
                        estimatedCompletionTime = null,
                        error = null
                    ))
                    
                } catch (e: Exception) {
                    logger.error(e) { "Error getting story generation status" }
                    call.respond(HttpStatusCode.InternalServerError, 
                        ErrorResponse("Internal server error occurred"))
                }
            }
            
            // Get user's AI generation quotas
            get("/quotas") {
                try {
                    val user = call.extractUser()
                    val quota = llmService.getUserQuota(user.id)
                    
                    call.respond(HttpStatusCode.OK, AIQuotaResponse(
                        dailyLimit = quota.dailyLimit,
                        dailyUsed = quota.dailyUsed,
                        dailyRemaining = quota.dailyLimit - quota.dailyUsed,
                        monthlyLimit = quota.monthlyLimit,
                        monthlyUsed = quota.monthlyUsed,
                        monthlyRemaining = quota.monthlyLimit - quota.monthlyUsed,
                        subscriptionTier = quota.subscriptionTier,
                        bonusCredits = quota.bonusCredits,
                        nextResetDaily = quota.nextResetDaily.toString(),
                        nextResetMonthly = quota.nextResetMonthly.toString()
                    ))
                    
                } catch (e: Exception) {
                    logger.error(e) { "Error getting user quota" }
                    call.respond(HttpStatusCode.InternalServerError, 
                        ErrorResponse("Internal server error occurred"))
                }
            }
            
            // Get prompt templates
            get("/templates") {
                try {
                    val user = call.extractUser()
                    val category = call.request.queryParameters["category"]
                    val isPublic = call.request.queryParameters["public"]?.toBooleanStrictOrNull()
                    
                    // In a real implementation, this would query ai_prompt_templates
                    val templates = listOf(
                        AIPromptTemplate(
                            id = UUID.randomUUID(),
                            name = "Adventure Quest",
                            description = "Create exciting adventure stories",
                            category = "adventure",
                            basePrompt = "Create an adventure story about {character} who discovers {item}...",
                            placeholders = mapOf(
                                "character" to "Main character name",
                                "item" to "Special object they find"
                            ),
                            recommendedAge = "6-8",
                            requiredImages = 2,
                            price = 0,
                            isPublic = true,
                            creatorName = "WonderNest",
                            rating = 4.8,
                            usageCount = 1250
                        )
                    )
                    
                    call.respond(HttpStatusCode.OK, AITemplatesResponse(
                        templates = templates,
                        total = templates.size
                    ))
                    
                } catch (e: Exception) {
                    logger.error(e) { "Error getting prompt templates" }
                    call.respond(HttpStatusCode.InternalServerError, 
                        ErrorResponse("Internal server error occurred"))
                }
            }
            
            // Create/save a custom prompt template
            post("/templates") {
                try {
                    val user = call.extractUser()
                    val request = call.receive<CreatePromptTemplateRequest>()
                    
                    // Validate request
                    if (request.name.isBlank() || request.basePrompt.isBlank()) {
                        call.respond(HttpStatusCode.BadRequest, 
                            ErrorResponse("Name and base prompt are required"))
                        return@post
                    }
                    
                    // In a real implementation, this would insert into ai_prompt_templates
                    val templateId = UUID.randomUUID()
                    
                    call.respond(HttpStatusCode.Created, CreatePromptTemplateResponse(
                        id = templateId,
                        message = "Prompt template created successfully"
                    ))
                    
                } catch (e: Exception) {
                    logger.error(e) { "Error creating prompt template" }
                    call.respond(HttpStatusCode.InternalServerError, 
                        ErrorResponse("Internal server error occurred"))
                }
            }
            
            // Analyze images for story context
            post("/images/analyze") {
                try {
                    val user = call.extractUser()
                    val request = call.receive<ImageAnalysisRequest>()
                    
                    if (request.imageIds.isEmpty()) {
                        call.respond(HttpStatusCode.BadRequest, ErrorResponse("No images provided"))
                        return@post
                    }
                    
                    when (val result = llmService.analyzeImages(request.imageIds)) {
                        is ImageAnalysisResult.Success -> {
                            call.respond(HttpStatusCode.OK, ImageAnalysisResponse(
                                success = true,
                                analyses = result.analyses.map { (imageId, analysis) ->
                                    ImageAnalysisDto(
                                        imageId = imageId,
                                        description = analysis.description,
                                        detectedObjects = analysis.detectedObjects.map { 
                                            DetectedObjectDto(it.name, it.confidence) 
                                        },
                                        sceneAnalysis = SceneAnalysisDto(
                                            setting = analysis.sceneAnalysis.setting,
                                            mood = analysis.sceneAnalysis.mood,
                                            timeOfDay = analysis.sceneAnalysis.timeOfDay,
                                            location = analysis.sceneAnalysis.location
                                        ),
                                        characters = analysis.characterAnalysis.map { char ->
                                            CharacterAnalysisDto(
                                                description = char.description,
                                                estimatedAge = char.estimatedAge,
                                                emotions = char.emotions
                                            )
                                        }
                                    )
                                },
                                processingTimeMs = result.processingTimeMs
                            ))
                        }
                        
                        is ImageAnalysisResult.Failed -> {
                            call.respond(HttpStatusCode.BadRequest, ImageAnalysisResponse(
                                success = false,
                                error = result.error
                            ))
                        }
                    }
                    
                } catch (e: Exception) {
                    logger.error(e) { "Error analyzing images" }
                    call.respond(HttpStatusCode.InternalServerError, 
                        ErrorResponse("Internal server error occurred"))
                }
            }
            
            // Get provider health status (admin/debugging endpoint)
            get("/providers/health") {
                try {
                    val user = call.extractUser()
                    
                    // This could be restricted to admin users
                    val healthStatus = llmService.checkProviderHealth()
                    
                    call.respond(HttpStatusCode.OK, ProvidersHealthResponse(
                        providers = healthStatus.map { (name, health) ->
                            ProviderHealthDto(
                                name = name,
                                isHealthy = health.isHealthy,
                                responseTimeMs = health.responseTimeMs,
                                lastChecked = health.lastChecked,
                                error = health.errorMessage,
                                availableModels = health.availableModels
                            )
                        }
                    ))
                    
                } catch (e: Exception) {
                    logger.error(e) { "Error checking provider health" }
                    call.respond(HttpStatusCode.InternalServerError, 
                        ErrorResponse("Internal server error occurred"))
                }
            }
        }
    }
}

// Request/Response DTOs
@Serializable
data class AIStoryGenerationRequest(
    val prompt: String,
    val imageIds: List<@Contextual UUID> = emptyList(),
    val childId: @Contextual UUID? = null,
    val targetAge: String = "6-8",
    val theme: String? = null,
    val educationalGoals: List<String> = emptyList(),
    val contentSafetyLevel: String = "strict",
    val maxTokens: Int? = null,
    val temperature: Double? = null
)

@Serializable
data class AIStoryGenerationResponse(
    val success: Boolean,
    @Contextual val generationId: UUID,
    @Contextual val storyId: UUID? = null,
    val content: String? = null,
    val safetyScores: SafetyScores? = null,
    val qualityMetrics: QualityMetrics? = null,
    val cost: Double? = null,
    val processingTimeMs: Long? = null,
    val status: String,
    val error: String? = null,
    val retryable: Boolean? = null
)

@Serializable
data class AIStoryStatusResponse(
    @Contextual val generationId: UUID,
    val status: String,
    val progress: Int,
    val estimatedCompletionTime: String? = null,
    val error: String? = null
)

@Serializable
data class AIQuotaResponse(
    val dailyLimit: Int,
    val dailyUsed: Int,
    val dailyRemaining: Int,
    val monthlyLimit: Int,
    val monthlyUsed: Int,
    val monthlyRemaining: Int,
    val subscriptionTier: String,
    val bonusCredits: Int,
    val nextResetDaily: String,
    val nextResetMonthly: String
)

@Serializable
data class AIPromptTemplate(
    @Contextual val id: UUID,
    val name: String,
    val description: String,
    val category: String,
    val basePrompt: String,
    val placeholders: Map<String, String>,
    val recommendedAge: String,
    val requiredImages: Int,
    val price: Int,
    val isPublic: Boolean,
    val creatorName: String,
    val rating: Double,
    val usageCount: Int
)

@Serializable
data class AITemplatesResponse(
    val templates: List<AIPromptTemplate>,
    val total: Int
)

@Serializable
data class CreatePromptTemplateRequest(
    val name: String,
    val description: String,
    val category: String,
    val basePrompt: String,
    val placeholders: Map<String, String>,
    val recommendedAge: String,
    val requiredImages: Int = 0,
    val isPublic: Boolean = false,
    val price: Int = 0
)

@Serializable
data class CreatePromptTemplateResponse(
    @Contextual val id: UUID,
    val message: String
)

@Serializable
data class ImageAnalysisRequest(
    val imageIds: List<@Contextual UUID>
)

@Serializable
data class ImageAnalysisResponse(
    val success: Boolean,
    val analyses: List<ImageAnalysisDto> = emptyList(),
    val processingTimeMs: Long? = null,
    val error: String? = null
)

@Serializable
data class ImageAnalysisDto(
    @Contextual val imageId: UUID,
    val description: String,
    val detectedObjects: List<DetectedObjectDto>,
    val sceneAnalysis: SceneAnalysisDto,
    val characters: List<CharacterAnalysisDto>
)

@Serializable
data class DetectedObjectDto(
    val name: String,
    val confidence: Double
)

@Serializable
data class SceneAnalysisDto(
    val setting: String,
    val mood: String,
    val timeOfDay: String? = null,
    val location: String? = null
)

@Serializable
data class CharacterAnalysisDto(
    val description: String,
    val estimatedAge: String? = null,
    val emotions: List<String>
)

@Serializable
data class ProvidersHealthResponse(
    val providers: List<ProviderHealthDto>
)

@Serializable
data class ProviderHealthDto(
    val name: String,
    val isHealthy: Boolean,
    val responseTimeMs: Long,
    val lastChecked: String,
    val error: String? = null,
    val availableModels: List<String> = emptyList()
)