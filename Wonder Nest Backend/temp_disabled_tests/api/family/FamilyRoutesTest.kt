package com.wondernest.api.family

import com.wondernest.utils.TestUtils
import com.wondernest.services.family.*
import com.wondernest.services.auth.JwtService
import com.wondernest.domain.model.*
import com.wondernest.domain.repository.FamilyRepository
import com.wondernest.data.database.table.UserRole
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
import org.mockito.Mockito.*
import java.util.*
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.test.assertNotNull
import kotlin.test.assertFalse

/**
 * Comprehensive tests for FamilyRoutes endpoints
 * Validates all family and child management operations critical for Flutter integration
 */
@DisplayName("Family Routes Tests")
class FamilyRoutesTest {

    private lateinit var mockFamilyRepository: FamilyRepository
    private lateinit var familyService: FamilyService
    private lateinit var jwtService: JwtService
    private lateinit var testUser: User
    private lateinit var testFamily: Family
    private lateinit var validJwtToken: String

    @BeforeEach
    fun setup() {
        mockFamilyRepository = mock(FamilyRepository::class.java)
        familyService = FamilyService(mockFamilyRepository)
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
    @DisplayName("Family Profile Tests")
    inner class FamilyProfileTests {

        @Test
        @DisplayName("Should retrieve family profile with all members and children")
        fun testGetFamilyProfile() = testApplication {
            application {
                configureTestApplication(familyService, jwtService)
            }

            val testChildren = listOf(
                TestUtils.createTestChild(familyId = testFamily.id, name = "Alice", age = 5),
                TestUtils.createTestChild(familyId = testFamily.id, name = "Bob", age = 8)
            )
            val testMembers = listOf(
                FamilyMember(
                    id = UUID.randomUUID(),
                    familyId = testFamily.id,
                    userId = testUser.id,
                    role = "parent",
                    permissions = mapOf("manage_children" to true),
                    joinedAt = testFamily.createdAt
                )
            )

            `when`(mockFamilyRepository.getFamilyById(testFamily.id)).thenReturn(testFamily)
            `when`(mockFamilyRepository.getFamilyMembers(testFamily.id)).thenReturn(testMembers)
            `when`(mockFamilyRepository.getChildrenByFamily(testFamily.id)).thenReturn(testChildren)

            val response = client.get("/api/v1/family/profile") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.OK, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertTrue(responseBody.containsKey("family"))
            assertTrue(responseBody.containsKey("members"))
            assertTrue(responseBody.containsKey("children"))

            // Validate family data structure matches Flutter expectations
            val familyJson = responseBody["family"]?.jsonObject
            assertNotNull(familyJson)
            TestUtils.validateFlutterApiResponse(
                familyJson!!.mapValues { it.value.toString().removeSurrounding("\"") },
                setOf("id", "name", "createdBy", "timezone", "language")
            )

            // Validate children array
            val childrenArray = responseBody["children"]?.jsonArray
            assertNotNull(childrenArray)
            assertEquals(2, childrenArray!!.size)
        }

        @Test
        @DisplayName("Should handle missing family gracefully")
        fun testGetNonExistentFamily() = testApplication {
            application {
                configureTestApplication(familyService, jwtService)
            }

            `when`(mockFamilyRepository.getFamilyById(any())).thenReturn(null)

            val response = client.get("/api/v1/family/profile") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.NotFound, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertTrue(responseBody.containsKey("error"))
            assertEquals("family_not_found", responseBody["error"]?.jsonPrimitive?.content)
        }

        @Test
        @DisplayName("Should require valid JWT token")
        fun testFamilyProfileRequiresAuth() = testApplication {
            application {
                configureTestApplication(familyService, jwtService)
            }

            val response = client.get("/api/v1/family/profile")

            assertEquals(HttpStatusCode.Unauthorized, response.status)
        }

        @Test
        @DisplayName("Should reject JWT without family context")
        fun testFamilyProfileRequiresFamilyContext() = testApplication {
            application {
                configureTestApplication(familyService, jwtService)
            }

            // Generate token without family context
            val tokenWithoutFamily = jwtService.generateToken(testUser).accessToken

            val response = client.get("/api/v1/family/profile") {
                header(HttpHeaders.Authorization, "Bearer $tokenWithoutFamily")
            }

            assertEquals(HttpStatusCode.BadRequest, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertTrue(responseBody["error"]?.jsonPrimitive?.content?.contains("No family context") == true)
        }
    }

    @Nested
    @DisplayName("Children Management Tests")
    inner class ChildrenManagementTests {

        @Test
        @DisplayName("Should retrieve all children for family")
        fun testGetChildren() = testApplication {
            application {
                configureTestApplication(familyService, jwtService)
            }

            val testChildren = listOf(
                TestUtils.createTestChild(familyId = testFamily.id, name = "Alice", age = 5),
                TestUtils.createTestChild(familyId = testFamily.id, name = "Bob", age = 8)
            )

            `when`(mockFamilyRepository.getChildrenByFamily(testFamily.id)).thenReturn(testChildren)

            val response = client.get("/api/v1/family/children") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.OK, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonArray
            assertEquals(2, responseBody.size)

            // Validate child structure matches Flutter expectations
            val firstChild = responseBody[0].jsonObject
            TestUtils.validateFlutterApiResponse(
                firstChild.mapValues { it.value.toString().removeSurrounding("\"") },
                setOf("id", "familyId", "name", "age", "birthDate")
            )
        }

        @Test
        @DisplayName("Should create new child profile with proper validation")
        fun testCreateChild() = testApplication {
            application {
                configureTestApplication(familyService, jwtService)
            }

            val newChild = TestUtils.createTestChild(
                familyId = testFamily.id,
                name = "Charlie",
                age = 6
            )

            `when`(mockFamilyRepository.createChildProfile(any())).thenReturn(newChild)

            val createRequest = CreateChildRequest(
                name = "Charlie",
                birthDate = "2018-03-15",
                gender = "other",
                interests = listOf("music", "art")
            )

            val response = client.post("/api/v1/family/children") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
                contentType(ContentType.Application.Json)
                setBody(Json.encodeToString(CreateChildRequest.serializer(), createRequest))
            }

            assertEquals(HttpStatusCode.Created, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertEquals("Charlie", responseBody["name"]?.jsonPrimitive?.content)
            assertEquals(testFamily.id.toString(), responseBody["familyId"]?.jsonPrimitive?.content)
            
            // Validate age-appropriate settings were applied
            val contentSettings = responseBody["contentSettings"]?.jsonObject
            assertNotNull(contentSettings)
            assertTrue(contentSettings!!["audioMonitoringEnabled"]?.jsonPrimitive?.boolean == true)
        }

        @Test
        @DisplayName("Should validate child creation input")
        fun testCreateChildValidation() = testApplication {
            application {
                configureTestApplication(familyService, jwtService)
            }

            // Test empty name
            val invalidRequest = CreateChildRequest(
                name = "",
                birthDate = "2018-03-15"
            )

            val response = client.post("/api/v1/family/children") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
                contentType(ContentType.Application.Json)
                setBody(Json.encodeToString(CreateChildRequest.serializer(), invalidRequest))
            }

            assertEquals(HttpStatusCode.BadRequest, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertTrue(responseBody["message"]?.jsonPrimitive?.content?.contains("name is required") == true)
        }

        @Test
        @DisplayName("Should handle invalid birth date format")
        fun testCreateChildInvalidBirthDate() = testApplication {
            application {
                configureTestApplication(familyService, jwtService)
            }

            val invalidRequest = CreateChildRequest(
                name = "Test Child",
                birthDate = "invalid-date"
            )

            val response = client.post("/api/v1/family/children") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
                contentType(ContentType.Application.Json)
                setBody(Json.encodeToString(CreateChildRequest.serializer(), invalidRequest))
            }

            assertEquals(HttpStatusCode.BadRequest, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertTrue(responseBody["message"]?.jsonPrimitive?.content?.contains("Invalid birth date") == true)
        }

        @Test
        @DisplayName("Should update child profile")
        fun testUpdateChild() = testApplication {
            application {
                configureTestApplication(familyService, jwtService)
            }

            val existingChild = TestUtils.createTestChild(name = "Original Name")
            val updatedChild = existingChild.copy(
                name = "Updated Name",
                interests = listOf("updated", "interests")
            )

            `when`(mockFamilyRepository.getChildProfile(existingChild.id)).thenReturn(existingChild)
            `when`(mockFamilyRepository.updateChildProfile(any())).thenReturn(updatedChild)

            val updateRequest = UpdateChildRequest(
                name = "Updated Name",
                interests = listOf("updated", "interests")
            )

            val response = client.put("/api/v1/family/children/${existingChild.id}") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
                contentType(ContentType.Application.Json)
                setBody(Json.encodeToString(UpdateChildRequest.serializer(), updateRequest))
            }

            assertEquals(HttpStatusCode.OK, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertEquals("Updated Name", responseBody["name"]?.jsonPrimitive?.content)
        }

        @Test
        @DisplayName("Should delete/archive child profile")
        fun testDeleteChild() = testApplication {
            application {
                configureTestApplication(familyService, jwtService)
            }

            val childId = UUID.randomUUID()
            `when`(mockFamilyRepository.archiveChildProfile(childId)).thenReturn(true)

            val response = client.delete("/api/v1/family/children/$childId") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.OK, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertTrue(responseBody["message"]?.jsonPrimitive?.content?.contains("archived successfully") == true)
        }

        @Test
        @DisplayName("Should handle child not found for delete")
        fun testDeleteNonExistentChild() = testApplication {
            application {
                configureTestApplication(familyService, jwtService)
            }

            val childId = UUID.randomUUID()
            `when`(mockFamilyRepository.archiveChildProfile(childId)).thenReturn(false)

            val response = client.delete("/api/v1/family/children/$childId") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.NotFound, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertEquals("child_not_found", responseBody["error"]?.jsonPrimitive?.content)
        }
    }

    @Nested
    @DisplayName("Individual Child Operations Tests")
    inner class IndividualChildTests {

        @Test
        @DisplayName("Should retrieve specific child profile")
        fun testGetIndividualChild() = testApplication {
            application {
                configureTestApplication(familyService, jwtService)
            }

            val testChild = TestUtils.createTestChild(familyId = testFamily.id)
            `when`(mockFamilyRepository.getChildProfile(testChild.id)).thenReturn(testChild)

            val response = client.get("/api/v1/family/children/${testChild.id}") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.OK, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertEquals(testChild.id.toString(), responseBody["id"]?.jsonPrimitive?.content)
            assertEquals(testChild.name, responseBody["name"]?.jsonPrimitive?.content)
            assertEquals(testChild.age, responseBody["age"]?.jsonPrimitive?.int)
        }

        @Test
        @DisplayName("Should handle child not found")
        fun testGetNonExistentChild() = testApplication {
            application {
                configureTestApplication(familyService, jwtService)
            }

            val childId = UUID.randomUUID()
            `when`(mockFamilyRepository.getChildProfile(childId)).thenReturn(null)

            val response = client.get("/api/v1/family/children/$childId") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.NotFound, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertEquals("child_not_found", responseBody["error"]?.jsonPrimitive?.content)
        }

        @Test
        @DisplayName("Should select active child for session")
        fun testSelectChild() = testApplication {
            application {
                configureTestApplication(familyService, jwtService)
            }

            val testChild = TestUtils.createTestChild(familyId = testFamily.id)
            `when`(mockFamilyRepository.getChildProfile(testChild.id)).thenReturn(testChild)

            val response = client.post("/api/v1/family/children/${testChild.id}/select") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.OK, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertTrue(responseBody.containsKey("message"))
            assertTrue(responseBody.containsKey("activeChild"))
            assertTrue(responseBody.containsKey("sessionToken"))
            assertTrue(responseBody["message"]?.jsonPrimitive?.content?.contains("selected successfully") == true)
        }

        @Test
        @DisplayName("Should prevent selecting child from different family")
        fun testSelectChildFamilyValidation() = testApplication {
            application {
                configureTestApplication(familyService, jwtService)
            }

            val differentFamilyId = UUID.randomUUID()
            val testChild = TestUtils.createTestChild(familyId = differentFamilyId) // Different family
            `when`(mockFamilyRepository.getChildProfile(testChild.id)).thenReturn(testChild)

            val response = client.post("/api/v1/family/children/${testChild.id}/select") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.Forbidden, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertEquals("access_denied", responseBody["error"]?.jsonPrimitive?.content)
            assertTrue(responseBody["message"]?.jsonPrimitive?.content?.contains("does not belong") == true)
        }
    }

    @Nested
    @DisplayName("Data Validation Tests")
    inner class DataValidationTests {

        @Test
        @DisplayName("Should validate UUID format in child operations")
        fun testInvalidUuidHandling() = testApplication {
            application {
                configureTestApplication(familyService, jwtService)
            }

            val response = client.get("/api/v1/family/children/invalid-uuid") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.BadRequest, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertEquals("invalid_child_id", responseBody["error"]?.jsonPrimitive?.content)
        }

        @Test
        @DisplayName("Should validate content settings in child updates")
        fun testChildContentSettingsValidation() = testApplication {
            application {
                configureTestApplication(familyService, jwtService)
            }

            val existingChild = TestUtils.createTestChild()
            val updatedChild = existingChild.copy(
                contentSettings = ContentSettings(
                    maxAgeRating = 12,
                    subtitlesEnabled = true,
                    audioMonitoringEnabled = false
                )
            )

            `when`(mockFamilyRepository.getChildProfile(existingChild.id)).thenReturn(existingChild)
            `when`(mockFamilyRepository.updateChildProfile(any())).thenReturn(updatedChild)

            val updateRequest = UpdateChildRequest(
                contentSettings = ContentSettings(
                    maxAgeRating = 12,
                    subtitlesEnabled = true,
                    audioMonitoringEnabled = false
                )
            )

            val response = client.put("/api/v1/family/children/${existingChild.id}") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
                contentType(ContentType.Application.Json)
                setBody(Json.encodeToString(UpdateChildRequest.serializer(), updateRequest))
            }

            assertEquals(HttpStatusCode.OK, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            val contentSettings = responseBody["contentSettings"]?.jsonObject
            assertEquals(12, contentSettings!!["maxAgeRating"]?.jsonPrimitive?.int)
            assertEquals(true, contentSettings["subtitlesEnabled"]?.jsonPrimitive?.boolean)
        }

        @Test
        @DisplayName("Should validate time restrictions in child updates")
        fun testChildTimeRestrictionsValidation() = testApplication {
            application {
                configureTestApplication(familyService, jwtService)
            }

            val existingChild = TestUtils.createTestChild()
            val updatedChild = existingChild.copy(
                timeRestrictions = TimeRestrictions(
                    dailyScreenTimeMinutes = 90,
                    bedtimeEnabled = true,
                    bedtimeStart = "20:00",
                    bedtimeEnd = "07:00"
                )
            )

            `when`(mockFamilyRepository.getChildProfile(existingChild.id)).thenReturn(existingChild)
            `when`(mockFamilyRepository.updateChildProfile(any())).thenReturn(updatedChild)

            val updateRequest = UpdateChildRequest(
                timeRestrictions = TimeRestrictions(
                    dailyScreenTimeMinutes = 90,
                    bedtimeEnabled = true,
                    bedtimeStart = "20:00",
                    bedtimeEnd = "07:00"
                )
            )

            val response = client.put("/api/v1/family/children/${existingChild.id}") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
                contentType(ContentType.Application.Json)
                setBody(Json.encodeToString(UpdateChildRequest.serializer(), updateRequest))
            }

            assertEquals(HttpStatusCode.OK, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            val timeRestrictions = responseBody["timeRestrictions"]?.jsonObject
            assertEquals(90, timeRestrictions!!["dailyScreenTimeMinutes"]?.jsonPrimitive?.int)
            assertEquals("20:00", timeRestrictions["bedtimeStart"]?.jsonPrimitive?.content)
        }
    }

    @Nested
    @DisplayName("Error Handling Tests")
    inner class ErrorHandlingTests {

        @Test
        @DisplayName("Should handle repository errors gracefully")
        fun testRepositoryError() = testApplication {
            application {
                configureTestApplication(familyService, jwtService)
            }

            `when`(mockFamilyRepository.getChildrenByFamily(any())).thenThrow(RuntimeException("Database error"))

            val response = client.get("/api/v1/family/children") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
            }

            assertEquals(HttpStatusCode.InternalServerError, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertEquals("server_error", responseBody["error"]?.jsonPrimitive?.content)
        }

        @Test
        @DisplayName("Should handle malformed JSON in requests")
        fun testMalformedJsonHandling() = testApplication {
            application {
                configureTestApplication(familyService, jwtService)
            }

            val response = client.post("/api/v1/family/children") {
                header(HttpHeaders.Authorization, "Bearer $validJwtToken")
                contentType(ContentType.Application.Json)
                setBody("{ malformed json")
            }

            assertEquals(HttpStatusCode.BadRequest, response.status)
        }
    }

    /**
     * Helper function to configure test application with family routes and JWT authentication
     */
    private fun Application.configureTestApplication(
        familyService: FamilyService,
        jwtService: JwtService
    ) {
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
                familyRoutes()
            }
        }
    }
}