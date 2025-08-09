package com.wondernest.domain.model

import com.wondernest.data.database.table.AuthProvider
import com.wondernest.data.database.table.UserRole
import com.wondernest.data.database.table.UserStatus
import com.wondernest.data.database.table.NotificationPreferences
import com.wondernest.data.database.table.PrivacySettings
import kotlinx.datetime.Instant
import kotlinx.serialization.Serializable
import java.util.*

@Serializable
data class User(
    val id: UUID,
    val email: String,
    val emailVerified: Boolean = false,
    val emailVerifiedAt: Instant? = null,
    val authProvider: AuthProvider = AuthProvider.EMAIL,
    val externalId: String? = null,
    val firstName: String? = null,
    val lastName: String? = null,
    val phone: String? = null,
    val timezone: String = "UTC",
    val language: String = "en",
    val status: UserStatus = UserStatus.PENDING_VERIFICATION,
    val role: UserRole = UserRole.PARENT,
    val privacySettings: PrivacySettings = PrivacySettings(),
    val notificationPreferences: NotificationPreferences = NotificationPreferences(),
    val mfaEnabled: Boolean = false,
    val mfaSecret: String? = null,
    val backupCodes: List<String>? = null,
    val createdAt: Instant,
    val updatedAt: Instant,
    val lastLoginAt: Instant? = null,
    val loginCount: Int = 0,
    val parentalConsentVerified: Boolean = false,
    val parentalConsentMethod: String? = null,
    val parentalConsentDate: Instant? = null,
    val deletedAt: Instant? = null
) {
    val isActive: Boolean get() = status == UserStatus.ACTIVE && deletedAt == null
    val isDeleted: Boolean get() = deletedAt != null
    val fullName: String get() = listOfNotNull(firstName, lastName).joinToString(" ")
    val displayName: String get() = fullName.ifBlank { email.substringBefore("@") }
}

@Serializable
data class UserSession(
    val id: UUID,
    val userId: UUID,
    val sessionToken: String,
    val refreshToken: String? = null,
    val deviceFingerprint: String? = null,
    val userAgent: String? = null,
    val ipAddress: String? = null,
    val locationData: Map<String, String>? = null,
    val createdAt: Instant,
    val expiresAt: Instant,
    val lastActivity: Instant,
    val isActive: Boolean = true
)

@Serializable
data class PasswordResetToken(
    val id: UUID,
    val userId: UUID,
    val token: String,
    val used: Boolean = false,
    val expiresAt: Instant,
    val createdAt: Instant
)