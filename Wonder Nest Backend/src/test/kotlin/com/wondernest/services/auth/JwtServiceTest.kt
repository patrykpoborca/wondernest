package com.wondernest.services.auth

import com.auth0.jwt.JWT
import com.auth0.jwt.algorithms.Algorithm
import com.wondernest.utils.TestUtils
import com.wondernest.data.database.table.UserRole
import com.wondernest.data.database.table.UserStatus
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Nested
import java.util.*
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Comprehensive tests for JwtService
 * Critical for ensuring JWT tokens work correctly with Flutter frontend
 */
@DisplayName("JWT Service Tests")
class JwtServiceTest {

    private lateinit var jwtService: JwtService

    @BeforeEach
    fun setup() {
        // Use test environment variables or defaults
        System.setProperty("JWT_SECRET", "test-jwt-secret-key-for-testing-only")
        System.setProperty("JWT_EXPIRES_IN", "3600000") // 1 hour
        System.setProperty("JWT_REFRESH_EXPIRES_IN", "2592000000") // 30 days
        jwtService = JwtService()
    }

    @Nested
    @DisplayName("Token Generation Tests")
    inner class TokenGenerationTests {

        @Test
        @DisplayName("Should generate valid JWT token with all required claims")
        fun testTokenGeneration() {
            val testUser = TestUtils.createTestUser(
                email = "test@example.com",
                firstName = "John",
                lastName = "Doe",
                role = UserRole.PARENT,
                status = UserStatus.ACTIVE
            )

            val tokenPair = jwtService.generateToken(testUser)

            // Validate token structure
            assertNotNull(tokenPair.accessToken, "Access token should not be null")
            assertNotNull(tokenPair.refreshToken, "Refresh token should not be null")
            assertTrue(tokenPair.expiresIn > 0, "Expires in should be positive")

            // Validate JWT structure
            TestUtils.assertJwtTokenStructure(tokenPair.accessToken)
            TestUtils.assertJwtTokenStructure(tokenPair.refreshToken)

            // Decode and verify claims in access token
            val decodedToken = JWT.decode(tokenPair.accessToken)
            assertEquals(testUser.id.toString(), decodedToken.getClaim("userId").asString())
            assertEquals(testUser.email, decodedToken.getClaim("email").asString())
            assertEquals(testUser.role.name, decodedToken.getClaim("role").asString())
            assertEquals(testUser.emailVerified, decodedToken.getClaim("verified").asBoolean())
            assertEquals(jwtService.issuer, decodedToken.issuer)
            assertEquals(jwtService.audience, decodedToken.audience.firstOrNull())

            // Verify refresh token has correct type claim
            val decodedRefreshToken = JWT.decode(tokenPair.refreshToken)
            assertEquals("refresh", decodedRefreshToken.getClaim("type").asString())
            assertEquals(testUser.id.toString(), decodedRefreshToken.getClaim("userId").asString())
        }

        @Test
        @DisplayName("Should generate JWT token with family context")
        fun testTokenGenerationWithFamilyContext() {
            val testUser = TestUtils.createTestUser(role = UserRole.PARENT)
            val familyId = UUID.randomUUID()

            val tokenPair = jwtService.generateTokenWithFamilyContext(testUser, familyId)

            assertNotNull(tokenPair.accessToken)
            assertNotNull(tokenPair.refreshToken)

            // Verify family context in access token
            val decodedToken = JWT.decode(tokenPair.accessToken)
            assertEquals(familyId.toString(), decodedToken.getClaim("familyId").asString())
            assertEquals(testUser.id.toString(), decodedToken.getClaim("userId").asString())
            assertEquals(testUser.email, decodedToken.getClaim("email").asString())
            assertEquals(testUser.role.name, decodedToken.getClaim("role").asString())

            // Verify family context in refresh token
            val decodedRefreshToken = JWT.decode(tokenPair.refreshToken)
            assertEquals(familyId.toString(), decodedRefreshToken.getClaim("familyId").asString())
            assertEquals("refresh", decodedRefreshToken.getClaim("type").asString())
        }

        @Test
        @DisplayName("Should generate tokens with correct expiration times")
        fun testTokenExpiration() {
            val testUser = TestUtils.createTestUser()
            val tokenPair = jwtService.generateToken(testUser)

            val decodedToken = JWT.decode(tokenPair.accessToken)
            val decodedRefreshToken = JWT.decode(tokenPair.refreshToken)

            val now = System.currentTimeMillis()
            val accessTokenExp = decodedToken.expiresAt.time
            val refreshTokenExp = decodedRefreshToken.expiresAt.time

            // Access token should expire in about 1 hour (allow 5 second tolerance)
            val expectedAccessExp = now + 3600000L // 1 hour
            assertTrue(
                Math.abs(accessTokenExp - expectedAccessExp) < 5000,
                "Access token expiration should be around 1 hour from now"
            )

            // Refresh token should expire in about 30 days (allow 1 minute tolerance)
            val expectedRefreshExp = now + 2592000000L // 30 days
            assertTrue(
                Math.abs(refreshTokenExp - expectedRefreshExp) < 60000,
                "Refresh token expiration should be around 30 days from now"
            )
        }
    }

