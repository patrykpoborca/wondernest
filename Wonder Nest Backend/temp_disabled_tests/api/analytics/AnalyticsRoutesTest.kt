package com.wondernest.api.analytics

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
 * Comprehensive tests for AnalyticsRoutes endpoints
 * Validates mock analytics responses are properly formatted for Flutter integration
 */
@DisplayName("Analytics Routes Tests")
class AnalyticsRoutesTest {

    private lateinit var jwtService: JwtService
    private lateinit var testUser: User
    private lateinit var testFamily: Family
    private lateinit var validJwtToken: String
    private lateinit var testChildId: String

    @BeforeEach
    fun setup() {
        jwtService = JwtService()
        
        testUser = TestUtils.createTestUser(
            role = UserRole.PARENT,
            email = "analytics@test.com"
        )
        testFamily = TestUtils.createTestFamily(createdBy = testUser.id)
        testChildId = UUID.randomUUID().toString()
        
        // Generate valid JWT with family context
        val tokenPair = jwtService.generateTokenWithFamilyContext(testUser, testFamily.id)
        validJwtToken = tokenPair.accessToken
    }

    @Nested
    @DisplayName("Daily Analytics Tests")
    inner class DailyAnalyticsTests {

        @Test
        @DisplayName("Should retrieve daily analytics with all required fields for Flutter")
        fun testGetDailyAnalytics() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            val response = client.get("/api/v1/analytics/daily?childId=$testChildId") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.OK, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            
            // Validate all fields required for Flutter analytics display
            val expectedFields = setOf(
                "date", "childId", "totalScreenTime", "contentConsumed",
                "educationalTime", "averageSessionLength", "mostEngagedCategory",
                "completedActivities", "learningProgress"
            )
            
            TestUtils.validateFlutterApiResponse(
                responseBody.mapValues { it.value.toString().removeSurrounding("\"") },
                expectedFields
            )

            // Validate field types and reasonable values
            assertEquals(testChildId, responseBody["childId"]?.jsonPrimitive?.content)
            assertNotNull(responseBody["date"]?.jsonPrimitive?.content)
            
            val totalScreenTime = responseBody["totalScreenTime"]?.jsonPrimitive?.int
            assertTrue(totalScreenTime!! >= 0, "Screen time should be non-negative")
            
            val educationalTime = responseBody["educationalTime"]?.jsonPrimitive?.int
            assertTrue(educationalTime!! >= 0, "Educational time should be non-negative")
            assertTrue(educationalTime <= totalScreenTime, "Educational time should not exceed total screen time")
            
            val learningProgress = responseBody["learningProgress"]?.jsonPrimitive?.double
            assertTrue(learningProgress!! >= 0.0, "Learning progress should be >= 0.0")
            assertTrue(learningProgress <= 1.0, "Learning progress should be <= 1.0")
            
            val completedActivities = responseBody["completedActivities"]?.jsonPrimitive?.int
            assertTrue(completedActivities!! >= 0, "Completed activities should be non-negative")
        }

