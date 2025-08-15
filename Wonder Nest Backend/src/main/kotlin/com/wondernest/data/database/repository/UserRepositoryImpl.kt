package com.wondernest.data.database.repository

import com.wondernest.data.database.DatabaseFactory
import com.wondernest.data.database.table.*
import com.wondernest.domain.model.User
import com.wondernest.domain.model.UserSession
import com.wondernest.domain.model.PasswordResetToken
import com.wondernest.domain.repository.UserRepository
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.SqlExpressionBuilder.greater
import org.jetbrains.exposed.sql.SqlExpressionBuilder.less
import org.jetbrains.exposed.sql.SqlExpressionBuilder.plus
import java.util.*
import kotlinx.datetime.Clock
import java.security.MessageDigest
import kotlinx.serialization.json.Json
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString

class UserRepositoryImpl : UserRepository {
    private val db = DatabaseFactory()

    private fun hashToken(token: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val hashBytes = digest.digest(token.toByteArray())
        return hashBytes.joinToString("") { "%02x".format(it) }
    }

    override suspend fun createUser(user: User): User = db.dbQuery {
        println("DEBUG: Attempting to insert user with ID: ${user.id}, email: ${user.email}")
        
        val insertResult = Users.insert {
            it[id] = user.id
            it[email] = user.email
            it[emailVerified] = user.emailVerified
            it[passwordHash] = ""  // Will be updated separately by updateUserPassword
            it[firstName] = user.firstName
            it[lastName] = user.lastName
            it[phone] = user.phone
            it[isActive] = true
            it[createdAt] = user.createdAt
            it[updatedAt] = user.updatedAt
        }
        
        println("DEBUG: Insert operation completed. Inserted row count: ${insertResult.insertedCount}")
        
        // Retrieve the user within the same transaction
        val createdUser = Users.select { Users.id eq user.id }
            .map { rowToUser(it) }
            .singleOrNull()
        
        println("DEBUG: Retrieved user after insert: $createdUser")
        
        if (createdUser == null) {
            throw RuntimeException("Failed to retrieve created user with ID: ${user.id}")
        }
        createdUser
    }

    override suspend fun getUserById(id: UUID): User? = db.dbQuery {
        Users.select { Users.id eq id and Users.isActive }
            .map { rowToUser(it) }
            .singleOrNull()
    }

    override suspend fun getUserByEmail(email: String): User? = db.dbQuery {
        Users.select { Users.email eq email and Users.isActive }
            .map { rowToUser(it) }
            .singleOrNull()
    }

    override suspend fun getUserByExternalId(externalId: String, provider: String): User? = db.dbQuery {
        // For now, return null since we don't have externalId or authProvider columns
        null
    }

    override suspend fun updateUser(user: User): User = db.dbQuery {
        Users.update({ Users.id eq user.id }) {
            it[email] = user.email
            it[emailVerified] = user.emailVerified
            it[firstName] = user.firstName
            it[lastName] = user.lastName
            it[phone] = user.phone
            it[updatedAt] = Clock.System.now()
        }
        getUserById(user.id)!!
    }

    override suspend fun deleteUser(id: UUID): Boolean = db.dbQuery {
        Users.update({ Users.id eq id }) {
            it[isActive] = false
        } > 0
    }

    override suspend fun getUserPasswordHash(userId: UUID): String? = db.dbQuery {
        Users.select { Users.id eq userId and Users.isActive }
            .map { it[Users.passwordHash] }
            .singleOrNull()
    }

    override suspend fun updateUserPassword(userId: UUID, passwordHash: String): Boolean = db.dbQuery {
        Users.update({ Users.id eq userId }) {
            it[Users.passwordHash] = passwordHash
            it[updatedAt] = Clock.System.now()
        } > 0
    }

    override suspend fun verifyUserEmail(userId: UUID): Boolean = db.dbQuery {
        Users.update({ Users.id eq userId }) {
            it[emailVerified] = true
            it[updatedAt] = Clock.System.now()
        } > 0
    }

    override suspend fun updateLastLogin(userId: UUID): Boolean = db.dbQuery {
        Users.update({ Users.id eq userId }) {
            it[updatedAt] = Clock.System.now()
        } > 0
    }

    // Session management
    override suspend fun createSession(session: UserSession): UserSession = db.dbQuery {
        UserSessions.insert {
            it[id] = session.id
            it[userId] = session.userId
            it[tokenHash] = hashToken(session.sessionToken)
            it[expiresAt] = session.expiresAt
            it[createdAt] = session.createdAt
            it[lastAccessed] = session.lastActivity
            it[deviceInfo] = session.locationData
        }
        session
    }

    override suspend fun getSessionByToken(token: String): UserSession? = db.dbQuery {
        UserSessions.select { 
            (UserSessions.tokenHash eq hashToken(token)) and 
            (UserSessions.expiresAt greater Clock.System.now())
        }
        .map { rowToUserSession(it) }
        .singleOrNull()
    }

