package com.wondernest.services.storage

import io.ktor.server.application.*
import mu.KotlinLogging

private val logger = KotlinLogging.logger {}

/**
 * Factory for creating appropriate storage provider based on configuration
 */
class StorageProviderFactory {
    
    companion object {
        fun create(application: Application): StorageProvider {
            val config = application.environment.config
            val provider = try {
                config.property("storage.provider").getString()
            } catch (e: Exception) {
                "local"
            }
            
            logger.info { "Creating storage provider: $provider" }
            
            return when (provider.lowercase()) {
                "local" -> createLocalProvider(application)
                "s3" -> {
                    logger.warn { "S3 provider not yet implemented, falling back to local" }
                    createLocalProvider(application)
                }
                else -> {
                    logger.warn { "Unknown storage provider: $provider, falling back to local" }
                    createLocalProvider(application)
                }
            }
        }
        
        private fun createLocalProvider(application: Application): LocalStorageProvider {
            val config = application.environment.config
            
            val basePath = try {
                config.property("storage.local.base-path").getString()
            } catch (e: Exception) {
                "./uploads"
            }
            
            val baseUrl = try {
                config.property("storage.local.serve-url").getString()
            } catch (e: Exception) {
                "http://localhost:8080"
            }
            
            logger.info { "Creating LocalStorageProvider with basePath: $basePath" }
            
            return LocalStorageProvider(basePath, baseUrl)
        }
    }
}