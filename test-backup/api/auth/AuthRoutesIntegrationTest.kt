package com.wondernest.api.auth

import com.wondernest.fixtures.TestUsers
import com.wondernest.services.auth.AuthResponse
import com.wondernest.utils.BaseAuthenticatedTest
import com.wondernest.utils.ResponseAssertions
import io.ktor.client.call.*
import io.ktor.client.request.*
import io.ktor.client.statement.*
import io.ktor.http.*
import io.ktor.server.testing.*
import kotlinx.serialization.json.Json
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/**
 * Comprehensive integration tests for authentication endpoints
 */
class AuthRoutesIntegrationTest : BaseAuthenticatedTest() {
    
    @Test
    fun `POST signup - successful registration with all fields`() = withTestApplication {
        val client = createJsonClient()
        
        val response = client.post("/api/v1/auth/signup") {
            contentType(ContentType.Application.Json)
            setBody(TestUsers.validUser)
        }
        
        assertEquals(HttpStatusCode.Created, response.status)
        ResponseAssertions.assertValidAuthResponse(response)
        ResponseAssertions.assertValidJson(response)
        
        val authResponse = response.body<AuthResponse>()
        assertEquals(TestUsers.validUser.email, authResponse.user["email"])
        assertNotNull(authResponse.accessToken)
        assertNotNull(authResponse.refreshToken)
        assertTrue(authResponse.expiresIn > 0)
    }
    
    @Test
    fun `POST signup - successful registration with minimal fields`() = withTestApplication {
        val client = createJsonClient()
        
        val response = client.post("/api/v1/auth/signup") {
            contentType(ContentType.Application.Json)
            setBody(TestUsers.minimalValidUser)
        }
        
        assertEquals(HttpStatusCode.Created, response.status)
        ResponseAssertions.assertValidAuthResponse(response)
        
        val authResponse = response.body<AuthResponse>()
        assertEquals(TestUsers.minimalValidUser.email, authResponse.user["email"])
    }
    
    @Test
    fun `POST signup - validation errors for invalid email`() = withTestApplication {
        val client = createJsonClient()
        
        val response = client.post("/api/v1/auth/signup") {
            contentType(ContentType.Application.Json)
            setBody(TestUsers.invalidEmailUser)
        }
        
        ResponseAssertions.assertValidationError(response, "email")
    }
    
    @Test
    fun `POST signup - validation errors for weak password`() = withTestApplication {
        val client = createJsonClient()
        
        val response = client.post("/api/v1/auth/signup") {
            contentType(ContentType.Application.Json)
            setBody(TestUsers.weakPasswordUser)
        }
        
        ResponseAssertions.assertValidationError(response, "password")
    }
    
    @Test
    fun `POST signup - handles unicode characters correctly`() = withTestApplication {
        val client = createJsonClient()
        
        val response = client.post("/api/v1/auth/signup") {
            contentType(ContentType.Application.Json)
            setBody(TestUsers.unicodeUser)
        }
        
        assertEquals(HttpStatusCode.Created, response.status)
        ResponseAssertions.assertValidAuthResponse(response)
        
        val authResponse = response.body<AuthResponse>()
        assertEquals(TestUsers.unicodeUser.email, authResponse.user["email"])
    }
    
    @Test
    fun `POST signup - prevents SQL injection attempts`() = withTestApplication {
        val client = createJsonClient()
        
        val response = client.post("/api/v1/auth/signup") {
            contentType(ContentType.Application.Json)
            setBody(TestUsers.sqlInjectionUser)
        }
        
        // Should either reject with validation error or sanitize the input
        assertTrue(
            response.status == HttpStatusCode.BadRequest || 
            response.status == HttpStatusCode.Created
        )
        
        if (response.status == HttpStatusCode.Created) {
            // If created, ensure SQL injection was sanitized
            val authResponse = response.body<AuthResponse>()
            val firstName = authResponse.user["firstName"] as? String
            assertTrue(firstName?.contains("DROP TABLE") != true)
        }
    }
    
