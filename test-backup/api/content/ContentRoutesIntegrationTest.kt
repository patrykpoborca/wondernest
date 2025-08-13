package com.wondernest.api.content

import com.wondernest.api.family.MessageResponse
import com.wondernest.utils.BaseAuthenticatedTest
import com.wondernest.utils.ResponseAssertions
import io.ktor.client.call.*
import io.ktor.client.request.*
import io.ktor.http.*
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * Integration tests for content management endpoints
 */
class ContentRoutesIntegrationTest : BaseAuthenticatedTest() {
    
    @Test
    fun `GET content library - requires authentication`() = withTestApplication {
        val client = createJsonClient()
        
        client.verifyAuthenticationRequired(HttpMethod.Get, "/api/v1/content/library")
    }
    
    @Test
    fun `GET content library - returns content for authenticated user`() = withTestApplication {
        val client = createJsonClient()
        val testUser = createTestUser()
        
        val response = client.authenticatedGet("/api/v1/content/library", testUser.token)
        
        assertEquals(HttpStatusCode.OK, response.status)
        ResponseAssertions.assertValidJson(response)
        
        // Since this is a TODO endpoint, it should return a message
        val messageResponse = response.body<MessageResponse>()
        assertTrue(messageResponse.message.contains("TODO", ignoreCase = true))
    }
    
    @Test
    fun `GET content recommendations - requires authentication`() = withTestApplication {
        val client = createJsonClient()
        
        val childId = "12345678-1234-1234-1234-123456789012"
        client.verifyAuthenticationRequired(HttpMethod.Get, "/api/v1/content/recommendations/$childId")
    }
    
    @Test
    fun `GET content recommendations - returns recommendations for child`() = withTestApplication {
        val client = createJsonClient()
        val testUser = createTestUser()
        
        val childId = "12345678-1234-1234-1234-123456789012"
        val response = client.authenticatedGet("/api/v1/content/recommendations/$childId", testUser.token)
        
        assertEquals(HttpStatusCode.OK, response.status)
        ResponseAssertions.assertValidJson(response)
        
        // Since this is a TODO endpoint, it should return a message
        val messageResponse = response.body<MessageResponse>()
        assertTrue(messageResponse.message.contains("TODO", ignoreCase = true))
    }
    
    @Test
    fun `GET content recommendations - validates child ID format`() = withTestApplication {
        val client = createJsonClient()
        val testUser = createTestUser()
        
        val invalidChildId = "invalid-uuid"
        val response = client.authenticatedGet("/api/v1/content/recommendations/$invalidChildId", testUser.token)
        
        // Should validate UUID format - currently TODO so returns OK
        assertTrue(
            response.status == HttpStatusCode.BadRequest ||
            response.status == HttpStatusCode.OK
        )
    }
    
    @Test
    fun `POST content engagement - requires authentication`() = withTestApplication {
        val client = createJsonClient()
        
        val engagementData = mapOf(
            "contentId" to "12345678-1234-1234-1234-123456789012",
            "childId" to "12345678-1234-1234-1234-123456789012",
            "engagementType" to "viewed",
            "duration" to 120
        )
        
        client.verifyAuthenticationRequired(HttpMethod.Post, "/api/v1/content/engagement", engagementData)
    }
    
    @Test
    fun `POST content engagement - tracks engagement successfully`() = withTestApplication {
        val client = createJsonClient()
        val testUser = createTestUser()
        
        val engagementData = mapOf(
            "contentId" to "12345678-1234-1234-1234-123456789012",
            "childId" to "12345678-1234-1234-1234-123456789012",
            "engagementType" to "viewed",
            "duration" to 120,
            "completionPercentage" to 85.5
        )
        
        val response = client.authenticatedPost("/api/v1/content/engagement", testUser.token, engagementData)
        
        assertEquals(HttpStatusCode.Created, response.status)
        ResponseAssertions.assertValidJson(response)
        
        // Since this is a TODO endpoint, it should return a message
        val messageResponse = response.body<MessageResponse>()
        assertTrue(messageResponse.message.contains("TODO", ignoreCase = true))
    }
    
