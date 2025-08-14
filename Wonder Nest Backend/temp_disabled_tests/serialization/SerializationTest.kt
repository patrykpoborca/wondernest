package com.wondernest.serialization

import com.wondernest.utils.TestUtils
import com.wondernest.domain.model.*
import com.wondernest.services.auth.*
import com.wondernest.services.family.*
import com.wondernest.api.content.*
import com.wondernest.data.database.table.UserRole
import com.wondernest.data.database.table.UserStatus
import com.wondernest.data.database.table.AuthProvider
import kotlinx.datetime.Clock
import kotlinx.serialization.json.*
import kotlinx.serialization.encodeToString
import kotlinx.serialization.decodeFromString
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Nested
import java.util.*
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.test.assertNotNull

/**
 * Critical serialization tests to ensure DTOs serialize exactly as Flutter expects
 * These tests validate the API contract between backend and Flutter frontend
 */
@DisplayName("DTO Serialization Tests")
class SerializationTest {

    private val json = Json {
        prettyPrint = true
        ignoreUnknownKeys = true
        encodeDefaults = true
    }

    @Nested
    @DisplayName("Authentication DTO Tests")
    inner class AuthenticationDTOTests {

        @Test
        @DisplayName("Should serialize SignupRequest correctly for Flutter")
        fun testSignupRequestSerialization() {
            val signupRequest = TestUtils.createSignupRequest(
                email = "flutter@test.com",
                password = "FlutterTest123",
                firstName = "Flutter",
                lastName = "User"
            )

            val serialized = json.encodeToString(signupRequest)
            val jsonElement = json.parseToJsonElement(serialized)
            val jsonObject = jsonElement.jsonObject

            // Verify all required fields are present for Flutter
            val expectedFields = setOf(
                "email", "password", "firstName", "lastName", 
                "phoneNumber", "countryCode", "timezone", "language"
            )
            
            expectedFields.forEach { field ->
                assertTrue(jsonObject.containsKey(field), "SignupRequest should contain $field for Flutter")
            }

            // Verify field values and types
            assertEquals("flutter@test.com", jsonObject["email"]?.jsonPrimitive?.content)
            assertEquals("FlutterTest123", jsonObject["password"]?.jsonPrimitive?.content)
            assertEquals("Flutter", jsonObject["firstName"]?.jsonPrimitive?.content)
            assertEquals("User", jsonObject["lastName"]?.jsonPrimitive?.content)
            assertEquals("US", jsonObject["countryCode"]?.jsonPrimitive?.content)
            assertEquals("UTC", jsonObject["timezone"]?.jsonPrimitive?.content)
            assertEquals("en", jsonObject["language"]?.jsonPrimitive?.content)

            // Test round-trip serialization
            val deserialized = json.decodeFromString<SignupRequest>(serialized)
            assertEquals(signupRequest.email, deserialized.email)
            assertEquals(signupRequest.firstName, deserialized.firstName)
        }

        @Test
        @DisplayName("Should serialize LoginRequest correctly for Flutter")
        fun testLoginRequestSerialization() {
            val loginRequest = TestUtils.createLoginRequest(
                email = "login@test.com",
                password = "LoginTest123"
            )

            val serialized = json.encodeToString(loginRequest)
            val jsonElement = json.parseToJsonElement(serialized)
            val jsonObject = jsonElement.jsonObject

            assertEquals("login@test.com", jsonObject["email"]?.jsonPrimitive?.content)
            assertEquals("LoginTest123", jsonObject["password"]?.jsonPrimitive?.content)

            // Test round-trip
            val deserialized = json.decodeFromString<LoginRequest>(serialized)
            assertEquals(loginRequest.email, deserialized.email)
            assertEquals(loginRequest.password, deserialized.password)
        }

        @Test
        @DisplayName("Should serialize AuthResponse correctly for Flutter")
        fun testAuthResponseSerialization() {
            val testUser = TestUtils.createTestUser(
                email = "auth@test.com",
                firstName = "Auth",
                lastName = "User"
            )
            val authResponse = TestUtils.createAuthResponse(
                user = testUser,
                accessToken = "test.jwt.token",
                refreshToken = "test.refresh.token",
                expiresIn = 3600000L
            )

            val serialized = json.encodeToString(authResponse)
            val jsonElement = json.parseToJsonElement(serialized)
            val jsonObject = jsonElement.jsonObject

            // Verify top-level structure for Flutter
            val expectedFields = setOf("user", "accessToken", "refreshToken", "expiresIn")
            expectedFields.forEach { field ->
                assertTrue(jsonObject.containsKey(field), "AuthResponse should contain $field for Flutter")
            }

            // Verify user object structure
            val userJson = jsonObject["user"]?.jsonObject
            assertNotNull(userJson, "User object should be present")
            
            val expectedUserFields = setOf(
                "id", "email", "emailVerified", "firstName", "lastName", 
                "role", "status", "timezone", "language", "createdAt", "updatedAt"
            )
            expectedUserFields.forEach { field ->
                assertTrue(userJson!!.containsKey(field), "User should contain $field for Flutter")
            }

            // Verify token structure
            assertEquals("test.jwt.token", jsonObject["accessToken"]?.jsonPrimitive?.content)
            assertEquals("test.refresh.token", jsonObject["refreshToken"]?.jsonPrimitive?.content)
            assertEquals(3600000L, jsonObject["expiresIn"]?.jsonPrimitive?.long)
        }

        @Test
        @DisplayName("Should serialize PinVerificationResponse correctly for Flutter")
        fun testPinVerificationResponseSerialization() {
            val pinResponse = PinVerificationResponse(
                verified = true,
                message = "PIN verified successfully",
                sessionToken = "session_token_123"
            )

            val serialized = json.encodeToString(pinResponse)
            val jsonElement = json.parseToJsonElement(serialized)
            val jsonObject = jsonElement.jsonObject

            assertEquals(true, jsonObject["verified"]?.jsonPrimitive?.boolean)
            assertEquals("PIN verified successfully", jsonObject["message"]?.jsonPrimitive?.content)
            assertEquals("session_token_123", jsonObject["sessionToken"]?.jsonPrimitive?.content)
        }
    }

