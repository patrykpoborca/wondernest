package com.wondernest.data.database.repository.web

import com.wondernest.domain.web.AdminUser
import com.wondernest.domain.web.AdminSession
import com.wondernest.domain.web.AdminRole
import java.time.Instant
import java.util.*

/**
 * Repository interface for admin user operations
 */
interface AdminUserRepository {
    suspend fun findById(id: UUID): AdminUser?
    suspend fun findByEmail(email: String): AdminUser?
    suspend fun create(adminUser: AdminUser): AdminUser
    suspend fun update(adminUser: AdminUser): AdminUser
    suspend fun updateLastLogin(id: UUID, lastLoginAt: Instant): Boolean
    suspend fun updateFailedLoginAttempts(id: UUID, attempts: Int): Boolean
    suspend fun lockUser(id: UUID, lockedUntil: Instant): Boolean
    suspend fun findByRole(role: AdminRole): List<AdminUser>
    suspend fun findActiveAdmins(): List<AdminUser>
}

/**
 * Repository interface for admin session operations
 */
interface AdminSessionRepository {
    suspend fun create(session: AdminSession): AdminSession
    suspend fun findById(id: UUID): AdminSession?
    suspend fun findByToken(token: String): AdminSession?
    suspend fun findByAdminUserId(adminUserId: UUID): List<AdminSession>
    suspend fun updateLastActivity(id: UUID, lastActivity: Instant): Boolean
    suspend fun deactivateSession(id: UUID): Boolean
    suspend fun deactivateAllUserSessions(adminUserId: UUID): Int
    suspend fun deleteExpiredSessions(): Int
    suspend fun findActiveSessionsForUser(adminUserId: UUID): List<AdminSession>
}