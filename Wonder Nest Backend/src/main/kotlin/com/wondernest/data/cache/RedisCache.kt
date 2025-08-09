package com.wondernest.data.cache

import io.lettuce.core.RedisClient
import io.lettuce.core.RedisURI
import io.lettuce.core.api.StatefulRedisConnection
import io.lettuce.core.api.async.RedisAsyncCommands
import kotlinx.coroutines.future.await
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import mu.KotlinLogging
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

private val logger = KotlinLogging.logger {}

class RedisCache {
    private lateinit var client: RedisClient
    private lateinit var connection: StatefulRedisConnection<String, String>
    private lateinit var commands: RedisAsyncCommands<String, String>

    fun init() {
        initializeWithRetry()
    }
    
    private fun initializeWithRetry(maxAttempts: Int = 10) {
        var attempt = 1
        var lastException: Exception? = null
        
        while (attempt <= maxAttempts) {
            try {
                logger.info { "Attempting to connect to Redis (attempt $attempt/$maxAttempts)" }
                
                val host = System.getenv("REDIS_HOST") ?: "redis"
                val port = System.getenv("REDIS_PORT")?.toIntOrNull() ?: 6379
                val password = System.getenv("REDIS_PASSWORD")
                val database = System.getenv("REDIS_DATABASE")?.toIntOrNull() ?: 0

                val uriBuilder = RedisURI.Builder
                    .redis(host)
                    .withPort(port)
                    .withDatabase(database)
                    .withTimeout(java.time.Duration.ofSeconds(10))
                
                if (!password.isNullOrBlank()) {
                    uriBuilder.withPassword(password.toCharArray())
                }

                client = RedisClient.create(uriBuilder.build())
                connection = client.connect()
                commands = connection.async()
                
                // Test the connection
                commands.ping().get(5, java.util.concurrent.TimeUnit.SECONDS)
                
                logger.info { "Redis cache initialized successfully" }
                logger.info { "Redis host: $host:$port, database: $database" }
                return // Success!
                
            } catch (e: Exception) {
                lastException = e
                logger.warn(e) { "Redis connection attempt $attempt failed: ${e.message}" }
                
                // Clean up failed connection
                if (::connection.isInitialized) {
                    try {
                        connection.close()
                    } catch (closeException: Exception) {
                        logger.warn(closeException) { "Error closing failed Redis connection" }
                    }
                }
                
                if (::client.isInitialized) {
                    try {
                        client.shutdown()
                    } catch (shutdownException: Exception) {
                        logger.warn(shutdownException) { "Error shutting down failed Redis client" }
                    }
                }
                
                if (attempt < maxAttempts) {
                    val delaySeconds = minOf(attempt * 2, 30) // Exponential backoff, max 30 seconds
                    logger.info { "Retrying Redis connection in $delaySeconds seconds..." }
                    Thread.sleep(delaySeconds * 1000L)
                }
                
                attempt++
            }
        }
        
        logger.error(lastException) { "Failed to connect to Redis after $maxAttempts attempts" }
        throw RuntimeException("Failed to initialize Redis cache after $maxAttempts attempts", lastException)
    }

    internal suspend inline fun <reified T> get(key: String): T? {
        return try {
            val value = commands.get(key).await()
            if (value != null) {
                Json.decodeFromString<T>(value)
            } else null
        } catch (e: Exception) {
            logger.warn(e) { "Failed to get value from cache for key: $key" }
            null
        }
    }

    internal suspend inline fun <reified T> set(key: String, value: T, ttl: Duration = 1.minutes): Boolean {
        return try {
            val jsonValue = Json.encodeToString(value)
            val result = if (ttl.inWholeSeconds > 0) {
                commands.setex(key, ttl.inWholeSeconds, jsonValue).await()
            } else {
                commands.set(key, jsonValue).await()
            }
            result == "OK"
        } catch (e: Exception) {
            logger.warn(e) { "Failed to set value in cache for key: $key" }
            false
        }
    }

    suspend fun delete(key: String): Boolean {
        return try {
            commands.del(key).await() > 0
        } catch (e: Exception) {
            logger.warn(e) { "Failed to delete value from cache for key: $key" }
            false
        }
    }

    suspend fun deleteByPattern(pattern: String): Long {
        return try {
            val keys = commands.keys(pattern).await()
            if (keys.isNotEmpty()) {
                commands.del(*keys.toTypedArray()).await()
            } else 0L
        } catch (e: Exception) {
            logger.warn(e) { "Failed to delete values by pattern: $pattern" }
            0L
        }
    }

    suspend fun exists(key: String): Boolean {
        return try {
            commands.exists(key).await() > 0
        } catch (e: Exception) {
            logger.warn(e) { "Failed to check existence of key: $key" }
            false
        }
    }

    suspend fun increment(key: String, by: Long = 1): Long {
        return try {
            commands.incrby(key, by).await()
        } catch (e: Exception) {
            logger.warn(e) { "Failed to increment key: $key" }
            0L
        }
    }

    suspend fun expire(key: String, ttl: Duration): Boolean {
        return try {
            commands.expire(key, ttl.inWholeSeconds).await()
        } catch (e: Exception) {
            logger.warn(e) { "Failed to set expiration for key: $key" }
            false
        }
    }

    internal suspend inline fun <reified T> getOrSet(
        key: String,
        ttl: Duration = 1.minutes,
        noinline fetcher: suspend () -> T
    ): T? {
        val cachedValue = get<T>(key)
        if (cachedValue != null) {
            return cachedValue
        }

        return try {
            val freshValue = fetcher()
            set(key, freshValue, ttl)
            freshValue
        } catch (e: Exception) {
            logger.warn(e) { "Failed to fetch fresh value for key: $key" }
            null
        }
    }

    // Rate limiting support
    suspend fun checkRateLimit(key: String, limit: Int, window: Duration): Boolean {
        return try {
            val count = commands.incr(key).await()
            if (count == 1L) {
                commands.expire(key, window.inWholeSeconds)
            }
            count <= limit
        } catch (e: Exception) {
            logger.warn(e) { "Failed to check rate limit for key: $key" }
            true // Allow request if cache is down
        }
    }

    // Session management
    suspend fun setSession(sessionId: String, data: Map<String, Any>, ttl: Duration = 24.minutes) {
        set("session:$sessionId", data, ttl)
    }

    suspend fun getSession(sessionId: String): Map<String, Any>? {
        return get("session:$sessionId")
    }

    suspend fun deleteSession(sessionId: String) {
        delete("session:$sessionId")
    }

    // Content caching
    suspend fun cacheContent(contentId: String, content: Any, ttl: Duration = 1.minutes) {
        set("content:$contentId", content, ttl)
    }

    suspend fun getCachedContent(contentId: String): Any? {
        return get("content:$contentId")
    }

    // Recommendation caching
    suspend fun cacheRecommendations(childId: String, recommendations: List<Any>, ttl: Duration = 30.minutes) {
        set("recommendations:$childId", recommendations, ttl)
    }

    suspend fun getCachedRecommendations(childId: String): List<Any>? {
        return get("recommendations:$childId")
    }

    fun close() {
        if (::connection.isInitialized) {
            connection.close()
        }
        if (::client.isInitialized) {
            client.shutdown()
        }
    }
}