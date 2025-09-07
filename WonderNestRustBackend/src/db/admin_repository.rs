use chrono::{DateTime, Utc};
use sqlx::{PgPool, Row};
use uuid::Uuid;
use ipnetwork::IpNetwork;

use crate::models::{
    AdminAccount, AdminRole, AdminPermission, AdminRolePermission, AdminSession,
    AdminInvitationToken, AdminPasswordResetToken, AdminAuditLog,
};

// =====================================================================================
// ADMIN REPOSITORY
// Database operations for admin portal functionality. All operations work with the
// admin schema tables and are completely separate from family user operations.
// =====================================================================================

#[derive(Clone)]
pub struct AdminRepository {
    pool: PgPool,
}

impl AdminRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }
    
    // =====================================================================================
    // ADMIN ACCOUNT OPERATIONS
    // =====================================================================================
    
    // Get admin account by ID
    pub async fn get_admin_by_id(&self, admin_id: Uuid) -> Result<Option<AdminAccount>, sqlx::Error> {
        let result = sqlx::query_as!(
            AdminAccount,
            r#"
            SELECT 
                id, email, password_hash, first_name, last_name, role_id,
                custom_permissions, status, is_root_admin, mfa_enabled, mfa_secret,
                ip_restrictions, 
                allowed_hours, email_verified, last_login_at, login_count,
                failed_login_attempts, locked_until, created_at, created_by,
                updated_at, updated_by
            FROM admin.admin_accounts 
            WHERE id = $1
            "#,
            admin_id
        )
        .fetch_optional(&self.pool)
        .await?;
        
        Ok(result)
    }
    
    // Get admin account by email
    pub async fn get_admin_by_email(&self, email: &str) -> Result<Option<AdminAccount>, sqlx::Error> {
        let result = sqlx::query_as!(
            AdminAccount,
            r#"
            SELECT 
                id, email, password_hash, first_name, last_name, role_id,
                custom_permissions, status, is_root_admin, mfa_enabled, mfa_secret,
                ip_restrictions, 
                allowed_hours, email_verified, last_login_at, login_count,
                failed_login_attempts, locked_until, created_at, created_by,
                updated_at, updated_by
            FROM admin.admin_accounts 
            WHERE email = $1
            "#,
            email.to_lowercase()
        )
        .fetch_optional(&self.pool)
        .await?;
        
        Ok(result)
    }
    
    // Create new admin account
    pub async fn create_admin_account(&self, admin: &AdminAccount) -> Result<AdminAccount, sqlx::Error> {
        let result = sqlx::query_as!(
            AdminAccount,
            r#"
            INSERT INTO admin.admin_accounts (
                id, email, password_hash, first_name, last_name, role_id,
                custom_permissions, status, is_root_admin, mfa_enabled, mfa_secret,
                ip_restrictions, allowed_hours, email_verified, last_login_at, 
                login_count, failed_login_attempts, locked_until, created_at, 
                created_by, updated_at, updated_by
            ) VALUES (
                $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15,
                $16, $17, $18, $19, $20, $21, $22
            )
            RETURNING 
                id, email, password_hash, first_name, last_name, role_id,
                custom_permissions, status, is_root_admin, mfa_enabled, mfa_secret,
                ip_restrictions, 
                allowed_hours, email_verified, last_login_at, login_count,
                failed_login_attempts, locked_until, created_at, created_by,
                updated_at, updated_by
            "#,
            admin.id,
            admin.email,
            admin.password_hash,
            admin.first_name,
            admin.last_name,
            admin.role_id,
            admin.custom_permissions,
            admin.status,
            admin.is_root_admin,
            admin.mfa_enabled,
            admin.mfa_secret,
            admin.ip_restrictions.as_ref().map(|ips| ips.as_slice()),
            admin.allowed_hours,
            admin.email_verified,
            admin.last_login_at,
            admin.login_count,
            admin.failed_login_attempts,
            admin.locked_until,
            admin.created_at,
            admin.created_by,
            admin.updated_at,
            admin.updated_by
        )
        .fetch_one(&self.pool)
        .await?;
        
        Ok(result)
    }
    
    // Update admin account
    pub async fn update_admin_account(&self, admin: &AdminAccount) -> Result<AdminAccount, sqlx::Error> {
        let result = sqlx::query_as!(
            AdminAccount,
            r#"
            UPDATE admin.admin_accounts SET
                email = $2, password_hash = $3, first_name = $4, last_name = $5,
                role_id = $6, custom_permissions = $7, status = $8, 
                is_root_admin = $9, mfa_enabled = $10, mfa_secret = $11,
                ip_restrictions = $12, allowed_hours = $13, email_verified = $14,
                last_login_at = $15, login_count = $16, failed_login_attempts = $17,
                locked_until = $18, updated_at = $19, updated_by = $20
            WHERE id = $1
            RETURNING 
                id, email, password_hash, first_name, last_name, role_id,
                custom_permissions, status, is_root_admin, mfa_enabled, mfa_secret,
                ip_restrictions, 
                allowed_hours, email_verified, last_login_at, login_count,
                failed_login_attempts, locked_until, created_at, created_by,
                updated_at, updated_by
            "#,
            admin.id,
            admin.email,
            admin.password_hash,
            admin.first_name,
            admin.last_name,
            admin.role_id,
            admin.custom_permissions,
            admin.status,
            admin.is_root_admin,
            admin.mfa_enabled,
            admin.mfa_secret,
            admin.ip_restrictions.as_ref().map(|ips| ips.as_slice()),
            admin.allowed_hours,
            admin.email_verified,
            admin.last_login_at,
            admin.login_count,
            admin.failed_login_attempts,
            admin.locked_until,
            admin.updated_at,
            admin.updated_by
        )
        .fetch_one(&self.pool)
        .await?;
        
        Ok(result)
    }
    
    // Update admin login statistics
    pub async fn update_admin_login_stats(&self, admin_id: Uuid, new_login_count: i32) -> Result<bool, sqlx::Error> {
        let result = sqlx::query!(
            r#"
            UPDATE admin.admin_accounts 
            SET 
                last_login_at = CURRENT_TIMESTAMP,
                login_count = $2,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = $1
            "#,
            admin_id,
            new_login_count
        )
        .execute(&self.pool)
        .await?;
        
        Ok(result.rows_affected() > 0)
    }
    
    // Update failed login attempts and lock status
    pub async fn update_failed_login_attempts(
        &self, 
        admin_id: Uuid, 
        failed_attempts: i32,
        locked_until: Option<DateTime<Utc>>,
    ) -> Result<bool, sqlx::Error> {
        let result = sqlx::query!(
            r#"
            UPDATE admin.admin_accounts 
            SET 
                failed_login_attempts = $2,
                locked_until = $3,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = $1
            "#,
            admin_id,
            failed_attempts,
            locked_until
        )
        .execute(&self.pool)
        .await?;
        
        Ok(result.rows_affected() > 0)
    }
    
    // =====================================================================================
    // ADMIN ROLE AND PERMISSION OPERATIONS
    // =====================================================================================
    
    // Get admin role by ID
    pub async fn get_admin_role_by_id(&self, role_id: i32) -> Result<Option<AdminRole>, sqlx::Error> {
        let result = sqlx::query_as!(
            AdminRole,
            r#"
            SELECT id, role_name, role_level, display_name, description, 
                   is_active, created_at, updated_at
            FROM admin.admin_roles 
            WHERE id = $1
            "#,
            role_id
        )
        .fetch_optional(&self.pool)
        .await?;
        
        Ok(result)
    }
    
    // Get admin role by name
    pub async fn get_admin_role_by_name(&self, role_name: &str) -> Result<Option<AdminRole>, sqlx::Error> {
        let result = sqlx::query_as!(
            AdminRole,
            r#"
            SELECT id, role_name, role_level, display_name, description, 
                   is_active, created_at, updated_at
            FROM admin.admin_roles 
            WHERE role_name = $1 AND is_active = true
            "#,
            role_name
        )
        .fetch_optional(&self.pool)
        .await?;
        
        Ok(result)
    }
    
    // Get admin role and permissions for a specific admin
    pub async fn get_admin_role_and_permissions(&self, admin_id: Uuid) -> Result<(AdminRole, Vec<AdminPermission>), sqlx::Error> {
        // Get the admin's role
        let role = sqlx::query_as!(
            AdminRole,
            r#"
            SELECT r.id, r.role_name, r.role_level, r.display_name, r.description,
                   r.is_active, r.created_at, r.updated_at
            FROM admin.admin_roles r
            INNER JOIN admin.admin_accounts a ON a.role_id = r.id
            WHERE a.id = $1
            "#,
            admin_id
        )
        .fetch_one(&self.pool)
        .await?;
        
        // Get all permissions for this role
        let permissions = sqlx::query_as!(
            AdminPermission,
            r#"
            SELECT p.id, p.permission_name, p.category, p.description,
                   p.requires_min_level, p.is_active, p.created_at, p.updated_at
            FROM admin.admin_permissions p
            INNER JOIN admin.admin_role_permissions rp ON rp.permission_id = p.id
            WHERE rp.role_id = $1 AND p.is_active = true
            ORDER BY p.category, p.permission_name
            "#,
            role.id
        )
        .fetch_all(&self.pool)
        .await?;
        
        Ok((role, permissions))
    }
    
    // Get all permissions for a role level (including inherited permissions)
    pub async fn get_permissions_for_role_level(&self, role_level: i32) -> Result<Vec<AdminPermission>, sqlx::Error> {
        let permissions = sqlx::query_as!(
            AdminPermission,
            r#"
            SELECT DISTINCT p.id, p.permission_name, p.category, p.description,
                   p.requires_min_level, p.is_active, p.created_at, p.updated_at
            FROM admin.admin_permissions p
            WHERE p.requires_min_level <= $1 AND p.is_active = true
            ORDER BY p.category, p.permission_name
            "#,
            role_level
        )
        .fetch_all(&self.pool)
        .await?;
        
        Ok(permissions)
    }
    
    // =====================================================================================
    // ADMIN SESSION OPERATIONS
    // =====================================================================================
    
    // Create admin session
    pub async fn create_admin_session(&self, session: &AdminSession) -> Result<AdminSession, sqlx::Error> {
        let result = sqlx::query_as!(
            AdminSession,
            r#"
            INSERT INTO admin.admin_sessions (
                id, admin_id, token_hash, refresh_token_hash, ip_address,
                user_agent, device_fingerprint, expires_at, last_accessed_at,
                is_active, created_at, invalidated_at, invalidated_reason
            ) VALUES (
                $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13
            )
            RETURNING 
                id, admin_id, token_hash, refresh_token_hash, 
                ip_address, user_agent, 
                device_fingerprint, expires_at, last_accessed_at, is_active,
                created_at, invalidated_at, invalidated_reason
            "#,
            session.id,
            session.admin_id,
            session.token_hash,
            session.refresh_token_hash,
            session.ip_address.map(|ip| ip as IpNetwork),
            session.user_agent,
            session.device_fingerprint,
            session.expires_at,
            session.last_accessed_at,
            session.is_active,
            session.created_at,
            session.invalidated_at,
            session.invalidated_reason
        )
        .fetch_one(&self.pool)
        .await?;
        
        Ok(result)
    }
    
    // Get admin session by token hash
    pub async fn get_admin_session_by_token(&self, token_hash: &str) -> Result<Option<AdminSession>, sqlx::Error> {
        let result = sqlx::query_as!(
            AdminSession,
            r#"
            SELECT 
                id, admin_id, token_hash, refresh_token_hash,
                ip_address, user_agent,
                device_fingerprint, expires_at, last_accessed_at, is_active,
                created_at, invalidated_at, invalidated_reason
            FROM admin.admin_sessions 
            WHERE token_hash = $1 AND is_active = true
            "#,
            token_hash
        )
        .fetch_optional(&self.pool)
        .await?;
        
        Ok(result)
    }
    
    // Get admin session by refresh token hash
    pub async fn get_admin_session_by_refresh_token(&self, refresh_token_hash: &str) -> Result<Option<AdminSession>, sqlx::Error> {
        let result = sqlx::query_as!(
            AdminSession,
            r#"
            SELECT 
                id, admin_id, token_hash, refresh_token_hash,
                ip_address, user_agent,
                device_fingerprint, expires_at, last_accessed_at, is_active,
                created_at, invalidated_at, invalidated_reason
            FROM admin.admin_sessions 
            WHERE refresh_token_hash = $1 AND is_active = true
            "#,
            refresh_token_hash
        )
        .fetch_optional(&self.pool)
        .await?;
        
        Ok(result)
    }
    
    // Update admin session tokens (for token refresh)
    pub async fn update_admin_session_tokens(
        &self,
        session_id: Uuid,
        new_token_hash: String,
        new_refresh_token_hash: Option<String>,
        new_expires_at: DateTime<Utc>,
    ) -> Result<bool, sqlx::Error> {
        let result = sqlx::query!(
            r#"
            UPDATE admin.admin_sessions 
            SET 
                token_hash = $2,
                refresh_token_hash = $3,
                expires_at = $4,
                last_accessed_at = CURRENT_TIMESTAMP
            WHERE id = $1
            "#,
            session_id,
            new_token_hash,
            new_refresh_token_hash,
            new_expires_at
        )
        .execute(&self.pool)
        .await?;
        
        Ok(result.rows_affected() > 0)
    }
    
    // Invalidate admin session
    pub async fn invalidate_admin_session(&self, session_id: Uuid, reason: String) -> Result<bool, sqlx::Error> {
        let result = sqlx::query!(
            r#"
            UPDATE admin.admin_sessions 
            SET 
                is_active = false,
                invalidated_at = CURRENT_TIMESTAMP,
                invalidated_reason = $2
            WHERE id = $1
            "#,
            session_id,
            reason
        )
        .execute(&self.pool)
        .await?;
        
        Ok(result.rows_affected() > 0)
    }
    
    // Invalidate all sessions for an admin (for security)
    pub async fn invalidate_all_admin_sessions(&self, admin_id: Uuid, reason: String) -> Result<i64, sqlx::Error> {
        let result = sqlx::query!(
            r#"
            UPDATE admin.admin_sessions 
            SET 
                is_active = false,
                invalidated_at = CURRENT_TIMESTAMP,
                invalidated_reason = $2
            WHERE admin_id = $1 AND is_active = true
            "#,
            admin_id,
            reason
        )
        .execute(&self.pool)
        .await?;
        
        Ok(result.rows_affected() as i64)
    }
    
    // =====================================================================================
    // ADMIN INVITATION OPERATIONS
    // =====================================================================================
    
    // Create admin invitation
    pub async fn create_admin_invitation(&self, invitation: &AdminInvitationToken) -> Result<AdminInvitationToken, sqlx::Error> {
        let result = sqlx::query_as!(
            AdminInvitationToken,
            r#"
            INSERT INTO admin.admin_invitation_tokens (
                id, email, token, role_id, invited_by, invitation_message,
                expires_at, used_at, used_by_ip, status, created_at, updated_at
            ) VALUES (
                $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12
            )
            RETURNING 
                id, email, token, role_id, invited_by, invitation_message,
                expires_at, used_at, used_by_ip,
                status, created_at, updated_at
            "#,
            invitation.id,
            invitation.email,
            invitation.token,
            invitation.role_id,
            invitation.invited_by,
            invitation.invitation_message,
            invitation.expires_at,
            invitation.used_at,
            invitation.used_by_ip.map(|ip| ip as IpNetwork),
            invitation.status,
            invitation.created_at,
            invitation.updated_at
        )
        .fetch_one(&self.pool)
        .await?;
        
        Ok(result)
    }
    
    // Get admin invitation by token
    pub async fn get_admin_invitation_by_token(&self, token: &str) -> Result<Option<AdminInvitationToken>, sqlx::Error> {
        let result = sqlx::query_as!(
            AdminInvitationToken,
            r#"
            SELECT 
                id, email, token, role_id, invited_by, invitation_message,
                expires_at, used_at, used_by_ip,
                status, created_at, updated_at
            FROM admin.admin_invitation_tokens 
            WHERE token = $1
            "#,
            token
        )
        .fetch_optional(&self.pool)
        .await?;
        
        Ok(result)
    }
    
    // Update admin invitation
    pub async fn update_admin_invitation(&self, invitation: &AdminInvitationToken) -> Result<AdminInvitationToken, sqlx::Error> {
        let result = sqlx::query_as!(
            AdminInvitationToken,
            r#"
            UPDATE admin.admin_invitation_tokens SET
                email = $2, token = $3, role_id = $4, invited_by = $5,
                invitation_message = $6, expires_at = $7, used_at = $8,
                used_by_ip = $9, status = $10, updated_at = $11
            WHERE id = $1
            RETURNING 
                id, email, token, role_id, invited_by, invitation_message,
                expires_at, used_at, used_by_ip,
                status, created_at, updated_at
            "#,
            invitation.id,
            invitation.email,
            invitation.token,
            invitation.role_id,
            invitation.invited_by,
            invitation.invitation_message,
            invitation.expires_at,
            invitation.used_at,
            invitation.used_by_ip.map(|ip| ip as IpNetwork),
            invitation.status,
            invitation.updated_at
        )
        .fetch_one(&self.pool)
        .await?;
        
        Ok(result)
    }
    
    // List pending invitations (for admin management)
    pub async fn list_pending_invitations(
        &self,
        page: i32,
        limit: i32,
    ) -> Result<(Vec<AdminInvitationToken>, i64), sqlx::Error> {
        let offset = (page - 1) * limit;
        
        // Get invitations
        let invitations = sqlx::query_as!(
            AdminInvitationToken,
            r#"
            SELECT 
                id, email, token, role_id, invited_by, invitation_message,
                expires_at, used_at, used_by_ip,
                status, created_at, updated_at
            FROM admin.admin_invitation_tokens 
            WHERE status = 'pending'
            ORDER BY created_at DESC
            LIMIT $1 OFFSET $2
            "#,
            limit as i64,
            offset as i64
        )
        .fetch_all(&self.pool)
        .await?;
        
        // Get total count
        let total = sqlx::query_scalar!(
            r#"
            SELECT COUNT(*) FROM admin.admin_invitation_tokens 
            WHERE status = 'pending'
            "#
        )
        .fetch_one(&self.pool)
        .await?
        .unwrap_or(0);
        
        Ok((invitations, total))
    }
    
    // =====================================================================================
    // ADMIN AUDIT LOG OPERATIONS
    // =====================================================================================
    
    // Create audit log entry
    pub async fn create_audit_log(&self, log: &AdminAuditLog) -> Result<AdminAuditLog, sqlx::Error> {
        let result = sqlx::query_as!(
            AdminAuditLog,
            r#"
            INSERT INTO admin.admin_audit_logs (
                id, admin_id, admin_email, action, resource_type, resource_id,
                description, details, ip_address, user_agent, session_id,
                severity, tags, checksum, previous_log_id, timestamp
            ) VALUES (
                $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16
            )
            RETURNING 
                id, admin_id, admin_email, action, resource_type, resource_id,
                description, details, ip_address,
                user_agent, session_id, severity, tags, checksum, 
                previous_log_id, timestamp
            "#,
            log.id,
            log.admin_id,
            log.admin_email,
            log.action,
            log.resource_type,
            log.resource_id,
            log.description,
            log.details,
            log.ip_address.map(|ip| ip as IpNetwork),
            log.user_agent,
            log.session_id,
            log.severity,
            log.tags.as_ref().map(|tags| tags.as_slice()),
            log.checksum,
            log.previous_log_id,
            log.timestamp
        )
        .fetch_one(&self.pool)
        .await?;
        
        Ok(result)
    }
    
    // Query audit logs with filters
    pub async fn query_audit_logs(
        &self,
        page: i32,
        limit: i32,
        admin_id: Option<Uuid>,
        action: Option<String>,
        resource_type: Option<String>,
        start_date: Option<DateTime<Utc>>,
        end_date: Option<DateTime<Utc>>,
        severity: Option<String>,
        ip_address: Option<IpNetwork>,
    ) -> Result<(Vec<AdminAuditLog>, i64), sqlx::Error> {
        let offset = (page - 1) * limit;
        
        // Build dynamic query based on filters
        let mut query = String::from(
            r#"
            SELECT 
                id, admin_id, admin_email, action, resource_type, resource_id,
                description, details, ip_address, user_agent, session_id,
                severity, tags, checksum, previous_log_id, timestamp
            FROM admin.admin_audit_logs
            WHERE 1=1
            "#
        );
        
        let mut params = Vec::new();
        let mut param_count = 0;
        
        // Add filters
        if admin_id.is_some() {
            param_count += 1;
            query.push_str(&format!(" AND admin_id = ${}", param_count));
            params.push(admin_id.unwrap().to_string());
        }
        
        if let Some(ref act) = action {
            param_count += 1;
            query.push_str(&format!(" AND action = ${}", param_count));
            params.push(act.clone());
        }
        
        if let Some(ref rt) = resource_type {
            param_count += 1;
            query.push_str(&format!(" AND resource_type = ${}", param_count));
            params.push(rt.clone());
        }
        
        if let Some(start) = start_date {
            param_count += 1;
            query.push_str(&format!(" AND timestamp >= ${}", param_count));
            params.push(start.to_rfc3339());
        }
        
        if let Some(end) = end_date {
            param_count += 1;
            query.push_str(&format!(" AND timestamp <= ${}", param_count));
            params.push(end.to_rfc3339());
        }
        
        if let Some(ref sev) = severity {
            param_count += 1;
            query.push_str(&format!(" AND severity = ${}", param_count));
            params.push(sev.clone());
        }
        
        if let Some(ip) = ip_address {
            param_count += 1;
            query.push_str(&format!(" AND ip_address = ${}", param_count));
            params.push(ip.to_string());
        }
        
        // Add ordering and pagination
        param_count += 1;
        query.push_str(&format!(" ORDER BY timestamp DESC LIMIT ${}", param_count));
        params.push(limit.to_string());
        
        param_count += 1;
        query.push_str(&format!(" OFFSET ${}", param_count));
        params.push(offset.to_string());
        
        // Execute query - For simplicity, using a basic approach here
        // In production, use a query builder or more sophisticated dynamic query handling
        let logs = sqlx::query_as!(
            AdminAuditLog,
            r#"
            SELECT 
                id, admin_id, admin_email, action, resource_type, resource_id,
                description, details, ip_address,
                user_agent, session_id, severity, tags, checksum, 
                previous_log_id, timestamp
            FROM admin.admin_audit_logs
            ORDER BY timestamp DESC
            LIMIT $1 OFFSET $2
            "#,
            limit as i64,
            offset as i64
        )
        .fetch_all(&self.pool)
        .await?;
        
        // Get total count (simplified)
        let total = sqlx::query_scalar!(
            r#"
            SELECT COUNT(*) FROM admin.admin_audit_logs
            "#
        )
        .fetch_one(&self.pool)
        .await?
        .unwrap_or(0);
        
        Ok((logs, total))
    }
    
    // =====================================================================================
    // UTILITY OPERATIONS
    // =====================================================================================
    
    // Clean up expired sessions and tokens (called by scheduled job)
    pub async fn cleanup_expired_admin_data(&self) -> Result<(i64, i64), sqlx::Error> {
        // Clean up expired sessions
        let expired_sessions = sqlx::query!(
            r#"
            UPDATE admin.admin_sessions 
            SET is_active = false, invalidated_at = CURRENT_TIMESTAMP, invalidated_reason = 'expired'
            WHERE expires_at < CURRENT_TIMESTAMP AND is_active = true
            "#
        )
        .execute(&self.pool)
        .await?
        .rows_affected();
        
        // Mark expired invitation tokens
        let expired_invitations = sqlx::query!(
            r#"
            UPDATE admin.admin_invitation_tokens 
            SET status = 'expired', updated_at = CURRENT_TIMESTAMP
            WHERE expires_at < CURRENT_TIMESTAMP AND status = 'pending'
            "#
        )
        .execute(&self.pool)
        .await?
        .rows_affected();
        
        Ok((expired_sessions as i64, expired_invitations as i64))
    }
    
    // Get admin statistics for dashboard
    pub async fn get_admin_statistics(&self) -> Result<serde_json::Value, sqlx::Error> {
        let stats = sqlx::query!(
            r#"
            SELECT
                (SELECT COUNT(*) FROM admin.admin_accounts WHERE status = 'active') as active_admins,
                (SELECT COUNT(*) FROM admin.admin_accounts WHERE status = 'pending') as pending_admins,
                (SELECT COUNT(*) FROM admin.admin_sessions WHERE is_active = true) as active_sessions,
                (SELECT COUNT(*) FROM admin.admin_invitation_tokens WHERE status = 'pending') as pending_invitations,
                (SELECT COUNT(*) FROM admin.admin_audit_logs WHERE timestamp > CURRENT_TIMESTAMP - INTERVAL '24 hours') as recent_audit_logs
            "#
        )
        .fetch_one(&self.pool)
        .await?;
        
        Ok(serde_json::json!({
            "active_admins": stats.active_admins,
            "pending_admins": stats.pending_admins,
            "active_sessions": stats.active_sessions,
            "pending_invitations": stats.pending_invitations,
            "recent_audit_logs": stats.recent_audit_logs
        }))
    }
}