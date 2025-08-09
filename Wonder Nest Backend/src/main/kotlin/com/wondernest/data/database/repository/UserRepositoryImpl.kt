package com.wondernest.data.database.repository

import com.wondernest.data.database.DatabaseFactory
import com.wondernest.data.database.table.*
import com.wondernest.domain.model.User
import com.wondernest.domain.model.UserSession
import com.wondernest.domain.model.PasswordResetToken
import com.wondernest.domain.repository.UserRepository
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import java.util.*
import kotlinx.datetime.Clock

class UserRepositoryImpl : UserRepository {
    private val db = DatabaseFactory()

    override suspend fun createUser(user: User): User = db.dbQuery {
        val userId = Users.insertAndGetId {
            it[id] = user.id
            it[email] = user.email
            it[emailVerified] = user.emailVerified
            it[emailVerifiedAt] = user.emailVerifiedAt
            it[authProvider] = user.authProvider
            it[externalId] = user.externalId
            it[firstName] = user.firstName
            it[lastName] = user.lastName
            it[phone] = user.phone
            it[timezone] = user.timezone
            it[language] = user.language
            it[status] = user.status
            it[role] = user.role
            it[privacySettings] = user.privacySettings
            it[notificationPreferences] = user.notificationPreferences
            it[mfaEnabled] = user.mfaEnabled
            it[mfaSecret] = user.mfaSecret
            it[backupCodes] = user.backupCodes?.toTypedArray()
            it[createdAt] = user.createdAt
            it[updatedAt] = user.updatedAt
            it[lastLoginAt] = user.lastLoginAt
            it[loginCount] = user.loginCount
            it[parentalConsentVerified] = user.parentalConsentVerified
            it[parentalConsentMethod] = user.parentalConsentMethod
            it[parentalConsentDate] = user.parentalConsentDate
            it[deletedAt] = user.deletedAt
        }
        
        getUserById(userId.value)!!
    }

    override suspend fun getUserById(id: UUID): User? = db.dbQuery {
        Users.select { Users.id eq id and Users.deletedAt.isNull() }
            .map { rowToUser(it) }
            .singleOrNull()
    }

    override suspend fun getUserByEmail(email: String): User? = db.dbQuery {
        Users.select { Users.email eq email and Users.deletedAt.isNull() }
            .map { rowToUser(it) }
            .singleOrNull()
    }

    override suspend fun getUserByExternalId(externalId: String, provider: String): User? = db.dbQuery {
        val authProvider = AuthProvider.valueOf(provider.uppercase())
        Users.select { 
            (Users.externalId eq externalId) and 
            (Users.authProvider eq authProvider) and 
            Users.deletedAt.isNull() 
        }
        .map { rowToUser(it) }
        .singleOrNull()
    }

    override suspend fun updateUser(user: User): User = db.dbQuery {
        Users.update({ Users.id eq user.id }) {
            it[email] = user.email
            it[emailVerified] = user.emailVerified
            it[emailVerifiedAt] = user.emailVerifiedAt
            it[firstName] = user.firstName
            it[lastName] = user.lastName
            it[phone] = user.phone
            it[timezone] = user.timezone
            it[language] = user.language
            it[status] = user.status
            it[privacySettings] = user.privacySettings
            it[notificationPreferences] = user.notificationPreferences
            it[mfaEnabled] = user.mfaEnabled
            it[mfaSecret] = user.mfaSecret
            it[backupCodes] = user.backupCodes?.toTypedArray()
            it[updatedAt] = Clock.System.now()
            it[parentalConsentVerified] = user.parentalConsentVerified
            it[parentalConsentMethod] = user.parentalConsentMethod
            it[parentalConsentDate] = user.parentalConsentDate
        }
        getUserById(user.id)!!
    }

    override suspend fun deleteUser(id: UUID): Boolean = db.dbQuery {
        Users.update({ Users.id eq id }) {
            it[deletedAt] = Clock.System.now()
        } > 0
    }

