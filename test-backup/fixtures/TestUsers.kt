package com.wondernest.fixtures

import com.wondernest.services.auth.LoginRequest
import com.wondernest.services.auth.OAuthLoginRequest
import com.wondernest.services.auth.SignupRequest
import com.wondernest.api.auth.PasswordResetRequest
import com.wondernest.api.auth.PasswordResetConfirmRequest
import com.wondernest.api.auth.RefreshTokenRequest

/**
 * Test fixture data for user-related operations
 */
object TestUsers {
    
    // Valid test users
    val validUser = SignupRequest(
        email = "test@example.com",
        password = "SecurePass123!",
        firstName = "Test",
        lastName = "User",
        timezone = "America/New_York",
        language = "en"
    )
    
    val secondValidUser = SignupRequest(
        email = "user2@example.com",
        password = "AnotherSecure123!",
        firstName = "Jane",
        lastName = "Doe",
        timezone = "UTC",
        language = "en"
    )
    
    val minimalValidUser = SignupRequest(
        email = "minimal@example.com",
        password = "MinimalPass123!",
        firstName = null,
        lastName = null,
        timezone = "UTC",
        language = "en"
    )
    
    // Users with different locales
    val frenchUser = SignupRequest(
        email = "french@example.com",
        password = "FrenchPass123!",
        firstName = "Jean",
        lastName = "Dupont",
        timezone = "Europe/Paris",
        language = "fr"
    )
    
    val spanishUser = SignupRequest(
        email = "spanish@example.com",
        password = "SpanishPass123!",
        firstName = "Carlos",
        lastName = "Rodriguez",
        timezone = "Europe/Madrid",
        language = "es"
    )
    
    // Invalid email formats
    val invalidEmailUser = validUser.copy(email = "invalid-email")
    val missingAtUser = validUser.copy(email = "invalid.email.com")
    val missingDomainUser = validUser.copy(email = "invalid@")
    val spacesInEmailUser = validUser.copy(email = "test user@example.com")
    
    // Invalid password users
    val weakPasswordUser = validUser.copy(password = "123")
    val shortPasswordUser = validUser.copy(password = "Pass1!")
    val noNumberPasswordUser = validUser.copy(password = "PasswordNoNumber!")
    val noSpecialCharPasswordUser = validUser.copy(password = "Password123")
    val allLowercaseUser = validUser.copy(password = "password123!")
    val allUppercaseUser = validUser.copy(password = "PASSWORD123!")
    
    // Security test users
    val sqlInjectionUser = validUser.copy(
        email = "'; DROP TABLE users; --@example.com",
        firstName = "'; DROP TABLE users; --",
        lastName = "'; DELETE FROM users; --"
    )
    
    val xssUser = validUser.copy(
        firstName = "<script>alert('xss')</script>",
        lastName = "<img src=x onerror=alert('xss')>",
        email = "<script>alert('xss')</script>@example.com"
    )
    
    val longStringUser = validUser.copy(
        firstName = "A".repeat(1000),
        lastName = "B".repeat(1000),
        email = "${"verylong".repeat(50)}@example.com"
    )
    
    // Unicode and special character users
    val unicodeUser = validUser.copy(
        email = "unicode@example.com",
        firstName = "测试",
        lastName = "用户",
        timezone = "Asia/Shanghai",
        language = "zh"
    )
    
    val emojiUser = validUser.copy(
        email = "emoji@example.com",
        firstName = "Test 😀",
        lastName = "User 🎉"
    )
    
    val specialCharUser = validUser.copy(
        email = "special@example.com",
        firstName = "Test-User_123",
        lastName = "O'Connor-Smith"
    )
    
    // Login requests
    val validLoginRequest = LoginRequest(
        email = validUser.email,
        password = validUser.password
    )
    
    val invalidEmailLoginRequest = LoginRequest(
        email = "nonexistent@example.com",
        password = validUser.password
    )
    
    val invalidPasswordLoginRequest = LoginRequest(
        email = validUser.email,
        password = "WrongPassword123!"
    )
    
    val sqlInjectionLoginRequest = LoginRequest(
        email = "'; DROP TABLE users; --",
        password = "'; DELETE FROM users; --"
    )
    
    // OAuth requests
    val validGoogleOAuthRequest = OAuthLoginRequest(
        provider = "google",
        token = "valid_google_token_123",
        email = "oauth@example.com",
        firstName = "OAuth",
        lastName = "User"
    )
    
    val validAppleOAuthRequest = OAuthLoginRequest(
        provider = "apple",
        token = "valid_apple_token_123",
        email = "apple@example.com",
        firstName = "Apple",
        lastName = "User"
    )
    
    val validFacebookOAuthRequest = OAuthLoginRequest(
        provider = "facebook",
        token = "valid_facebook_token_123",
        email = "facebook@example.com",
        firstName = "Facebook",
        lastName = "User"
    )
    
    val invalidOAuthRequest = OAuthLoginRequest(
        provider = "google",
        token = "invalid_token",
        email = "invalid@example.com"
    )
    
    val expiredOAuthRequest = OAuthLoginRequest(
        provider = "google",
        token = "expired_token_123",
        email = "expired@example.com"
    )
    
