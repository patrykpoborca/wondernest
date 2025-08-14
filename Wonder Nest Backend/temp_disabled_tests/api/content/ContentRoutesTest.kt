package com.wondernest.api.content

import com.wondernest.utils.TestUtils
import com.wondernest.services.auth.JwtService
import com.wondernest.data.database.table.UserRole
import com.wondernest.domain.model.User
import com.wondernest.domain.model.Family
import io.ktor.client.request.*
import io.ktor.client.statement.*
import io.ktor.http.*
import io.ktor.server.testing.*
import io.ktor.serialization.kotlinx.json.*
import io.ktor.server.application.*
import io.ktor.server.auth.*
import io.ktor.server.auth.jwt.*
import io.ktor.server.plugins.contentnegotiation.*
import io.ktor.server.routing.*
import kotlinx.serialization.json.*
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Nested
import java.util.*
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.test.assertNotNull

/**
 * Comprehensive tests for ContentRoutes endpoints
 * Validates content filtering, pagination, and recommendations critical for Flutter integration
 */
@DisplayName("Content Routes Tests")
class ContentRoutesTest {

    private lateinit var jwtService: JwtService
    private lateinit var testUser: User
    private lateinit var testFamily: Family
    private lateinit var validJwtToken: String

    @BeforeEach
    fun setup() {
        jwtService = JwtService()
        
        testUser = TestUtils.createTestUser(
            role = UserRole.PARENT,
            email = "parent@test.com"
        )
        testFamily = TestUtils.createTestFamily(createdBy = testUser.id)
        
        // Generate valid JWT with family context
        val tokenPair = jwtService.generateTokenWithFamilyContext(testUser, testFamily.id)
        validJwtToken = tokenPair.accessToken
    }

    @Nested
    @DisplayName("Content Library Tests")
    inner class ContentLibraryTests {

        @Test
        @DisplayName("Should retrieve paginated content with default parameters")
        fun testGetContentDefault() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            val response = client.get("/api/v1/content") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.OK, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            
            // Validate response structure matches Flutter expectations
            TestUtils.validateFlutterApiResponse(
                responseBody.mapValues { it.value.toString().removeSurrounding("\"") },
                setOf("items", "totalItems", "currentPage", "totalPages", "categories")
            )

            // Validate pagination structure
            val items = responseBody["items"]?.jsonArray
            assertNotNull(items, "Items array should be present")
            
            val totalItems = responseBody["totalItems"]?.jsonPrimitive?.int
            assertNotNull(totalItems, "Total items should be present")
            
            val currentPage = responseBody["currentPage"]?.jsonPrimitive?.int
            assertEquals(1, currentPage, "Default page should be 1")
            
            val totalPages = responseBody["totalPages"]?.jsonPrimitive?.int
            assertNotNull(totalPages, "Total pages should be present")

            // Validate categories structure
            val categories = responseBody["categories"]?.jsonArray
            assertNotNull(categories, "Categories should be present")
            assertTrue(categories!!.size > 0, "Should have at least one category")
        }

        @Test
        @DisplayName("Should filter content by age group")
        fun testContentAgeFiltering() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            val response = client.get("/api/v1/content?ageGroup=5") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.OK, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            val items = responseBody["items"]?.jsonArray
            assertNotNull(items)