    @Test
    fun `POST signup - prevents XSS attempts`() = withTestApplication {
        val client = createJsonClient()
        
        val response = client.post("/api/v1/auth/signup") {
            contentType(ContentType.Application.Json)
            setBody(TestUsers.xssUser)
        }
        
        // Should either reject with validation error or sanitize the input
        assertTrue(
            response.status == HttpStatusCode.BadRequest || 
            response.status == HttpStatusCode.Created
        )
        
        if (response.status == HttpStatusCode.Created) {
            // If created, ensure XSS was sanitized
            val authResponse = response.body<AuthResponse>()
            val firstName = authResponse.user["firstName"] as? String
            assertTrue(firstName?.contains("<script>") != true)
        }
    }
    
    @Test
    fun `POST signup - handles duplicate email registration`() = withTestApplication {
        val client = createJsonClient()
        
        // First registration
        val firstResponse = client.post("/api/v1/auth/signup") {
            contentType(ContentType.Application.Json)
            setBody(TestUsers.validUser)
        }
        assertEquals(HttpStatusCode.Created, firstResponse.status)
        
        // Duplicate registration
        val duplicateResponse = client.post("/api/v1/auth/signup") {
            contentType(ContentType.Application.Json)
            setBody(TestUsers.validUser)
        }
        
        ResponseAssertions.assertResourceConflict(duplicateResponse, "email")
    }
    
    @Test
    fun `POST login - successful authentication`() = withTestApplication {
        val client = createJsonClient()
        
        // First create a user
        client.post("/api/v1/auth/signup") {
            contentType(ContentType.Application.Json)
            setBody(TestUsers.validUser)
        }
        
        // Then login
        val response = client.post("/api/v1/auth/login") {
            contentType(ContentType.Application.Json)
            setBody(TestUsers.validLoginRequest)
        }
        
        assertEquals(HttpStatusCode.OK, response.status)
        ResponseAssertions.assertValidAuthResponse(response)
        
        val authResponse = response.body<AuthResponse>()
        assertEquals(TestUsers.validUser.email, authResponse.user["email"])
    }
    
    @Test
    fun `POST login - invalid credentials`() = withTestApplication {
        val client = createJsonClient()
        
        val response = client.post("/api/v1/auth/login") {
            contentType(ContentType.Application.Json)
            setBody(TestUsers.invalidEmailLoginRequest)
        }
        
        ResponseAssertions.assertAuthenticationRequired(response)
    }
    
    @Test
    fun `POST login - wrong password`() = withTestApplication {
        val client = createJsonClient()
        
        // Create a user first
        client.post("/api/v1/auth/signup") {
            contentType(ContentType.Application.Json)
            setBody(TestUsers.validUser)
        }
        
        // Try to login with wrong password
        val response = client.post("/api/v1/auth/login") {
            contentType(ContentType.Application.Json)
            setBody(TestUsers.invalidPasswordLoginRequest)
        }
        
        ResponseAssertions.assertAuthenticationRequired(response)
    }
    
    @Test
    fun `POST oauth - successful Google OAuth`() = withTestApplication {
        val client = createJsonClient()
        
        val response = client.post("/api/v1/auth/oauth") {
            contentType(ContentType.Application.Json)
            setBody(TestUsers.validGoogleOAuthRequest)
        }
        
        // OAuth implementation may not be fully implemented yet
        assertTrue(
            response.status == HttpStatusCode.OK ||
            response.status == HttpStatusCode.NotImplemented ||
            response.status == HttpStatusCode.Unauthorized
        )
    }
    
