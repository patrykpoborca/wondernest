package com.wondernest.api.health

import com.wondernest.data.cache.RedisCache
import com.wondernest.data.database.DatabaseFactory
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.serialization.Serializable
import org.koin.ktor.ext.inject
import org.slf4j.LoggerFactory
import java.time.Instant

private val logger = LoggerFactory.getLogger("HealthRoutes")

@Serializable
data class HealthStatus(
    val status: String,
    val timestamp: String,
    val version: String = "0.0.1",
    val environment: String = System.getenv("KTOR_ENV") ?: "unknown",
    val services: Map<String, ServiceHealth>
)

@Serializable
data class ServiceHealth(
    val status: String,
    val message: String? = null,
    val responseTime: Long? = null
)

fun Route.healthRoutes() {
    val databaseFactory by inject<DatabaseFactory>()
    val redisCache by inject<RedisCache>()

    // Basic health check - minimal response for load balancers
    get("/health") {
        call.respond(HttpStatusCode.OK, mapOf("status" to "UP"))
    }
    
    // HEAD support for health check (used by load balancers)
    head("/health") {
        call.respond(HttpStatusCode.OK)
    }

    // Detailed health check with service status
    get("/health/detailed") {
        val startTime = System.currentTimeMillis()
        
        try {
            val services = mutableMapOf<String, ServiceHealth>()

            // Check database health
            val dbStartTime = System.currentTimeMillis()
            val dbHealthy = try {
                databaseFactory.isHealthy()
            } catch (e: Exception) {
                logger.warn("Database health check failed", e)
                false
            }
            val dbResponseTime = System.currentTimeMillis() - dbStartTime

            services["database"] = ServiceHealth(
                status = if (dbHealthy) "UP" else "DOWN",
                message = if (dbHealthy) "Connected" else "Connection failed",
                responseTime = dbResponseTime
            )

            // Check Redis health
            val redisStartTime = System.currentTimeMillis()
            val redisHealthy = try {
                redisCache.exists("health-check-test")
                true
            } catch (e: Exception) {
                logger.warn("Redis health check failed", e)
                false
            }
            val redisResponseTime = System.currentTimeMillis() - redisStartTime

            services["redis"] = ServiceHealth(
                status = if (redisHealthy) "UP" else "DOWN",
                message = if (redisHealthy) "Connected" else "Connection failed",
                responseTime = redisResponseTime
            )

            // Overall status
            val overallHealthy = dbHealthy && redisHealthy
            val status = if (overallHealthy) "UP" else "DOWN"

            val healthStatus = HealthStatus(
                status = status,
                timestamp = Instant.now().toString(),
                services = services
            )

            val statusCode = if (overallHealthy) HttpStatusCode.OK else HttpStatusCode.ServiceUnavailable
            call.respond(statusCode, healthStatus)

        } catch (e: Exception) {
            logger.error("Health check failed", e)
            call.respond(
                HttpStatusCode.InternalServerError,
                HealthStatus(
                    status = "DOWN",
                    timestamp = Instant.now().toString(),
                    services = mapOf(
                        "application" to ServiceHealth(
                            status = "DOWN",
                            message = "Internal error: ${e.message}"
                        )
                    )
                )
            )
        }
    }

    // Readiness check - indicates the app is ready to receive traffic
    get("/health/ready") {
        try {
            val dbHealthy = databaseFactory.isHealthy()
            val redisHealthy = try {
                redisCache.exists("readiness-check")
                true
            } catch (e: Exception) {
                false
            }

            if (dbHealthy && redisHealthy) {
                call.respond(HttpStatusCode.OK, mapOf("status" to "READY"))
            } else {
                call.respond(
                    HttpStatusCode.ServiceUnavailable,
                    mapOf(
                        "status" to "NOT_READY",
                        "database" to if (dbHealthy) "UP" else "DOWN",
                        "redis" to if (redisHealthy) "UP" else "DOWN"
                    )
                )
            }
        } catch (e: Exception) {
            logger.error("Readiness check failed", e)
            call.respond(
                HttpStatusCode.InternalServerError,
                mapOf("status" to "ERROR", "message" to e.message)
            )
        }
    }

    // Liveness check - indicates the app is alive (basic check)
    get("/health/live") {
        // This should only fail if the application itself is dead
        call.respond(HttpStatusCode.OK, mapOf("status" to "ALIVE"))
    }

    // Startup check - indicates the app has finished starting up
    get("/health/startup") {
        try {
            // Check if critical services are initialized
            val dbInitialized = try {
                databaseFactory.isHealthy()
            } catch (e: Exception) {
                false
            }

            if (dbInitialized) {
                call.respond(HttpStatusCode.OK, mapOf("status" to "STARTED"))
            } else {
                call.respond(
                    HttpStatusCode.ServiceUnavailable,
                    mapOf("status" to "STARTING")
                )
            }
        } catch (e: Exception) {
            logger.error("Startup check failed", e)
            call.respond(
                HttpStatusCode.ServiceUnavailable,
                mapOf("status" to "STARTING", "error" to e.message)
            )
        }
    }
}