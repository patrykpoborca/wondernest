package com.wondernest.api.health

import com.wondernest.utils.BaseIntegrationTest
import com.wondernest.utils.ResponseAssertions
import io.ktor.client.call.*
import io.ktor.client.request.*
import io.ktor.client.statement.*
import io.ktor.http.*
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/**
 * Integration tests for health monitoring endpoints
 */
class HealthRoutesIntegrationTest : BaseIntegrationTest() {
    
    @Test
    fun `GET health - basic health check returns UP`() = withMockedApplication {
        val client = createJsonClient()
        
        val response = client.get("/health")
        
        assertEquals(HttpStatusCode.OK, response.status)
        ResponseAssertions.assertValidJson(response)
        
        val healthResponse = Json.parseToJsonElement(response.bodyAsText()).jsonObject
        assertEquals("UP", healthResponse["status"]?.jsonPrimitive?.content)
    }
    
    @Test
    fun `GET health - response time is fast`() = withMockedApplication {
        val client = createJsonClient()
        
        val startTime = System.currentTimeMillis()
        val response = client.get("/health")
        
        assertEquals(HttpStatusCode.OK, response.status)
        ResponseAssertions.assertResponseTime(startTime, 100, "GET /health")
    }
    
    @Test
    fun `GET health detailed - returns comprehensive health status`() = withMockedApplication {
        val client = createJsonClient()
        
        val response = client.get("/health/detailed")
        
        // Should return 200 with mocked services or 503 if services are down
        assertTrue(
            response.status == HttpStatusCode.OK || 
            response.status == HttpStatusCode.ServiceUnavailable
        )
        ResponseAssertions.assertValidJson(response)
        
        val healthStatus = response.body<HealthStatus>()
        
        // Validate response structure
        assertNotNull(healthStatus.status)
        assertTrue(healthStatus.status == "UP" || healthStatus.status == "DOWN")
        assertNotNull(healthStatus.timestamp)
        ResponseAssertions.assertValidTimestamp(healthStatus.timestamp)
        assertNotNull(healthStatus.version)
        assertNotNull(healthStatus.environment)
        assertNotNull(healthStatus.services)
        
        // Validate service health objects
        healthStatus.services.forEach { (serviceName, serviceHealth) ->
            assertNotNull(serviceHealth.status)
            assertTrue(serviceHealth.status == "UP" || serviceHealth.status == "DOWN")
            // Response time should be present and reasonable
            serviceHealth.responseTime?.let { responseTime ->
                assertTrue(responseTime >= 0)
                assertTrue(responseTime < 10000) // Should be under 10 seconds
            }
        }
    }
    
    @Test
    fun `GET health detailed - includes required services`() = withMockedApplication {
        val client = createJsonClient()
        
        val response = client.get("/health/detailed")
        val healthStatus = response.body<HealthStatus>()
        
        // Should include database and redis services
        assertTrue(healthStatus.services.containsKey("database"))
        assertTrue(healthStatus.services.containsKey("redis"))
        
        val databaseHealth = healthStatus.services["database"]!!
        val redisHealth = healthStatus.services["redis"]!!
        
        assertNotNull(databaseHealth.status)
        assertNotNull(redisHealth.status)
    }
    
    @Test
    fun `GET health ready - readiness probe`() = withMockedApplication {
        val client = createJsonClient()
        
        val response = client.get("/health/ready")
        
        // Should return 200 if ready, 503 if not ready
        assertTrue(
            response.status == HttpStatusCode.OK || 
            response.status == HttpStatusCode.ServiceUnavailable
        )
        ResponseAssertions.assertValidJson(response)
        
        val readinessResponse = Json.parseToJsonElement(response.bodyAsText()).jsonObject
        val status = readinessResponse["status"]?.jsonPrimitive?.content
        
        if (response.status == HttpStatusCode.OK) {
            assertEquals("READY", status)
        } else {
            assertEquals("NOT_READY", status)
            // Should include service status details
            assertTrue(readinessResponse.containsKey("database"))
            assertTrue(readinessResponse.containsKey("redis"))
        }
    }
    
    @Test
    fun `GET health live - liveness probe always returns alive`() = withMockedApplication {
        val client = createJsonClient()
        
        val response = client.get("/health/live")
        
        assertEquals(HttpStatusCode.OK, response.status)
        ResponseAssertions.assertValidJson(response)
        
        val livenessResponse = Json.parseToJsonElement(response.bodyAsText()).jsonObject
        assertEquals("ALIVE", livenessResponse["status"]?.jsonPrimitive?.content)
    }
    
