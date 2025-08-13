package com.wondernest

import io.ktor.client.request.*
import io.ktor.client.statement.*
import io.ktor.http.*
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class SimpleApplicationTest {
    
    @Test
    fun testHealthEndpoint() = simpleTestApplication {
        val response = client.get("/health")
        assertEquals(HttpStatusCode.OK, response.status)
        
        val bodyText = response.bodyAsText()
        assertTrue(bodyText.contains("healthy"))
    }
    
    @Test
    fun testReadyEndpoint() = simpleTestApplication {
        val response = client.get("/ready")
        assertEquals(HttpStatusCode.OK, response.status)
        
        val bodyText = response.bodyAsText()
        assertTrue(bodyText.contains("ready"))
    }
    
    @Test
    fun testNotFoundEndpoint() = simpleTestApplication {
        val response = client.get("/nonexistent")
        assertEquals(HttpStatusCode.NotFound, response.status)
    }
}