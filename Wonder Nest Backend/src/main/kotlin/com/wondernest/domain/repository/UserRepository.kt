package com.wondernest.domain.repository

import com.wondernest.domain.model.User
import com.wondernest.domain.model.UserSession
import com.wondernest.domain.model.PasswordResetToken
import java.util.*

interface UserRepository {
    suspend fun createUser(user: User): User
    suspend fun getUserById(id: UUID): User?
    suspend fun getUserByEmail(email: String): User?
    suspend fun getUserByExternalId(externalId: String, provider: String): User?
    suspend fun updateUser(user: User): User
    suspend fun deleteUser(id: UUID): Boolean
    suspend fun getUserPasswordHash(userId: UUID): String?
    suspend fun updateUserPassword(userId: UUID, passwordHash: String): Boolean
    suspend fun verifyUserEmail(userId: UUID): Boolean
    suspend fun updateLastLogin(userId: UUID): Boolean
    
    // Session management
    suspend fun createSession(session: UserSession): UserSession
    suspend fun getSessionByToken(token: String): UserSession?
    suspend fun updateSessionActivity(sessionId: UUID): Boolean
    suspend fun invalidateSession(sessionId: UUID): Boolean
    suspend fun invalidateAllUserSessions(userId: UUID): Boolean
    
    // Password reset
    suspend fun createPasswordResetToken(token: PasswordResetToken): PasswordResetToken
    suspend fun getPasswordResetToken(token: String): PasswordResetToken?
    suspend fun markPasswordResetTokenUsed(tokenId: UUID): Boolean
    suspend fun deleteExpiredPasswordResetTokens(): Int
    
    // User search and listing
    suspend fun searchUsers(query: String, limit: Int = 50): List<User>
    suspend fun getUsersByIds(ids: List<UUID>): List<User>
}