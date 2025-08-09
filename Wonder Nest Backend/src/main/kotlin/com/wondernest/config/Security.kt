package com.wondernest.config

import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.plugins.ratelimit.*
import io.ktor.server.plugins.statuspages.*
import io.ktor.server.response.*
import kotlinx.serialization.Serializable
import kotlin.time.Duration.Companion.seconds

@Serializable
data class ErrorResponse(
    val error: String,
    val message: String,
    val timestamp: Long = System.currentTimeMillis()
)

fun Application.configureSecurity() {
    install(RateLimit) {
        // Default rate limit for all endpoints
        register(RateLimitName("api")) {
            rateLimiter(limit = 100, refillPeriod = 60.seconds)
        }
        
        // Stricter rate limit for authentication endpoints
        register(RateLimitName("auth")) {
            rateLimiter(limit = 5, refillPeriod = 60.seconds)
        }
        
        // Rate limit for file uploads
        register(RateLimitName("upload")) {
            rateLimiter(limit = 10, refillPeriod = 60.seconds)
        }
    }

    install(StatusPages) {
        exception<Throwable> { call, cause ->
            when (cause) {
                is IllegalArgumentException -> {
                    call.respond(
                        HttpStatusCode.BadRequest,
                        ErrorResponse("VALIDATION_ERROR", cause.message ?: "Invalid input")
                    )
                }
                is SecurityException -> {
                    call.respond(
                        HttpStatusCode.Forbidden,
                        ErrorResponse("SECURITY_ERROR", "Access denied")
                    )
                }
                is NoSuchElementException -> {
                    call.respond(
                        HttpStatusCode.NotFound,
                        ErrorResponse("NOT_FOUND", cause.message ?: "Resource not found")
                    )
                }
                else -> {
                    call.application.environment.log.error("Unhandled exception", cause)
                    call.respond(
                        HttpStatusCode.InternalServerError,
                        ErrorResponse("INTERNAL_ERROR", "An unexpected error occurred")
                    )
                }
            }
        }
        
        status(HttpStatusCode.NotFound) { call, status ->
            call.respond(
                status,
                ErrorResponse("NOT_FOUND", "The requested resource was not found")
            )
        }
        
        status(HttpStatusCode.Unauthorized) { call, status ->
            call.respond(
                status,
                ErrorResponse("UNAUTHORIZED", "Authentication required")
            )
        }
    }
}