package com.wondernest.api.auth

import com.wondernest.utils.TestUtils
import com.wondernest.services.auth.*
import com.wondernest.domain.model.User
import com.wondernest.domain.model.Family
import com.wondernest.domain.repository.UserRepository
import com.wondernest.domain.repository.FamilyRepository
import com.wondernest.services.email.EmailService
import com.wondernest.data.database.table.UserStatus
import com.wondernest.data.database.table.UserRole
import io.ktor.client.request.*
import io.ktor.client.statement.*
import io.ktor.http.*
import io.ktor.server.testing.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.serialization.json.*
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.assertThrows
import org.mockito.Mockito.*
import java.util.*
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.test.assertNotNull
import kotlin.test.assertNull

/**
 * Comprehensive tests for AuthRoutes endpoints
 * Tests critical authentication flows that Flutter frontend depends on
 */
@DisplayName("Authentication Routes Tests")
class AuthRoutesTest {

    private lateinit var mockUserRepository: UserRepository
    private lateinit var mockFamilyRepository: FamilyRepository
    private lateinit var mockEmailService: EmailService
    private lateinit var authService: AuthService
    private lateinit var jwtService: JwtService

    @BeforeEach
    fun setup() {
        mockUserRepository = mock(UserRepository::class.java)
        mockFamilyRepository = mock(FamilyRepository::class.java)
        mockEmailService = mock(EmailService::class.java)
        
        jwtService = JwtService()
        authService = AuthService(
            userRepository = mockUserRepository,
            familyRepository = mockFamilyRepository,
            jwtService = jwtService,
            emailService = mockEmailService
        )
    }

