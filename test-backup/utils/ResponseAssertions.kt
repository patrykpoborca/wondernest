package com.wondernest.utils

import com.wondernest.api.auth.MessageResponse
import com.wondernest.services.auth.AuthResponse
import io.ktor.client.call.*
import io.ktor.client.statement.*
import io.ktor.http.*
import kotlinx.serialization.json.Json
import org.junit.jupiter.api.Assertions.*
import java.time.Instant
import java.util.*

/**
 * Utility class for common test assertions
 */
object ResponseAssertions {
    
    /**
     * Asserts that the response is a valid authentication response
     */
    suspend fun assertValidAuthResponse(response: HttpResponse) {
        assertEquals(HttpStatusCode.OK, response.status, "Expected successful auth response")
        
        val authResponse = response.body<AuthResponse>()
        
        // Validate response structure
        assertNotNull(authResponse.user, "User object should not be null")
        assertNotNull(authResponse.accessToken, "Access token should not be null")
        assertNotNull(authResponse.refreshToken, "Refresh token should not be null")
        assertTrue(authResponse.expiresIn > 0, "Expires in should be positive")
        
        // Validate user object
        val user = authResponse.user
        assertNotNull(user["id"], "User ID should not be null")
        assertNotNull(user["email"], "User email should not be null")
        
        // Validate JWT token format (basic check)
        assertTrue(
            authResponse.accessToken.split(".").size == 3,
            "Access token should be a valid JWT format"
        )
        assertTrue(
            authResponse.refreshToken.split(".").size == 3,
            "Refresh token should be a valid JWT format"
        )
    }
    
    /**
     * Asserts that the response is a valid error response
     */
    suspend fun assertErrorResponse(
        response: HttpResponse,
        expectedStatus: HttpStatusCode,
        expectedMessage: String? = null
    ) {
        assertEquals(expectedStatus, response.status, "Expected error status code")
        
        val errorResponse = response.body<MessageResponse>()
        assertNotNull(errorResponse.message, "Error message should not be null")
        
        if (expectedMessage != null) {
            assertTrue(
                errorResponse.message.contains(expectedMessage, ignoreCase = true),
                "Error message should contain '$expectedMessage', got '${errorResponse.message}'"
            )
        }
    }
    
    /**
     * Asserts that the response contains validation errors
     */
    suspend fun assertValidationError(
        response: HttpResponse,
        expectedField: String? = null
    ) {
        assertTrue(
            response.status == HttpStatusCode.BadRequest || 
            response.status == HttpStatusCode.UnprocessableEntity,
            "Expected validation error status (400 or 422), got ${response.status}"
        )
        
        val errorResponse = response.body<MessageResponse>()
        assertNotNull(errorResponse.message, "Validation error message should not be null")
        
        if (expectedField != null) {
            assertTrue(
                errorResponse.message.contains(expectedField, ignoreCase = true),
                "Validation error should mention field '$expectedField', got '${errorResponse.message}'"
            )
        }
    }
    
    /**
     * Asserts that the response indicates authentication is required
     */
    suspend fun assertAuthenticationRequired(response: HttpResponse) {
        assertEquals(
            HttpStatusCode.Unauthorized,
            response.status,
            "Expected 401 Unauthorized for authentication required"
        )
        
        val errorResponse = response.body<MessageResponse>()
        assertTrue(
            errorResponse.message.contains("authentication", ignoreCase = true) ||
            errorResponse.message.contains("unauthorized", ignoreCase = true) ||
            errorResponse.message.contains("token", ignoreCase = true),
            "Error message should indicate authentication issue, got '${errorResponse.message}'"
        )
    }
    
    /**
     * Asserts that the response indicates insufficient permissions
     */
    suspend fun assertInsufficientPermissions(response: HttpResponse) {
        assertEquals(
            HttpStatusCode.Forbidden,
            response.status,
            "Expected 403 Forbidden for insufficient permissions"
        )
        
        val errorResponse = response.body<MessageResponse>()
        assertTrue(
            errorResponse.message.contains("permission", ignoreCase = true) ||
            errorResponse.message.contains("forbidden", ignoreCase = true) ||
            errorResponse.message.contains("access", ignoreCase = true),
            "Error message should indicate permission issue, got '${errorResponse.message}'"
        )
    }
    
