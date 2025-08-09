package com.wondernest.config

import com.wondernest.api.analytics.analyticsRoutes
import com.wondernest.api.audio.audioRoutes
import com.wondernest.api.auth.authRoutes
import com.wondernest.api.content.contentRoutes
import com.wondernest.api.family.familyRoutes
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import io.micrometer.prometheus.PrometheusMeterRegistry
import kotlinx.serialization.Serializable

@Serializable
data class HealthResponse(
    val status: String,
    val timestamp: Long = System.currentTimeMillis(),
    val version: String = "0.0.1"
)

fun Application.configureRouting() {
    routing {
        // Health check endpoints
        get("/health") {
            call.respond(HttpStatusCode.OK, HealthResponse("healthy"))
        }
        
        get("/ready") {
            // Add database connectivity check here
            call.respond(HttpStatusCode.OK, HealthResponse("ready"))
        }
        
        // Metrics endpoint
        get("/metrics") {
            val registry = call.application.attributes.getOrNull(MicrometerRegistryKey)
            if (registry != null) {
                call.respondText(registry.scrape(), ContentType.Text.Plain)
            } else {
                call.respond(HttpStatusCode.ServiceUnavailable, "Metrics not available")
            }
        }
        
        // API routes
        route("/api/v1") {
            authRoutes()
            familyRoutes()
            contentRoutes()
            audioRoutes()
            analyticsRoutes()
        }
    }
}