    @Nested
    @DisplayName("Family DTO Tests")
    inner class FamilyDTOTests {

        @Test
        @DisplayName("Should serialize ChildProfile correctly for Flutter")
        fun testChildProfileSerialization() {
            val childProfile = TestUtils.createTestChild(
                name = "Flutter Child",
                age = 7
            )

            val serialized = json.encodeToString(childProfile)
            val jsonElement = json.parseToJsonElement(serialized)
            val jsonObject = jsonElement.jsonObject

            // Verify all critical fields for Flutter child management
            val expectedFields = setOf(
                "id", "familyId", "name", "age", "birthDate", "gender",
                "avatarUrl", "primaryLanguage", "interests", "contentSettings",
                "timeRestrictions", "themePreferences", "createdAt", "updatedAt"
            )

            expectedFields.forEach { field ->
                assertTrue(jsonObject.containsKey(field), "ChildProfile should contain $field for Flutter")
            }

            // Verify critical field types and values
            assertEquals("Flutter Child", jsonObject["name"]?.jsonPrimitive?.content)
            assertEquals(7, jsonObject["age"]?.jsonPrimitive?.int)
            assertEquals("en", jsonObject["primaryLanguage"]?.jsonPrimitive?.content)

            // Verify nested objects
            val contentSettings = jsonObject["contentSettings"]?.jsonObject
            assertNotNull(contentSettings, "ContentSettings should be present")
            assertTrue(contentSettings!!.containsKey("maxAgeRating"))
            assertTrue(contentSettings.containsKey("audioMonitoringEnabled"))

            val timeRestrictions = jsonObject["timeRestrictions"]?.jsonObject
            assertNotNull(timeRestrictions, "TimeRestrictions should be present")
            assertTrue(timeRestrictions!!.containsKey("dailyScreenTimeMinutes"))
            assertTrue(timeRestrictions.containsKey("bedtimeEnabled"))

            val themePreferences = jsonObject["themePreferences"]?.jsonObject
            assertNotNull(themePreferences, "ThemePreferences should be present")
        }

        @Test
        @DisplayName("Should serialize CreateChildRequest correctly for Flutter")
        fun testCreateChildRequestSerialization() {
            val createRequest = CreateChildRequest(
                name = "New Child",
                birthDate = "2018-06-15",
                gender = "other",
                avatarUrl = "https://example.com/avatar.jpg",
                interests = listOf("music", "art", "science")
            )

            val serialized = json.encodeToString(createRequest)
            val jsonElement = json.parseToJsonElement(serialized)
            val jsonObject = jsonElement.jsonObject

            assertEquals("New Child", jsonObject["name"]?.jsonPrimitive?.content)
            assertEquals("2018-06-15", jsonObject["birthDate"]?.jsonPrimitive?.content)
            assertEquals("other", jsonObject["gender"]?.jsonPrimitive?.content)
            assertEquals("https://example.com/avatar.jpg", jsonObject["avatarUrl"]?.jsonPrimitive?.content)

            val interests = jsonObject["interests"]?.jsonArray
            assertNotNull(interests, "Interests should be present")
            assertEquals(3, interests!!.size)
            assertEquals("music", interests[0].jsonPrimitive.content)
        }

        @Test
        @DisplayName("Should serialize UpdateChildRequest correctly for Flutter")
        fun testUpdateChildRequestSerialization() {
            val updateRequest = UpdateChildRequest(
                name = "Updated Name",
                interests = listOf("updated", "interests"),
                contentSettings = ContentSettings(
                    maxAgeRating = 10,
                    subtitlesEnabled = true,
                    audioMonitoringEnabled = false
                ),
                timeRestrictions = TimeRestrictions(
                    dailyScreenTimeMinutes = 120,
                    bedtimeEnabled = false
                )
            )

            val serialized = json.encodeToString(updateRequest)
            val jsonElement = json.parseToJsonElement(serialized)
            val jsonObject = jsonElement.jsonObject

            assertEquals("Updated Name", jsonObject["name"]?.jsonPrimitive?.content)
            
            val interests = jsonObject["interests"]?.jsonArray
            assertEquals(2, interests!!.size)
            
            val contentSettings = jsonObject["contentSettings"]?.jsonObject
            assertEquals(10, contentSettings!!["maxAgeRating"]?.jsonPrimitive?.int)
            assertEquals(true, contentSettings["subtitlesEnabled"]?.jsonPrimitive?.boolean)
            
            val timeRestrictions = jsonObject["timeRestrictions"]?.jsonObject
            assertEquals(120, timeRestrictions!!["dailyScreenTimeMinutes"]?.jsonPrimitive?.int)
            assertEquals(false, timeRestrictions["bedtimeEnabled"]?.jsonPrimitive?.boolean)
        }

        @Test
        @DisplayName("Should serialize FamilyProfileResponse correctly for Flutter")
        fun testFamilyProfileResponseSerialization() {
            val testFamily = TestUtils.createTestFamily(name = "Flutter Family")
            val testChild = TestUtils.createTestChild(familyId = testFamily.id)
            val testMember = FamilyMember(
                id = UUID.randomUUID(),
                familyId = testFamily.id,
                userId = UUID.randomUUID(),
                role = "parent",
                permissions = mapOf("manage_children" to true),
                joinedAt = Clock.System.now()
            )

            val familyProfile = FamilyProfileResponse(
                family = testFamily,
                members = listOf(testMember),
                children = listOf(testChild)
            )

            val serialized = json.encodeToString(familyProfile)
            val jsonElement = json.parseToJsonElement(serialized)
            val jsonObject = jsonElement.jsonObject

            // Verify top-level structure
            assertTrue(jsonObject.containsKey("family"))
            assertTrue(jsonObject.containsKey("members"))
            assertTrue(jsonObject.containsKey("children"))

            // Verify arrays are properly serialized
            val members = jsonObject["members"]?.jsonArray
            val children = jsonObject["children"]?.jsonArray
            assertEquals(1, members!!.size)
            assertEquals(1, children!!.size)
        }
    }