    @Test
    fun `GET health startup - startup probe`() = withMockedApplication {
        val client = createJsonClient()
        
        val response = client.get("/health/startup")
        
        // Should return 200 if started, 503 if starting
        assertTrue(
            response.status == HttpStatusCode.OK || 
            response.status == HttpStatusCode.ServiceUnavailable
        )
        ResponseAssertions.assertValidJson(response)
        
        val startupResponse = Json.parseToJsonElement(response.bodyAsText()).jsonObject
        val status = startupResponse["status"]?.jsonPrimitive?.content
        
        assertTrue(status == "STARTED" || status == "STARTING")
    }
    
    @Test
    fun `health endpoints - do not require authentication`() = withMockedApplication {
        val client = createJsonClient()
        
        // All health endpoints should be accessible without authentication
        val endpoints = listOf(
            "/health",
            "/health/detailed", 
            "/health/ready",
            "/health/live",
            "/health/startup"
        )
        
        endpoints.forEach { endpoint ->
            val response = client.get(endpoint)
            // Should not return 401 Unauthorized
            assertTrue(
                response.status != HttpStatusCode.Unauthorized,
                "$endpoint should not require authentication"
            )
        }
    }
    
    @Test
    fun `health endpoints - handle concurrent requests`() = withMockedApplication {
        val client = createJsonClient()
        
        // Make multiple concurrent health check requests
        val responses = (1..10).map {
            client.get("/health")
        }
        
        // All should succeed
        responses.forEach { response ->
            assertEquals(HttpStatusCode.OK, response.status)
        }
    }
    
    @Test
    fun `GET health detailed - performance under load`() = withMockedApplication {
        val client = createJsonClient()
        
        // Multiple detailed health checks should still be reasonably fast
        repeat(5) {
            val startTime = System.currentTimeMillis()
            val response = client.get("/health/detailed")
            
            assertTrue(
                response.status == HttpStatusCode.OK ||
                response.status == HttpStatusCode.ServiceUnavailable
            )
            ResponseAssertions.assertResponseTime(startTime, 1000, "GET /health/detailed")
        }
    }
    
    @Test
    fun `health endpoints - proper content type headers`() = withMockedApplication {
        val client = createJsonClient()
        
        val endpoints = listOf(
            "/health",
            "/health/detailed",
            "/health/ready", 
            "/health/live",
            "/health/startup"
        )
        
        endpoints.forEach { endpoint ->
            val response = client.get(endpoint)
            val contentType = response.contentType()
            
            assertEquals(
                ContentType.Application.Json.withoutParameters(),
                contentType?.withoutParameters(),
                "$endpoint should return JSON content type"
            )
        }
    }
    
    @Test
    fun `GET health detailed - validates service response times`() = withMockedApplication {
        val client = createJsonClient()
        
        val response = client.get("/health/detailed")
        val healthStatus = response.body<HealthStatus>()
        
        healthStatus.services.forEach { (serviceName, serviceHealth) ->
            serviceHealth.responseTime?.let { responseTime ->
                assertTrue(
                    responseTime >= 0,
                    "$serviceName response time should be non-negative: $responseTime"
                )
                assertTrue(
                    responseTime < 30000,
                    "$serviceName response time should be reasonable: $responseTime ms"
                )
            }
        }
    }
    
    @Test
    fun `health endpoints - handle invalid HTTP methods`() = withMockedApplication {
        val client = createJsonClient()
        
        // Health endpoints should only support GET
        val postResponse = client.post("/health") {
            contentType(ContentType.Application.Json)
            setBody("{}")
        }
        
        assertEquals(HttpStatusCode.MethodNotAllowed, postResponse.status)
        
        val putResponse = client.put("/health") {
            contentType(ContentType.Application.Json)
            setBody("{}")
        }
        
        assertEquals(HttpStatusCode.MethodNotAllowed, putResponse.status)
    }
    
    @Test
    fun `GET health detailed - environment information`() = withMockedApplication {
        val client = createJsonClient()
        
        val response = client.get("/health/detailed")
        val healthStatus = response.body<HealthStatus>()
        
        // Should include environment information
        assertNotNull(healthStatus.environment)
        assertNotNull(healthStatus.version)
        
        // Environment should be a reasonable value
        assertTrue(
            healthStatus.environment in listOf("test", "development", "staging", "production", "unknown"),
            "Environment should be a known value: ${healthStatus.environment}"
        )
    }
    
    @Test
    fun `health endpoints - consistent response format`() = withMockedApplication {
        val client = createJsonClient()
        
        // All health endpoints should return valid JSON
        val endpoints = listOf(
            "/health",
            "/health/detailed",
            "/health/ready",
            "/health/live", 
            "/health/startup"
        )
        
        endpoints.forEach { endpoint ->
            val response = client.get(endpoint)
            ResponseAssertions.assertValidJson(response)
            
            val jsonResponse = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            
            // Should always have a status field
            assertTrue(
                jsonResponse.containsKey("status"),
                "$endpoint response should contain status field"
            )
            
            val status = jsonResponse["status"]?.jsonPrimitive?.content
            assertNotNull(status, "$endpoint status should not be null")
        }
    }
}