    override suspend fun updateSessionActivity(sessionId: UUID): Boolean = db.dbQuery {
        UserSessions.update({ UserSessions.id eq sessionId }) {
            it[lastAccessed] = Clock.System.now()
        } > 0
    }

    override suspend fun invalidateSession(sessionId: UUID): Boolean = db.dbQuery {
        UserSessions.deleteWhere { UserSessions.id eq sessionId } > 0
    }

    override suspend fun invalidateAllUserSessions(userId: UUID): Boolean = db.dbQuery {
        UserSessions.deleteWhere { UserSessions.userId eq userId } > 0
    }

    // Password reset
    override suspend fun createPasswordResetToken(token: PasswordResetToken): PasswordResetToken = db.dbQuery {
        PasswordResetTokens.insert {
            it[id] = token.id
            it[userId] = token.userId
            it[PasswordResetTokens.token] = token.token
            it[used] = token.used
            it[expiresAt] = token.expiresAt
            it[createdAt] = token.createdAt
        }
        token
    }

    override suspend fun getPasswordResetToken(token: String): PasswordResetToken? = db.dbQuery {
        PasswordResetTokens.select { 
            (PasswordResetTokens.token eq token) and 
            (PasswordResetTokens.used eq false) and
            (PasswordResetTokens.expiresAt greater Clock.System.now())
        }
        .map { rowToPasswordResetToken(it) }
        .singleOrNull()
    }

    override suspend fun markPasswordResetTokenUsed(tokenId: UUID): Boolean = db.dbQuery {
        PasswordResetTokens.update({ PasswordResetTokens.id eq tokenId }) {
            it[used] = true
        } > 0
    }

    override suspend fun deleteExpiredPasswordResetTokens(): Int = db.dbQuery {
        PasswordResetTokens.deleteWhere { 
            PasswordResetTokens.expiresAt less Clock.System.now()
        }
    }

    override suspend fun searchUsers(query: String, limit: Int): List<User> = db.dbQuery {
        Users.select { 
            (Users.email like "%$query%") or 
            (Users.firstName like "%$query%") or 
            (Users.lastName like "%$query%") and
            Users.isActive
        }
        .limit(limit)
        .map { rowToUser(it) }
    }

    override suspend fun getUsersByIds(ids: List<UUID>): List<User> = db.dbQuery {
        Users.select { Users.id inList ids and Users.isActive }
            .map { rowToUser(it) }
    }

    private fun rowToUser(row: ResultRow) = User(
        id = row[Users.id].value,
        email = row[Users.email],
        emailVerified = row[Users.emailVerified],
        emailVerifiedAt = null,  // Column doesn't exist in current schema
        authProvider = AuthProvider.EMAIL,  // Default value
        externalId = null,  // Column doesn't exist in current schema
        firstName = row[Users.firstName],
        lastName = row[Users.lastName],
        phone = row[Users.phone],
        timezone = "UTC",  // Default value
        language = "en",  // Default value
        status = if (row[Users.isActive]) UserStatus.ACTIVE else UserStatus.SUSPENDED,
        role = UserRole.PARENT,  // Default value
        privacySettings = PrivacySettings(),  // Default value
        notificationPreferences = NotificationPreferences(),  // Default value
        mfaEnabled = false,  // Default value
        mfaSecret = null,  // Default value
        backupCodes = null,  // Default value
        createdAt = row[Users.createdAt],
        updatedAt = row[Users.updatedAt],
        lastLoginAt = null,  // Default value
        loginCount = 0,  // Default value
        parentalConsentVerified = false,  // Default value
        parentalConsentMethod = null,  // Default value
        parentalConsentDate = null,  // Default value
        deletedAt = null  // Using isActive instead of deletedAt
    )

    private fun rowToUserSession(row: ResultRow) = UserSession(
        id = row[UserSessions.id].value,
        userId = row[UserSessions.userId].value,
        sessionToken = row[UserSessions.tokenHash],  // Column is tokenHash not sessionToken
        refreshToken = null,  // Column doesn't exist in current schema
        deviceFingerprint = null,  // Column doesn't exist in current schema
        userAgent = null,  // Column doesn't exist in current schema
        ipAddress = null,  // Column doesn't exist in current schema
        locationData = row[UserSessions.deviceInfo],  // Column is deviceInfo
        createdAt = row[UserSessions.createdAt],
        expiresAt = row[UserSessions.expiresAt],
        lastActivity = row[UserSessions.lastAccessed],  // Column is lastAccessed not lastActivity
        isActive = true  // Assume active if record exists
    )

    private fun rowToPasswordResetToken(row: ResultRow) = PasswordResetToken(
        id = row[PasswordResetTokens.id].value,
        userId = row[PasswordResetTokens.userId].value,
        token = row[PasswordResetTokens.token],
        used = row[PasswordResetTokens.used],
        expiresAt = row[PasswordResetTokens.expiresAt],
        createdAt = row[PasswordResetTokens.createdAt]
    )
}