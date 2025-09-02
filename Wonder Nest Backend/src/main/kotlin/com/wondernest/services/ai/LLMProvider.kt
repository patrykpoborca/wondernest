package com.wondernest.services.ai

import kotlinx.serialization.Serializable
import java.time.Instant
import java.util.UUID

/**
 * Generic interface for Large Language Model providers
 * Supports multiple providers (Gemini, OpenAI, Anthropic, etc.) with unified interface
 */
interface LLMProvider {
    val providerName: String
    val supportedModels: List<String>
    
    /**
     * Generate a story based on the provided request
     */
    suspend fun generateStory(request: StoryGenerationRequest): LLMResponse
    
    /**
     * Analyze images for story generation context
     */
    suspend fun analyzeImages(images: List<String>): ImageAnalysisResponse
    
    /**
     * Check if the provider is healthy and available
     */
    suspend fun healthCheck(): ProviderHealth
    
    /**
     * Get current usage and cost information
     */
    suspend fun getUsageStats(): UsageStats
}

@Serializable
data class StoryGenerationRequest(
    val prompt: String,
    val imageDescriptions: List<String> = emptyList(),
    val targetAge: String = "6-8",
    val theme: String? = null,
    val educationalGoals: List<String> = emptyList(),
    val contentSafetyLevel: ContentSafetyLevel = ContentSafetyLevel.STRICT,
    val maxTokens: Int = 4000,
    val temperature: Double = 0.7,
    val metadata: Map<String, String> = emptyMap()
)

@Serializable
data class LLMResponse(
    val success: Boolean,
    val generatedContent: String? = null,
    val tokenUsage: TokenUsage,
    val safetyScores: SafetyScores,
    val qualityMetrics: QualityMetrics,
    val processingTimeMs: Long,
    val cost: Double,
    val error: LLMError? = null,
    val rawResponse: String? = null, // For debugging
    val metadata: Map<String, String> = emptyMap()
)

@Serializable
data class ImageAnalysisResponse(
    val success: Boolean,
    val analyses: List<ImageAnalysis>,
    val overallDescription: String,
    val safetyAssessment: SafetyAssessment,
    val processingTimeMs: Long,
    val cost: Double,
    val error: LLMError? = null
)

@Serializable
data class ImageAnalysis(
    val imageId: String,
    val description: String,
    val detectedObjects: List<DetectedObject>,
    val sceneAnalysis: SceneAnalysis,
    val visualStyle: VisualStyle,
    val characterAnalysis: List<CharacterAnalysis> = emptyList()
)

@Serializable
data class DetectedObject(
    val name: String,
    val confidence: Double,
    val boundingBox: BoundingBox? = null,
    val attributes: Map<String, String> = emptyMap()
)

@Serializable
data class BoundingBox(
    val x: Double,
    val y: Double,
    val width: Double,
    val height: Double
)

@Serializable
data class SceneAnalysis(
    val setting: String, // indoor, outdoor, fantasy, etc.
    val timeOfDay: String? = null,
    val weather: String? = null,
    val mood: String,
    val location: String? = null
)

@Serializable
data class VisualStyle(
    val artStyle: String, // cartoon, realistic, watercolor, etc.
    val colorPalette: List<String> = emptyList(),
    val mood: String,
    val complexity: String // simple, detailed, busy
)

@Serializable
data class CharacterAnalysis(
    val description: String,
    val estimatedAge: String? = null,
    val gender: String? = null,
    val emotions: List<String> = emptyList(),
    val clothing: String? = null,
    val pose: String? = null
)

@Serializable
data class SafetyAssessment(
    val overallSafetyScore: Double, // 0.0 to 1.0
    val ageAppropriateness: Double,
    val contentWarnings: List<String> = emptyList(),
    val violenceScore: Double = 0.0,
    val scaryContentScore: Double = 0.0,
    val inappropriateContentScore: Double = 0.0
)

@Serializable
data class TokenUsage(
    val promptTokens: Int,
    val completionTokens: Int,
    val totalTokens: Int,
    val cacheTokens: Int = 0
)

@Serializable
data class SafetyScores(
    val overallSafetyScore: Double, // 0.0 to 1.0, higher is safer
    val ageAppropriateScore: Double,
    val educationalScore: Double,
    val violenceScore: Double = 0.0, // Lower is safer
    val scaryContentScore: Double = 0.0,
    val profanityScore: Double = 0.0,
    val contentFlags: List<String> = emptyList()
)

@Serializable
data class QualityMetrics(
    val coherenceScore: Double, // 0.0 to 1.0
    val creativityScore: Double,
    val educationalValue: Double,
    val ageAppropriateness: Double,
    val storyStructureScore: Double,
    val vocabularyComplexity: Double
)

@Serializable
data class ProviderHealth(
    val isHealthy: Boolean,
    val responseTimeMs: Long,
    val lastChecked: String,
    val errorMessage: String? = null,
    val availableModels: List<String> = emptyList()
)

@Serializable
data class UsageStats(
    val totalRequests: Long,
    val totalTokens: Long,
    val totalCost: Double,
    val averageResponseTime: Long,
    val successRate: Double,
    val lastRequestTime: String? = null
)

@Serializable
data class LLMError(
    val code: String,
    val message: String,
    val details: Map<String, String> = emptyMap(),
    val retryable: Boolean = false
)

enum class ContentSafetyLevel {
    STRICT,    // Maximum safety, very conservative
    MODERATE,  // Balanced approach
    PERMISSIVE // Minimal filtering, trust parent judgment
}

/**
 * Exception classes for LLM operations
 */
sealed class LLMException(message: String, cause: Throwable? = null) : Exception(message, cause) {
    class ProviderUnavailable(message: String, cause: Throwable? = null) : LLMException(message, cause)
    class QuotaExceeded(message: String) : LLMException(message)
    class SafetyViolation(message: String, val safetyScores: SafetyScores) : LLMException(message)
    class InvalidRequest(message: String) : LLMException(message)
    class GenerationFailed(message: String, cause: Throwable? = null) : LLMException(message, cause)
    class RateLimitExceeded(message: String, val retryAfterSeconds: Long? = null) : LLMException(message)
}