    @Nested
    @DisplayName("Token Verification Tests")
    inner class TokenVerificationTests {

        @Test
        @DisplayName("Should successfully verify valid tokens")
        fun testValidTokenVerification() {
            val testUser = TestUtils.createTestUser()
            val tokenPair = jwtService.generateToken(testUser)

            // Verify access token
            val userId = jwtService.verifyToken(tokenPair.accessToken)
            assertEquals(testUser.id.toString(), userId)

            // Verify refresh token
            val refreshUserId = jwtService.verifyRefreshToken(tokenPair.refreshToken)
            assertEquals(testUser.id.toString(), refreshUserId)
        }

        @Test
        @DisplayName("Should reject invalid tokens")
        fun testInvalidTokenVerification() {
            // Test completely invalid token
            assertNull(jwtService.verifyToken("invalid.token.here"))
            assertNull(jwtService.verifyRefreshToken("invalid.token.here"))

            // Test empty token
            assertNull(jwtService.verifyToken(""))
            assertNull(jwtService.verifyRefreshToken(""))

            // Test malformed token (missing parts)
            assertNull(jwtService.verifyToken("onlyonepart"))
            assertNull(jwtService.verifyRefreshToken("only.twoparts"))
        }

        @Test
        @DisplayName("Should reject tokens with wrong signature")
        fun testWrongSignatureRejection() {
            val testUser = TestUtils.createTestUser()
            
            // Create token with different secret
            val wrongAlgorithm = Algorithm.HMAC256("wrong-secret")
            val wrongToken = JWT.create()
                .withIssuer(jwtService.issuer)
                .withAudience(jwtService.audience)
                .withSubject(testUser.id.toString())
                .withClaim("userId", testUser.id.toString())
                .sign(wrongAlgorithm)

            assertNull(jwtService.verifyToken(wrongToken))
        }

        @Test
        @DisplayName("Should handle expired tokens gracefully")
        fun testExpiredTokenHandling() {
            val testUser = TestUtils.createTestUser()
            
            // Create expired token (expired 1 hour ago)
            val expiredDate = Date(System.currentTimeMillis() - 3600000L)
            val expiredToken = JWT.create()
                .withIssuer(jwtService.issuer)
                .withAudience(jwtService.audience)
                .withSubject(testUser.id.toString())
                .withClaim("userId", testUser.id.toString())
                .withExpiresAt(expiredDate)
                .sign(Algorithm.HMAC256(jwtService.secret))

            assertNull(jwtService.verifyToken(expiredToken))
        }

        @Test
        @DisplayName("Should reject access token as refresh token")
        fun testTokenTypeMismatch() {
            val testUser = TestUtils.createTestUser()
            val tokenPair = jwtService.generateToken(testUser)

            // Access token should not work as refresh token
            assertNull(jwtService.verifyRefreshToken(tokenPair.accessToken))
        }
    }

    @Nested
    @DisplayName("Token Extraction Tests")
    inner class TokenExtractionTests {

        @Test
        @DisplayName("Should extract user ID from token without verification")
        fun testUserIdExtraction() {
            val testUser = TestUtils.createTestUser()
            val tokenPair = jwtService.generateToken(testUser)

            val extractedUserId = jwtService.extractUserIdFromToken(tokenPair.accessToken)
            assertEquals(testUser.id.toString(), extractedUserId)
        }

        @Test
        @DisplayName("Should extract role from token")
        fun testRoleExtraction() {
            val testUser = TestUtils.createTestUser(role = UserRole.PARENT)
            val tokenPair = jwtService.generateToken(testUser)

            val extractedRole = jwtService.extractRoleFromToken(tokenPair.accessToken)
            assertEquals(UserRole.PARENT.name, extractedRole)
        }

        @Test
        @DisplayName("Should extract family ID from token with family context")
        fun testFamilyIdExtraction() {
            val testUser = TestUtils.createTestUser()
            val familyId = UUID.randomUUID()
            val tokenPair = jwtService.generateTokenWithFamilyContext(testUser, familyId)

            val extractedFamilyId = jwtService.extractFamilyIdFromToken(tokenPair.accessToken)
            assertEquals(familyId.toString(), extractedFamilyId)

            // Token without family context should return null
            val regularTokenPair = jwtService.generateToken(testUser)
            val noFamilyId = jwtService.extractFamilyIdFromToken(regularTokenPair.accessToken)
            assertNull(noFamilyId)
        }

        @Test
        @DisplayName("Should handle malformed tokens in extraction")
        fun testMalformedTokenExtraction() {
            assertNull(jwtService.extractUserIdFromToken("invalid.token"))
            assertNull(jwtService.extractRoleFromToken("malformed"))
            assertNull(jwtService.extractFamilyIdFromToken(""))
        }
    }