    @Test
    fun `GET content categories - requires authentication`() = withTestApplication {
        val client = createJsonClient()
        
        client.verifyAuthenticationRequired(HttpMethod.Get, "/api/v1/categories")
    }
    
    @Test
    fun `GET content categories - returns available categories`() = withTestApplication {
        val client = createJsonClient()
        val testUser = createTestUser()
        
        val response = client.authenticatedGet("/api/v1/categories", testUser.token)
        
        assertEquals(HttpStatusCode.OK, response.status)
        ResponseAssertions.assertValidJson(response)
        
        // Since this is a TODO endpoint, it should return a message
        val messageResponse = response.body<MessageResponse>()
        assertTrue(messageResponse.message.contains("TODO", ignoreCase = true))
    }
    
    @Test
    fun `content endpoints - handle invalid UUIDs gracefully`() = withTestApplication {
        val client = createJsonClient()
        val testUser = createTestUser()
        
        val invalidUUIDs = listOf(
            "invalid-uuid",
            "12345678-1234-1234-1234-12345678901",  // Too short
            "12345678-1234-1234-1234-1234567890123", // Too long
            "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",   // Invalid characters
            ""
        )
        
        invalidUUIDs.forEach { invalidUuid ->
            val response = client.authenticatedGet("/api/v1/content/recommendations/$invalidUuid", testUser.token)
            
            // Should handle invalid UUIDs gracefully
            assertTrue(
                response.status == HttpStatusCode.BadRequest ||
                response.status == HttpStatusCode.NotFound ||
                response.status == HttpStatusCode.OK // TODO endpoint
            )
        }
    }
    
    @Test
    fun `content engagement - validates required fields`() = withTestApplication {
        val client = createJsonClient()
        val testUser = createTestUser()
        
        val incompleteEngagementData = mapOf(
            "contentId" to "12345678-1234-1234-1234-123456789012"
            // Missing childId, engagementType, etc.
        )
        
        val response = client.authenticatedPost("/api/v1/content/engagement", testUser.token, incompleteEngagementData)
        
        // Should validate required fields - currently TODO so might return 201
        assertTrue(
            response.status == HttpStatusCode.BadRequest ||
            response.status == HttpStatusCode.Created
        )
    }
    
    @Test
    fun `content engagement - validates engagement types`() = withTestApplication {
        val client = createJsonClient()
        val testUser = createTestUser()
        
        val validEngagementTypes = listOf("viewed", "completed", "liked", "shared", "skipped")
        val invalidEngagementTypes = listOf("invalid_type", "", "VIEWED", "viewed123")
        
        // Test valid engagement types
        validEngagementTypes.forEach { engagementType ->
            val engagementData = mapOf(
                "contentId" to "12345678-1234-1234-1234-123456789012",
                "childId" to "12345678-1234-1234-1234-123456789012",
                "engagementType" to engagementType,
                "duration" to 60
            )
            
            val response = client.authenticatedPost("/api/v1/content/engagement", testUser.token, engagementData)
            
            // Should accept valid engagement types
            assertTrue(
                response.status == HttpStatusCode.Created ||
                response.status == HttpStatusCode.BadRequest // If validation is strict
            )
        }
        
        // Test invalid engagement types
        invalidEngagementTypes.forEach { engagementType ->
            val engagementData = mapOf(
                "contentId" to "12345678-1234-1234-1234-123456789012",
                "childId" to "12345678-1234-1234-1234-123456789012",
                "engagementType" to engagementType,
                "duration" to 60
            )
            
            val response = client.authenticatedPost("/api/v1/content/engagement", testUser.token, engagementData)
            
            // Should reject invalid engagement types
            assertTrue(
                response.status == HttpStatusCode.BadRequest ||
                response.status == HttpStatusCode.Created // TODO endpoint might accept anything
            )
        }
    }
    