    /**
     * Asserts that the response indicates a resource was not found
     */
    suspend fun assertResourceNotFound(response: HttpResponse, resourceType: String? = null) {
        assertEquals(
            HttpStatusCode.NotFound,
            response.status,
            "Expected 404 Not Found for missing resource"
        )
        
        val errorResponse = response.body<MessageResponse>()
        assertTrue(
            errorResponse.message.contains("not found", ignoreCase = true) ||
            errorResponse.message.contains("does not exist", ignoreCase = true),
            "Error message should indicate resource not found, got '${errorResponse.message}'"
        )
        
        if (resourceType != null) {
            assertTrue(
                errorResponse.message.contains(resourceType, ignoreCase = true),
                "Error message should mention resource type '$resourceType', got '${errorResponse.message}'"
            )
        }
    }
    
    /**
     * Asserts that the response indicates a conflict (resource already exists)
     */
    suspend fun assertResourceConflict(response: HttpResponse, resourceType: String? = null) {
        assertEquals(
            HttpStatusCode.Conflict,
            response.status,
            "Expected 409 Conflict for resource conflict"
        )
        
        val errorResponse = response.body<MessageResponse>()
        assertTrue(
            errorResponse.message.contains("already exists", ignoreCase = true) ||
            errorResponse.message.contains("conflict", ignoreCase = true) ||
            errorResponse.message.contains("duplicate", ignoreCase = true),
            "Error message should indicate resource conflict, got '${errorResponse.message}'"
        )
        
        if (resourceType != null) {
            assertTrue(
                errorResponse.message.contains(resourceType, ignoreCase = true),
                "Error message should mention resource type '$resourceType', got '${errorResponse.message}'"
            )
        }
    }
    
    /**
     * Asserts that the response indicates rate limiting
     */
    suspend fun assertRateLimited(response: HttpResponse) {
        assertEquals(
            HttpStatusCode.TooManyRequests,
            response.status,
            "Expected 429 Too Many Requests for rate limiting"
        )
    }
    
    /**
     * Asserts that the response indicates a server error
     */
    suspend fun assertServerError(response: HttpResponse) {
        assertEquals(
            HttpStatusCode.InternalServerError,
            response.status,
            "Expected 500 Internal Server Error"
        )
        
        val errorResponse = response.body<MessageResponse>()
        assertNotNull(errorResponse.message, "Server error message should not be null")
    }
    
    /**
     * Asserts that the response contains valid JSON
     */
    suspend fun assertValidJson(response: HttpResponse) {
        val contentType = response.contentType()
        assertEquals(
            ContentType.Application.Json.withoutParameters(),
            contentType?.withoutParameters(),
            "Response should have JSON content type"
        )
        
        // Try to parse as JSON to ensure it's valid
        try {
            Json.parseToJsonElement(response.bodyAsText())
        } catch (e: Exception) {
            fail("Response body should be valid JSON: ${e.message}")
        }
    }
    
    /**
     * Asserts that a UUID string is valid
     */
    fun assertValidUUID(uuidString: String, fieldName: String = "UUID") {
        try {
            UUID.fromString(uuidString)
        } catch (e: IllegalArgumentException) {
            fail("$fieldName should be a valid UUID: $uuidString")
        }
    }
    
    /**
     * Asserts that a timestamp string is valid
     */
    fun assertValidTimestamp(timestampString: String, fieldName: String = "Timestamp") {
        try {
            Instant.parse(timestampString)
        } catch (e: Exception) {
            fail("$fieldName should be a valid ISO timestamp: $timestampString")
        }
    }
    
    /**
     * Asserts that an email string is valid format
     */
    fun assertValidEmail(email: String, fieldName: String = "Email") {
        val emailRegex = "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        assertTrue(
            email.matches(emailRegex.toRegex()),
            "$fieldName should be a valid email format: $email"
        )
    }
    
    /**
     * Asserts that response time is within acceptable limits
     */
    fun assertResponseTime(startTime: Long, maxMilliseconds: Long, endpoint: String) {
        val responseTime = System.currentTimeMillis() - startTime
        assertTrue(
            responseTime <= maxMilliseconds,
            "$endpoint response time ($responseTime ms) should be under $maxMilliseconds ms"
        )
    }
}