    @Nested
    @DisplayName("Parent Registration Tests")
    inner class ParentRegistrationTests {

        @Test
        @DisplayName("Should successfully register parent with family creation")
        fun testSuccessfulParentRegistration() = testApplication {
            application {
                // Configure test application with auth routes
                configureTestApplication(authService)
            }

            // Mock successful user creation
            val testUser = TestUtils.createTestUser(
                email = "parent@example.com",
                firstName = "John",
                lastName = "Doe",
                status = UserStatus.PENDING_VERIFICATION
            )
            val testFamily = TestUtils.createTestFamily(createdBy = testUser.id)
            
            `when`(mockUserRepository.getUserByEmail(any())).thenReturn(null)
            `when`(mockUserRepository.createUser(any())).thenReturn(testUser)
            `when`(mockUserRepository.updateUserPassword(any(), any())).thenReturn(true)
            `when`(mockFamilyRepository.createFamily(any())).thenReturn(testFamily)
            `when`(mockFamilyRepository.addFamilyMember(any())).thenReturn(Unit)
            `when`(mockUserRepository.createSession(any())).thenReturn(Unit)

            val signupRequest = TestUtils.createSignupRequest(
                email = "parent@example.com",
                firstName = "John",
                lastName = "Doe"
            )

            val response = client.post("/api/v1/auth/parent/register") {
                contentType(ContentType.Application.Json)
                setBody(Json.encodeToString(SignupRequest.serializer(), signupRequest))
            }

            // Assertions
            assertEquals(HttpStatusCode.Created, response.status)
            
            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertTrue(responseBody.containsKey("user"))
            assertTrue(responseBody.containsKey("accessToken"))
            assertTrue(responseBody.containsKey("refreshToken"))
            assertTrue(responseBody.containsKey("expiresIn"))

            // Validate JWT token structure
            val accessToken = responseBody["accessToken"]?.jsonPrimitive?.content
            assertNotNull(accessToken)
            TestUtils.assertJwtTokenStructure(accessToken!!)
            
            // Verify JWT contains familyId claim
            val familyIdFromToken = jwtService.extractFamilyIdFromToken(accessToken)
            assertNotNull(familyIdFromToken, "JWT token should contain familyId claim")

            // Verify user object structure matches Flutter expectations
            val userJson = responseBody["user"]?.jsonObject
            assertNotNull(userJson)
            TestUtils.validateFlutterApiResponse(
                userJson!!.mapValues { it.value.toString().removeSurrounding("\"") },
                setOf("id", "email", "firstName", "lastName", "role", "emailVerified")
            )
        }

        @Test
        @DisplayName("Should reject duplicate email registration")
        fun testDuplicateEmailRegistration() = testApplication {
            application {
                configureTestApplication(authService)
            }

            // Mock existing user
            val existingUser = TestUtils.createTestUser(email = "existing@example.com")
            `when`(mockUserRepository.getUserByEmail("existing@example.com")).thenReturn(existingUser)

            val signupRequest = TestUtils.createSignupRequest(email = "existing@example.com")

            val response = client.post("/api/v1/auth/parent/register") {
                contentType(ContentType.Application.Json)
                setBody(Json.encodeToString(SignupRequest.serializer(), signupRequest))
            }

            assertEquals(HttpStatusCode.BadRequest, response.status)
            
            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertTrue(responseBody.containsKey("message"))
            assertTrue(responseBody["message"]?.jsonPrimitive?.content?.contains("already exists") == true)
        }

        @Test
        @DisplayName("Should validate password requirements")
        fun testPasswordValidation() = testApplication {
            application {
                configureTestApplication(authService)
            }

            `when`(mockUserRepository.getUserByEmail(any())).thenReturn(null)

            // Test various invalid passwords
            TestUtils.PasswordTestCases.invalidPasswords.forEach { (reason, invalidPassword) ->
                val signupRequest = TestUtils.createSignupRequest(password = invalidPassword)

                val response = client.post("/api/v1/auth/parent/register") {
                    contentType(ContentType.Application.Json)
                    setBody(Json.encodeToString(SignupRequest.serializer(), signupRequest))
                }

                assertEquals(HttpStatusCode.BadRequest, response.status, 
                    "Should reject password: $invalidPassword (reason: $reason)")
            }
        }

        @Test
        @DisplayName("Should validate email format")
        fun testEmailValidation() = testApplication {
            application {
                configureTestApplication(authService)
            }

            `when`(mockUserRepository.getUserByEmail(any())).thenReturn(null)

            // Test invalid emails
            TestUtils.EmailTestCases.invalidEmails.forEach { invalidEmail ->
                val signupRequest = TestUtils.createSignupRequest(email = invalidEmail)

                val response = client.post("/api/v1/auth/parent/register") {
                    contentType(ContentType.Application.Json)
                    setBody(Json.encodeToString(SignupRequest.serializer(), signupRequest))
                }

                assertEquals(HttpStatusCode.BadRequest, response.status,
                    "Should reject invalid email: '$invalidEmail'")
            }
        }

        @Test
        @DisplayName("Should handle JSON parsing errors gracefully")
        fun testInvalidJsonHandling() = testApplication {
            application {
                configureTestApplication(authService)
            }

            val response = client.post("/api/v1/auth/parent/register") {
                contentType(ContentType.Application.Json)
                setBody("{ invalid json structure")
            }

            assertEquals(HttpStatusCode.BadRequest, response.status)
            
            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertTrue(responseBody.containsKey("message"))
            assertTrue(responseBody["message"]?.jsonPrimitive?.content?.contains("Invalid JSON") == true)
        }
    }