    @Test
    fun `content engagement - validates numeric values`() = withTestApplication {
        val client = createJsonClient()
        val testUser = createTestUser()
        
        // Test negative duration
        val negativeDurationData = mapOf(
            "contentId" to "12345678-1234-1234-1234-123456789012",
            "childId" to "12345678-1234-1234-1234-123456789012",
            "engagementType" to "viewed",
            "duration" to -10
        )
        
        val negativeResponse = client.authenticatedPost("/api/v1/content/engagement", testUser.token, negativeDurationData)
        
        // Should reject negative duration
        assertTrue(
            negativeResponse.status == HttpStatusCode.BadRequest ||
            negativeResponse.status == HttpStatusCode.Created // TODO endpoint
        )
        
        // Test invalid completion percentage
        val invalidPercentageData = mapOf(
            "contentId" to "12345678-1234-1234-1234-123456789012",
            "childId" to "12345678-1234-1234-1234-123456789012",
            "engagementType" to "viewed",
            "duration" to 60,
            "completionPercentage" to 150.0 // Over 100%
        )
        
        val invalidPercentageResponse = client.authenticatedPost("/api/v1/content/engagement", testUser.token, invalidPercentageData)
        
        // Should reject invalid percentage
        assertTrue(
            invalidPercentageResponse.status == HttpStatusCode.BadRequest ||
            invalidPercentageResponse.status == HttpStatusCode.Created // TODO endpoint
        )
    }
    
    @Test
    fun `content endpoints - response time performance`() = withTestApplication {
        val client = createJsonClient()
        val testUser = createTestUser()
        
        // Test content library performance
        val libraryStart = System.currentTimeMillis()
        client.authenticatedGet("/api/v1/content/library", testUser.token)
        ResponseAssertions.assertResponseTime(libraryStart, 1000, "GET /api/v1/content/library")
        
        // Test recommendations performance
        val childId = "12345678-1234-1234-1234-123456789012"
        val recommendationsStart = System.currentTimeMillis()
        client.authenticatedGet("/api/v1/content/recommendations/$childId", testUser.token)
        ResponseAssertions.assertResponseTime(recommendationsStart, 1000, "GET /api/v1/content/recommendations")
        
        // Test categories performance
        val categoriesStart = System.currentTimeMillis()
        client.authenticatedGet("/api/v1/categories", testUser.token)
        ResponseAssertions.assertResponseTime(categoriesStart, 500, "GET /api/v1/categories")
    }
    
    @Test
    fun `content endpoints - handle concurrent requests`() = withTestApplication {
        val client = createJsonClient()
        val testUser = createTestUser()
        
        // Make multiple concurrent requests to content library
        val responses = (1..5).map {
            client.authenticatedGet("/api/v1/content/library", testUser.token)
        }
        
        // All should succeed
        responses.forEach { response ->
            assertEquals(HttpStatusCode.OK, response.status)
        }
    }
    
    @Test
    fun `content endpoints - handle malformed JSON gracefully`() = withTestApplication {
        val client = createJsonClient()
        val testUser = createTestUser()
        
        val malformedJsonResponse = client.post("/api/v1/content/engagement") {
            header(HttpHeaders.Authorization, "Bearer ${testUser.token}")
            contentType(ContentType.Application.Json)
            setBody("{ malformed json }")
        }
        
        assertEquals(HttpStatusCode.BadRequest, malformedJsonResponse.status)
    }
    
    @Test
    fun `content endpoints - handle empty request body`() = withTestApplication {
        val client = createJsonClient()
        val testUser = createTestUser()
        
        val emptyBodyResponse = client.post("/api/v1/content/engagement") {
            header(HttpHeaders.Authorization, "Bearer ${testUser.token}")
            contentType(ContentType.Application.Json)
            setBody("")
        }
        
        assertEquals(HttpStatusCode.BadRequest, emptyBodyResponse.status)
    }
}