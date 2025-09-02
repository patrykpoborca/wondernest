package com.wondernest.config

import com.wondernest.api.analytics.analyticsRoutes
import com.wondernest.api.audio.audioRoutes
import com.wondernest.api.auth.authRoutes
import com.wondernest.api.content.contentRoutes
import com.wondernest.api.coppa.coppaRoutes
import com.wondernest.api.family.familyRoutes
import com.wondernest.api.fileUploadRoutes
import com.wondernest.server.api.fileRoutes
import com.wondernest.api.games.gameDataRoutes
import com.wondernest.api.games.enhancedGameRoutes
import com.wondernest.api.games.storyAdventureRoutes
import com.wondernest.api.health.healthRoutes
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.http.content.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import io.micrometer.prometheus.PrometheusMeterRegistry
import java.io.File

fun Application.configureRouting() {
    routing {
        // OpenAPI and Swagger UI endpoints
        get("/openapi.yaml") {
            val openApiSpec = this@configureRouting::class.java.classLoader.getResourceAsStream("openapi.yaml")
            if (openApiSpec != null) {
                call.respondText(openApiSpec.bufferedReader().use { it.readText() }, ContentType.Text.Plain)
            } else {
                call.respond(HttpStatusCode.NotFound, "OpenAPI specification not found")
            }
        }
        
        get("/swagger") {
            call.respondText(
                """
                <!DOCTYPE html>
                <html>
                <head>
                    <title>WonderNest API Documentation</title>
                    <link rel="stylesheet" type="text/css" href="https://unpkg.com/swagger-ui-dist@4.15.5/swagger-ui.css" />
                </head>
                <body>
                    <div id="swagger-ui"></div>
                    <script src="https://unpkg.com/swagger-ui-dist@4.15.5/swagger-ui-bundle.js"></script>
                    <script src="https://unpkg.com/swagger-ui-dist@4.15.5/swagger-ui-standalone-preset.js"></script>
                    <script>
                        SwaggerUIBundle({
                            url: '/openapi.yaml',
                            dom_id: '#swagger-ui',
                            presets: [
                                SwaggerUIBundle.presets.apis,
                                SwaggerUIStandalonePreset
                            ],
                            layout: "StandaloneLayout"
                        });
                    </script>
                </body>
                </html>
                """.trimIndent(),
                ContentType.Text.Html
            )
        }
        
        // Static file serving for uploads
        staticFiles("/files", File("uploads")) {
            // Optional: Add CORS headers for file serving
            default("index.html")
            enableAutoHeadResponse()
        }
        
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
            coppaRoutes()
            fileUploadRoutes()         // File upload routes
            gameDataRoutes()           // Legacy game data routes (SimpleGameData)
        }
        
        // API v2 routes with proper game architecture
        route("/api/v2") {
            authRoutes()                // Reuse auth for v2
            gameDataRoutes()            // Standard game data routes (plugin architecture)
            enhancedGameRoutes()        // Legacy enhanced routes
            fileRoutes()                // Enhanced file routes with tagging
        }
        
        // Story Adventure routes (includes both standard plugin routes and platform-specific routes)
        storyAdventureRoutes()
    }
}