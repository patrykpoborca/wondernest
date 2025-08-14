package com.wondernest

import com.wondernest.utils.TestUtils
import com.wondernest.services.auth.*
import com.wondernest.services.family.*
import com.wondernest.domain.model.*
import com.wondernest.domain.repository.*
import com.wondernest.services.email.EmailService
import com.wondernest.data.database.table.UserRole
import com.wondernest.data.database.table.UserStatus
import io.ktor.client.request.*
import io.ktor.client.statement.*
import io.ktor.http.*
import io.ktor.server.testing.*
import kotlinx.serialization.json.*
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.TestMethodOrder
import org.junit.jupiter.api.MethodOrderer
import org.junit.jupiter.api.Order
import org.mockito.Mockito.*
import java.util.*
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.test.assertNotNull

/**
 * Comprehensive integration test that validates the entire API flow
 * This test ensures all endpoints work together correctly for Flutter integration
 */
@DisplayName("Comprehensive Integration Test Suite")
@TestMethodOrder(MethodOrderer.OrderAnnotation::class)
class ComprehensiveIntegrationTest {

    private lateinit var mockUserRepository: UserRepository
    private lateinit var mockFamilyRepository: FamilyRepository
    private lateinit var mockEmailService: EmailService
    private lateinit var authService: AuthService
    private lateinit var familyService: FamilyService
    private lateinit var jwtService: JwtService
    
    // Test data that will be used across multiple tests
    private lateinit var testUser: User
    private lateinit var testFamily: Family
    private lateinit var testChild: ChildProfile
    private var accessToken: String = ""
    private var familyId: UUID = UUID.randomUUID()

    @BeforeEach
    fun setup() {
        // Initialize mocks
        mockUserRepository = mock(UserRepository::class.java)
        mockFamilyRepository = mock(FamilyRepository::class.java)
        mockEmailService = mock(EmailService::class.java)
        
        // Initialize services
        jwtService = TestConfig.createTestJwtService()
        authService = AuthService(
            userRepository = mockUserRepository,
            familyRepository = mockFamilyRepository,
            jwtService = jwtService,
            emailService = mockEmailService
        )
        familyService = FamilyService(mockFamilyRepository)
        
        // Setup test data
        setupTestData()
    }

    private fun setupTestData() {
        testUser = TestUtils.createTestUser(
            email = TestConfig.TestData.TEST_EMAIL,
            firstName = "Integration",
            lastName = "Test",
            role = UserRole.PARENT,
            status = UserStatus.ACTIVE
        )
        
        testFamily = TestUtils.createTestFamily(
            name = TestConfig.TestData.TEST_FAMILY_NAME,
            createdBy = testUser.id
        )
        familyId = testFamily.id
        
        testChild = TestUtils.createTestChild(
            familyId = familyId,
            name = TestConfig.TestData.TEST_CHILD_NAME,
            age = 6
        )
    }