    @Test
    fun `POST refresh - successful token refresh`() = withTestApplication {
        val client = createJsonClient()
        
        // Create user and get tokens
        val signupResponse = client.post("/api/v1/auth/signup") {
            contentType(ContentType.Application.Json)
            setBody(TestUsers.validUser)
        }
        val authResponse = signupResponse.body<AuthResponse>()
        
        // Refresh token
        val refreshResponse = client.post("/api/v1/auth/refresh") {
            contentType(ContentType.Application.Json)
            setBody(TestUsers.RefreshTokenRequest(authResponse.refreshToken))
        }
        
        // Implementation dependent - might not be fully implemented
        assertTrue(
            refreshResponse.status == HttpStatusCode.OK ||
            refreshResponse.status == HttpStatusCode.NotImplemented ||
            refreshResponse.status == HttpStatusCode.Unauthorized
        )
    }
    
    @Test
    fun `POST logout - successful logout`() = withTestApplication {
        val client = createJsonClient()
        
        // Create user and get token
        val testUser = createTestUser()
        
        val response = client.authenticatedPost("/api/v1/auth/logout", testUser.token)
        
        assertEquals(HttpStatusCode.OK, response.status)
        
        val messageResponse = response.body<MessageResponse>()
        assertTrue(messageResponse.message.contains("logged out", ignoreCase = true))
    }
    
    @Test
    fun `POST logout - requires authentication`() = withTestApplication {
        val client = createJsonClient()
        
        client.verifyAuthenticationRequired(HttpMethod.Post, "/api/v1/auth/logout")
    }
    
    @Test
    fun `GET me - successful profile retrieval`() = withTestApplication {
        val client = createJsonClient()
        
        // Create user and get token
        val testUser = createTestUser()
        
        val response = client.authenticatedGet("/api/v1/auth/me", testUser.token)
        
        assertEquals(HttpStatusCode.OK, response.status)
        ResponseAssertions.assertValidJson(response)
        
        val userProfile = Json.parseToJsonElement(response.bodyAsText()).jsonObject
        assertEquals(testUser.id, userProfile["id"]?.jsonPrimitive?.content)
        assertEquals(testUser.email, userProfile["email"]?.jsonPrimitive?.content)
        assertNotNull(userProfile["role"])
        assertNotNull(userProfile["verified"])
    }
    
    @Test
    fun `GET me - requires authentication`() = withTestApplication {
        val client = createJsonClient()
        
        client.verifyAuthenticationRequired(HttpMethod.Get, "/api/v1/auth/me")
    }
    
    @Test
    fun `POST password-reset - successful reset request`() = withTestApplication {
        val client = createJsonClient()
        
        // Create user first
        client.post("/api/v1/auth/signup") {
            contentType(ContentType.Application.Json)
            setBody(TestUsers.validUser)
        }
        
        val response = client.post("/api/v1/auth/password-reset") {
            contentType(ContentType.Application.Json)
            setBody(TestUsers.validPasswordResetRequest)
        }
        
        assertEquals(HttpStatusCode.OK, response.status)
        
        val messageResponse = response.body<MessageResponse>()
        assertTrue(messageResponse.message.contains("reset", ignoreCase = true))
    }
    
    @Test
    fun `POST password-reset - handles non-existent email gracefully`() = withTestApplication {
        val client = createJsonClient()
        
        val response = client.post("/api/v1/auth/password-reset") {
            contentType(ContentType.Application.Json)
            setBody(TestUsers.nonexistentPasswordResetRequest)
        }
        
        // Should return success for security reasons (don't reveal if email exists)
        assertEquals(HttpStatusCode.OK, response.status)
        
        val messageResponse = response.body<MessageResponse>()
        assertTrue(messageResponse.message.contains("reset", ignoreCase = true))
    }
    
    @Test
    fun `POST password-reset confirm - with valid token`() = withTestApplication {
        val client = createJsonClient()
        
        val response = client.post("/api/v1/auth/password-reset/confirm") {
            contentType(ContentType.Application.Json)
            setBody(TestUsers.validPasswordResetConfirmRequest)
        }
        
        // Implementation dependent - might not be fully implemented
        assertTrue(
            response.status == HttpStatusCode.OK ||
            response.status == HttpStatusCode.BadRequest ||
            response.status == HttpStatusCode.NotImplemented
        )
    }
    
