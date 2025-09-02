package com.wondernest.config

import com.wondernest.services.ai.*
import org.koin.dsl.module

/**
 * Dependency injection module for AI services
 */
val aiModule = module {
    
    // LLM Providers
    single<GeminiProvider> {
        val apiKey = System.getenv("GEMINI_API_KEY") 
            ?: throw IllegalStateException("GEMINI_API_KEY environment variable is required")
        
        GeminiProvider(
            apiKey = apiKey,
            model = "gemini-1.5-flash"
        )
    }
    
    // Future providers can be added here
    // single<OpenAIProvider> { OpenAIProvider(...) }
    // single<AnthropicProvider> { AnthropicProvider(...) }
    
    // Provider registry
    single<Map<String, LLMProvider>> {
        mapOf(
            "gemini" to get<GeminiProvider>()
            // Add other providers here as they're implemented
        )
    }
    
    // Main LLM service
    single<LLMService> {
        LLMService(
            providers = get(),
            defaultProvider = "gemini"
        )
    }
}

/**
 * Configuration data class for AI services
 */
data class AIConfig(
    val geminiApiKey: String,
    val defaultProvider: String = "gemini",
    val enableImageAnalysis: Boolean = true,
    val maxConcurrentGenerations: Int = 10,
    val generationTimeoutSeconds: Int = 60,
    val cacheExpirationDays: Int = 30
) {
    companion object {
        fun fromEnvironment(): AIConfig {
            return AIConfig(
                geminiApiKey = System.getenv("GEMINI_API_KEY") 
                    ?: throw IllegalStateException("GEMINI_API_KEY is required"),
                defaultProvider = System.getenv("AI_DEFAULT_PROVIDER") ?: "gemini",
                enableImageAnalysis = System.getenv("AI_ENABLE_IMAGE_ANALYSIS")?.toBooleanStrictOrNull() ?: true,
                maxConcurrentGenerations = System.getenv("AI_MAX_CONCURRENT")?.toIntOrNull() ?: 10,
                generationTimeoutSeconds = System.getenv("AI_TIMEOUT_SECONDS")?.toIntOrNull() ?: 60,
                cacheExpirationDays = System.getenv("AI_CACHE_EXPIRATION_DAYS")?.toIntOrNull() ?: 30
            )
        }
    }
}