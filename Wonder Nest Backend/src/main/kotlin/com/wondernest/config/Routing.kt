package com.wondernest.config

import com.wondernest.api.analytics.analyticsRoutes
import com.wondernest.api.audio.audioRoutes
import com.wondernest.api.auth.authRoutes
import com.wondernest.api.content.contentRoutes
import com.wondernest.api.coppa.coppaRoutes
import com.wondernest.api.family.familyRoutes
// import com.wondernest.api.games.gameRoutes
import com.wondernest.api.health.healthRoutes
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import io.micrometer.prometheus.PrometheusMeterRegistry

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
            // gameRoutes()
        }
    }
}