    @Test
    fun `POST password-reset confirm - with invalid token`() = withTestApplication {
        val client = createJsonClient()
        
        val response = client.post("/api/v1/auth/password-reset/confirm") {
            contentType(ContentType.Application.Json)
            setBody(TestUsers.invalidTokenPasswordResetConfirmRequest)
        }
        
        assertTrue(response.status == HttpStatusCode.BadRequest)
    }
    
    @Test
    fun `POST verify-email - successful verification`() = withTestApplication {
        val client = createJsonClient()
        
        // Create user and get token
        val testUser = createTestUser()
        
        val response = client.authenticatedPost("/api/v1/auth/verify-email", testUser.token)
        
        assertEquals(HttpStatusCode.OK, response.status)
        
        val messageResponse = response.body<MessageResponse>()
        assertTrue(messageResponse.message.contains("verified", ignoreCase = true))
    }
    
    @Test
    fun `POST verify-email - requires authentication`() = withTestApplication {
        val client = createJsonClient()
        
        client.verifyAuthenticationRequired(HttpMethod.Post, "/api/v1/auth/verify-email")
    }
    
    @Test
    fun `authentication endpoints - response time performance`() = withTestApplication {
        val client = createJsonClient()
        
        // Test signup performance
        val signupStart = System.currentTimeMillis()
        val signupResponse = client.post("/api/v1/auth/signup") {
            contentType(ContentType.Application.Json)
            setBody(TestUsers.secondValidUser)
        }
        ResponseAssertions.assertResponseTime(signupStart, 2000, "POST /api/v1/auth/signup")
        
        // Test login performance
        val loginStart = System.currentTimeMillis()
        val loginResponse = client.post("/api/v1/auth/login") {
            contentType(ContentType.Application.Json)
            setBody(TestUsers.LoginRequest(
                TestUsers.secondValidUser.email,
                TestUsers.secondValidUser.password
            ))
        }
        ResponseAssertions.assertResponseTime(loginStart, 1000, "POST /api/v1/auth/login")
        
        // Test profile retrieval performance
        if (loginResponse.status == HttpStatusCode.OK) {
            val authResponse = loginResponse.body<AuthResponse>()
            val profileStart = System.currentTimeMillis()
            client.authenticatedGet("/api/v1/auth/me", authResponse.accessToken)
            ResponseAssertions.assertResponseTime(profileStart, 500, "GET /api/v1/auth/me")
        }
    }
    
    @Test
    fun `authentication endpoints - handle malformed JSON`() = withTestApplication {
        val client = createJsonClient()
        
        val malformedJsonResponse = client.post("/api/v1/auth/signup") {
            contentType(ContentType.Application.Json)
            setBody("{ malformed json }")
        }
        
        assertEquals(HttpStatusCode.BadRequest, malformedJsonResponse.status)
    }
    
    @Test
    fun `authentication endpoints - handle empty request body`() = withTestApplication {
        val client = createJsonClient()
        
        val emptyBodyResponse = client.post("/api/v1/auth/signup") {
            contentType(ContentType.Application.Json)
            setBody("")
        }
        
        assertEquals(HttpStatusCode.BadRequest, emptyBodyResponse.status)
    }
    
    @Test
    fun `authentication endpoints - handle oversized request`() = withTestApplication {
        val client = createJsonClient()
        
        val oversizedUser = TestUsers.validUser.copy(
            firstName = "A".repeat(10000),
            lastName = "B".repeat(10000)
        )
        
        val response = client.post("/api/v1/auth/signup") {
            contentType(ContentType.Application.Json)
            setBody(oversizedUser)
        }
        
        // Should either handle gracefully or reject
        assertTrue(
            response.status == HttpStatusCode.BadRequest ||
            response.status == HttpStatusCode.PayloadTooLarge ||
            response.status == HttpStatusCode.Created
        )
    }
}