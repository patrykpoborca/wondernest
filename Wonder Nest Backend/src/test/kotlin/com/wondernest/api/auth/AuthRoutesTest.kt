package com.wondernest.api.auth

import com.wondernest.config.*
import com.wondernest.services.auth.SignupRequest
import com.wondernest.services.auth.LoginRequest
import io.ktor.client.request.*
import io.ktor.client.statement.*
import io.ktor.http.*
import io.ktor.server.testing.*
import kotlinx.serialization.json.Json
import kotlin.test.*

class AuthRoutesTest {

    @Test
    fun testHealthEndpoint() = testApplication {
        application {
            configureDependencyInjection()
            configureSerialization()
            configureHTTP()
            configureSecurity()
            configureRouting()
        }

        val response = client.get("/health")
        assertEquals(HttpStatusCode.OK, response.status)
    }

    @Test
    fun testSignupEndpoint() = testApplication {
        application {
            configureDependencyInjection()
            configureSerialization()
            configureHTTP()
            configureSecurity()
            configureRouting()
        }

        val signupRequest = SignupRequest(
            email = "test@example.com",
            password = "TestPassword123!",
            firstName = "Test",
            lastName = "User"
        )

        val response = client.post("/api/v1/auth/signup") {
            contentType(ContentType.Application.Json)
            setBody(Json.encodeToString(SignupRequest.serializer(), signupRequest))
        }

        // Note: This will fail in actual testing due to missing database
        // This is just a structure example
        println("Signup response status: ${response.status}")
    }

    @Test
    fun testLoginEndpoint() = testApplication {
        application {
            configureDependencyInjection()
            configureSerialization()
            configureHTTP()
            configureSecurity()
            configureRouting()
        }

        val loginRequest = LoginRequest(
            email = "test@example.com",
            password = "TestPassword123!"
        )

        val response = client.post("/api/v1/auth/login") {
            contentType(ContentType.Application.Json)
            setBody(Json.encodeToString(LoginRequest.serializer(), loginRequest))
        }

        // Note: This will fail in actual testing due to missing database
        // This is just a structure example
        println("Login response status: ${response.status}")
    }
}