    @Test
    @Order(1)
    @DisplayName("Complete Authentication Flow - Parent Registration to Login")
    fun testCompleteAuthenticationFlow() = testApplication {
        application {
            configureTestApplication(authService, familyService, jwtService)
        }

        // Setup mocks for successful registration
        `when`(mockUserRepository.getUserByEmail(any())).thenReturn(null)
        `when`(mockUserRepository.createUser(any())).thenReturn(testUser)
        `when`(mockUserRepository.updateUserPassword(any(), any())).thenReturn(true)
        `when`(mockFamilyRepository.createFamily(any())).thenReturn(testFamily)
        `when`(mockFamilyRepository.addFamilyMember(any())).thenReturn(Unit)
        `when`(mockUserRepository.createSession(any())).thenReturn(Unit)

        // Step 1: Register parent
        val signupRequest = TestUtils.createSignupRequest(
            email = TestConfig.TestData.TEST_EMAIL,
            password = TestConfig.TestData.TEST_PASSWORD
        )

        val registerResponse = client.post(TestConfig.Endpoints.AUTH_PARENT_REGISTER) {
            contentType(ContentType.Application.Json)
            setBody(Json.encodeToString(SignupRequest.serializer(), signupRequest))
        }

        assertEquals(HttpStatusCode.Created, registerResponse.status)
        
        val registerBody = Json.parseToJsonElement(registerResponse.bodyAsText()).jsonObject
        ApiAssertions.assertAuthResponse(registerBody)
        
        // Extract access token for subsequent requests
        accessToken = registerBody["accessToken"]?.jsonPrimitive?.content!!
        
        // Verify JWT contains familyId
        val familyIdFromToken = jwtService.extractFamilyIdFromToken(accessToken)
        assertNotNull(familyIdFromToken, "JWT should contain familyId")

        // Step 2: Verify PIN works
        val pinRequest = PinVerificationRequest(pin = TestConfig.TestData.DEFAULT_PIN)
        
        val pinResponse = client.post(TestConfig.Endpoints.AUTH_PARENT_VERIFY_PIN) {
            contentType(ContentType.Application.Json)
            setBody(Json.encodeToString(PinVerificationRequest.serializer(), pinRequest))
        }
        
        assertEquals(HttpStatusCode.OK, pinResponse.status)
        
        val pinBody = Json.parseToJsonElement(pinResponse.bodyAsText()).jsonObject
        assertEquals(true, pinBody["verified"]?.jsonPrimitive?.boolean)
        assertNotNull(pinBody["sessionToken"]?.jsonPrimitive?.content)

        // Step 3: Test login flow
        `when`(mockUserRepository.getUserByEmail(TestConfig.TestData.TEST_EMAIL)).thenReturn(testUser)
        val passwordHash = org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder(12)
            .encode(TestConfig.TestData.TEST_PASSWORD)
        `when`(mockUserRepository.getUserPasswordHash(testUser.id)).thenReturn(passwordHash)
        `when`(mockFamilyRepository.getFamilyByUserId(testUser.id)).thenReturn(testFamily)
        `when`(mockUserRepository.updateLastLogin(testUser.id)).thenReturn(Unit)

        val loginRequest = TestUtils.createLoginRequest(
            email = TestConfig.TestData.TEST_EMAIL,
            password = TestConfig.TestData.TEST_PASSWORD
        )

        val loginResponse = client.post(TestConfig.Endpoints.AUTH_PARENT_LOGIN) {
            contentType(ContentType.Application.Json)
            setBody(Json.encodeToString(LoginRequest.serializer(), loginRequest))
        }

        assertEquals(HttpStatusCode.OK, loginResponse.status)
        
        val loginBody = Json.parseToJsonElement(loginResponse.bodyAsText()).jsonObject
        ApiAssertions.assertAuthResponse(loginBody)
        
        // Update access token from login
        accessToken = loginBody["accessToken"]?.jsonPrimitive?.content!!
    }