    @Nested
    @DisplayName("Flutter Integration Tests")
    inner class FlutterIntegrationTests {

        @Test
        @DisplayName("Should generate tokens compatible with Flutter JWT expectations")
        fun testFlutterTokenCompatibility() {
            val testUser = TestUtils.createTestUser(
                email = "flutter@test.com",
                firstName = "Flutter",
                lastName = "User",
                role = UserRole.PARENT
            )
            val familyId = UUID.randomUUID()

            val tokenPair = jwtService.generateTokenWithFamilyContext(testUser, familyId)

            // Flutter expects these specific claims in the JWT
            val decodedToken = JWT.decode(tokenPair.accessToken)
            
            // Required claims for Flutter
            assertNotNull(decodedToken.getClaim("userId").asString(), "Flutter requires userId claim")
            assertNotNull(decodedToken.getClaim("email").asString(), "Flutter requires email claim")
            assertNotNull(decodedToken.getClaim("role").asString(), "Flutter requires role claim")
            assertNotNull(decodedToken.getClaim("verified").asBoolean(), "Flutter requires verified claim")
            assertNotNull(decodedToken.getClaim("familyId").asString(), "Flutter requires familyId claim for parent users")

            // Verify claim values match Flutter expectations
            assertEquals(testUser.email, decodedToken.getClaim("email").asString())
            assertEquals("PARENT", decodedToken.getClaim("role").asString())
            assertTrue(decodedToken.getClaim("verified").asBoolean())
            assertEquals(familyId.toString(), decodedToken.getClaim("familyId").asString())
        }

        @Test
        @DisplayName("Should generate refresh tokens that Flutter can use")
        fun testFlutterRefreshTokenCompatibility() {
            val testUser = TestUtils.createTestUser()
            val familyId = UUID.randomUUID()
            val tokenPair = jwtService.generateTokenWithFamilyContext(testUser, familyId)

            // Flutter expects refresh tokens to contain userId and familyId for context
            val decodedRefreshToken = JWT.decode(tokenPair.refreshToken)
            
            assertEquals(testUser.id.toString(), decodedRefreshToken.getClaim("userId").asString())
            assertEquals(familyId.toString(), decodedRefreshToken.getClaim("familyId").asString())
            assertEquals("refresh", decodedRefreshToken.getClaim("type").asString())

            // Verify refresh token can be used for verification
            val verifiedUserId = jwtService.verifyRefreshToken(tokenPair.refreshToken)
            assertEquals(testUser.id.toString(), verifiedUserId)
        }

        @Test
        @DisplayName("Should handle different user roles for Flutter")
        fun testUserRolesForFlutter() {
            val parentUser = TestUtils.createTestUser(role = UserRole.PARENT)
            val superAdminUser = TestUtils.createTestUser(role = UserRole.SUPER_ADMIN)
            val adminUser = TestUtils.createTestUser(role = UserRole.ADMIN)

            val parentToken = jwtService.generateToken(parentUser)
            val superAdminToken = jwtService.generateToken(superAdminUser)
            val adminToken = jwtService.generateToken(adminUser)

            // Verify role claims
            assertEquals("PARENT", jwtService.extractRoleFromToken(parentToken.accessToken))
            assertEquals("SUPER_ADMIN", jwtService.extractRoleFromToken(superAdminToken.accessToken))
            assertEquals("ADMIN", jwtService.extractRoleFromToken(adminToken.accessToken))
        }
    }

    @Nested
    @DisplayName("Security Tests")
    inner class SecurityTests {

        @Test
        @DisplayName("Should generate unique tokens for each request")
        fun testTokenUniqueness() {
            val testUser = TestUtils.createTestUser()
            val familyId = UUID.randomUUID()

            val token1 = jwtService.generateTokenWithFamilyContext(testUser, familyId)
            Thread.sleep(1) // Ensure different issued at time
            val token2 = jwtService.generateTokenWithFamilyContext(testUser, familyId)

            // Tokens should be different (due to different issued at times)
            assertTrue(token1.accessToken != token2.accessToken)
            assertTrue(token1.refreshToken != token2.refreshToken)
        }

        @Test
        @DisplayName("Should handle concurrent token generation safely")
        fun testConcurrentTokenGeneration() {
            val testUser = TestUtils.createTestUser()
            val familyId = UUID.randomUUID()
            val tokens = mutableListOf<TokenPair>()

            // Generate tokens concurrently
            val threads = (1..10).map { 
                Thread {
                    synchronized(tokens) {
                        tokens.add(jwtService.generateTokenWithFamilyContext(testUser, familyId))
                    }
                }
            }

            threads.forEach { it.start() }
            threads.forEach { it.join() }

            // All tokens should be valid and unique
            assertEquals(10, tokens.size)
            val accessTokens = tokens.map { it.accessToken }.toSet()
            assertEquals(10, accessTokens.size, "All access tokens should be unique")

            // All tokens should be verifiable
            tokens.forEach { token ->
                val userId = jwtService.verifyToken(token.accessToken)
                assertEquals(testUser.id.toString(), userId)
            }
        }
    }
}