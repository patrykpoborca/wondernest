package com.wondernest.utils

import com.wondernest.services.auth.AuthResponse
import com.wondernest.services.auth.LoginRequest
import com.wondernest.services.auth.SignupRequest
import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.request.*
import io.ktor.http.*
import io.ktor.server.testing.*
import org.junit.jupiter.api.BeforeEach

/**
 * Base class for tests that require authentication
 */
abstract class BaseAuthenticatedTest : BaseIntegrationTest() {
    
    protected var validToken: String = ""
    protected var testUser: TestUser? = null
    
    data class TestUser(
        val id: String,
        val email: String,
        val token: String,
        val refreshToken: String
    )
    
    @BeforeEach
    override fun setUp() {
        super.setUp()
        // Create a test user and get authentication token
        // This will be overridden by tests that need specific user setup
    }
    
    /**
     * Creates a test user and returns authentication details
     */
    protected suspend fun ApplicationTestBuilder.createTestUser(
        email: String = "test@example.com",
        password: String = "TestPassword123!",
        firstName: String = "Test",
        lastName: String = "User"
    ): TestUser {
        val client = createJsonClient()
        
        val signupRequest = SignupRequest(
            email = email,
            password = password,
            firstName = firstName,
            lastName = lastName,
            timezone = "UTC",
            language = "en"
        )
        
        val signupResponse = client.post("/api/v1/auth/signup") {
            contentType(ContentType.Application.Json)
            setBody(signupRequest)
        }
        
        if (signupResponse.status == HttpStatusCode.Created) {
            val authResponse = signupResponse.body<AuthResponse>()
            return TestUser(
                id = authResponse.user["id"] as String,
                email = authResponse.user["email"] as String,
                token = authResponse.accessToken,
                refreshToken = authResponse.refreshToken
            )
        } else {
            // Try login if user already exists
            val loginRequest = LoginRequest(email = email, password = password)
            val loginResponse = client.post("/api/v1/auth/login") {
                contentType(ContentType.Application.Json)
                setBody(loginRequest)
            }
            
            val authResponse = loginResponse.body<AuthResponse>()
            return TestUser(
                id = authResponse.user["id"] as String,
                email = authResponse.user["email"] as String,
                token = authResponse.accessToken,
                refreshToken = authResponse.refreshToken
            )
        }
    }
    
    /**
     * Creates a test user with minimal setup
     */
    protected suspend fun ApplicationTestBuilder.createMinimalTestUser(): TestUser {
        return createTestUser(
            email = "minimal@example.com",
            password = "MinimalPass123!"
        )
    }
    
    /**
     * Creates multiple test users for testing scenarios
     */
    protected suspend fun ApplicationTestBuilder.createTestUsers(count: Int): List<TestUser> {
        return (1..count).map { index ->
            createTestUser(
                email = "user$index@example.com",
                password = "TestPass123!",
                firstName = "User",
                lastName = index.toString()
            )
        }
    }
    
    /**
     * Gets an expired JWT token for testing
     */
    protected fun getExpiredToken(): String {
        // This would normally be generated with an expired timestamp
        return "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.expired.token"
    }
    
    /**
     * Gets an invalid JWT token for testing
     */
    protected fun getInvalidToken(): String {
        return "invalid.jwt.token"
    }
    
    /**
     * Gets a malformed JWT token for testing
     */
    protected fun getMalformedToken(): String {
        return "not-a-jwt-token-at-all"
    }
    
    /**
     * Creates authentication headers
     */
    protected fun createAuthHeaders(token: String): Map<String, String> {
        return mapOf(HttpHeaders.Authorization to "Bearer $token")
    }
    
    /**
     * Test helper to verify authentication requirements
     */
    protected suspend fun HttpClient.verifyAuthenticationRequired(
        method: HttpMethod,
        path: String,
        body: Any? = null
    ) {
        // Test without token
        val noTokenResponse = request(path) {
            this.method = method
            if (body != null) {
                contentType(ContentType.Application.Json)
                setBody(body)
            }
        }
        assert(noTokenResponse.status == HttpStatusCode.Unauthorized) {
            "Expected 401 Unauthorized for request without token, got ${noTokenResponse.status}"
        }
        
        // Test with invalid token
        val invalidTokenResponse = request(path) {
            this.method = method
            header(HttpHeaders.Authorization, "Bearer ${getInvalidToken()}")
            if (body != null) {
                contentType(ContentType.Application.Json)
                setBody(body)
            }
        }
        assert(invalidTokenResponse.status == HttpStatusCode.Unauthorized) {
            "Expected 401 Unauthorized for request with invalid token, got ${invalidTokenResponse.status}"
        }
        
        // Test with malformed token
        val malformedTokenResponse = request(path) {
            this.method = method
            header(HttpHeaders.Authorization, "Bearer ${getMalformedToken()}")
            if (body != null) {
                contentType(ContentType.Application.Json)
                setBody(body)
            }
        }
        assert(malformedTokenResponse.status == HttpStatusCode.Unauthorized) {
            "Expected 401 Unauthorized for request with malformed token, got ${malformedTokenResponse.status}"
        }
    }
}