package com.wondernest.utils

import com.wondernest.TestConfiguration
import com.wondernest.testApplication
import io.ktor.client.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.request.*
import io.ktor.client.statement.*
import io.ktor.http.*
import io.ktor.serialization.kotlinx.json.*
import io.ktor.server.testing.*
import kotlinx.serialization.json.Json
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.BeforeEach
import org.testcontainers.junit.jupiter.Testcontainers

/**
 * Base class for integration tests providing common setup and utilities
 */
@Testcontainers
abstract class BaseIntegrationTest {
    
    companion object {
        @JvmStatic
        @BeforeAll
        fun setUpClass() {
            if (!TestConfiguration.postgres.isRunning) {
                TestConfiguration.postgres.start()
            }
        }
    }
    
    protected lateinit var testClient: HttpClient
    
    @BeforeEach
    open fun setUp() {
        // Override in subclasses for specific setup
    }
    
    @AfterEach
    open fun tearDown() {
        // Override in subclasses for specific cleanup
    }
    
    /**
     * Creates a test application with real database
     */
    protected fun withTestApplication(test: suspend ApplicationTestBuilder.() -> Unit) {
        testApplication(useRealDatabase = true, test = test)
    }
    
    /**
     * Creates a test application with mocked services
     */
    protected fun withMockedApplication(test: suspend ApplicationTestBuilder.() -> Unit) {
        testApplication(useRealDatabase = false, test = test)
    }
    
    /**
     * Creates an HTTP client with JSON content negotiation
     */
    protected fun ApplicationTestBuilder.createJsonClient(): HttpClient {
        return createClient {
            install(ContentNegotiation) {
                json(Json {
                    prettyPrint = true
                    isLenient = true
                    ignoreUnknownKeys = true
                })
            }
        }
    }
    
    /**
     * Makes an authenticated request with the given JWT token
     */
    protected suspend fun HttpClient.authenticatedRequest(
        method: HttpMethod,
        path: String,
        token: String,
        body: Any? = null,
        setup: HttpRequestBuilder.() -> Unit = {}
    ): HttpResponse {
        return request(path) {
            this.method = method
            header(HttpHeaders.Authorization, "Bearer $token")
            if (body != null) {
                contentType(ContentType.Application.Json)
                setBody(body)
            }
            setup()
        }
    }
    
    /**
     * Makes a GET request with authentication
     */
    protected suspend fun HttpClient.authenticatedGet(
        path: String,
        token: String,
        setup: HttpRequestBuilder.() -> Unit = {}
    ): HttpResponse = authenticatedRequest(HttpMethod.Get, path, token, setup = setup)
    
    /**
     * Makes a POST request with authentication
     */
    protected suspend fun HttpClient.authenticatedPost(
        path: String,
        token: String,
        body: Any? = null,
        setup: HttpRequestBuilder.() -> Unit = {}
    ): HttpResponse = authenticatedRequest(HttpMethod.Post, path, token, body, setup)
    
    /**
     * Makes a PUT request with authentication
     */
    protected suspend fun HttpClient.authenticatedPut(
        path: String,
        token: String,
        body: Any? = null,
        setup: HttpRequestBuilder.() -> Unit = {}
    ): HttpResponse = authenticatedRequest(HttpMethod.Put, path, token, body, setup)
    
    /**
     * Makes a DELETE request with authentication
     */
    protected suspend fun HttpClient.authenticatedDelete(
        path: String,
        token: String,
        setup: HttpRequestBuilder.() -> Unit = {}
    ): HttpResponse = authenticatedRequest(HttpMethod.Delete, path, token, setup = setup)
}