    @Nested
    @DisplayName("Content DTO Tests")
    inner class ContentDTOTests {

        @Test
        @DisplayName("Should serialize ContentItem correctly for Flutter")
        fun testContentItemSerialization() {
            val contentItem = ContentItem(
                id = "test_content",
                title = "Test Content",
                description = "Test description",
                category = "educational",
                ageRating = 5,
                duration = 15,
                thumbnailUrl = "/thumbnails/test.jpg",
                contentUrl = "/content/test.mp4",
                tags = listOf("test", "educational", "fun"),
                isEducational = true,
                difficulty = "easy",
                createdAt = "2024-01-15T10:00:00Z"
            )

            val serialized = json.encodeToString(contentItem)
            val jsonElement = json.parseToJsonElement(serialized)
            val jsonObject = jsonElement.jsonObject

            // Verify all required fields for Flutter content display
            val expectedFields = setOf(
                "id", "title", "description", "category", "ageRating", "duration",
                "thumbnailUrl", "contentUrl", "tags", "isEducational", "difficulty", "createdAt"
            )

            expectedFields.forEach { field ->
                assertTrue(jsonObject.containsKey(field), "ContentItem should contain $field for Flutter")
            }

            // Verify field values and types
            assertEquals("test_content", jsonObject["id"]?.jsonPrimitive?.content)
            assertEquals("Test Content", jsonObject["title"]?.jsonPrimitive?.content)
            assertEquals("educational", jsonObject["category"]?.jsonPrimitive?.content)
            assertEquals(5, jsonObject["ageRating"]?.jsonPrimitive?.int)
            assertEquals(15, jsonObject["duration"]?.jsonPrimitive?.int)
            assertEquals(true, jsonObject["isEducational"]?.jsonPrimitive?.boolean)
            assertEquals("easy", jsonObject["difficulty"]?.jsonPrimitive?.content)

            val tags = jsonObject["tags"]?.jsonArray
            assertEquals(3, tags!!.size)
            assertEquals("test", tags[0].jsonPrimitive.content)
        }

        @Test
        @DisplayName("Should serialize ContentResponse correctly for Flutter")
        fun testContentResponseSerialization() {
            val contentItems = listOf(
                TestUtils.ContentTestData.createMockContentItem("content_1", 5, "educational"),
                TestUtils.ContentTestData.createMockContentItem("content_2", 7, "stories")
            ).map { mockData ->
                ContentItem(
                    id = mockData["id"] as String,
                    title = mockData["title"] as String,
                    description = mockData["description"] as String,
                    category = mockData["category"] as String,
                    ageRating = mockData["ageRating"] as Int,
                    duration = mockData["duration"] as Int,
                    thumbnailUrl = mockData["thumbnailUrl"] as String,
                    contentUrl = mockData["contentUrl"] as String,
                    tags = mockData["tags"] as List<String>,
                    isEducational = mockData["isEducational"] as Boolean,
                    difficulty = mockData["difficulty"] as String,
                    createdAt = mockData["createdAt"] as String
                )
            }

            val categories = listOf(
                ContentCategory("edu", "Educational", "Learn", "📚", "#4CAF50", 3, 12)
            )

            val contentResponse = ContentResponse(
                items = contentItems,
                totalItems = 2,
                currentPage = 1,
                totalPages = 1,
                categories = categories
            )

            val serialized = json.encodeToString(contentResponse)
            val jsonElement = json.parseToJsonElement(serialized)
            val jsonObject = jsonElement.jsonObject

            // Verify pagination structure for Flutter
            val expectedFields = setOf("items", "totalItems", "currentPage", "totalPages", "categories")
            expectedFields.forEach { field ->
                assertTrue(jsonObject.containsKey(field), "ContentResponse should contain $field for Flutter")
            }

            // Verify pagination values
            assertEquals(2, jsonObject["totalItems"]?.jsonPrimitive?.int)
            assertEquals(1, jsonObject["currentPage"]?.jsonPrimitive?.int)
            assertEquals(1, jsonObject["totalPages"]?.jsonPrimitive?.int)

            // Verify arrays
            val items = jsonObject["items"]?.jsonArray
            val categoriesArray = jsonObject["categories"]?.jsonArray
            assertEquals(2, items!!.size)
            assertEquals(1, categoriesArray!!.size)
        }

        @Test
        @DisplayName("Should serialize ContentCategory correctly for Flutter")
        fun testContentCategorySerialization() {
            val category = ContentCategory(
                id = "educational",
                name = "Educational",
                description = "Learning content",
                icon = "🎓",
                color = "#4CAF50",
                minAge = 3,
                maxAge = 12
            )

            val serialized = json.encodeToString(category)
            val jsonElement = json.parseToJsonElement(serialized)
            val jsonObject = jsonElement.jsonObject

            // Verify all fields for Flutter category filtering
            val expectedFields = setOf("id", "name", "description", "icon", "color", "minAge", "maxAge")
            expectedFields.forEach { field ->
                assertTrue(jsonObject.containsKey(field), "ContentCategory should contain $field for Flutter")
            }

            assertEquals("educational", jsonObject["id"]?.jsonPrimitive?.content)
            assertEquals("Educational", jsonObject["name"]?.jsonPrimitive?.content)
            assertEquals("🎓", jsonObject["icon"]?.jsonPrimitive?.content)
            assertEquals("#4CAF50", jsonObject["color"]?.jsonPrimitive?.content)
            assertEquals(3, jsonObject["minAge"]?.jsonPrimitive?.int)
            assertEquals(12, jsonObject["maxAge"]?.jsonPrimitive?.int)
        }
    }

