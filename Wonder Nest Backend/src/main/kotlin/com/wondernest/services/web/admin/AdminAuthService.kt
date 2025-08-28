package com.wondernest.services.web.admin

import com.wondernest.data.database.repository.web.AdminUserRepository
import com.wondernest.data.database.repository.web.AdminSessionRepository
import com.wondernest.domain.web.*
import com.wondernest.services.auth.JwtService
import com.wondernest.services.security.TwoFactorService
import com.wondernest.services.security.SecurityService
import com.wondernest.services.logging.AuditLogService
import mu.KotlinLogging
import org.springframework.security.crypto.bcrypt.BCrypt
import java.time.Instant
import java.time.temporal.ChronoUnit
import java.util.*

private val logger = KotlinLogging.logger {}

/**
 * Service for admin user authentication and session management
 */
class AdminAuthService(
    private val adminUserRepository: AdminUserRepository,
    private val adminSessionRepository: AdminSessionRepository,
    private val jwtService: JwtService,
    private val twoFactorService: TwoFactorService,
    private val securityService: SecurityService,
    private val auditLogService: AuditLogService
) {
    companion object {
        private const val MAX_LOGIN_ATTEMPTS = 5
        private const val LOCKOUT_DURATION_MINUTES = 30L
        private const val SESSION_DURATION_HOURS = 4L
    }

    /**
     * Authenticate admin user with email/password and optional 2FA
     */
    suspend fun authenticateAdmin(
        request: AdminLoginRequest,
        ipAddress: String,
        userAgent: String? = null
    ): AdminLoginResponse {
        logger.info { "Admin login attempt for email: ${request.email} from IP: $ipAddress" }
        
        // Rate limiting check
        securityService.checkLoginRateLimit(request.email, ipAddress)
        
        // Find admin user by email
        val adminUser = adminUserRepository.findByEmail(request.email)
            ?: run {
                auditLogService.logFailedAdminLogin(request.email, ipAddress, "User not found")
                throw AuthenticationException("Invalid credentials")
            }
        
        // Check if user is active
        if (!adminUser.isActive) {
            auditLogService.logFailedAdminLogin(adminUser.email, ipAddress, "Account disabled")
            throw AuthenticationException("Account is disabled")
        }
        
        // Check if user is locked
        if (adminUser.isLocked()) {
            auditLogService.logFailedAdminLogin(adminUser.email, ipAddress, "Account locked")
            throw AuthenticationException("Account is temporarily locked")
        }
        
        // Validate password
        if (!BCrypt.checkpw(request.password, adminUser.passwordHash)) {
            // Increment failed login attempts
            val newAttempts = adminUser.failedLoginAttempts + 1
            adminUserRepository.updateFailedLoginAttempts(adminUser.id, newAttempts)
            
            // Lock user if max attempts reached
            if (newAttempts >= MAX_LOGIN_ATTEMPTS) {
                val lockUntil = Instant.now().plus(LOCKOUT_DURATION_MINUTES, ChronoUnit.MINUTES)
                adminUserRepository.lockUser(adminUser.id, lockUntil)
                auditLogService.logAdminAccountLocked(adminUser.id, ipAddress)
            }
            
            auditLogService.logFailedAdminLogin(adminUser.email, ipAddress, "Invalid password")
            throw AuthenticationException("Invalid credentials")
        }
        
        // Check 2FA if enabled
        if (adminUser.twoFactorEnabled) {
            if (request.twoFactorCode.isNullOrBlank()) {
                return AdminLoginResponse(
                    accessToken = "",
                    refreshToken = "",
                    adminUser = adminUser.toProfile(),
                    permissions = emptyList(),
                    expiresIn = 0,
                    requiresTwoFactor = true
                )
            }
            
            if (!twoFactorService.validateCode(adminUser.twoFactorSecret!!, request.twoFactorCode)) {
                auditLogService.logFailed2FA(adminUser.id, ipAddress)
                throw AuthenticationException("Invalid 2FA code")
            }
        }
        
        // Reset failed login attempts on successful authentication
        if (adminUser.failedLoginAttempts > 0) {
            adminUserRepository.updateFailedLoginAttempts(adminUser.id, 0)
        }
        
        // Generate session tokens
        val sessionToken = generateSecureToken()
        val refreshToken = generateSecureToken()
        
        // Create admin session
        val session = AdminSession(
            id = UUID.randomUUID(),
            adminUserId = adminUser.id,
            sessionToken = hashToken(sessionToken),
            refreshToken = hashToken(refreshToken),
            ipAddress = ipAddress,
            userAgent = userAgent,
            expiresAt = Instant.now().plus(SESSION_DURATION_HOURS, ChronoUnit.HOURS),
            lastActivity = Instant.now(),
            isActive = true,
            createdAt = Instant.now()
        )
        
        adminSessionRepository.create(session)
        
        // Generate JWT token with admin claims
        val jwtToken = jwtService.generateToken(
            userId = adminUser.id,
            sessionType = "admin",
            role = adminUser.role.name,
            permissions = adminUser.permissions,
            sessionId = session.id,
            expiresIn = java.time.Duration.ofHours(SESSION_DURATION_HOURS)
        )
        
        // Update last login timestamp
        adminUserRepository.updateLastLogin(adminUser.id, Instant.now())
        
        // Log successful login
        auditLogService.logSuccessfulAdminLogin(adminUser.id, ipAddress)
        
        logger.info { "Admin login successful for user: ${adminUser.id}" }
        
        return AdminLoginResponse(
            accessToken = jwtToken.token,
            refreshToken = refreshToken,
            adminUser = adminUser.toProfile(),
            permissions = adminUser.permissions,
            expiresIn = jwtToken.expiresIn
        )
    }
    
    /**
     * Refresh admin token using refresh token
     */
    suspend fun refreshAdminToken(refreshToken: String): AdminLoginResponse {
        val hashedRefreshToken = hashToken(refreshToken)
        val session = adminSessionRepository.findByToken(hashedRefreshToken)
            ?: throw AuthenticationException("Invalid refresh token")
        
        if (!session.isActive || session.isExpired()) {
            adminSessionRepository.deactivateSession(session.id)
            throw AuthenticationException("Session expired")
        }
        
        val adminUser = adminUserRepository.findById(session.adminUserId)
            ?: throw AuthenticationException("User not found")
        
        if (!adminUser.isActive) {
            throw AuthenticationException("Account is disabled")
        }
        
        // Update session activity
        adminSessionRepository.updateLastActivity(session.id, Instant.now())
        
        // Generate new JWT token
        val jwtToken = jwtService.generateToken(
            userId = adminUser.id,
            sessionType = "admin",
            role = adminUser.role.name,
            permissions = adminUser.permissions,
            sessionId = session.id,
            expiresIn = java.time.Duration.ofHours(SESSION_DURATION_HOURS)
        )
        
        logger.info { "Admin token refreshed for user: ${adminUser.id}" }
        
        return AdminLoginResponse(
            accessToken = jwtToken.token,
            refreshToken = refreshToken,
            adminUser = adminUser.toProfile(),
            permissions = adminUser.permissions,
            expiresIn = jwtToken.expiresIn
        )
    }
    
    /**
     * Logout admin user by deactivating session
     */
    suspend fun logoutAdmin(token: String): Boolean {
        val hashedToken = hashToken(token)
        val session = adminSessionRepository.findByToken(hashedToken)
            ?: return false
        
        val result = adminSessionRepository.deactivateSession(session.id)
        
        if (result) {
            auditLogService.logAdminLogout(session.adminUserId)
            logger.info { "Admin logout successful for session: ${session.id}" }
        }
        
        return result
    }
    
    /**
     * Validate admin session and return user if valid
     */
    suspend fun validateSession(token: String): AdminUser? {
        val hashedToken = hashToken(token)
        val session = adminSessionRepository.findByToken(hashedToken)
            ?: return null
        
        if (!session.isActive || session.isExpired()) {
            adminSessionRepository.deactivateSession(session.id)
            return null
        }
        
        val adminUser = adminUserRepository.findById(session.adminUserId)
            ?: return null
        
        if (!adminUser.isActive) {
            adminSessionRepository.deactivateSession(session.id)
            return null
        }
        
        // Update session activity
        adminSessionRepository.updateLastActivity(session.id, Instant.now())
        
        return adminUser
    }
    
    /**
     * Get active sessions for admin user
     */
    suspend fun getActiveSessions(adminUserId: UUID): List<AdminSession> {
        return adminSessionRepository.findActiveSessionsForUser(adminUserId)
    }
    
    /**
     * Deactivate all sessions for admin user (force logout)
     */
    suspend fun deactivateAllSessions(adminUserId: UUID): Int {
        val count = adminSessionRepository.deactivateAllUserSessions(adminUserId)
        auditLogService.logForceLogoutAdmin(adminUserId, count)
        return count
    }
    
    /**
     * Clean up expired sessions
     */
    suspend fun cleanupExpiredSessions(): Int {
        return adminSessionRepository.deleteExpiredSessions()
    }
    
    private fun generateSecureToken(length: Int = 32): String {
        return securityService.generateSecureToken(length)
    }
    
    private fun hashToken(token: String): String {
        return BCrypt.hashpw(token, BCrypt.gensalt(12))
    }
}

/**
 * Exception for authentication failures
 */
class AuthenticationException(message: String) : Exception(message)