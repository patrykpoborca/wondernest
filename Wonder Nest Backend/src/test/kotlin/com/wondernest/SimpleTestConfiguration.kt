package com.wondernest

import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import io.ktor.server.testing.*
import com.wondernest.config.configureSerialization
import com.wondernest.config.configureHTTP
import com.wondernest.config.configureSecurity

/**
 * Simple test configuration for WonderNest Backend
 * Provides a minimal working test setup without external dependencies
 */
fun Application.simpleTestModule() {
    // Configure basic KTOR features without external dependencies
    configureSerialization()
    configureHTTP()
    configureSecurity()
    
    // Configure minimal routing for testing
    routing {
        // Basic health check endpoint that doesn't require dependencies
        get("/health") {
            call.respond(HttpStatusCode.OK, mapOf("status" to "healthy"))
        }
        
        // Ready endpoint for testing
        get("/ready") {
            call.respond(HttpStatusCode.OK, mapOf("status" to "ready"))
        }
    }
}

/**
 * Creates a simple test application
 */
fun simpleTestApplication(test: suspend ApplicationTestBuilder.() -> Unit) = 
    testApplication {
        application {
            simpleTestModule()
        }
        test()
    }