    @Nested
    @DisplayName("Domain Model Tests")
    inner class DomainModelTests {

        @Test
        @DisplayName("Should serialize User correctly for Flutter")
        fun testUserSerialization() {
            val user = TestUtils.createTestUser(
                email = "user@test.com",
                firstName = "Test",
                lastName = "User",
                role = UserRole.PARENT,
                status = UserStatus.ACTIVE
            )

            val serialized = json.encodeToString(user)
            val jsonElement = json.parseToJsonElement(serialized)
            val jsonObject = jsonElement.jsonObject

            // Verify critical user fields for Flutter authentication state
            val criticalFields = setOf(
                "id", "email", "emailVerified", "firstName", "lastName", 
                "role", "status", "timezone", "language"
            )

            criticalFields.forEach { field ->
                assertTrue(jsonObject.containsKey(field), "User should contain $field for Flutter")
            }

            assertEquals("user@test.com", jsonObject["email"]?.jsonPrimitive?.content)
            assertEquals("Test", jsonObject["firstName"]?.jsonPrimitive?.content)
            assertEquals("User", jsonObject["lastName"]?.jsonPrimitive?.content)
            assertEquals("PARENT", jsonObject["role"]?.jsonPrimitive?.content)
            assertEquals("ACTIVE", jsonObject["status"]?.jsonPrimitive?.content)
        }

        @Test
        @DisplayName("Should serialize Family correctly for Flutter")
        fun testFamilySerialization() {
            val family = TestUtils.createTestFamily(
                name = "Test Family"
            )

            val serialized = json.encodeToString(family)
            val jsonElement = json.parseToJsonElement(serialized)
            val jsonObject = jsonElement.jsonObject

            // Verify family fields for Flutter family management
            val expectedFields = setOf(
                "id", "name", "createdBy", "timezone", "language", 
                "familySettings", "createdAt", "updatedAt"
            )

            expectedFields.forEach { field ->
                assertTrue(jsonObject.containsKey(field), "Family should contain $field for Flutter")
            }

            assertEquals("Test Family", jsonObject["name"]?.jsonPrimitive?.content)
            
            val familySettings = jsonObject["familySettings"]?.jsonObject
            assertNotNull(familySettings, "FamilySettings should be present")
            assertTrue(familySettings!!.containsKey("maxScreenTimeMinutes"))
            assertTrue(familySettings.containsKey("bedtimeEnabled"))
        }

        @Test
        @DisplayName("Should serialize nested settings objects correctly")
        fun testNestedSettingsSerialization() {
            val contentSettings = ContentSettings(
                maxAgeRating = 8,
                blockedCategories = listOf("horror", "violence"),
                allowedDomains = listOf("example.com", "test.com"),
                subtitlesEnabled = true,
                audioMonitoringEnabled = true,
                educationalContentOnly = false
            )

            val serialized = json.encodeToString(contentSettings)
            val jsonElement = json.parseToJsonElement(serialized)
            val jsonObject = jsonElement.jsonObject

            assertEquals(8, jsonObject["maxAgeRating"]?.jsonPrimitive?.int)
            assertEquals(true, jsonObject["subtitlesEnabled"]?.jsonPrimitive?.boolean)
            
            val blocked = jsonObject["blockedCategories"]?.jsonArray
            val allowed = jsonObject["allowedDomains"]?.jsonArray
            assertEquals(2, blocked!!.size)
            assertEquals(2, allowed!!.size)
            assertEquals("horror", blocked[0].jsonPrimitive.content)
        }
    }