    @Test
    @Order(2)
    @DisplayName("Complete Family Management Flow - Profile to Child Management")
    fun testCompleteFamilyManagementFlow() = testApplication {
        application {
            configureTestApplication(authService, familyService, jwtService)
        }

        // Generate a valid token for this test
        val tokenPair = jwtService.generateTokenWithFamilyContext(testUser, familyId)
        val validToken = tokenPair.accessToken

        // Setup mocks for family operations
        `when`(mockFamilyRepository.getFamilyById(familyId)).thenReturn(testFamily)
        `when`(mockFamilyRepository.getFamilyMembers(familyId)).thenReturn(emptyList())
        `when`(mockFamilyRepository.getChildrenByFamily(familyId)).thenReturn(listOf(testChild))

        // Step 1: Get family profile
        val profileResponse = client.get(TestConfig.Endpoints.FAMILY_PROFILE) {
            header(HttpHeaders.Authorization, validToken.toBearerToken())
        }

        assertEquals(HttpStatusCode.OK, profileResponse.status)
        
        val profileBody = Json.parseToJsonElement(profileResponse.bodyAsText()).jsonObject
        assertTrue(profileBody.containsKey("family"))
        assertTrue(profileBody.containsKey("members"))
        assertTrue(profileBody.containsKey("children"))

        // Step 2: Get children list
        val childrenResponse = client.get(TestConfig.Endpoints.FAMILY_CHILDREN) {
            header(HttpHeaders.Authorization, validToken.toBearerToken())
        }

        assertEquals(HttpStatusCode.OK, childrenResponse.status)
        
        val childrenArray = Json.parseToJsonElement(childrenResponse.bodyAsText()).jsonArray
        assertEquals(1, childrenArray.size)

        // Step 3: Create new child
        `when`(mockFamilyRepository.createChildProfile(any())).thenReturn(testChild)

        val createChildRequest = CreateChildRequest(
            name = "New Test Child",
            birthDate = "2019-05-10",
            gender = "other",
            interests = listOf("music", "art")
        )

        val createChildResponse = client.post(TestConfig.Endpoints.FAMILY_CHILDREN) {
            header(HttpHeaders.Authorization, validToken.toBearerToken())
            contentType(ContentType.Application.Json)
            setBody(Json.encodeToString(CreateChildRequest.serializer(), createChildRequest))
        }

        assertEquals(HttpStatusCode.Created, createChildResponse.status)
        
        val createdChildBody = Json.parseToJsonElement(createChildResponse.bodyAsText()).jsonObject
        assertEquals("New Test Child", createdChildBody["name"]?.jsonPrimitive?.content)

        // Step 4: Update child
        `when`(mockFamilyRepository.getChildProfile(testChild.id)).thenReturn(testChild)
        val updatedChild = testChild.copy(name = "Updated Child Name")
        `when`(mockFamilyRepository.updateChildProfile(any())).thenReturn(updatedChild)

        val updateRequest = UpdateChildRequest(name = "Updated Child Name")

        val updateResponse = client.put("${TestConfig.Endpoints.FAMILY_CHILDREN}/${testChild.id}") {
            header(HttpHeaders.Authorization, validToken.toBearerToken())
            contentType(ContentType.Application.Json)
            setBody(Json.encodeToString(UpdateChildRequest.serializer(), updateRequest))
        }

        assertEquals(HttpStatusCode.OK, updateResponse.status)
    }

    @Test
    @Order(3)
    @DisplayName("Complete Content Discovery Flow - Browse to Recommendations")
    fun testCompleteContentDiscoveryFlow() = testApplication {
        application {
            configureTestApplication(authService, familyService, jwtService)
        }

        val validToken = jwtService.generateTokenWithFamilyContext(testUser, familyId).accessToken

        // Step 1: Browse content with default parameters
        val contentResponse = client.get(TestConfig.Endpoints.CONTENT) {
            header(HttpHeaders.Authorization, validToken.toBearerToken())
        }

        assertEquals(HttpStatusCode.OK, contentResponse.status)
        
        val contentBody = Json.parseToJsonElement(contentResponse.bodyAsText()).jsonObject
        ApiAssertions.assertPaginatedResponse(contentBody)
        
        val items = contentBody["items"]?.jsonArray
        val categories = contentBody["categories"]?.jsonArray
        assertNotNull(items)
        assertNotNull(categories)
        assertTrue(items!!.size > 0, "Should have content items")
        assertTrue(categories!!.size > 0, "Should have categories")

        // Step 2: Filter content by age and category
        val filteredResponse = client.get("${TestConfig.Endpoints.CONTENT}?ageGroup=6&category=educational") {
            header(HttpHeaders.Authorization, validToken.toBearerToken())
        }

        assertEquals(HttpStatusCode.OK, filteredResponse.status)
        
        val filteredBody = Json.parseToJsonElement(filteredResponse.bodyAsText()).jsonObject
        val filteredItems = filteredBody["items"]?.jsonArray
        
        // Verify filtering worked
        filteredItems?.forEach { item ->
            val contentItem = item.jsonObject
            val ageRating = contentItem["ageRating"]?.jsonPrimitive?.int
            val category = contentItem["category"]?.jsonPrimitive?.content
            
            assertTrue(ageRating!! <= 8, "Content should be age-appropriate")
            assertEquals("educational", category, "Content should match category filter")
        }

        // Step 3: Get content recommendations
        val recommendationsResponse = client.get("${TestConfig.Endpoints.CONTENT}/recommendations/${testChild.id}") {
            header(HttpHeaders.Authorization, validToken.toBearerToken())
        }

        assertEquals(HttpStatusCode.OK, recommendationsResponse.status)
        
        val recommendationsBody = Json.parseToJsonElement(recommendationsResponse.bodyAsText()).jsonObject
        assertTrue(recommendationsBody.containsKey("childId"))
        assertTrue(recommendationsBody.containsKey("recommendations"))
        assertTrue(recommendationsBody.containsKey("reason"))
        
        val recommendations = recommendationsBody["recommendations"]?.jsonArray
        assertNotNull(recommendations)
        assertTrue(recommendations!!.size > 0, "Should have recommendations")

        // Step 4: Get specific content item
        val specificContentResponse = client.get("${TestConfig.Endpoints.CONTENT}/content_1") {
            header(HttpHeaders.Authorization, validToken.toBearerToken())
        }

        assertEquals(HttpStatusCode.OK, specificContentResponse.status)
        
        val specificContentBody = Json.parseToJsonElement(specificContentResponse.bodyAsText()).jsonObject
        assertEquals("content_1", specificContentBody["id"]?.jsonPrimitive?.content)
        assertTrue(specificContentBody.containsKey("title"))
        assertTrue(specificContentBody.containsKey("description"))

        // Step 5: Get content categories
        val categoriesResponse = client.get("/api/v1/categories") {
            header(HttpHeaders.Authorization, validToken.toBearerToken())
        }

        assertEquals(HttpStatusCode.OK, categoriesResponse.status)
        
        val categoriesBody = Json.parseToJsonElement(categoriesResponse.bodyAsText()).jsonObject
        val categoriesArray = categoriesBody["categories"]?.jsonArray
        assertNotNull(categoriesArray)
        assertTrue(categoriesArray!!.size > 0)
    }

