package com.wondernest.config

import com.wondernest.api.analytics.analyticsRoutes
import com.wondernest.api.audio.audioRoutes
import com.wondernest.api.auth.authRoutes
import com.wondernest.api.content.contentRoutes
import com.wondernest.api.family.familyRoutes
import com.wondernest.api.health.healthRoutes
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import io.micrometer.prometheus.PrometheusMeterRegistry

fun Application.configureRouting() {
    routing {
        // Health and monitoring endpoints
        healthRoutes()
        
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