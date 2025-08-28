package com.wondernest.domain.web

import kotlinx.serialization.Serializable
import java.time.Instant
import java.util.*

/**
 * Admin user domain model for web platform
 */
data class AdminUser(
    val id: UUID,
    val email: String,
    val passwordHash: String,
    val salt: String,
    val firstName: String,
    val lastName: String,
    val phoneNumber: String? = null,
    val role: AdminRole,
    val permissions: List<String>,
    val twoFactorEnabled: Boolean = false,
    val twoFactorSecret: String? = null,
    val isActive: Boolean = true,
    val emailVerified: Boolean = false,
    val lastLoginAt: Instant? = null,
    val failedLoginAttempts: Int = 0,
    val lockedUntil: Instant? = null,
    val createdBy: UUID? = null,
    val createdAt: Instant,
    val updatedAt: Instant
) {
    fun toProfile(): AdminUserProfile {
        return AdminUserProfile(
            id = id.toString(),
            email = email,
            firstName = firstName,
            lastName = lastName,
            role = role.name.lowercase(),
            permissions = permissions,
            twoFactorEnabled = twoFactorEnabled
        )
    }
    
    fun isLocked(): Boolean {
        return lockedUntil?.isAfter(Instant.now()) == true
    }
}

/**
 * Admin roles with different permission levels
 */
enum class AdminRole(val displayName: String, val level: Int) {
    SUPER_ADMIN("Super Administrator", 100),
    CONTENT_MODERATOR("Content Moderator", 50),
    CONTENT_CREATOR("Content Creator", 30),
    ANALYTICS_VIEWER("Analytics Viewer", 20),
    SUPPORT_AGENT("Support Agent", 10);
    
    fun hasHigherLevelThan(other: AdminRole): Boolean {
        return this.level > other.level
    }
}

/**
 * Admin session for web authentication
 */
data class AdminSession(
    val id: UUID,
    val adminUserId: UUID,
    val sessionToken: String,
    val refreshToken: String? = null,
    val ipAddress: String,
    val userAgent: String? = null,
    val deviceFingerprint: String? = null,
    val expiresAt: Instant,
    val lastActivity: Instant,
    val isActive: Boolean = true,
    val createdAt: Instant
) {
    fun isExpired(): Boolean = expiresAt.isBefore(Instant.now())
}

/**
 * Serializable admin user profile for API responses
 */
@Serializable
data class AdminUserProfile(
    val id: String,
    val email: String,
    val firstName: String,
    val lastName: String,
    val role: String,
    val permissions: List<String>,
    val twoFactorEnabled: Boolean
)

/**
 * Admin login request model
 */
@Serializable
data class AdminLoginRequest(
    val email: String,
    val password: String,
    val twoFactorCode: String? = null
)

/**
 * Admin login response model
 */
@Serializable
data class AdminLoginResponse(
    val accessToken: String,
    val refreshToken: String,
    val adminUser: AdminUserProfile,
    val permissions: List<String>,
    val expiresIn: Long,
    val requiresTwoFactor: Boolean = false
)

/**
 * Admin permissions enum
 */
enum class AdminPermission(val code: String, val description: String) {
    // User Management
    MANAGE_USERS("manage_users", "Manage parent and child accounts"),
    VIEW_USER_DATA("view_user_data", "View user profile and activity data"),
    MODERATE_USER_CONTENT("moderate_user_content", "Moderate user-generated content"),
    
    // Content Management
    CREATE_CONTENT("create_content", "Create new stories and games"),
    EDIT_CONTENT("edit_content", "Edit existing content"),
    PUBLISH_CONTENT("publish_content", "Publish content to platform"),
    MODERATE_CONTENT("moderate_content", "Review and approve content"),
    DELETE_CONTENT("delete_content", "Delete content from platform"),
    
    // Analytics & Reporting
    VIEW_PLATFORM_ANALYTICS("view_platform_analytics", "View platform-wide analytics"),
    EXPORT_DATA("export_data", "Export user and platform data"),
    VIEW_FINANCIAL_DATA("view_financial_data", "View revenue and financial metrics"),
    
    // System Administration
    MANAGE_SYSTEM_SETTINGS("manage_system_settings", "Manage platform configuration"),
    VIEW_AUDIT_LOGS("view_audit_logs", "View system audit logs"),
    MANAGE_ADMIN_USERS("manage_admin_users", "Manage other admin users"),
    
    // Security
    MANAGE_SECURITY_SETTINGS("manage_security_settings", "Manage security configuration"),
    VIEW_SECURITY_LOGS("view_security_logs", "View security-related logs"),
    FORCE_PASSWORD_RESET("force_password_reset", "Force password resets for users");
    
    companion object {
        fun getRolePermissions(role: AdminRole): List<AdminPermission> {
            return when (role) {
                AdminRole.SUPER_ADMIN -> values().toList()
                AdminRole.CONTENT_MODERATOR -> listOf(
                    VIEW_USER_DATA, MODERATE_USER_CONTENT, CREATE_CONTENT,
                    EDIT_CONTENT, MODERATE_CONTENT, VIEW_PLATFORM_ANALYTICS,
                    VIEW_AUDIT_LOGS
                )
                AdminRole.CONTENT_CREATOR -> listOf(
                    CREATE_CONTENT, EDIT_CONTENT, VIEW_PLATFORM_ANALYTICS
                )
                AdminRole.ANALYTICS_VIEWER -> listOf(
                    VIEW_PLATFORM_ANALYTICS, EXPORT_DATA, VIEW_AUDIT_LOGS
                )
                AdminRole.SUPPORT_AGENT -> listOf(
                    VIEW_USER_DATA, MODERATE_USER_CONTENT, VIEW_PLATFORM_ANALYTICS
                )
            }
        }
    }
}