    override suspend fun getUserPasswordHash(userId: UUID): String? = db.dbQuery {
        Users.select { Users.id eq userId and Users.deletedAt.isNull() }
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
            it[emailVerifiedAt] = Clock.System.now()
            it[status] = UserStatus.ACTIVE
            it[updatedAt] = Clock.System.now()
        } > 0
    }

    override suspend fun updateLastLogin(userId: UUID): Boolean = db.dbQuery {
        Users.update({ Users.id eq userId }) {
            it[lastLoginAt] = Clock.System.now()
            it[loginCount] = Users.loginCount + 1
            it[updatedAt] = Clock.System.now()
        } > 0
    }

    // Session management
    override suspend fun createSession(session: UserSession): UserSession = db.dbQuery {
        UserSessions.insert {
            it[id] = session.id
            it[userId] = session.userId
            it[sessionToken] = session.sessionToken
            it[refreshToken] = session.refreshToken
            it[deviceFingerprint] = session.deviceFingerprint
            it[userAgent] = session.userAgent
            it[ipAddress] = session.ipAddress
            it[locationData] = session.locationData
            it[createdAt] = session.createdAt
            it[expiresAt] = session.expiresAt
            it[lastActivity] = session.lastActivity
            it[isActive] = session.isActive
        }
        session
    }

    override suspend fun getSessionByToken(token: String): UserSession? = db.dbQuery {
        UserSessions.select { 
            UserSessions.sessionToken eq token and 
            UserSessions.isActive eq true and
            UserSessions.expiresAt greater Clock.System.now()
        }
        .map { rowToUserSession(it) }
        .singleOrNull()
    }

    override suspend fun updateSessionActivity(sessionId: UUID): Boolean = db.dbQuery {
        UserSessions.update({ UserSessions.id eq sessionId }) {
            it[lastActivity] = Clock.System.now()
        } > 0
    }

    override suspend fun invalidateSession(sessionId: UUID): Boolean = db.dbQuery {
        UserSessions.update({ UserSessions.id eq sessionId }) {
            it[isActive] = false
        } > 0
    }

    override suspend fun invalidateAllUserSessions(userId: UUID): Boolean = db.dbQuery {
        UserSessions.update({ UserSessions.userId eq userId }) {
            it[isActive] = false
        } > 0
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
            PasswordResetTokens.token eq token and 
            PasswordResetTokens.used eq false and
            PasswordResetTokens.expiresAt greater Clock.System.now()
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
            expiresAt less Clock.System.now()
        }
    }

    override suspend fun searchUsers(query: String, limit: Int): List<User> = db.dbQuery {
        Users.select { 
            (Users.email like "%$query%") or 
            (Users.firstName like "%$query%") or 
            (Users.lastName like "%$query%") and
            Users.deletedAt.isNull()
        }
        .limit(limit)
        .map { rowToUser(it) }
    }

    override suspend fun getUsersByIds(ids: List<UUID>): List<User> = db.dbQuery {
        Users.select { Users.id inList ids and Users.deletedAt.isNull() }
            .map { rowToUser(it) }
    }

    private fun rowToUser(row: ResultRow) = User(
        id = row[Users.id].value,
        email = row[Users.email],
        emailVerified = row[Users.emailVerified],
        emailVerifiedAt = row[Users.emailVerifiedAt],
        authProvider = row[Users.authProvider],
        externalId = row[Users.externalId],
        firstName = row[Users.firstName],
        lastName = row[Users.lastName],
        phone = row[Users.phone],
        timezone = row[Users.timezone],
        language = row[Users.language],
        status = row[Users.status],
        role = row[Users.role],
        privacySettings = row[Users.privacySettings],
        notificationPreferences = row[Users.notificationPreferences],
        mfaEnabled = row[Users.mfaEnabled],
        mfaSecret = row[Users.mfaSecret],
        backupCodes = row[Users.backupCodes]?.toList(),
        createdAt = row[Users.createdAt],
        updatedAt = row[Users.updatedAt],
        lastLoginAt = row[Users.lastLoginAt],
        loginCount = row[Users.loginCount],
        parentalConsentVerified = row[Users.parentalConsentVerified],
        parentalConsentMethod = row[Users.parentalConsentMethod],
        parentalConsentDate = row[Users.parentalConsentDate],
        deletedAt = row[Users.deletedAt]
    )

    private fun rowToUserSession(row: ResultRow) = UserSession(
        id = row[UserSessions.id].value,
        userId = row[UserSessions.userId].value,
        sessionToken = row[UserSessions.sessionToken],
        refreshToken = row[UserSessions.refreshToken],
        deviceFingerprint = row[UserSessions.deviceFingerprint],
        userAgent = row[UserSessions.userAgent],
        ipAddress = row[UserSessions.ipAddress],
        locationData = row[UserSessions.locationData],
        createdAt = row[UserSessions.createdAt],
        expiresAt = row[UserSessions.expiresAt],
        lastActivity = row[UserSessions.lastActivity],
        isActive = row[UserSessions.isActive]
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