package com.wondernest.services.ai

import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.plugins.logging.*
import io.ktor.client.request.*
import io.ktor.client.statement.*
import io.ktor.http.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.*
import mu.KotlinLogging
import java.time.Instant
import kotlin.system.measureTimeMillis

private val logger = KotlinLogging.logger {}

/**
 * Google Gemini provider implementation
 */
class GeminiProvider(
    private val apiKey: String,
    private val model: String = "gemini-1.5-flash",
    private val baseUrl: String = "https://generativelanguage.googleapis.com/v1beta"
) : LLMProvider {
    
    override val providerName = "gemini"
    override val supportedModels = listOf("gemini-1.5-flash", "gemini-1.5-pro", "gemini-1.0-pro")
    
    private val httpClient = HttpClient {
        install(ContentNegotiation) {
            json(Json {
                ignoreUnknownKeys = true
                coerceInputValues = true
            })
        }
        install(Logging) {
            level = LogLevel.INFO
        }
    }
    
    override suspend fun generateStory(request: StoryGenerationRequest): LLMResponse {
        logger.info { "Generating story with Gemini for age ${request.targetAge}" }
        
        val prompt = buildStoryPrompt(request)
        val geminiRequest = buildGeminiRequest(prompt, request)
        
        var llmResponse: LLMResponse? = null
        val processingTime = measureTimeMillis {
            try {
                val response: HttpResponse = httpClient.post("$baseUrl/models/$model:generateContent") {
                    header("x-goog-api-key", apiKey)
                    contentType(ContentType.Application.Json)
                    setBody(geminiRequest)
                }
                
                when (response.status) {
                    HttpStatusCode.OK -> {
                        val geminiResponse = response.body<GeminiResponse>()
                        llmResponse = processGeminiResponse(geminiResponse, request)
                    }
                    HttpStatusCode.TooManyRequests -> {
                        throw LLMException.RateLimitExceeded(
                            "Gemini rate limit exceeded",
                            retryAfterSeconds = 60
                        )
                    }
                    HttpStatusCode.BadRequest -> {
                        val errorBody = response.bodyAsText()
                        throw LLMException.InvalidRequest("Invalid request to Gemini: $errorBody")
                    }
                    else -> {
                        val errorBody = response.bodyAsText()
                        throw LLMException.GenerationFailed("Gemini request failed: ${response.status} - $errorBody")
                    }
                }
            } catch (e: LLMException) {
                throw e
            } catch (e: Exception) {
                logger.error(e) { "Unexpected error calling Gemini API" }
                throw LLMException.ProviderUnavailable("Gemini provider unavailable", e)
            }
        }
        
        return llmResponse?.copy(processingTimeMs = processingTime) 
            ?: throw LLMException.GenerationFailed("Processing failed")
    }
    
    override suspend fun analyzeImages(images: List<String>): ImageAnalysisResponse {
        logger.info { "Analyzing ${images.size} images with Gemini Vision" }
        
        val prompt = buildImageAnalysisPrompt()
        val parts = mutableListOf<GeminiPart>()
        
        // Add text prompt
        parts.add(GeminiPart.Text(prompt))
        
        // Add images
        images.forEach { base64Image ->
            parts.add(GeminiPart.Image(
                GeminiImageData(
                    mimeType = "image/jpeg", // Assume JPEG, could be detected
                    data = base64Image
                )
            ))
        }
        
        val geminiRequest = GeminiRequest(
            contents = listOf(GeminiContent(parts = parts)),
            generationConfig = GeminiGenerationConfig(
                temperature = 0.3, // Lower temperature for more consistent analysis
                maxOutputTokens = 2000
            ),
            safetySettings = buildSafetySettings(ContentSafetyLevel.STRICT)
        )
        
        var analysisResponse: ImageAnalysisResponse? = null
        val processingTime = measureTimeMillis {
            try {
                val response: HttpResponse = httpClient.post("$baseUrl/models/gemini-1.5-flash:generateContent") {
                    header("x-goog-api-key", apiKey)
                    contentType(ContentType.Application.Json)
                    setBody(geminiRequest)
                }
                
                if (response.status == HttpStatusCode.OK) {
                    val geminiResponse = response.body<GeminiResponse>()
                    analysisResponse = processImageAnalysisResponse(geminiResponse, images)
                } else {
                    throw LLMException.GenerationFailed("Image analysis failed: ${response.status}")
                }
            } catch (e: LLMException) {
                throw e
            } catch (e: Exception) {
                logger.error(e) { "Error analyzing images with Gemini" }
                throw LLMException.GenerationFailed("Image analysis failed", e)
            }
        }
        
        return analysisResponse?.copy(processingTimeMs = processingTime)
            ?: throw LLMException.GenerationFailed("Image analysis processing failed")
    }
    
    override suspend fun healthCheck(): ProviderHealth {
        return try {
            val startTime = System.currentTimeMillis()
            
            val response = httpClient.get("$baseUrl/models") {
                header("x-goog-api-key", apiKey)
            }
            
            val responseTime = System.currentTimeMillis() - startTime
            
            if (response.status == HttpStatusCode.OK) {
                ProviderHealth(
                    isHealthy = true,
                    responseTimeMs = responseTime,
                    lastChecked = Instant.now().toString(),
                    availableModels = supportedModels
                )
            } else {
                ProviderHealth(
                    isHealthy = false,
                    responseTimeMs = responseTime,
                    lastChecked = Instant.now().toString(),
                    errorMessage = "HTTP ${response.status}"
                )
            }
        } catch (e: Exception) {
            logger.error(e) { "Gemini health check failed" }
            ProviderHealth(
                isHealthy = false,
                responseTimeMs = -1,
                lastChecked = Instant.now().toString(),
                errorMessage = e.message ?: "Unknown error"
            )
        }
    }
    
    override suspend fun getUsageStats(): UsageStats {
        // For now, return empty stats as Gemini doesn't provide detailed usage APIs
        // This could be enhanced with local tracking
        return UsageStats(
            totalRequests = 0,
            totalTokens = 0,
            totalCost = 0.0,
            averageResponseTime = 0,
            successRate = 1.0
        )
    }
    
    private fun buildStoryPrompt(request: StoryGenerationRequest): String {
        val basePrompt = """
            You are a creative children's story writer specializing in age-appropriate, educational, and engaging stories.
            
            Create a complete children's story with the following requirements:
            - Target age: ${request.targetAge}
            - Theme: ${request.theme ?: "adventure and learning"}
            - Educational goals: ${request.educationalGoals.joinToString(", ").ifEmpty { "creativity and imagination" }}
            - Content safety: ${request.contentSafetyLevel} level
            
            ${if (request.imageDescriptions.isNotEmpty()) {
                "Include these characters/elements from the provided images: ${request.imageDescriptions.joinToString(", ")}"
            } else ""}
            
            Story requirements:
            1. Age-appropriate vocabulary and themes for ${request.targetAge} year olds
            2. Clear story structure with beginning, middle, and end
            3. Positive moral lesson or educational value
            4. Engaging characters children can relate to
            5. Safe content with no violence, scary elements, or inappropriate themes
            6. Length appropriate for attention span of target age
            
            User prompt: ${request.prompt}
            
            Please write a complete story following these guidelines. Format as a structured story with title, and clear paragraphs.
        """.trimIndent()
        
        return basePrompt
    }
    
    private fun buildImageAnalysisPrompt(): String {
        return """
            Analyze the provided images for children's story creation. For each image, provide:
            
            1. Detailed description of the scene, characters, and objects
            2. Character analysis (age, emotions, clothing, pose if people are present)
            3. Setting analysis (indoor/outdoor, time of day, location type)
            4. Visual style (art style, colors, mood)
            5. Story potential (what kind of stories could feature these elements)
            6. Safety assessment (age-appropriateness, any concerns)
            
            Format your response as structured JSON with the following format:
            {
                "overallDescription": "Brief summary of all images",
                "images": [
                    {
                        "description": "Detailed description",
                        "characters": ["character descriptions"],
                        "setting": "setting description",
                        "objects": ["notable objects"],
                        "mood": "overall mood",
                        "storyPotential": "what stories could be told",
                        "safetyScore": 0.95
                    }
                ],
                "safetyAssessment": {
                    "overallSafe": true,
                    "ageAppropriate": true,
                    "concerns": []
                }
            }
        """.trimIndent()
    }
    
    private fun buildGeminiRequest(prompt: String, request: StoryGenerationRequest): GeminiRequest {
        return GeminiRequest(
            contents = listOf(
                GeminiContent(
                    parts = listOf(GeminiPart.Text(prompt))
                )
            ),
            generationConfig = GeminiGenerationConfig(
                temperature = request.temperature,
                maxOutputTokens = request.maxTokens,
                topP = 0.9,
                topK = 40
            ),
            safetySettings = buildSafetySettings(request.contentSafetyLevel)
        )
    }
    
    private fun buildSafetySettings(safetyLevel: ContentSafetyLevel): List<GeminiSafetySetting> {
        val threshold = when (safetyLevel) {
            ContentSafetyLevel.STRICT -> "BLOCK_MEDIUM_AND_ABOVE"
            ContentSafetyLevel.MODERATE -> "BLOCK_ONLY_HIGH"
            ContentSafetyLevel.PERMISSIVE -> "BLOCK_NONE"
        }
        
        return listOf(
            GeminiSafetySetting("HARM_CATEGORY_HARASSMENT", threshold),
            GeminiSafetySetting("HARM_CATEGORY_HATE_SPEECH", threshold),
            GeminiSafetySetting("HARM_CATEGORY_SEXUALLY_EXPLICIT", "BLOCK_MEDIUM_AND_ABOVE"), // Always strict for children
            GeminiSafetySetting("HARM_CATEGORY_DANGEROUS_CONTENT", threshold)
        )
    }
    
    private fun processGeminiResponse(geminiResponse: GeminiResponse, request: StoryGenerationRequest): LLMResponse {
        val candidate = geminiResponse.candidates.firstOrNull()
            ?: return LLMResponse(
                success = false,
                tokenUsage = TokenUsage(0, 0, 0),
                safetyScores = SafetyScores(0.0, 0.0, 0.0),
                qualityMetrics = QualityMetrics(0.0, 0.0, 0.0, 0.0, 0.0, 0.0),
                processingTimeMs = 0,
                cost = 0.0,
                error = LLMError("NO_CANDIDATES", "No candidates returned by Gemini")
            )
        
        val generatedText = (candidate.content.parts.firstOrNull() as? GeminiPart.Text)?.text
            ?: return LLMResponse(
                success = false,
                tokenUsage = TokenUsage(0, 0, 0),
                safetyScores = SafetyScores(0.0, 0.0, 0.0),
                qualityMetrics = QualityMetrics(0.0, 0.0, 0.0, 0.0, 0.0, 0.0),
                processingTimeMs = 0,
                cost = 0.0,
                error = LLMError("NO_CONTENT", "No text content generated")
            )
        
        // Calculate token usage (Gemini provides usage metadata)
        val tokenUsage = TokenUsage(
            promptTokens = geminiResponse.usageMetadata?.promptTokenCount ?: 0,
            completionTokens = geminiResponse.usageMetadata?.candidatesTokenCount ?: 0,
            totalTokens = geminiResponse.usageMetadata?.totalTokenCount ?: 0
        )
        
        // Calculate cost based on Gemini Flash pricing
        val cost = calculateCost(tokenUsage)
        
        // Analyze safety ratings
        val safetyScores = analyzeSafetyRatings(candidate.safetyRatings)
        
        // Basic quality metrics (could be enhanced with additional analysis)
        val qualityMetrics = assessStoryQuality(generatedText, request)
        
        return LLMResponse(
            success = true,
            generatedContent = generatedText,
            tokenUsage = tokenUsage,
            safetyScores = safetyScores,
            qualityMetrics = qualityMetrics,
            processingTimeMs = 0, // Set by caller
            cost = cost,
            rawResponse = Json.encodeToString(GeminiResponse.serializer(), geminiResponse)
        )
    }
    
    private fun processImageAnalysisResponse(geminiResponse: GeminiResponse, images: List<String>): ImageAnalysisResponse {
        val candidate = geminiResponse.candidates.firstOrNull()
            ?: throw LLMException.GenerationFailed("No candidates returned for image analysis")
        
        val analysisText = (candidate.content.parts.firstOrNull() as? GeminiPart.Text)?.text
            ?: throw LLMException.GenerationFailed("No analysis content generated")
        
        // Parse JSON response or use text analysis
        val imageAnalyses = parseImageAnalysis(analysisText, images)
        
        return ImageAnalysisResponse(
            success = true,
            analyses = imageAnalyses,
            overallDescription = "Combined analysis of ${images.size} images",
            safetyAssessment = SafetyAssessment(
                overallSafetyScore = 0.95,
                ageAppropriateness = 0.95
            ),
            processingTimeMs = 0,
            cost = calculateCost(TokenUsage(100, 200, 300)) // Rough estimate
        )
    }
    
    private fun calculateCost(tokenUsage: TokenUsage): Double {
        // Gemini Flash pricing (as of 2024)
        val promptCostPer1k = 0.00015
        val completionCostPer1k = 0.0006
        
        val promptCost = (tokenUsage.promptTokens / 1000.0) * promptCostPer1k
        val completionCost = (tokenUsage.completionTokens / 1000.0) * completionCostPer1k
        
        return promptCost + completionCost
    }
    
    private fun analyzeSafetyRatings(safetyRatings: List<GeminiSafetyRating>?): SafetyScores {
        if (safetyRatings == null) {
            return SafetyScores(
                overallSafetyScore = 1.0,
                ageAppropriateScore = 1.0,
                educationalScore = 0.8
            )
        }
        
        val flags = mutableListOf<String>()
        var minSafetyScore = 1.0
        
        safetyRatings.forEach { rating ->
            val score = when (rating.probability) {
                "NEGLIGIBLE" -> 1.0
                "LOW" -> 0.8
                "MEDIUM" -> 0.5
                "HIGH" -> 0.2
                else -> 0.7
            }
            
            if (score < minSafetyScore) {
                minSafetyScore = score
            }
            
            if (score < 0.7) {
                flags.add("${rating.category}: ${rating.probability}")
            }
        }
        
        return SafetyScores(
            overallSafetyScore = minSafetyScore,
            ageAppropriateScore = minSafetyScore,
            educationalScore = 0.8, // Default, could be enhanced
            contentFlags = flags
        )
    }
    
    private fun assessStoryQuality(text: String, request: StoryGenerationRequest): QualityMetrics {
        // Basic quality assessment - could be enhanced with ML models
        val wordCount = text.split("\\s+".toRegex()).size
        val sentenceCount = text.split("[.!?]".toRegex()).size
        val avgWordsPerSentence = if (sentenceCount > 0) wordCount.toDouble() / sentenceCount else 0.0
        
        // Rough heuristics for quality scoring
        val coherenceScore = if (avgWordsPerSentence in 8.0..15.0) 0.9 else 0.7
        val creativityScore = if (wordCount > 200) 0.8 else 0.6
        val ageAppropriateness = assessAgeAppropriateness(text, request.targetAge)
        
        return QualityMetrics(
            coherenceScore = coherenceScore,
            creativityScore = creativityScore,
            educationalValue = 0.8, // Default, could analyze for educational content
            ageAppropriateness = ageAppropriateness,
            storyStructureScore = if (text.contains("Once upon") || text.contains("The End")) 0.9 else 0.7,
            vocabularyComplexity = assessVocabularyComplexity(text, request.targetAge)
        )
    }
    
    private fun assessAgeAppropriateness(text: String, targetAge: String): Double {
        // Very basic assessment - could be enhanced
        val lowercaseText = text.lowercase()
        
        // Check for age-inappropriate content
        val inappropriateWords = listOf("scary", "frightening", "violent", "death", "kill")
        val foundInappropriate = inappropriateWords.any { lowercaseText.contains(it) }
        
        return if (foundInappropriate) 0.5 else 0.9
    }
    
    private fun assessVocabularyComplexity(text: String, targetAge: String): Double {
        // Basic vocabulary complexity assessment
        val words = text.split("\\s+".toRegex())
        val avgWordLength = words.map { it.length }.average()
        
        return when (targetAge) {
            "3-5" -> if (avgWordLength < 5.0) 0.9 else 0.6
            "6-8" -> if (avgWordLength in 4.0..6.0) 0.9 else 0.7
            "9-12" -> if (avgWordLength in 5.0..8.0) 0.9 else 0.7
            else -> 0.8
        }
    }
    
    private fun parseImageAnalysis(analysisText: String, images: List<String>): List<ImageAnalysis> {
        // Basic parsing - could be enhanced to properly parse JSON responses
        return images.mapIndexed { index, _ ->
            ImageAnalysis(
                imageId = "image_$index",
                description = "Image analysis from Gemini",
                detectedObjects = emptyList(),
                sceneAnalysis = SceneAnalysis(
                    setting = "unknown",
                    mood = "neutral"
                ),
                visualStyle = VisualStyle(
                    artStyle = "unknown",
                    mood = "neutral",
                    complexity = "moderate"
                )
            )
        }
    }
}