    @Nested
    @DisplayName("Date/Time Serialization Tests")
    inner class DateTimeSerializationTests {

        @Test
        @DisplayName("Should serialize datetime fields consistently for Flutter")
        fun testDateTimeSerialization() {
            val user = TestUtils.createTestUser()

            val serialized = json.encodeToString(user)
            val jsonElement = json.parseToJsonElement(serialized)
            val jsonObject = jsonElement.jsonObject

            // Verify datetime fields are properly serialized
            assertNotNull(jsonObject["createdAt"], "createdAt should be serialized")
            assertNotNull(jsonObject["updatedAt"], "updatedAt should be serialized")
            
            // Verify ISO format is maintained for Flutter DateTime parsing
            val createdAt = jsonObject["createdAt"]?.jsonPrimitive?.content
            assertNotNull(createdAt, "createdAt should be string")
            assertTrue(createdAt!!.contains("T"), "DateTime should be in ISO format with T separator")
            assertTrue(createdAt.endsWith("Z"), "DateTime should end with Z for UTC")
        }

        @Test
        @DisplayName("Should handle nullable datetime fields")
        fun testNullableDateTimeSerialization() {
            val user = TestUtils.createTestUser().copy(
                lastLoginAt = null,
                deletedAt = null
            )

            val serialized = json.encodeToString(user)
            val jsonElement = json.parseToJsonElement(serialized)
            val jsonObject = jsonElement.jsonObject

            // Nullable fields should be present with null values for Flutter
            assertTrue(jsonObject.containsKey("lastLoginAt"))
            assertTrue(jsonObject.containsKey("deletedAt"))
            assertEquals(JsonNull, jsonObject["lastLoginAt"])
            assertEquals(JsonNull, jsonObject["deletedAt"])
        }
    }