    @Test
    @Order(4)
    @DisplayName("Complete Analytics Flow - Daily to Weekly Overview")
    fun testCompleteAnalyticsFlow() = testApplication {
        application {
            configureTestApplication(authService, familyService, jwtService)
        }

        val validToken = jwtService.generateTokenWithFamilyContext(testUser, familyId).accessToken

        // Step 1: Get daily analytics
        val dailyResponse = client.get("${TestConfig.Endpoints.ANALYTICS_DAILY}?childId=${testChild.id}") {
            header(HttpHeaders.Authorization, validToken.toBearerToken())
        }

        assertEquals(HttpStatusCode.OK, dailyResponse.status)
        
        val dailyBody = Json.parseToJsonElement(dailyResponse.bodyAsText()).jsonObject
        val expectedDailyFields = setOf(
            "date", "childId", "totalScreenTime", "contentConsumed",
            "educationalTime", "averageSessionLength", "mostEngagedCategory",
            "completedActivities", "learningProgress"
        )
        expectedDailyFields.forEach { field ->
            assertTrue(dailyBody.containsKey(field), "Daily analytics missing field: $field")
        }

        // Step 2: Get weekly overview
        val weeklyResponse = client.get("${TestConfig.Endpoints.ANALYTICS_WEEKLY}?childId=${testChild.id}") {
            header(HttpHeaders.Authorization, validToken.toBearerToken())
        }

        assertEquals(HttpStatusCode.OK, weeklyResponse.status)
        
        val weeklyBody = Json.parseToJsonElement(weeklyResponse.bodyAsText()).jsonObject
        val expectedWeeklyFields = setOf(
            "weekStart", "totalScreenTime", "educationalPercentage",
            "averageDailyUsage", "topCategories", "completionRate", "parentalInteraction"
        )
        expectedWeeklyFields.forEach { field ->
            assertTrue(weeklyBody.containsKey(field), "Weekly analytics missing field: $field")
        }

        // Step 3: Get child insights
        val insightsResponse = client.get("/api/v1/analytics/children/${testChild.id}/insights") {
            header(HttpHeaders.Authorization, validToken.toBearerToken())
        }

        assertEquals(HttpStatusCode.OK, insightsResponse.status)
        
        val insightsBody = Json.parseToJsonElement(insightsResponse.bodyAsText()).jsonObject
        val expectedInsightsFields = setOf(
            "childId", "preferredLearningStyle", "strongSubjects",
            "improvementAreas", "recommendedActivities", "parentalGuidance"
        )
        expectedInsightsFields.forEach { field ->
            assertTrue(insightsBody.containsKey(field), "Child insights missing field: $field")
        }

        // Step 4: Get milestones
        val milestonesResponse = client.get("/api/v1/analytics/children/${testChild.id}/milestones") {
            header(HttpHeaders.Authorization, validToken.toBearerToken())
        }

        assertEquals(HttpStatusCode.OK, milestonesResponse.status)
        
        val milestonesBody = Json.parseToJsonElement(milestonesResponse.bodyAsText()).jsonObject
        assertTrue(milestonesBody.containsKey("age"))
        assertTrue(milestonesBody.containsKey("milestones"))
        assertTrue(milestonesBody.containsKey("nextGoals"))

        // Step 5: Track analytics event
        val analyticsEvent = AnalyticsEvent(
            eventType = "content_completed",
            childId = testChild.id.toString(),
            contentId = "content_1",
            duration = 300
        )

        val trackEventResponse = client.post("/api/v1/analytics/events") {
            header(HttpHeaders.Authorization, validToken.toBearerToken())
            contentType(ContentType.Application.Json)
            setBody(Json.encodeToString(AnalyticsEvent.serializer(), analyticsEvent))
        }

        assertEquals(HttpStatusCode.Created, trackEventResponse.status)
        
        val trackEventBody = Json.parseToJsonElement(trackEventResponse.bodyAsText()).jsonObject
        assertTrue(trackEventBody.containsKey("message"))
        assertTrue(trackEventBody.containsKey("eventId"))
        assertTrue(trackEventBody.containsKey("timestamp"))
    }