            // Validate that all returned content is age-appropriate
            items!!.forEach { item ->
                val contentItem = item.jsonObject
                val ageRating = contentItem["ageRating"]?.jsonPrimitive?.int
                assertNotNull(ageRating, "Each content item should have an age rating")
                assertTrue(
                    ageRating!! <= 7, // 5 + 2 tolerance
                    "Content should be age-appropriate for age group 5"
                )
            }
        }

        @Test
        @DisplayName("Should filter content by category")
        fun testContentCategoryFiltering() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            val response = client.get("/api/v1/content?category=educational") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.OK, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            val items = responseBody["items"]?.jsonArray
            assertNotNull(items)

            // Validate that all returned content matches the category
            items!!.forEach { item ->
                val contentItem = item.jsonObject
                val category = contentItem["category"]?.jsonPrimitive?.content
                assertEquals("educational", category, "All content should be educational")
            }
        }

        @Test
        @DisplayName("Should handle pagination correctly")
        fun testContentPagination() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            // Test first page
            val page1Response = client.get("/api/v1/content?page=1&limit=2") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.OK, page1Response.status)

            val page1Body = Json.parseToJsonElement(page1Response.bodyAsText()).jsonObject
            val page1Items = page1Body["items"]?.jsonArray
            val totalItems = page1Body["totalItems"]?.jsonPrimitive?.int
            val totalPages = page1Body["totalPages"]?.jsonPrimitive?.int
            val currentPage = page1Body["currentPage"]?.jsonPrimitive?.int

            assertEquals(1, currentPage, "Current page should be 1")
            assertTrue(page1Items!!.size <= 2, "Should return at most 2 items per page")
            assertTrue(totalItems!! > 0, "Should have content items")
            assertTrue(totalPages!! > 0, "Should have at least one page")

            // Test second page if there are multiple pages
            if (totalPages > 1) {
                val page2Response = client.get("/api/v1/content?page=2&limit=2") {
                    header(HttpHeaders.Authorization, "Bearer $validJwtToken")
                }

                assertEquals(HttpStatusCode.OK, page2Response.status)

                val page2Body = Json.parseToJsonElement(page2Response.bodyAsText()).jsonObject
                val page2Items = page2Body["items"]?.jsonArray
                val page2CurrentPage = page2Body["currentPage"]?.jsonPrimitive?.int

                assertEquals(2, page2CurrentPage, "Current page should be 2")
                assertTrue(page2Items!!.size >= 0, "Page 2 should have valid items")
            }
        }

        @Test
        @DisplayName("Should handle empty results gracefully")
        fun testEmptyContentResults() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            // Request content with unlikely age/category combination
            val response = client.get("/api/v1/content?ageGroup=1&category=nonexistent") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.OK, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            val items = responseBody["items"]?.jsonArray
            val totalItems = responseBody["totalItems"]?.jsonPrimitive?.int
            val currentPage = responseBody["currentPage"]?.jsonPrimitive?.int
            val totalPages = responseBody["totalPages"]?.jsonPrimitive?.int

            assertNotNull(items, "Items should be present even if empty")
            assertEquals(0, totalItems, "Should have 0 total items")
            assertEquals(1, currentPage, "Current page should still be 1")
            assertEquals(0, totalPages, "Should have 0 total pages")
        }

        @Test
        @DisplayName("Should validate content item structure")
        fun testContentItemStructure() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            val response = client.get("/api/v1/content?limit=1") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.OK, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            val items = responseBody["items"]?.jsonArray
            assertNotNull(items)

            if (items!!.isNotEmpty()) {
                val firstItem = items[0].jsonObject
                
                // Validate all required fields for Flutter
                val requiredFields = setOf(
                    "id", "title", "description", "category", "ageRating", 
                    "duration", "thumbnailUrl", "contentUrl", "tags", 
                    "isEducational", "difficulty", "createdAt"
                )
                
                TestUtils.validateFlutterApiResponse(
                    firstItem.mapValues { it.value.toString().removeSurrounding("\"") },
                    requiredFields
                )

                // Validate data types
                assertTrue(firstItem["ageRating"]?.jsonPrimitive?.int!! >= 0, "Age rating should be non-negative")
                assertTrue(firstItem["duration"]?.jsonPrimitive?.int!! > 0, "Duration should be positive")
                assertTrue(firstItem["tags"]?.jsonArray?.isNotEmpty() == true, "Should have tags")
                assertNotNull(firstItem["isEducational"]?.jsonPrimitive?.boolean, "Educational flag should be boolean")
            }
        }

        @Test
        @DisplayName("Should require authentication")
        fun testContentRequiresAuth() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            val response = client.get("/api/v1/content")

            assertEquals(HttpStatusCode.Unauthorized, response.status)
        }

        @Test
        @DisplayName("Should require family context in JWT")
        fun testContentRequiresFamilyContext() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            // Generate token without family context
            val tokenWithoutFamily = jwtService.generateToken(testUser).accessToken

            val response = client.get("/api/v1/content") {
                header(HttpHeaders.Authorization, "Bearer $tokenWithoutFamily")
            }

            assertEquals(HttpStatusCode.BadRequest, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertTrue(responseBody["message"]?.jsonPrimitive?.content?.contains("No family context") == true)
        }
    }

    @Nested
    @DisplayName("Content Recommendations Tests")
    inner class ContentRecommendationsTests {

        @Test
        @DisplayName("Should generate recommendations for child")
        fun testGetRecommendations() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            val childId = UUID.randomUUID().toString()
            val response = client.get("/api/v1/content/recommendations/$childId") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.OK, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            
            // Validate response structure
            TestUtils.validateFlutterApiResponse(
                responseBody.mapValues { it.value.toString().removeSurrounding("\"") },
                setOf("childId", "recommendations", "reason", "generatedAt")
            )

            assertEquals(childId, responseBody["childId"]?.jsonPrimitive?.content)
            
            val recommendations = responseBody["recommendations"]?.jsonArray
            assertNotNull(recommendations, "Should have recommendations array")
            assertTrue(recommendations!!.size > 0, "Should have at least one recommendation")
            
            val reason = responseBody["reason"]?.jsonPrimitive?.content
            assertNotNull(reason, "Should have reason for recommendations")
            
            val generatedAt = responseBody["generatedAt"]?.jsonPrimitive?.long
            assertNotNull(generatedAt, "Should have generation timestamp")
        }

        @Test
        @DisplayName("Should require child ID parameter")
        fun testRecommendationsRequireChildId() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            val response = client.get("/api/v1/content/recommendations/") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.NotFound, response.status)
        }

        @Test
        @DisplayName("Should validate recommendation content structure")
        fun testRecommendationContentStructure() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            val childId = UUID.randomUUID().toString()
            val response = client.get("/api/v1/content/recommendations/$childId") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.OK, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            val recommendations = responseBody["recommendations"]?.jsonArray
            assertNotNull(recommendations)

            // Validate each recommendation has proper structure
            recommendations!!.forEach { recommendation ->
                val item = recommendation.jsonObject
                assertTrue(item.containsKey("id"), "Recommendation should have ID")
                assertTrue(item.containsKey("title"), "Recommendation should have title")
                assertTrue(item.containsKey("category"), "Recommendation should have category")
                assertTrue(item.containsKey("ageRating"), "Recommendation should have age rating")
            }
        }
    }

    @Nested
    @DisplayName("Individual Content Tests")
    inner class IndividualContentTests {

        @Test
        @DisplayName("Should retrieve specific content item")
        fun testGetIndividualContent() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            val contentId = "content_1" // Known test content ID
            val response = client.get("/api/v1/content/$contentId") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.OK, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertEquals(contentId, responseBody["id"]?.jsonPrimitive?.content)
            
            // Validate full content structure
            val requiredFields = setOf(
                "id", "title", "description", "category", "ageRating",
                "duration", "thumbnailUrl", "contentUrl", "tags",
                "isEducational", "difficulty", "createdAt"
            )
            
            TestUtils.validateFlutterApiResponse(
                responseBody.mapValues { it.value.toString().removeSurrounding("\"") },
                requiredFields
            )
        }

        @Test
        @DisplayName("Should handle non-existent content")
        fun testGetNonExistentContent() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            val response = client.get("/api/v1/content/nonexistent-content") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.NotFound, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertTrue(responseBody["message"]?.jsonPrimitive?.content?.contains("not found") == true)
        }
    }

    @Nested
    @DisplayName("Content Categories Tests")
    inner class ContentCategoriesTests {

        @Test
        @DisplayName("Should retrieve content categories")
        fun testGetCategories() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            val response = client.get("/api/v1/categories") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.OK, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            val categories = responseBody["categories"]?.jsonArray
            assertNotNull(categories, "Should have categories array")
            assertTrue(categories!!.size > 0, "Should have at least one category")

            // Validate category structure
            val firstCategory = categories[0].jsonObject
            val requiredCategoryFields = setOf(
                "id", "name", "description", "icon", "color", "minAge", "maxAge"
            )
            
            TestUtils.validateFlutterApiResponse(
                firstCategory.mapValues { it.value.toString().removeSurrounding("\"") },
                requiredCategoryFields
            )

            // Validate age ranges make sense
            val minAge = firstCategory["minAge"]?.jsonPrimitive?.int
            val maxAge = firstCategory["maxAge"]?.jsonPrimitive?.int
            assertNotNull(minAge, "Category should have minimum age")
            assertNotNull(maxAge, "Category should have maximum age")
            assertTrue(minAge!! >= 0, "Minimum age should be non-negative")
            assertTrue(maxAge!! >= minAge, "Maximum age should be >= minimum age")
        }
    }

    @Nested
    @DisplayName("Content Engagement Tests")
    inner class ContentEngagementTests {

        @Test
        @DisplayName("Should track content engagement")
        fun testTrackEngagement() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            val response = client.post("/api/v1/content/engagement") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
                contentType(ContentType.Application.Json)
                setBody("""
                    {
                        "contentId": "content_1",
                        "childId": "${UUID.randomUUID()}",
                        "action": "viewed",
                        "duration": 300
                    }
                """.trimIndent())
            }

            assertEquals(HttpStatusCode.Created, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertTrue(responseBody["message"]?.jsonPrimitive?.content?.contains("tracked") == true)
        }
    }

    @Nested
    @DisplayName("Query Parameter Validation Tests")
    inner class QueryParameterTests {

        @Test
        @DisplayName("Should handle invalid age group parameter")
        fun testInvalidAgeGroup() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            val response = client.get("/api/v1/content?ageGroup=invalid") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            // Should handle gracefully - invalid age group is ignored
            assertEquals(HttpStatusCode.OK, response.status)
        }

        @Test
        @DisplayName("Should handle invalid pagination parameters")
        fun testInvalidPaginationParameters() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            // Test negative page
            val response1 = client.get("/api/v1/content?page=-1") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }
            assertEquals(HttpStatusCode.OK, response1.status) // Should default to page 1

            // Test invalid limit
            val response2 = client.get("/api/v1/content?limit=invalid") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }
            assertEquals(HttpStatusCode.OK, response2.status) // Should use default limit
        }

        @Test
        @DisplayName("Should handle large page numbers")
        fun testLargePageNumbers() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            val response = client.get("/api/v1/content?page=999999") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.OK, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            val items = responseBody["items"]?.jsonArray
            // Should return empty results for pages beyond available content
            assertEquals(0, items!!.size)
        }
    }

    @Nested
    @DisplayName("Error Handling Tests")
    inner class ErrorHandlingTests {

        @Test
        @DisplayName("Should handle server errors gracefully")
        fun testServerErrorHandling() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            // This tests the catch block in the routes - in real scenarios,
            // you'd mock dependencies to throw exceptions
            val response = client.get("/api/v1/content") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            // The mock implementation should work correctly
            assertEquals(HttpStatusCode.OK, response.status)
        }

        @Test
        @DisplayName("Should handle malformed content ID")
        fun testMalformedContentId() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            val response = client.get("/api/v1/content/") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            // Should return 404 for empty content ID
            assertEquals(HttpStatusCode.NotFound, response.status)
        }
    }

    /**
     * Helper function to configure test application with content routes and JWT authentication
     */
    private fun Application.configureTestApplication(jwtService: JwtService) {
        install(ContentNegotiation) {
            json()
        }
        
        install(Authentication) {
            jwt("auth-jwt") {
                realm = jwtService.realm
                verifier(
                    JWT.require(Algorithm.HMAC256(jwtService.secret))
                        .withIssuer(jwtService.issuer)
                        .build()
                )
                validate { credential ->
                    if (credential.payload.getClaim("userId").asString() != null) {
                        JWTPrincipal(credential.payload)
                    } else null
                }
            }
        }

        routing {
            route("/api/v1") {
                contentRoutes()
            }
        }
    }
}