// Gemini API data classes
@Serializable
data class GeminiRequest(
    val contents: List<GeminiContent>,
    val generationConfig: GeminiGenerationConfig? = null,
    val safetySettings: List<GeminiSafetySetting>? = null
)

@Serializable
data class GeminiContent(
    val parts: List<GeminiPart>
)

@Serializable
sealed class GeminiPart {
    @Serializable
    @SerialName("text")
    data class Text(val text: String) : GeminiPart()
    
    @Serializable
    @SerialName("inlineData")
    data class Image(
        @SerialName("inlineData")
        val inlineData: GeminiImageData
    ) : GeminiPart()
}

@Serializable
data class GeminiImageData(
    val mimeType: String,
    val data: String
)

@Serializable
data class GeminiGenerationConfig(
    val temperature: Double? = null,
    val topP: Double? = null,
    val topK: Int? = null,
    val maxOutputTokens: Int? = null,
    val stopSequences: List<String>? = null
)

@Serializable
data class GeminiSafetySetting(
    val category: String,
    val threshold: String
)

@Serializable
data class GeminiResponse(
    val candidates: List<GeminiCandidate>,
    val usageMetadata: GeminiUsageMetadata? = null
)

@Serializable
data class GeminiCandidate(
    val content: GeminiContent,
    val finishReason: String? = null,
    val safetyRatings: List<GeminiSafetyRating>? = null,
    val index: Int? = null
)

@Serializable
data class GeminiUsageMetadata(
    val promptTokenCount: Int,
    val candidatesTokenCount: Int,
    val totalTokenCount: Int
)

@Serializable
data class GeminiSafetyRating(
    val category: String,
    val probability: String,
    val blocked: Boolean? = null
)