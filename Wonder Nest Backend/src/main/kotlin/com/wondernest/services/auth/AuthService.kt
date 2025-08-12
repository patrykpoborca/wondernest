package com.wondernest.services.auth

import com.wondernest.data.database.table.AuthProvider
import com.wondernest.data.database.table.UserRole
import com.wondernest.data.database.table.UserStatus
import com.wondernest.domain.model.User
import com.wondernest.domain.model.UserSession
import com.wondernest.domain.model.PasswordResetToken
import com.wondernest.domain.repository.UserRepository
import com.wondernest.services.email.EmailService
import kotlinx.datetime.Clock
import kotlinx.datetime.DateTimeUnit
import kotlinx.datetime.plus
import mu.KotlinLogging
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder
import kotlinx.serialization.Serializable
import java.security.SecureRandom
import java.util.*

private val logger = KotlinLogging.logger {}

@Serializable
data class SignupRequest(
    val email: String,
    val password: String,
    val firstName: String? = null,
    val lastName: String? = null,
    val timezone: String = "UTC",
    val language: String = "en"
)

@Serializable
data class LoginRequest(
    val email: String,
    val password: String
)

@Serializable
data class AuthResponse(
    val user: User,
    val accessToken: String,
    val refreshToken: String,
    val expiresIn: Long
)

@Serializable
data class OAuthLoginRequest(
    val provider: String,
    val idToken: String,
    val email: String,
    val firstName: String? = null,
    val lastName: String? = null
)