    @Nested
    @DisplayName("Parent Login Tests")
    inner class ParentLoginTests {

        @Test
        @DisplayName("Should successfully login parent with family context")
        fun testSuccessfulParentLogin() = testApplication {
            application {
                configureTestApplication(authService)
            }

            val testUser = TestUtils.createTestUser(
                email = "parent@example.com",
                role = UserRole.PARENT,
                status = UserStatus.ACTIVE
            )
            val testFamily = TestUtils.createTestFamily(createdBy = testUser.id)
            val passwordHash = org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder(12)
                .encode("TestPassword123")

            `when`(mockUserRepository.getUserByEmail("parent@example.com")).thenReturn(testUser)
            `when`(mockUserRepository.getUserPasswordHash(testUser.id)).thenReturn(passwordHash)
            `when`(mockFamilyRepository.getFamilyByUserId(testUser.id)).thenReturn(testFamily)
            `when`(mockUserRepository.updateLastLogin(testUser.id)).thenReturn(Unit)
            `when`(mockUserRepository.createSession(any())).thenReturn(Unit)

            val loginRequest = TestUtils.createLoginRequest(
                email = "parent@example.com",
                password = "TestPassword123"
            )

            val response = client.post("/api/v1/auth/parent/login") {
                contentType(ContentType.Application.Json)
                setBody(Json.encodeToString(LoginRequest.serializer(), loginRequest))
            }

            assertEquals(HttpStatusCode.OK, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertTrue(responseBody.containsKey("user"))
            assertTrue(responseBody.containsKey("accessToken"))
            assertTrue(responseBody.containsKey("refreshToken"))
            assertTrue(responseBody.containsKey("expiresIn"))

            // Verify JWT contains familyId claim
            val accessToken = responseBody["accessToken"]?.jsonPrimitive?.content
            assertNotNull(accessToken)
            val familyIdFromToken = jwtService.extractFamilyIdFromToken(accessToken!!)
            assertEquals(testFamily.id.toString(), familyIdFromToken)
        }

        @Test
        @DisplayName("Should reject invalid credentials")
        fun testInvalidCredentials() = testApplication {
            application {
                configureTestApplication(authService)
            }

            // Test non-existent user
            `when`(mockUserRepository.getUserByEmail(any())).thenReturn(null)

            val loginRequest = TestUtils.createLoginRequest(
                email = "nonexistent@example.com",
                password = "WrongPassword123"
            )

            val response = client.post("/api/v1/auth/parent/login") {
                contentType(ContentType.Application.Json)
                setBody(Json.encodeToString(LoginRequest.serializer(), loginRequest))
            }

            assertEquals(HttpStatusCode.Unauthorized, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertTrue(responseBody["message"]?.jsonPrimitive?.content?.contains("Invalid credentials") == true)
        }

        @Test
        @DisplayName("Should reject wrong password")
        fun testWrongPassword() = testApplication {
            application {
                configureTestApplication(authService)
            }

            val testUser = TestUtils.createTestUser(role = UserRole.PARENT, status = UserStatus.ACTIVE)
            val wrongPasswordHash = org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder(12)
                .encode("DifferentPassword")

            `when`(mockUserRepository.getUserByEmail(any())).thenReturn(testUser)
            `when`(mockUserRepository.getUserPasswordHash(testUser.id)).thenReturn(wrongPasswordHash)

            val loginRequest = TestUtils.createLoginRequest(password = "TestPassword123")

            val response = client.post("/api/v1/auth/parent/login") {
                contentType(ContentType.Application.Json)
                setBody(Json.encodeToString(LoginRequest.serializer(), loginRequest))
            }

            assertEquals(HttpStatusCode.Unauthorized, response.status)
        }

        @Test
        @DisplayName("Should reject suspended accounts")
        fun testSuspendedAccount() = testApplication {
            application {
                configureTestApplication(authService)
            }

            val suspendedUser = TestUtils.createTestUser(
                role = UserRole.PARENT,
                status = UserStatus.SUSPENDED
            )

            `when`(mockUserRepository.getUserByEmail(any())).thenReturn(suspendedUser)

            val loginRequest = TestUtils.createLoginRequest()

            val response = client.post("/api/v1/auth/parent/login") {
                contentType(ContentType.Application.Json)
                setBody(Json.encodeToString(LoginRequest.serializer(), loginRequest))
            }

            assertEquals(HttpStatusCode.Unauthorized, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertTrue(responseBody["message"]?.jsonPrimitive?.content?.contains("suspended") == true)
        }

        @Test
        @DisplayName("Should reject non-parent users")
        fun testNonParentUser() = testApplication {
            application {
                configureTestApplication(authService)
            }

            val childUser = TestUtils.createTestUser(
                role = UserRole.CHILD, // Non-parent role
                status = UserStatus.ACTIVE
            )

            `when`(mockUserRepository.getUserByEmail(any())).thenReturn(childUser)

            val loginRequest = TestUtils.createLoginRequest()

            val response = client.post("/api/v1/auth/parent/login") {
                contentType(ContentType.Application.Json)
                setBody(Json.encodeToString(LoginRequest.serializer(), loginRequest))
            }

            assertEquals(HttpStatusCode.Unauthorized, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertTrue(responseBody["message"]?.jsonPrimitive?.content?.contains("parents only") == true)
        }
    }

    @Nested
    @DisplayName("PIN Verification Tests")
    inner class PinVerificationTests {

        @Test
        @DisplayName("Should successfully verify correct PIN")
        fun testSuccessfulPinVerification() = testApplication {
            application {
                configureTestApplication(authService)
            }

            val pinRequest = PinVerificationRequest(pin = "1234")

            val response = client.post("/api/v1/auth/parent/verify-pin") {
                contentType(ContentType.Application.Json)
                setBody(Json.encodeToString(PinVerificationRequest.serializer(), pinRequest))
            }

            assertEquals(HttpStatusCode.OK, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertEquals(true, responseBody["verified"]?.jsonPrimitive?.boolean)
            assertTrue(responseBody.containsKey("sessionToken"))
            assertNotNull(responseBody["sessionToken"]?.jsonPrimitive?.content)
            assertTrue(responseBody["message"]?.jsonPrimitive?.content?.contains("verified successfully") == true)
        }

        @Test
        @DisplayName("Should reject incorrect PIN")
        fun testIncorrectPin() = testApplication {
            application {
                configureTestApplication(authService)
            }

            val pinRequest = PinVerificationRequest(pin = "9999")

            val response = client.post("/api/v1/auth/parent/verify-pin") {
                contentType(ContentType.Application.Json)
                setBody(Json.encodeToString(PinVerificationRequest.serializer(), pinRequest))
            }

            assertEquals(HttpStatusCode.Unauthorized, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertEquals(false, responseBody["verified"]?.jsonPrimitive?.boolean)
            assertNull(responseBody["sessionToken"]?.jsonPrimitive?.contentOrNull)
            assertTrue(responseBody["message"]?.jsonPrimitive?.content?.contains("Invalid PIN") == true)
        }

        @Test
        @DisplayName("Should validate PIN format")
        fun testPinFormatValidation() = testApplication {
            application {
                configureTestApplication(authService)
            }

            val invalidPins = listOf("123", "12345", "abcd", "", "   ", "123a")

            invalidPins.forEach { invalidPin ->
                val pinRequest = PinVerificationRequest(pin = invalidPin)

                val response = client.post("/api/v1/auth/parent/verify-pin") {
                    contentType(ContentType.Application.Json)
                    setBody(Json.encodeToString(PinVerificationRequest.serializer(), pinRequest))
                }

                assertEquals(HttpStatusCode.BadRequest, response.status,
                    "Should reject invalid PIN format: '$invalidPin'")

                val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
                assertEquals(false, responseBody["verified"]?.jsonPrimitive?.boolean)
                assertTrue(responseBody["message"]?.jsonPrimitive?.content?.contains("Invalid PIN format") == true)
            }
        }
    }

    @Nested
    @DisplayName("Error Handling Tests")
    inner class ErrorHandlingTests {

        @Test
        @DisplayName("Should handle missing request body gracefully")
        fun testMissingRequestBody() = testApplication {
            application {
                configureTestApplication(authService)
            }

            val response = client.post("/api/v1/auth/parent/register") {
                contentType(ContentType.Application.Json)
                // No body
            }

            assertEquals(HttpStatusCode.BadRequest, response.status)
        }

        @Test
        @DisplayName("Should handle server errors gracefully")
        fun testServerError() = testApplication {
            application {
                configureTestApplication(authService)
            }

            // Mock repository to throw exception
            `when`(mockUserRepository.getUserByEmail(any())).thenThrow(RuntimeException("Database error"))

            val signupRequest = TestUtils.createSignupRequest()

            val response = client.post("/api/v1/auth/parent/register") {
                contentType(ContentType.Application.Json)
                setBody(Json.encodeToString(SignupRequest.serializer(), signupRequest))
            }

            assertEquals(HttpStatusCode.InternalServerError, response.status)

            val responseBody = Json.parseToJsonElement(response.bodyAsText()).jsonObject
            assertTrue(responseBody.containsKey("message"))
            assertTrue(responseBody["message"]?.jsonPrimitive?.content?.contains("Registration failed") == true)
        }

        @Test
        @DisplayName("Should handle content type validation")
        fun testContentTypeValidation() = testApplication {
            application {
                configureTestApplication(authService)
            }

            val signupRequest = TestUtils.createSignupRequest()

            val response = client.post("/api/v1/auth/parent/register") {
                contentType(ContentType.Text.Plain) // Wrong content type
                setBody(Json.encodeToString(SignupRequest.serializer(), signupRequest))
            }

            // Should handle content type mismatch gracefully
            assertTrue(response.status.value >= 400, "Should return client error for wrong content type")
        }
    }

    /**
     * Helper function to configure test application with auth routes
     */
    private fun Application.configureTestApplication(authService: AuthService) {
        install(ContentNegotiation) {
            json()
        }
        
        routing {
            route("/api/v1") {
                authRoutes()
            }
        }
    }
}