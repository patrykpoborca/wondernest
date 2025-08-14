package com.wondernest

import com.auth0.jwt.JWT
import com.auth0.jwt.algorithms.Algorithm
import com.wondernest.api.auth.authRoutes
import com.wondernest.api.family.familyRoutes
import com.wondernest.api.content.contentRoutes
import com.wondernest.api.analytics.analyticsRoutes
import com.wondernest.services.auth.AuthService
import com.wondernest.services.auth.JwtService
import com.wondernest.services.family.FamilyService
import io.ktor.serialization.kotlinx.json.*
import io.ktor.server.application.*
import io.ktor.server.auth.*
import io.ktor.server.auth.jwt.*
import io.ktor.server.plugins.contentnegotiation.*
import io.ktor.server.routing.*

/**
 * Comprehensive test application configuration
 * Provides reusable configuration for all endpoint tests
 */

/**
 * Configure test application with all necessary plugins and routes
 */
fun Application.configureTestApplication(
    authService: AuthService? = null,
    familyService: FamilyService? = null,
    jwtService: JwtService = JwtService()
) {
    // Install content negotiation for JSON handling
    install(ContentNegotiation) {
        json()
    }
    
    // Install JWT authentication
    install(Authentication) {
        jwt("auth-jwt") {
            realm = jwtService.realm
            verifier(
                JWT.require(Algorithm.HMAC256(jwtService.secret))
                    .withIssuer(jwtService.issuer)
                    .build()
            )
            validate { credential ->
                if (credential.payload.getClaim("userId").asString() != null) {
                    JWTPrincipal(credential.payload)
                } else null
            }
        }
    }

    // Configure routing with all API endpoints
    routing {
        route("/api/v1") {
            // Only include routes if their dependencies are provided
            if (authService != null) {
                authRoutes()
            }
            
            if (familyService != null) {
                familyRoutes()
            }
            
            // Content and analytics routes don't require additional services (they use mock data)
            contentRoutes()
            analyticsRoutes()
            
            // Health check endpoint for testing
            get("/health") {
                call.respond(io.ktor.http.HttpStatusCode.OK, mapOf("status" to "healthy"))
            }
        }
    }
}

/**
 * Test configuration constants
 */
object TestConfig {
    const val TEST_JWT_SECRET = "test-jwt-secret-key-for-testing-only-do-not-use-in-production"
    const val TEST_JWT_ISSUER = "wondernest-test-api"
    const val TEST_JWT_AUDIENCE = "wondernest-test-users"
    const val TEST_JWT_REALM = "WonderNest Test API"
    
    /**
     * Create a test JWT service with consistent configuration
     */
    fun createTestJwtService(): JwtService {
        System.setProperty("JWT_SECRET", TEST_JWT_SECRET)
        System.setProperty("JWT_ISSUER", TEST_JWT_ISSUER)
        System.setProperty("JWT_AUDIENCE", TEST_JWT_AUDIENCE)
        System.setProperty("JWT_REALM", TEST_JWT_REALM)
        System.setProperty("JWT_EXPIRES_IN", "3600000") // 1 hour
        System.setProperty("JWT_REFRESH_EXPIRES_IN", "2592000000") // 30 days
        
        return JwtService()
    }
    
    /**
     * Common test URLs and endpoints
     */
    object Endpoints {
        const val AUTH_PARENT_REGISTER = "/api/v1/auth/parent/register"
        const val AUTH_PARENT_LOGIN = "/api/v1/auth/parent/login"
        const val AUTH_PARENT_VERIFY_PIN = "/api/v1/auth/parent/verify-pin"
        const val FAMILY_PROFILE = "/api/v1/family/profile"
        const val FAMILY_CHILDREN = "/api/v1/family/children"
        const val CONTENT = "/api/v1/content"
        const val ANALYTICS_DAILY = "/api/v1/analytics/daily"
        const val ANALYTICS_WEEKLY = "/api/v1/analytics/weekly"
        const val HEALTH = "/api/v1/health"
    }
    
    /**
     * Common test data
     */
    object TestData {
        const val TEST_EMAIL = "test@wondernest.app"
        const val TEST_PASSWORD = "TestPassword123"
        const val TEST_CHILD_NAME = "Test Child"
        const val TEST_FAMILY_NAME = "Test Family"
        const val DEFAULT_PIN = "1234"
    }
}

/**
 * Extension functions for common test operations
 */
fun String.toBearerToken(): String = "Bearer $this"

/**
 * Common assertions for API responses
 */
object ApiAssertions {
    
    /**
     * Assert that response contains required fields for authentication
     */
    fun assertAuthResponse(responseJson: kotlinx.serialization.json.JsonObject) {
        val requiredFields = setOf("user", "accessToken", "refreshToken", "expiresIn")
        requiredFields.forEach { field ->
            assert(responseJson.containsKey(field)) {
                "Auth response missing required field: $field"
            }
        }
    }
    
    /**
     * Assert that response contains required fields for pagination
     */
    fun assertPaginatedResponse(responseJson: kotlinx.serialization.json.JsonObject) {
        val requiredFields = setOf("items", "totalItems", "currentPage", "totalPages")
        requiredFields.forEach { field ->
            assert(responseJson.containsKey(field)) {
                "Paginated response missing required field: $field"
            }
        }
    }
    
    /**
     * Assert that error response has proper structure
     */
    fun assertErrorResponse(responseJson: kotlinx.serialization.json.JsonObject) {
        assert(responseJson.containsKey("message") || responseJson.containsKey("error")) {
            "Error response should contain 'message' or 'error' field"
        }
    }
}