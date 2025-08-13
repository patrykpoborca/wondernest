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

object Users : UUIDTable("core.users") {
    val email = varchar("email", 255).uniqueIndex()
    val emailVerified = bool("email_verified").default(false)
    val passwordHash = varchar("password_hash", 255)
    val firstName = varchar("first_name", 100).nullable()
    val lastName = varchar("last_name", 100).nullable()
    val phone = varchar("phone", 20).nullable()
    val isActive = bool("is_active").default(true)
    val createdAt = timestamp("created_at").defaultExpression(CurrentTimestamp())
    val updatedAt = timestamp("updated_at").defaultExpression(CurrentTimestamp())
}

object UserSessions : UUIDTable("core.user_sessions") {
    val userId = reference("user_id", Users)
    val tokenHash = varchar("token_hash", 512).uniqueIndex()  // Increased to 512 to handle JWT tokens
    val expiresAt = timestamp("expires_at")
    val createdAt = timestamp("created_at").defaultExpression(CurrentTimestamp())
    val lastAccessed = timestamp("last_accessed").defaultExpression(CurrentTimestamp())
    val deviceInfo = jsonb<Map<String, String>>("device_info",
        serialize = { Json.encodeToString(it) },
        deserialize = { Json.decodeFromString(it) }
    ).nullable()
}

object PasswordResetTokens : UUIDTable("password_reset_tokens") {
    val userId = reference("user_id", Users)
    val token = varchar("token", 255).uniqueIndex()
    val used = bool("used").default(false)
    val expiresAt = timestamp("expires_at")
    val createdAt = timestamp("created_at").defaultExpression(CurrentTimestamp())
}