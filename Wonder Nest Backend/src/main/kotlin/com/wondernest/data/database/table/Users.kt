package com.wondernest.data.database.table

import org.jetbrains.exposed.dao.id.UUIDTable
import org.jetbrains.exposed.sql.kotlin.datetime.CurrentTimestamp
import org.jetbrains.exposed.sql.kotlin.datetime.timestamp
import org.jetbrains.exposed.sql.json.jsonb
import org.jetbrains.exposed.sql.*
import kotlinx.datetime.Instant
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.encodeToString
import kotlinx.serialization.decodeFromString

// Enums for user-related tables
@Serializable
enum class AuthProvider { EMAIL, GOOGLE, APPLE, FACEBOOK }

@Serializable
enum class UserStatus { PENDING_VERIFICATION, ACTIVE, SUSPENDED, DELETED }

@Serializable
enum class UserRole { PARENT, ADMIN, SUPER_ADMIN }

@Serializable
data class NotificationPreferences(
    val email: Boolean = true,
    val push: Boolean = true,
    val sms: Boolean = false
)

@Serializable 
data class PrivacySettings(
    val dataSharing: Boolean = false,
    val researchParticipation: Boolean = false,
    val marketingEmails: Boolean = false
)

object Users : UUIDTable("users") {
    val email = varchar("email", 255).uniqueIndex()
    val emailVerified = bool("email_verified").default(false)
    val emailVerifiedAt = timestamp("email_verified_at").nullable()
    val passwordHash = varchar("password_hash", 255).nullable()
    val authProvider = enumerationByName<AuthProvider>("auth_provider", 20).default(AuthProvider.EMAIL)
    val externalId = varchar("external_id", 255).nullable()
    
    // Profile information
    val firstName = varchar("first_name", 100).nullable()
    val lastName = varchar("last_name", 100).nullable()
    val phone = varchar("phone", 20).nullable()
    val timezone = varchar("timezone", 50).default("UTC")
    val language = varchar("language", 10).default("en")
    
    // Account status and settings
    val status = enumerationByName<UserStatus>("status", 30).default(UserStatus.PENDING_VERIFICATION)
    val role = enumerationByName<UserRole>("role", 20).default(UserRole.PARENT)
    
    // Privacy and notification preferences
    val privacySettings = jsonb<PrivacySettings>("privacy_settings",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    ).default(PrivacySettings())
    val notificationPreferences = jsonb<NotificationPreferences>("notification_preferences",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    ).default(NotificationPreferences())
    
    // MFA settings
    val mfaEnabled = bool("mfa_enabled").default(false)
    val mfaSecret = varchar("mfa_secret", 255).nullable()
    val backupCodes = text("backup_codes").nullable() // Storing as JSON array string for now
    
    // Audit fields
    val createdAt = timestamp("created_at").defaultExpression(CurrentTimestamp())
    val updatedAt = timestamp("updated_at").defaultExpression(CurrentTimestamp())
    val lastLoginAt = timestamp("last_login_at").nullable()
    val loginCount = integer("login_count").default(0)
    
    // COPPA compliance
    val parentalConsentVerified = bool("parental_consent_verified").default(false)
    val parentalConsentMethod = varchar("parental_consent_method", 50).nullable()
    val parentalConsentDate = timestamp("parental_consent_date").nullable()
    
    // Soft delete
    val deletedAt = timestamp("deleted_at").nullable()
}

object UserSessions : UUIDTable("user_sessions") {
    val userId = reference("user_id", Users)
    val sessionToken = varchar("session_token", 255).uniqueIndex()
    val refreshToken = varchar("refresh_token", 255).nullable().uniqueIndex()
    val deviceFingerprint = varchar("device_fingerprint", 255).nullable()
    val userAgent = text("user_agent").nullable()
    val ipAddress = varchar("ip_address", 45).nullable()
    val locationData = jsonb<Map<String, String>>("location_data",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    ).nullable()
    
    val createdAt = timestamp("created_at").defaultExpression(CurrentTimestamp())
    val expiresAt = timestamp("expires_at")
    val lastActivity = timestamp("last_activity").defaultExpression(CurrentTimestamp())
    val isActive = bool("is_active").default(true)
}

object PasswordResetTokens : UUIDTable("password_reset_tokens") {
    val userId = reference("user_id", Users)
    val token = varchar("token", 255).uniqueIndex()
    val used = bool("used").default(false)
    val expiresAt = timestamp("expires_at")
    val createdAt = timestamp("created_at").defaultExpression(CurrentTimestamp())
}