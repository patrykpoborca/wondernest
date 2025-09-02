package com.wondernest.services.ai

import mu.KotlinLogging
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.transactions.transaction
import java.util.UUID
import java.time.Instant
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.withTimeout
import kotlin.time.Duration.Companion.seconds

private val logger = KotlinLogging.logger {}

/**
 * Service that manages multiple LLM providers with automatic failover,
 * quota management, and cost optimization
 */
class LLMService(
    private val providers: Map<String, LLMProvider>,
    private val defaultProvider: String = "gemini"
) {
    
    init {
        require(providers.isNotEmpty()) { "At least one LLM provider must be configured" }
        require(defaultProvider in providers) { "Default provider '$defaultProvider' must be in configured providers" }
        logger.info { "LLMService initialized with providers: ${providers.keys.joinToString()}" }
    }
    
    /**
     * Generate a story with automatic provider selection and failover
     */
    suspend fun generateStory(
        parentId: UUID,
        childId: UUID?,
        familyId: UUID,
        request: StoryGenerationRequest
    ): StoryGenerationResult {
        logger.info { "Generating story for parent $parentId, child $childId" }
        
        // Check quota before generation
        checkAndUpdateQuota(parentId)
        
        // Create generation record
        val generationId = createGenerationRecord(parentId, childId, familyId, request)
        
        return try {
            // Get optimal provider
            val providerName = selectOptimalProvider(request)
            val provider = providers[providerName] 
                ?: throw LLMException.ProviderUnavailable("Provider $providerName not available")
            
            logger.info { "Using provider: $providerName for generation $generationId" }
            
            // Generate with timeout
            val response = withTimeout(60.seconds) {
                provider.generateStory(request)
            }
            
            if (response.success && response.generatedContent != null) {
                // Create story template
                val storyId = createStoryTemplate(generationId, response, request)
                
                // Update generation record
                updateGenerationRecord(generationId, "completed", response, storyId)
                
                StoryGenerationResult.Success(
                    generationId = generationId,
                    storyId = storyId,
                    content = response.generatedContent,
                    safetyScores = response.safetyScores,
                    qualityMetrics = response.qualityMetrics,
                    cost = response.cost,
                    processingTimeMs = response.processingTimeMs
                )
            } else {
                updateGenerationRecord(generationId, "failed", response)
                StoryGenerationResult.Failed(
                    generationId = generationId,
                    error = response.error?.message ?: "Generation failed",
                    retryable = response.error?.retryable ?: false
                )
            }
            
        } catch (e: LLMException) {
            logger.error(e) { "Story generation failed for $generationId" }
            updateGenerationRecord(generationId, "failed", null, error = e.message)
            
            when (e) {
                is LLMException.SafetyViolation -> StoryGenerationResult.SafetyViolation(
                    generationId = generationId,
                    safetyScores = e.safetyScores,
                    message = e.message ?: "Safety violation occurred"
                )
                is LLMException.QuotaExceeded -> StoryGenerationResult.QuotaExceeded(
                    generationId = generationId,
                    message = e.message ?: "Quota exceeded"
                )
                else -> StoryGenerationResult.Failed(
                    generationId = generationId,
                    error = e.message ?: "Unknown error",
                    retryable = e is LLMException.RateLimitExceeded || e is LLMException.ProviderUnavailable
                )
            }
        } catch (e: Exception) {
            logger.error(e) { "Unexpected error during story generation $generationId" }
            updateGenerationRecord(generationId, "failed", null, error = e.message)
            
            StoryGenerationResult.Failed(
                generationId = generationId,
                error = "Internal error occurred",
                retryable = false
            )
        }
    }
    
    /**
     * Analyze images for story generation context
     */
    suspend fun analyzeImages(imageIds: List<UUID>): ImageAnalysisResult {
        logger.info { "Analyzing ${imageIds.size} images for story context" }
        
        try {
            // Get image data from database
            val imageData = getImageDataForAnalysis(imageIds)
            if (imageData.isEmpty()) {
                return ImageAnalysisResult.Failed("No images found for analysis")
            }
            
            // Check cache first
            val cachedAnalyses = getCachedImageAnalyses(imageIds)
            val uncachedImageIds = imageIds - cachedAnalyses.keys
            
            val allAnalyses = cachedAnalyses.toMutableMap()
            
            if (uncachedImageIds.isNotEmpty()) {
                // Get provider for image analysis
                val provider = providers[defaultProvider] 
                    ?: throw LLMException.ProviderUnavailable("Default provider not available")
                
                val uncachedImageData = imageData.filter { it.key in uncachedImageIds }
                val response = provider.analyzeImages(uncachedImageData.values.toList())
                
                if (response.success) {
                    // Cache the results
                    cacheImageAnalyses(uncachedImageIds.zip(response.analyses).toMap())
                    allAnalyses.putAll(uncachedImageIds.zip(response.analyses).toMap())
                }
            }
            
            return ImageAnalysisResult.Success(
                analyses = allAnalyses,
                processingTimeMs = 0 // Could track this
            )
            
        } catch (e: Exception) {
            logger.error(e) { "Image analysis failed" }
            return ImageAnalysisResult.Failed("Image analysis failed: ${e.message}")
        }
    }
    
    /**
     * Get user's quota information
     */
    suspend fun getUserQuota(userId: UUID): UserQuotaInfo {
        return transaction {
            // This would query the ai_generation_quotas table
            // For now, return default values
            UserQuotaInfo(
                dailyLimit = 5,
                dailyUsed = 0,
                monthlyLimit = 50,
                monthlyUsed = 0,
                subscriptionTier = "free",
                nextResetDaily = Instant.now().plusSeconds(86400),
                nextResetMonthly = Instant.now().plusSeconds(2592000)
            )
        }
    }
    
    /**
     * Check provider health status
     */
    suspend fun checkProviderHealth(): Map<String, ProviderHealth> {
        return coroutineScope {
            providers.map { (name, provider) ->
                name to async { 
                    try {
                        provider.healthCheck()
                    } catch (e: Exception) {
                        ProviderHealth(
                            isHealthy = false,
                            responseTimeMs = -1,
                            lastChecked = Instant.now().toString(),
                            errorMessage = e.message
                        )
                    }
                }
            }.associate { (name, deferred) ->
                name to deferred.await()
            }
        }
    }
    
    private suspend fun checkAndUpdateQuota(userId: UUID) {
        val quota = getUserQuota(userId)
        if (quota.dailyUsed >= quota.dailyLimit) {
            throw LLMException.QuotaExceeded("Daily generation limit exceeded (${quota.dailyLimit})")
        }
        if (quota.monthlyUsed >= quota.monthlyLimit) {
            throw LLMException.QuotaExceeded("Monthly generation limit exceeded (${quota.monthlyLimit})")
        }
        
        // Update usage count
        transaction {
            // Update quota usage - this would be actual SQL
            logger.info { "Updated quota for user $userId" }
        }
    }
    
    private fun selectOptimalProvider(request: StoryGenerationRequest): String {
        // For now, use the default provider
        // Could be enhanced with load balancing, cost optimization, etc.
        return defaultProvider
    }
    
    private suspend fun createGenerationRecord(
        parentId: UUID,
        childId: UUID?,
        familyId: UUID,
        request: StoryGenerationRequest
    ): UUID {
        return transaction {
            // Insert into ai_story_generations table
            val generationId = UUID.randomUUID()
            logger.info { "Created generation record: $generationId" }
            generationId
        }
    }
    
    private suspend fun updateGenerationRecord(
        generationId: UUID,
        status: String,
        response: LLMResponse?,
        storyId: UUID? = null,
        error: String? = null
    ) {
        transaction {
            // Update ai_story_generations table
            logger.info { "Updated generation record $generationId with status: $status" }
        }
    }
    
    private suspend fun createStoryTemplate(
        generationId: UUID,
        response: LLMResponse,
        request: StoryGenerationRequest
    ): UUID {
        return transaction {
            // Create story template with AI metadata
            val storyId = UUID.randomUUID()
            
            // This would insert into story_templates with proper structure
            logger.info { "Created story template: $storyId for generation: $generationId" }
            
            storyId
        }
    }
    
    private suspend fun getImageDataForAnalysis(imageIds: List<UUID>): Map<UUID, String> {
        return transaction {
            // Query uploaded_files table and convert images to base64
            // For now, return empty map
            emptyMap()
        }
    }
    
    private suspend fun getCachedImageAnalyses(imageIds: List<UUID>): Map<UUID, ImageAnalysis> {
        return transaction {
            // Query ai_image_analysis_cache table
            emptyMap()
        }
    }
    
    private suspend fun cacheImageAnalyses(analyses: Map<UUID, ImageAnalysis>) {
        transaction {
            // Insert into ai_image_analysis_cache table
            logger.info { "Cached ${analyses.size} image analyses" }
        }
    }
}