    @Test
    @Order(5)
    @DisplayName("End-to-End Error Handling Validation")
    fun testEndToEndErrorHandling() = testApplication {
        application {
            configureTestApplication(authService, familyService, jwtService)
        }

        val validToken = jwtService.generateTokenWithFamilyContext(testUser, familyId).accessToken

        // Test 1: Unauthorized access
        val unauthorizedResponse = client.get(TestConfig.Endpoints.FAMILY_PROFILE)
        assertEquals(HttpStatusCode.Unauthorized, unauthorizedResponse.status)

        // Test 2: Missing family context
        val tokenWithoutFamily = jwtService.generateToken(testUser).accessToken
        val noFamilyResponse = client.get(TestConfig.Endpoints.FAMILY_PROFILE) {
            header(HttpHeaders.Authorization, tokenWithoutFamily.toBearerToken())
        }
        assertEquals(HttpStatusCode.BadRequest, noFamilyResponse.status)

        // Test 3: Invalid JSON
        val invalidJsonResponse = client.post(TestConfig.Endpoints.FAMILY_CHILDREN) {
            header(HttpHeaders.Authorization, validToken.toBearerToken())
            contentType(ContentType.Application.Json)
            setBody("{ invalid json")
        }
        assertEquals(HttpStatusCode.BadRequest, invalidJsonResponse.status)

        // Test 4: Missing required parameters
        val missingParamsResponse = client.get(TestConfig.Endpoints.ANALYTICS_DAILY) {
            header(HttpHeaders.Authorization, validToken.toBearerToken())
        }
        assertEquals(HttpStatusCode.BadRequest, missingParamsResponse.status)

        // Test 5: Non-existent resource
        val notFoundResponse = client.get("${TestConfig.Endpoints.CONTENT}/nonexistent") {
            header(HttpHeaders.Authorization, validToken.toBearerToken())
        }
        assertEquals(HttpStatusCode.NotFound, notFoundResponse.status)
    }

