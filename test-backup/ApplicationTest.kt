package com.wondernest

import io.ktor.client.request.*
import io.ktor.client.statement.*
import io.ktor.http.*
import io.ktor.server.testing.*
import kotlin.test.*

class ApplicationTest {
    @Test
    fun testRoot() = testApplication {
        application {
            module()
        }
        
        // Test health endpoint
        val response = client.get("/health")
        assertEquals(HttpStatusCode.OK, response.status)
        
        val bodyText = response.bodyAsText()
        assertTrue(bodyText.contains("healthy"))
    }
    
    @Test
    fun testReadyEndpoint() = testApplication {
        application {
            module()
        }
        
        val response = client.get("/ready")
        assertEquals(HttpStatusCode.OK, response.status)
        
        val bodyText = response.bodyAsText()
        assertTrue(bodyText.contains("ready"))
    }
    
    @Test
    fun testMetricsEndpoint() = testApplication {
        application {
            module()
        }
        
        val response = client.get("/metrics")
        // Metrics endpoint should be available
        assertTrue(response.status == HttpStatusCode.OK || response.status == HttpStatusCode.ServiceUnavailable)
    }
    
    @Test
    fun testNotFoundEndpoint() = testApplication {
        application {
            module()
        }
        
        val response = client.get("/nonexistent")
        assertEquals(HttpStatusCode.NotFound, response.status)
    }
}