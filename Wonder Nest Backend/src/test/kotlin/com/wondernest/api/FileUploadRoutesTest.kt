package com.wondernest.api

import com.wondernest.config.configureDependencyInjection
import com.wondernest.config.configureSecurity
import com.wondernest.data.database.table.UserRole
import com.wondernest.domain.model.User
import com.wondernest.services.auth.JwtService
import io.ktor.client.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.request.*
import io.ktor.client.request.forms.*
import io.ktor.client.statement.*
import io.ktor.http.*
import io.ktor.http.content.*
import io.ktor.serialization.kotlinx.json.*
import io.ktor.server.testing.*
import kotlinx.datetime.Clock
import kotlinx.serialization.json.Json
import org.junit.jupiter.api.Test
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class FileUploadRoutesTest {
    
    private fun ApplicationTestBuilder.createClient(): HttpClient {
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
    
    private fun generateTestToken(): String {
        val jwtService = JwtService()
        val testUser = User(
            id = UUID.randomUUID(),
            email = "test@example.com",
            firstName = "Test",
            lastName = "User",
            role = UserRole.PARENT,
            createdAt = Clock.System.now(),
            updatedAt = Clock.System.now()
        )
        return jwtService.generateToken(testUser).accessToken
    }
    
    @Test
    fun `test file upload endpoint`() = testApplication {
        application {
            configureDependencyInjection()
            configureSecurity()
            routing {
                authenticate("auth-jwt") {
                    route("/api/v1") {
                        fileUploadRoutes()
                    }
                }
            }
        }
        
        val client = createClient()
        val token = generateTestToken()
        
        // Create a simple test file
        val fileContent = "Test file content"
        val fileName = "test.txt"
        
        val response = client.submitFormWithBinaryData(
            url = "/api/v1/files/upload",
            formData = formData {
                append("file", fileContent.toByteArray(), Headers.build {
                    append(HttpHeaders.ContentType, "text/plain")
                    append(HttpHeaders.ContentDisposition, "filename=\"$fileName\"")
                })
            }
        ) {
            header(HttpHeaders.Authorization, "Bearer $token")
            parameter("category", "document")
            parameter("isPublic", "false")
        }
        
        assertEquals(HttpStatusCode.Created, response.status)
        
        val responseBody = response.bodyAsText()
        assertTrue(responseBody.contains("success"))
        assertTrue(responseBody.contains("test.txt"))
    }
    
    @Test
    fun `test file upload without authentication returns 401`() = testApplication {
        application {
            configureDependencyInjection()
            configureSecurity()
            routing {
                authenticate("auth-jwt") {
                    route("/api/v1") {
                        fileUploadRoutes()
                    }
                }
            }
        }
        
        val client = createClient()
        
        val response = client.submitFormWithBinaryData(
            url = "/api/v1/files/upload",
            formData = formData {
                append("file", "content".toByteArray(), Headers.build {
                    append(HttpHeaders.ContentType, "text/plain")
                    append(HttpHeaders.ContentDisposition, "filename=\"test.txt\"")
                })
            }
        )
        
        assertEquals(HttpStatusCode.Unauthorized, response.status)
    }
    
    @Test
    fun `test list files endpoint`() = testApplication {
        application {
            configureDependencyInjection()
            configureSecurity()
            routing {
                authenticate("auth-jwt") {
                    route("/api/v1") {
                        fileUploadRoutes()
                    }
                }
            }
        }
        
        val client = createClient()
        val token = generateTestToken()
        
        val response = client.get("/api/v1/files") {
            header(HttpHeaders.Authorization, "Bearer $token")
            parameter("category", "content")
            parameter("limit", "10")
            parameter("offset", "0")
        }
        
        assertEquals(HttpStatusCode.OK, response.status)
        
        val responseBody = response.bodyAsText()
        assertTrue(responseBody.contains("success"))
        assertTrue(responseBody.contains("data"))
    }
    
    @Test
    fun `test invalid file type returns 400`() = testApplication {
        application {
            configureDependencyInjection()
            configureSecurity()
            routing {
                authenticate("auth-jwt") {
                    route("/api/v1") {
                        fileUploadRoutes()
                    }
                }
            }
        }
        
        val client = createClient()
        val token = generateTestToken()
        
        val response = client.submitFormWithBinaryData(
            url = "/api/v1/files/upload",
            formData = formData {
                append("file", "malicious content".toByteArray(), Headers.build {
                    append(HttpHeaders.ContentType, "application/x-msdownload")
                    append(HttpHeaders.ContentDisposition, "filename=\"virus.exe\"")
                })
            }
        ) {
            header(HttpHeaders.Authorization, "Bearer $token")
        }
        
        assertEquals(HttpStatusCode.BadRequest, response.status)
        
        val responseBody = response.bodyAsText()
        assertTrue(responseBody.contains("VALIDATION_ERROR"))
    }
    
    @Test
    fun `test file categories validation`() = testApplication {
        application {
            configureDependencyInjection()
            configureSecurity()
            routing {
                authenticate("auth-jwt") {
                    route("/api/v1") {
                        fileUploadRoutes()
                    }
                }
            }
        }
        
        val client = createClient()
        val token = generateTestToken()
        
        val categories = listOf("profile_picture", "content", "document", "game_asset", "artwork")
        
        for (category in categories) {
            val response = client.submitFormWithBinaryData(
                url = "/api/v1/files/upload",
                formData = formData {
                    append("file", "test content".toByteArray(), Headers.build {
                        append(HttpHeaders.ContentType, "text/plain")
                        append(HttpHeaders.ContentDisposition, "filename=\"test_$category.txt\"")
                    })
                }
            ) {
                header(HttpHeaders.Authorization, "Bearer $token")
                parameter("category", category)
            }
            
            assertEquals(HttpStatusCode.Created, response.status, "Failed for category: $category")
        }
    }
}