    val unsupportedProviderOAuthRequest = OAuthLoginRequest(
        provider = "twitter",
        token = "twitter_token_123",
        email = "twitter@example.com"
    )
    
    // Password reset requests
    val validPasswordResetRequest = PasswordResetRequest(
        email = validUser.email
    )
    
    val nonexistentPasswordResetRequest = PasswordResetRequest(
        email = "nonexistent@example.com"
    )
    
    val invalidEmailPasswordResetRequest = PasswordResetRequest(
        email = "invalid-email"
    )
    
    // Password reset confirmation requests
    val validPasswordResetConfirmRequest = PasswordResetConfirmRequest(
        token = "valid_reset_token_123",
        newPassword = "NewSecurePass123!"
    )
    
    val invalidTokenPasswordResetConfirmRequest = PasswordResetConfirmRequest(
        token = "invalid_token",
        newPassword = "NewSecurePass123!"
    )
    
    val expiredTokenPasswordResetConfirmRequest = PasswordResetConfirmRequest(
        token = "expired_token_123",
        newPassword = "NewSecurePass123!"
    )
    
    val weakPasswordResetConfirmRequest = PasswordResetConfirmRequest(
        token = "valid_reset_token_123",
        newPassword = "weak"
    )
    
    // Refresh token requests
    val validRefreshTokenRequest = RefreshTokenRequest(
        refreshToken = "valid_refresh_token_123"
    )
    
    val invalidRefreshTokenRequest = RefreshTokenRequest(
        refreshToken = "invalid_refresh_token"
    )
    
    val expiredRefreshTokenRequest = RefreshTokenRequest(
        refreshToken = "expired_refresh_token_123"
    )
    
    val revokedRefreshTokenRequest = RefreshTokenRequest(
        refreshToken = "revoked_refresh_token_123"
    )
    
    // JWT tokens for testing
    object TestTokens {
        const val validJWT = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VySWQiOiJjZGY4ZjM4OS1lOGIxLTQxZTMtODQwOC1kNDY5ZTE1YjNlNjIiLCJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJyb2xlIjoidXNlciIsInZlcmlmaWVkIjp0cnVlLCJpYXQiOjE2MzM5NjU2MDAsImV4cCI6OTk5OTk5OTk5OX0.mock_signature"
        const val expiredJWT = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VySWQiOiJjZGY4ZjM4OS1lOGIxLTQxZTMtODQwOC1kNDY5ZTE1YjNlNjIiLCJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJyb2xlIjoidXNlciIsInZlcmlmaWVkIjp0cnVlLCJpYXQiOjE2MzM5NjU2MDAsImV4cCI6MTYzMzk2NTYwMX0.mock_signature"
        const val invalidJWT = "invalid.jwt.token"
        const val malformedJWT = "not-a-jwt-token-at-all"
        const val tamperedJWT = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VySWQiOiJoYWNrZXIiLCJlbWFpbCI6ImhhY2tlckBleGFtcGxlLmNvbSIsInJvbGUiOiJhZG1pbiIsInZlcmlmaWVkIjp0cnVlLCJpYXQiOjE2MzM5NjU2MDAsImV4cCI6OTk5OTk5OTk5OX0.tampered_signature"
        
        const val validRefreshToken = "refresh_token_valid_123"
        const val expiredRefreshToken = "refresh_token_expired_123"
        const val invalidRefreshToken = "refresh_token_invalid"
        const val revokedRefreshToken = "refresh_token_revoked_123"
    }
    
    // Rate limiting test data
    fun generateBulkSignupRequests(count: Int): List<SignupRequest> {
        return (1..count).map { index ->
            SignupRequest(
                email = "bulk$index@example.com",
                password = "BulkPass123!",
                firstName = "Bulk",
                lastName = "User$index"
            )
        }
    }
    
    fun generateBulkLoginRequests(count: Int): List<LoginRequest> {
        return (1..count).map { index ->
            LoginRequest(
                email = "bulk$index@example.com",
                password = "BulkPass123!"
            )
        }
    }
    
    // Edge case data
    object EdgeCases {
        val emptyStringFields = SignupRequest(
            email = "",
            password = "",
            firstName = "",
            lastName = "",
            timezone = "",
            language = ""
        )
        
        val nullableFieldsAsEmpty = SignupRequest(
            email = "test@example.com",
            password = "TestPass123!",
            firstName = "",
            lastName = "",
            timezone = "UTC",
            language = "en"
        )
        
        val whitespaceFields = SignupRequest(
            email = "   whitespace@example.com   ",
            password = "WhitespacePass123!",
            firstName = "   Test   ",
            lastName = "   User   ",
            timezone = "UTC",
            language = "en"
        )
        
        val veryLongValidPassword = "VeryLongPasswordThatIsStillValid123!".repeat(10)
        val maxLengthUser = SignupRequest(
            email = "maxlength@example.com",
            password = veryLongValidPassword.take(128),
            firstName = "A".repeat(100),
            lastName = "B".repeat(100),
            timezone = "America/New_York",
            language = "en"
        )
    }
}