    @Nested
    @DisplayName("Round-trip Serialization Tests")
    inner class RoundTripTests {

        @Test
        @DisplayName("Should maintain data integrity through serialization round-trip")
        fun testSerializationRoundTrip() {
            val originalChild = TestUtils.createTestChild(
                name = "Round Trip Test",
                age = 6
            )

            // Serialize to JSON
            val serialized = json.encodeToString(originalChild)
            
            // Deserialize back to object
            val deserialized = json.decodeFromString<ChildProfile>(serialized)
            
            // Verify all fields match
            assertEquals(originalChild.id, deserialized.id)
            assertEquals(originalChild.name, deserialized.name)
            assertEquals(originalChild.age, deserialized.age)
            assertEquals(originalChild.familyId, deserialized.familyId)
            assertEquals(originalChild.interests, deserialized.interests)
            assertEquals(originalChild.contentSettings, deserialized.contentSettings)
        }

        @Test
        @DisplayName("Should handle optional fields correctly in round-trip")
        fun testOptionalFieldsRoundTrip() {
            val requestWithOptionals = CreateChildRequest(
                name = "Test Child",
                birthDate = "2020-01-01",
                gender = "other",
                avatarUrl = "https://example.com/avatar.jpg",
                interests = listOf("music")
            )

            val serialized = json.encodeToString(requestWithOptionals)
            val deserialized = json.decodeFromString<CreateChildRequest>(serialized)

            assertEquals(requestWithOptionals.name, deserialized.name)
            assertEquals(requestWithOptionals.gender, deserialized.gender)
            assertEquals(requestWithOptionals.avatarUrl, deserialized.avatarUrl)
            assertEquals(requestWithOptionals.interests, deserialized.interests)
        }

        @Test
        @DisplayName("Should handle default values in round-trip")
        fun testDefaultValuesRoundTrip() {
            val requestWithDefaults = CreateChildRequest(
                name = "Test Child",
                birthDate = "2020-01-01"
                // gender, avatarUrl, interests use defaults
            )

            val serialized = json.encodeToString(requestWithDefaults)
            val deserialized = json.decodeFromString<CreateChildRequest>(serialized)

            assertEquals(requestWithDefaults.name, deserialized.name)
            assertEquals(null, deserialized.gender) // default value
            assertEquals(emptyList(), deserialized.interests) // default value
        }
    }
}