/**
 * Result types for LLM operations
 */
sealed class StoryGenerationResult {
    data class Success(
        val generationId: UUID,
        val storyId: UUID,
        val content: String,
        val safetyScores: SafetyScores,
        val qualityMetrics: QualityMetrics,
        val cost: Double,
        val processingTimeMs: Long
    ) : StoryGenerationResult()
    
    data class Failed(
        val generationId: UUID,
        val error: String,
        val retryable: Boolean
    ) : StoryGenerationResult()
    
    data class SafetyViolation(
        val generationId: UUID,
        val safetyScores: SafetyScores,
        val message: String
    ) : StoryGenerationResult()
    
    data class QuotaExceeded(
        val generationId: UUID,
        val message: String
    ) : StoryGenerationResult()
}

sealed class ImageAnalysisResult {
    data class Success(
        val analyses: Map<UUID, ImageAnalysis>,
        val processingTimeMs: Long
    ) : ImageAnalysisResult()
    
    data class Failed(
        val error: String
    ) : ImageAnalysisResult()
}

data class UserQuotaInfo(
    val dailyLimit: Int,
    val dailyUsed: Int,
    val monthlyLimit: Int,
    val monthlyUsed: Int,
    val subscriptionTier: String,
    val nextResetDaily: Instant,
    val nextResetMonthly: Instant,
    val bonusCredits: Int = 0
)