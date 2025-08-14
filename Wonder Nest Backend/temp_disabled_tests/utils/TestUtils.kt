package com.wondernest.utils

import com.wondernest.data.database.table.AuthProvider
import com.wondernest.data.database.table.UserRole
import com.wondernest.data.database.table.UserStatus
import com.wondernest.domain.model.*
import com.wondernest.services.auth.*
import kotlinx.datetime.Clock
import kotlinx.datetime.DateTimeUnit
import kotlinx.datetime.plus
import java.util.*

/**
 * Test utilities for WonderNest Backend tests
 * Provides reusable test data and helper functions for consistent testing
 */
object TestUtils {
    
    /**
     * Creates a test User instance with sensible defaults
     */
    fun createTestUser(
        id: UUID = UUID.randomUUID(),
        email: String = "test@example.com",
        firstName: String = "Test",
        lastName: String = "User",
        role: UserRole = UserRole.PARENT,
        status: UserStatus = UserStatus.ACTIVE,
        emailVerified: Boolean = true
    ): User {
        val now = Clock.System.now()
        return User(
            id = id,
            email = email,
            emailVerified = emailVerified,
            emailVerifiedAt = if (emailVerified) now else null,
            authProvider = AuthProvider.EMAIL,
            firstName = firstName,
            lastName = lastName,
            timezone = "UTC",
            language = "en",
            status = status,
            role = role,
            createdAt = now,
            updatedAt = now
        )
    }

    /**
     * Creates a test Family instance with sensible defaults
     */
    fun createTestFamily(
        id: UUID = UUID.randomUUID(),
        name: String = "Test Family",
        createdBy: UUID = UUID.randomUUID(),
        familySettings: FamilySettings = FamilySettings(
            maxScreenTimeMinutes = 60,
            bedtimeEnabled = true,
            educationalContentOnly = false
        )
    ): Family {
        val now = Clock.System.now()
        return Family(
            id = id,
            name = name,
            createdBy = createdBy,
            timezone = "UTC",
            language = "en",
            familySettings = familySettings,
            createdAt = now,
            updatedAt = now
        )
    }

    /**
     * Creates a test ChildProfile instance with sensible defaults
     */
    fun createTestChild(
        id: UUID = UUID.randomUUID(),
        familyId: UUID = UUID.randomUUID(),
        name: String = "Test Child",
        age: Int = 5
    ): ChildProfile {
        val now = Clock.System.now()
        val birthDate = now.minus((age * 365).toLong(), DateTimeUnit.DAY)
        
        return ChildProfile(
            id = id,
            familyId = familyId,
            name = name,
            age = age,
            birthDate = birthDate,
            gender = "other",
            primaryLanguage = "en",
            interests = listOf("animals", "music"),
            contentSettings = ContentSettings(
                maxAgeRating = age + 2,
                subtitlesEnabled = false,
                audioMonitoringEnabled = true,
                educationalContentOnly = false
            ),
            timeRestrictions = TimeRestrictions(
                dailyScreenTimeMinutes = 60,
                bedtimeEnabled = true,
                bedtimeStart = "19:00",
                bedtimeEnd = "07:00"
            ),
            themePreferences = ThemePreferences(
                primaryColor = "blue",
                darkMode = false,
                animations = true
            ),
            createdAt = now,
            updatedAt = now
        )
    }

    /**
     * Creates a valid SignupRequest for testing
     */
    fun createSignupRequest(
        email: String = "test@example.com",
        password: String = "TestPassword123",
        firstName: String = "Test",
        lastName: String = "User"
    ): SignupRequest {
        return SignupRequest(
            email = email,
            password = password,
            firstName = firstName,
            lastName = lastName,
            phoneNumber = "+1234567890",
            countryCode = "US",
            timezone = "UTC",
            language = "en"
        )
    }

    /**
     * Creates a valid LoginRequest for testing
     */
    fun createLoginRequest(
        email: String = "test@example.com",
        password: String = "TestPassword123"
    ): LoginRequest {
        return LoginRequest(
            email = email,
            password = password
        )
    }