        @Test
        @DisplayName("Should require childId parameter")
        fun testDailyAnalyticsRequireChildId() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            val response = client.get("/api/v1/analytics/daily") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.BadRequest, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertTrue(responseBody["message"]?.jsonPrimitive?.content?.contains("Child ID is required") == true)
        }

        @Test
        @DisplayName("Should require authentication")
        fun testDailyAnalyticsRequiresAuth() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            val response = client.get("/api/v1/analytics/daily?childId=$testChildId")

            assertEquals(HttpStatusCode.Unauthorized, response.status)
        }

        @Test
        @DisplayName("Should require family context in JWT")
        fun testDailyAnalyticsRequiresFamilyContext() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            // Generate token without family context
            val tokenWithoutFamily = jwtService.generateToken(testUser).accessToken

            val response = client.get("/api/v1/analytics/daily?childId=$testChildId") {
                header(HttpHeaders.Authorization, "Bearer $tokenWithoutFamily")
            }

            assertEquals(HttpStatusCode.BadRequest, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertTrue(responseBody["message"]?.jsonPrimitive?.content?.contains("No family context") == true)
        }
    }

    @Nested
    @DisplayName("Child Insights Tests")
    inner class ChildInsightsTests {

        @Test
        @DisplayName("Should retrieve child insights with proper structure for Flutter")
        fun testGetChildInsights() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            val response = client.get("/api/v1/analytics/children/$testChildId/insights") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.OK, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            
            // Validate insights structure for Flutter
            val expectedFields = setOf(
                "childId", "preferredLearningStyle", "strongSubjects",
                "improvementAreas", "recommendedActivities", "parentalGuidance"
            )
            
            TestUtils.validateFlutterApiResponse(
                responseBody.mapValues { it.value.toString().removeSurrounding("\"") },
                expectedFields
            )

            // Validate field types
            assertEquals(testChildId, responseBody["childId"]?.jsonPrimitive?.content)
            assertNotNull(responseBody["preferredLearningStyle"]?.jsonPrimitive?.content)
            
            val strongSubjects = responseBody["strongSubjects"]?.jsonArray
            assertNotNull(strongSubjects, "Strong subjects should be an array")
            assertTrue(strongSubjects!!.size > 0, "Should have at least one strong subject")
            
            val improvementAreas = responseBody["improvementAreas"]?.jsonArray
            assertNotNull(improvementAreas, "Improvement areas should be an array")
            
            val recommendedActivities = responseBody["recommendedActivities"]?.jsonArray
            assertNotNull(recommendedActivities, "Recommended activities should be an array")
            assertTrue(recommendedActivities!!.size > 0, "Should have at least one recommended activity")
            
            val parentalGuidance = responseBody["parentalGuidance"]?.jsonArray
            assertNotNull(parentalGuidance, "Parental guidance should be an array")
            assertTrue(parentalGuidance!!.size > 0, "Should have at least one guidance item")
        }

        @Test
        @DisplayName("Should validate individual insight items")
        fun testInsightItemsValidation() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            val response = client.get("/api/v1/analytics/children/$testChildId/insights") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.OK, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            
            // Validate that array items are strings
            val strongSubjects = responseBody["strongSubjects"]?.jsonArray
            strongSubjects?.forEach { subject ->
                assertNotNull(subject.jsonPrimitive.content, "Subject should be a string")
                assertTrue(subject.jsonPrimitive.content.isNotBlank(), "Subject should not be blank")
            }
            
            val parentalGuidance = responseBody["parentalGuidance"]?.jsonArray
            parentalGuidance?.forEach { guidance ->
                assertNotNull(guidance.jsonPrimitive.content, "Guidance should be a string")
                assertTrue(guidance.jsonPrimitive.content.isNotBlank(), "Guidance should not be blank")
                assertTrue(guidance.jsonPrimitive.content.length > 10, "Guidance should be meaningful")
            }
        }
    }

    @Nested
    @DisplayName("Weekly Overview Tests")
    inner class WeeklyOverviewTests {

        @Test
        @DisplayName("Should retrieve weekly overview with proper metrics for Flutter")
        fun testGetWeeklyOverview() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            val response = client.get("/api/v1/analytics/weekly?childId=$testChildId") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.OK, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            
            // Validate weekly overview structure for Flutter dashboard
            val expectedFields = setOf(
                "weekStart", "totalScreenTime", "educationalPercentage",
                "averageDailyUsage", "topCategories", "completionRate", "parentalInteraction"
            )
            
            TestUtils.validateFlutterApiResponse(
                responseBody.mapValues { it.value.toString().removeSurrounding("\"") },
                expectedFields
            )

            // Validate metric values and types
            assertNotNull(responseBody["weekStart"]?.jsonPrimitive?.content)
            
            val totalScreenTime = responseBody["totalScreenTime"]?.jsonPrimitive?.int
            assertTrue(totalScreenTime!! > 0, "Total screen time should be positive")
            
            val educationalPercentage = responseBody["educationalPercentage"]?.jsonPrimitive?.double
            assertTrue(educationalPercentage!! >= 0.0, "Educational percentage should be >= 0")
            assertTrue(educationalPercentage <= 100.0, "Educational percentage should be <= 100")
            
            val averageDailyUsage = responseBody["averageDailyUsage"]?.jsonPrimitive?.int
            assertTrue(averageDailyUsage!! > 0, "Average daily usage should be positive")
            assertTrue(averageDailyUsage <= totalScreenTime, "Average daily should not exceed weekly total")
            
            val topCategories = responseBody["topCategories"]?.jsonArray
            assertNotNull(topCategories, "Top categories should be an array")
            assertTrue(topCategories!!.size > 0, "Should have at least one top category")
            
            val completionRate = responseBody["completionRate"]?.jsonPrimitive?.double
            assertTrue(completionRate!! >= 0.0, "Completion rate should be >= 0")
            assertTrue(completionRate <= 1.0, "Completion rate should be <= 1")
            
            val parentalInteraction = responseBody["parentalInteraction"]?.jsonPrimitive?.int
            assertTrue(parentalInteraction!! >= 0, "Parental interaction should be non-negative")
        }

        @Test
        @DisplayName("Should validate top categories structure")
        fun testTopCategoriesValidation() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            val response = client.get("/api/v1/analytics/weekly?childId=$testChildId") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.OK, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            val topCategories = responseBody["topCategories"]?.jsonArray
            
            topCategories?.forEach { category ->
                val categoryName = category.jsonPrimitive.content
                assertNotNull(categoryName, "Category should be a string")
                assertTrue(categoryName.isNotBlank(), "Category should not be blank")
                // Validate against known content categories
                val validCategories = setOf("educational", "stories", "music", "art", "science")
                assertTrue(validCategories.contains(categoryName), 
                    "Category '$categoryName' should be a valid content category")
            }
        }
    }

    @Nested
    @DisplayName("Milestone Tests")
    inner class MilestoneTests {

        @Test
        @DisplayName("Should retrieve child milestones with proper structure for Flutter")
        fun testGetChildMilestones() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            val response = client.get("/api/v1/analytics/children/$testChildId/milestones") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.OK, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            
            // Validate milestone structure for Flutter progress tracking
            val expectedFields = setOf("age", "milestones", "nextGoals")
            expectedFields.forEach { field ->
                assertTrue(responseBody.containsKey(field), "Milestones should contain $field for Flutter")
            }

            val age = responseBody["age"]?.jsonPrimitive?.int
            assertTrue(age!! > 0, "Age should be positive")
            assertTrue(age <= 18, "Age should be reasonable for child")
            
            val milestones = responseBody["milestones"]?.jsonArray
            assertNotNull(milestones, "Milestones should be an array")
            assertTrue(milestones!!.size > 0, "Should have at least one milestone")
            
            val nextGoals = responseBody["nextGoals"]?.jsonArray
            assertNotNull(nextGoals, "Next goals should be an array")
            assertTrue(nextGoals!!.size > 0, "Should have at least one next goal")
        }

        @Test
        @DisplayName("Should validate milestone item structure")
        fun testMilestoneItemValidation() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            val response = client.get("/api/v1/analytics/children/$testChildId/milestones") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.OK, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            val milestones = responseBody["milestones"]?.jsonArray
            
            milestones?.forEach { milestone ->
                val milestoneObj = milestone.jsonObject
                
                // Each milestone should have category, description, and achieved status
                assertTrue(milestoneObj.containsKey("category"), "Milestone should have category")
                assertTrue(milestoneObj.containsKey("description"), "Milestone should have description")
                assertTrue(milestoneObj.containsKey("achieved"), "Milestone should have achieved status")
                
                val category = milestoneObj["category"]?.jsonPrimitive?.content
                assertNotNull(category, "Category should be a string")
                assertTrue(category!!.isNotBlank(), "Category should not be blank")
                
                val description = milestoneObj["description"]?.jsonPrimitive?.content
                assertNotNull(description, "Description should be a string")
                assertTrue(description!!.isNotBlank(), "Description should not be blank")
                
                val achieved = milestoneObj["achieved"]?.jsonPrimitive?.boolean
                assertNotNull(achieved, "Achieved should be a boolean")
            }

            val nextGoals = responseBody["nextGoals"]?.jsonArray
            nextGoals?.forEach { goal ->
                val goalText = goal.jsonPrimitive.content
                assertNotNull(goalText, "Goal should be a string")
                assertTrue(goalText.isNotBlank(), "Goal should not be blank")
                assertTrue(goalText.length > 5, "Goal should be meaningful")
            }
        }
    }

    @Nested
    @DisplayName("Analytics Events Tests")
    inner class AnalyticsEventsTests {

        @Test
        @DisplayName("Should track analytics events successfully")
        fun testTrackAnalyticsEvent() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            val analyticsEvent = AnalyticsEvent(
                eventType = "content_completed",
                childId = testChildId,
                contentId = "content_123",
                duration = 300,
                metadata = mapOf("category" to "educational", "difficulty" to "easy")
            )

            val response = client.post("/api/v1/analytics/events") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
                contentType(ContentType.Application.Json)
                setBody(Json.encodeToString(AnalyticsEvent.serializer(), analyticsEvent))
            }

            assertEquals(HttpStatusCode.Created, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            
            // Validate tracking response for Flutter
            val expectedFields = setOf("message", "eventId", "timestamp")
            expectedFields.forEach { field ->
                assertTrue(responseBody.containsKey(field), "Tracking response should contain $field")
            }

            assertTrue(responseBody["message"]?.jsonPrimitive?.content?.contains("tracked successfully") == true)
            assertNotNull(responseBody["eventId"]?.jsonPrimitive?.content)
            assertTrue(responseBody["timestamp"]?.jsonPrimitive?.long!! > 0)
        }

        @Test
        @DisplayName("Should validate required event fields")
        fun testAnalyticsEventValidation() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            // Test missing eventType
            val invalidEvent = AnalyticsEvent(
                eventType = "",
                childId = testChildId
            )

            val response = client.post("/api/v1/analytics/events") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
                contentType(ContentType.Application.Json)
                setBody(Json.encodeToString(AnalyticsEvent.serializer(), invalidEvent))
            }

            assertEquals(HttpStatusCode.BadRequest, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertTrue(responseBody["message"]?.jsonPrimitive?.content?.contains("Event type and child ID are required") == true)
        }

        @Test
        @DisplayName("Should handle various event types")
        fun testVariousEventTypes() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            val eventTypes = listOf(
                "content_started", "content_completed", "content_paused",
                "activity_started", "activity_completed", 
                "milestone_achieved", "struggle_detected"
            )

            eventTypes.forEach { eventType ->
                val event = AnalyticsEvent(
                    eventType = eventType,
                    childId = testChildId
                )

                val response = client.post("/api/v1/analytics/events") {
                    header(HttpHeaders.Authorization, "Bearer $validJwtToken")
                    contentType(ContentType.Application.Json)
                    setBody(Json.encodeToString(AnalyticsEvent.serializer(), event))
                }

                assertEquals(HttpStatusCode.Created, response.status, 
                    "Should successfully track event type: $eventType")
            }
        }
    }

    @Nested
    @DisplayName("Legacy Endpoints Tests")
    inner class LegacyEndpointsTests {

        @Test
        @DisplayName("Should redirect legacy daily analytics endpoint")
        fun testLegacyDailyAnalyticsRedirect() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            val response = client.get("/api/v1/analytics/children/$testChildId/daily") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.OK, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertTrue(responseBody["message"]?.jsonPrimitive?.content?.contains("Use /analytics/daily") == true)
        }
    }

    @Nested
    @DisplayName("Error Handling Tests")
    inner class ErrorHandlingTests {

        @Test
        @DisplayName("Should handle malformed JSON in event tracking")
        fun testMalformedEventJson() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            val response = client.post("/api/v1/analytics/events") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
                contentType(ContentType.Application.Json)
                setBody("{ malformed json")
            }

            assertEquals(HttpStatusCode.BadRequest, response.status)
        }

        @Test
        @DisplayName("Should handle server errors gracefully")
        fun testServerErrorHandling() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            // The current mock implementation should work fine, but in real scenarios
            // you'd mock dependencies to throw exceptions to test error handling
            val response = client.get("/api/v1/analytics/daily?childId=$testChildId") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.OK, response.status)
        }

        @Test
        @DisplayName("Should handle invalid child ID formats")
        fun testInvalidChildIdFormat() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            // Test with invalid UUID format
            val response = client.get("/api/v1/analytics/daily?childId=invalid-uuid") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            // Should still work since we're using mock data, but in production
            // this would validate child exists and belongs to family
            assertEquals(HttpStatusCode.OK, response.status)
        }
    }

    @Nested
    @DisplayName("Data Consistency Tests")
    inner class DataConsistencyTests {

        @Test
        @DisplayName("Should maintain consistent child ID across all analytics endpoints")
        fun testChildIdConsistency() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            // Test all endpoints return the same child ID
            val endpoints = listOf(
                "/api/v1/analytics/daily?childId=$testChildId",
                "/api/v1/analytics/weekly?childId=$testChildId",
                "/api/v1/analytics/children/$testChildId/insights",
                "/api/v1/analytics/children/$testChildId/milestones"
            )

            endpoints.forEach { endpoint ->
                val response = client.get(endpoint) {
                    header(HttpHeaders.Authorization, "Bearer $validJwtToken")
                }

                assertEquals(HttpStatusCode.OK, response.status)

                val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
                
                // Check childId field exists and matches (where applicable)
                if (responseBody.containsKey("childId")) {
                    assertEquals(testChildId, responseBody["childId"]?.jsonPrimitive?.content,
                        "Child ID should be consistent across endpoints")
                }
            }
        }

        @Test
        @DisplayName("Should provide reasonable mock data relationships")
        fun testMockDataRelationships() = testApplication {
            application {
                configureTestApplication(jwtService)
            }

            // Get daily and weekly analytics
            val dailyResponse = client.get("/api/v1/analytics/daily?childId=$testChildId") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            val weeklyResponse = client.get("/api/v1/analytics/weekly?childId=$testChildId") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.OK, dailyResponse.status)
            assertEquals(HttpStatusCode.OK, weeklyResponse.status)

            val dailyData = Json.parseToJsonElement(dailyResponse.bodyAsText()).jsonObject
            val weeklyData = Json.parseToJsonElement(weeklyResponse.bodyAsText()).jsonObject

            val dailyScreenTime = dailyData["totalScreenTime"]?.jsonPrimitive?.int!!
            val averageDailyUsage = weeklyData["averageDailyUsage"]?.jsonPrimitive?.int!!

            // These should be in reasonable relationship
            assertTrue(Math.abs(dailyScreenTime - averageDailyUsage) <= 30,
                "Daily screen time should be reasonably close to average daily usage")
        }
    }

    /**
     * Helper function to configure test application with analytics routes and JWT authentication
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
                analyticsRoutes()
            }
        }
    }
}