    @Test
    @Order(6)
    @DisplayName("Data Consistency Across All Endpoints")
    fun testDataConsistencyAcrossEndpoints() = testApplication {
        application {
            configureTestApplication(authService, familyService, jwtService)
        }

        val validToken = jwtService.generateTokenWithFamilyContext(testUser, familyId).accessToken

        // Verify JWT claims are consistent
        val extractedFamilyId = jwtService.extractFamilyIdFromToken(validToken)
        val extractedUserId = jwtService.extractUserIdFromToken(validToken)
        val extractedRole = jwtService.extractRoleFromToken(validToken)

        assertEquals(familyId.toString(), extractedFamilyId)
        assertEquals(testUser.id.toString(), extractedUserId)
        assertEquals(UserRole.PARENT.name, extractedRole)

        // Test consistent child ID across analytics endpoints
        val childIdToTest = testChild.id.toString()
        
        val analyticsEndpoints = mapOf(
            "daily" to "${TestConfig.Endpoints.ANALYTICS_DAILY}?childId=$childIdToTest",
            "weekly" to "${TestConfig.Endpoints.ANALYTICS_WEEKLY}?childId=$childIdToTest",
            "insights" to "/api/v1/analytics/children/$childIdToTest/insights"
        )

        analyticsEndpoints.forEach { (type, endpoint) ->
            val response = client.get(endpoint) {
                header(HttpHeaders.Authorization, validToken.toBearerToken())
            }
            
            assertEquals(HttpStatusCode.OK, response.status, "Failed for $type analytics")
            
            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            if (responseBody.containsKey("childId")) {
                assertEquals(childIdToTest, responseBody["childId"]?.jsonPrimitive?.content,
                    "Child ID should be consistent in $type analytics")
            }
        }
    }

    @Test
    @Order(7)
    @DisplayName("Flutter Integration Compatibility Validation")
    fun testFlutterIntegrationCompatibility() = testApplication {
        application {
            configureTestApplication(authService, familyService, jwtService)
        }

        val validToken = jwtService.generateTokenWithFamilyContext(testUser, familyId).accessToken

        // Test all critical Flutter integration points
        val flutterCriticalEndpoints = mapOf(
            "Authentication Response" to TestConfig.Endpoints.AUTH_PARENT_REGISTER,
            "Family Profile" to TestConfig.Endpoints.FAMILY_PROFILE,
            "Content Library" to TestConfig.Endpoints.CONTENT,
            "Daily Analytics" to "${TestConfig.Endpoints.ANALYTICS_DAILY}?childId=${testChild.id}"
        )

        // Setup minimal mocks for this test
        `when`(mockUserRepository.getUserByEmail(any())).thenReturn(null)
        `when`(mockUserRepository.createUser(any())).thenReturn(testUser)
        `when`(mockUserRepository.updateUserPassword(any(), any())).thenReturn(true)
        `when`(mockFamilyRepository.createFamily(any())).thenReturn(testFamily)
        `when`(mockFamilyRepository.addFamilyMember(any())).thenReturn(Unit)
        `when`(mockUserRepository.createSession(any())).thenReturn(Unit)
        `when`(mockFamilyRepository.getFamilyById(familyId)).thenReturn(testFamily)
        `when`(mockFamilyRepository.getFamilyMembers(familyId)).thenReturn(emptyList())
        `when`(mockFamilyRepository.getChildrenByFamily(familyId)).thenReturn(listOf(testChild))

        flutterCriticalEndpoints.forEach { (name, endpoint) ->
            val response = when (name) {
                "Authentication Response" -> {
                    val signupRequest = TestUtils.createSignupRequest()
                    client.post(endpoint) {
                        contentType(ContentType.Application.Json)
                        setBody(Json.encodeToString(SignupRequest.serializer(), signupRequest))
                    }
                }
                else -> {
                    client.get(endpoint) {
                        header(HttpHeaders.Authorization, validToken.toBearerToken())
                    }
                }
            }

            assertTrue(response.status.isSuccess(), "$name endpoint should be successful")
            
            // Verify response is valid JSON
            val responseBody = Json.parseToJsonElement(response.bodyAsText())
            assertNotNull(responseBody, "$name should return valid JSON")
            
            // Verify response structure based on endpoint type
            when (name) {
                "Authentication Response" -> {
                    ApiAssertions.assertAuthResponse(responseBody.jsonObject)
                }
                "Content Library" -> {
                    ApiAssertions.assertPaginatedResponse(responseBody.jsonObject)
                }
            }
        }
    }
}