    /**
     * Creates a valid AuthResponse for testing
     */
    fun createAuthResponse(
        user: User = createTestUser(),
        accessToken: String = "mock.jwt.token",
        refreshToken: String = "mock.refresh.token",
        expiresIn: Long = 3600000L
    ): AuthResponse {
        return AuthResponse(
            user = user,
            accessToken = accessToken,
            refreshToken = refreshToken,
            expiresIn = expiresIn
        )
    }

    /**
     * Password validation test cases
     */
    object PasswordTestCases {
        val validPasswords = listOf(
            "TestPassword123",
            "SecureP@ss1",
            "MyPassw0rd!",
            "Complex123Pass"
        )
        
        val invalidPasswords = mapOf(
            "short" to "Short1", // Too short (< 8 chars)
            "no_digit" to "NoDigitPassword", // No digits
            "no_uppercase" to "nouppercasepass123", // No uppercase
            "no_lowercase" to "NOLOWERCASEPASS123", // No lowercase
            "blank" to "", // Empty
            "only_spaces" to "        " // Only spaces
        )
    }

    /**
     * Email validation test cases
     */
    object EmailTestCases {
        val validEmails = listOf(
            "test@example.com",
            "user.name@domain.co.uk",
            "parent123@wondernest.app",
            "long.email.address@subdomain.example.org"
        )
        
        val invalidEmails = listOf(
            "invalid-email", // No @ symbol
            "@example.com", // No local part
            "user@", // No domain
            "user@domain", // No TLD
            "user name@example.com", // Spaces not allowed
            "", // Empty
            "   " // Whitespace
        )
    }

    /**
     * Content filtering test data
     */
    object ContentTestData {
        fun createMockContentItem(
            id: String = "test_content_1",
            ageRating: Int = 5,
            category: String = "educational"
        ) = mapOf(
            "id" to id,
            "title" to "Test Content Title",
            "description" to "Test content description",
            "category" to category,
            "ageRating" to ageRating,
            "duration" to 15,
            "thumbnailUrl" to "/thumbnails/test.jpg",
            "contentUrl" to "/content/test.mp4",
            "tags" to listOf("test", "educational"),
            "isEducational" to (category == "educational"),
            "difficulty" to "easy",
            "createdAt" to "2024-01-15T10:00:00Z"
        )
    }

    /**
     * Assert that a map contains expected keys and values
     */
    fun assertMapContains(actual: Map<String, Any?>, expected: Map<String, Any?>) {
        expected.forEach { (key, expectedValue) ->
            assert(actual.containsKey(key)) { "Missing key: $key in actual map: ${actual.keys}" }
            assert(actual[key] == expectedValue) { 
                "Expected '$key' to be '$expectedValue' but was '${actual[key]}'" 
            }
        }
    }

    /**
     * Common HTTP status code assertions
     */
    fun assertResponseStatus(actualStatus: Int, expectedStatus: Int, message: String = "") {
        assert(actualStatus == expectedStatus) { 
            "Expected HTTP status $expectedStatus but got $actualStatus. $message" 
        }
    }

    /**
     * Validate JWT token structure (basic validation without signature verification)
     */
    fun assertJwtTokenStructure(token: String, expectedClaims: Set<String> = emptySet()) {
        val parts = token.split(".")
        assert(parts.size == 3) { "JWT token should have 3 parts separated by dots, got ${parts.size}" }
        
        // Basic format validation - in real tests, you'd decode and verify claims
        assert(parts[0].isNotBlank()) { "JWT header should not be blank" }
        assert(parts[1].isNotBlank()) { "JWT payload should not be blank" }
        assert(parts[2].isNotBlank()) { "JWT signature should not be blank" }
        
        // Additional claim validation would go here in real implementation
    }

    /**
     * Validate that response follows Flutter expected structure
     */
    fun validateFlutterApiResponse(response: Map<String, Any?>, requiredFields: Set<String>) {
        requiredFields.forEach { field ->
            assert(response.containsKey(field)) { 
                "Flutter expects field '$field' in API response but it was missing. Available fields: ${response.keys}" 
            }
        }
    }

    /**
     * Generates test data for pagination testing
     */
    fun generatePaginationTestData(totalItems: Int): List<Map<String, Any>> {
        return (1..totalItems).map { index ->
            mapOf(
                "id" to "item_$index",
                "name" to "Test Item $index",
                "index" to index
            )
        }
    }
}