class AuthService(
    private val userRepository: UserRepository,
    private val jwtService: JwtService,
    private val emailService: EmailService? = null
) {
    private val passwordEncoder = BCryptPasswordEncoder(12)
    private val secureRandom = SecureRandom()

    suspend fun signup(request: SignupRequest): AuthResponse {
        // Validate email format
        if (!isValidEmail(request.email)) {
            throw IllegalArgumentException("Invalid email format")
        }

        // Check if user already exists
        val existingUser = userRepository.getUserByEmail(request.email)
        if (existingUser != null) {
            throw IllegalArgumentException("User with this email already exists")
        }

        // Validate password strength
        validatePassword(request.password)

        // Create user
        val now = Clock.System.now()
        val hashedPassword = passwordEncoder.encode(request.password)
        
        val newUser = User(
            id = UUID.randomUUID(),
            email = request.email.lowercase(),
            emailVerified = false,
            authProvider = AuthProvider.EMAIL,
            firstName = request.firstName?.trim(),
            lastName = request.lastName?.trim(),
            timezone = request.timezone,
            language = request.language,
            status = UserStatus.PENDING_VERIFICATION,
            role = UserRole.PARENT,
            createdAt = now,
            updatedAt = now
        )

        val createdUser = userRepository.createUser(newUser)
        
        // Store password hash separately
        userRepository.updateUserPassword(createdUser.id, hashedPassword)

        // Send verification email
        try {
            emailService?.sendVerificationEmail(createdUser)
        } catch (e: Exception) {
            logger.warn(e) { "Failed to send verification email to ${createdUser.email}" }
        }

        // Generate tokens
        val tokenPair = jwtService.generateToken(createdUser)
        
        // Create session
        val session = createUserSession(createdUser, tokenPair)
        userRepository.createSession(session)

        logger.info { "User signed up: ${createdUser.email} (${createdUser.id})" }

        return AuthResponse(
            user = createdUser,
            accessToken = tokenPair.accessToken,
            refreshToken = tokenPair.refreshToken,
            expiresIn = tokenPair.expiresIn
        )
    }

    suspend fun login(request: LoginRequest): AuthResponse {
        val user = userRepository.getUserByEmail(request.email.lowercase())
            ?: throw SecurityException("Invalid credentials")

        if (user.status == UserStatus.SUSPENDED) {
            throw SecurityException("Account suspended")
        }

        // Check password
        val passwordHash = userRepository.getUserPasswordHash(user.id)
            ?: throw SecurityException("Invalid credentials")

        if (!passwordEncoder.matches(request.password, passwordHash)) {
            throw SecurityException("Invalid credentials")
        }

        // Update last login
        userRepository.updateLastLogin(user.id)

        // Generate tokens
        val tokenPair = jwtService.generateToken(user)
        
        // Create session
        val session = createUserSession(user, tokenPair)
        userRepository.createSession(session)

        logger.info { "User logged in: ${user.email} (${user.id})" }

        return AuthResponse(
            user = user,
            accessToken = tokenPair.accessToken,
            refreshToken = tokenPair.refreshToken,
            expiresIn = tokenPair.expiresIn
        )
    }

    suspend fun oauthLogin(request: OAuthLoginRequest): AuthResponse {
        val provider = AuthProvider.valueOf(request.provider.uppercase())
        
        // In a real implementation, you would verify the idToken with the provider
        // For now, we'll assume it's valid
        
        var user = userRepository.getUserByEmail(request.email.lowercase())
        
        if (user == null) {
            // Create new user from OAuth
            val now = Clock.System.now()
            user = User(
                id = UUID.randomUUID(),
                email = request.email.lowercase(),
                emailVerified = true, // OAuth providers verify emails
                emailVerifiedAt = now,
                authProvider = provider,
                externalId = extractExternalIdFromToken(request.idToken),
                firstName = request.firstName?.trim(),
                lastName = request.lastName?.trim(),
                status = UserStatus.ACTIVE,
                role = UserRole.PARENT,
                createdAt = now,
                updatedAt = now
            )
            
            user = userRepository.createUser(user)
            logger.info { "New OAuth user created: ${user.email} (${user.id})" }
        } else {
            // Update existing user
            userRepository.updateLastLogin(user.id)
        }

        // Generate tokens
        val tokenPair = jwtService.generateToken(user)
        
        // Create session
        val session = createUserSession(user, tokenPair)
        userRepository.createSession(session)

        logger.info { "OAuth login: ${user.email} (${user.id}) via ${provider}" }

        return AuthResponse(
            user = user,
            accessToken = tokenPair.accessToken,
            refreshToken = tokenPair.refreshToken,
            expiresIn = tokenPair.expiresIn
        )
    }

    suspend fun refreshToken(refreshToken: String): AuthResponse {
        val userId = jwtService.verifyRefreshToken(refreshToken)
            ?: throw SecurityException("Invalid refresh token")

        val user = userRepository.getUserById(UUID.fromString(userId))
            ?: throw SecurityException("User not found")

        if (user.status != UserStatus.ACTIVE) {
            throw SecurityException("Account not active")
        }

        // Generate new tokens
        val tokenPair = jwtService.generateToken(user)
        
        // Create new session
        val session = createUserSession(user, tokenPair)
        userRepository.createSession(session)

        return AuthResponse(
            user = user,
            accessToken = tokenPair.accessToken,
            refreshToken = tokenPair.refreshToken,
            expiresIn = tokenPair.expiresIn
        )
    }

    suspend fun logout(sessionToken: String): Boolean {
        val session = userRepository.getSessionByToken(sessionToken)
        return if (session != null) {
            userRepository.invalidateSession(session.id)
        } else {
            false
        }
    }

    suspend fun verifyEmail(userId: UUID): Boolean {
        return userRepository.verifyUserEmail(userId)
    }

    suspend fun requestPasswordReset(email: String): Boolean {
        val user = userRepository.getUserByEmail(email.lowercase()) ?: return false
        
        val token = generateSecureToken()
        val expiresAt = Clock.System.now().plus(24, DateTimeUnit.HOUR) // 24 hours
        
        val resetToken = PasswordResetToken(
            id = UUID.randomUUID(),
            userId = user.id,
            token = token,
            expiresAt = expiresAt,
            createdAt = Clock.System.now()
        )
        
        userRepository.createPasswordResetToken(resetToken)
        
        try {
            emailService?.sendPasswordResetEmail(user, token)
        } catch (e: Exception) {
            logger.warn(e) { "Failed to send password reset email to ${user.email}" }
            return false
        }
        
        logger.info { "Password reset requested for: ${user.email}" }
        return true
    }

    suspend fun resetPassword(token: String, newPassword: String): Boolean {
        val resetToken = userRepository.getPasswordResetToken(token) ?: return false
        
        validatePassword(newPassword)
        
        val hashedPassword = passwordEncoder.encode(newPassword)
        val updated = userRepository.updateUserPassword(resetToken.userId, hashedPassword)
        
        if (updated) {
            userRepository.markPasswordResetTokenUsed(resetToken.id)
            // Invalidate all existing sessions
            userRepository.invalidateAllUserSessions(resetToken.userId)
            logger.info { "Password reset completed for user: ${resetToken.userId}" }
        }
        
        return updated
    }

    private fun createUserSession(user: User, tokenPair: TokenPair): UserSession {
        val now = Clock.System.now()
        return UserSession(
            id = UUID.randomUUID(),
            userId = user.id,
            sessionToken = tokenPair.accessToken,
            refreshToken = tokenPair.refreshToken,
            createdAt = now,
            expiresAt = now.plus(tokenPair.expiresIn, DateTimeUnit.MILLISECOND),
            lastActivity = now
        )
    }

    private fun validatePassword(password: String) {
        if (password.length < 8) {
            throw IllegalArgumentException("Password must be at least 8 characters long")
        }
        if (!password.any { it.isDigit() }) {
            throw IllegalArgumentException("Password must contain at least one digit")
        }
        if (!password.any { it.isUpperCase() }) {
            throw IllegalArgumentException("Password must contain at least one uppercase letter")
        }
        if (!password.any { it.isLowerCase() }) {
            throw IllegalArgumentException("Password must contain at least one lowercase letter")
        }
    }

    private fun isValidEmail(email: String): Boolean {
        return email.contains("@") && email.contains(".") && email.length >= 5
    }

    private fun generateSecureToken(): String {
        val bytes = ByteArray(32)
        secureRandom.nextBytes(bytes)
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes)
    }

    private fun extractExternalIdFromToken(idToken: String): String {
        // This is a placeholder - in real implementation, decode the JWT token
        // and extract the subject (sub) claim which contains the external user ID
        return UUID.randomUUID().toString()
    }
}