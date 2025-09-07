use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;
use ipnetwork::IpNetwork;

// =====================================================================================
// ADMIN MODELS - Matching admin.* tables exactly
// These models represent the admin portal authentication system, completely separate
// from the family user authentication system
// =====================================================================================

// Admin role enumeration (matches admin.admin_roles table)
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct AdminRole {
    pub id: i32,
    pub role_name: String,
    pub role_level: i32, // 1 (Support) to 5 (Root)
    pub display_name: String,
    pub description: Option<String>,
    pub is_active: bool,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
}

// Admin permission enumeration (matches admin.admin_permissions table)
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct AdminPermission {
    pub id: i32,
    pub permission_name: String,
    pub category: String, // auth, user_management, content, analytics, system
    pub description: Option<String>,
    pub requires_min_level: i32,
    pub is_active: bool,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
}

// Admin role-permission mapping (matches admin.admin_role_permissions table)
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct AdminRolePermission {
    pub id: i32,
    pub role_id: i32,
    pub permission_id: i32,
    pub granted_at: DateTime<Utc>,
    pub granted_by: Option<Uuid>,
}

// Main admin account model (matches admin.admin_accounts table exactly)
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct AdminAccount {
    pub id: Uuid,
    pub email: String,
    pub password_hash: Option<String>, // NULL for invitation-pending accounts
    pub first_name: Option<String>,
    pub last_name: Option<String>,
    
    // Role and permissions
    pub role_id: i32,
    pub custom_permissions: serde_json::Value, // JSONB array of additional permissions
    
    // Account status and security
    pub status: String, // pending, active, disabled, locked
    pub is_root_admin: bool,
    pub mfa_enabled: bool,
    pub mfa_secret: Option<String>,
    
    // Access restrictions
    pub ip_restrictions: Option<Vec<IpNetwork>>, // INET[] in PostgreSQL
    pub allowed_hours: Option<serde_json::Value>, // JSONB time restrictions
    
    // Account metadata
    pub email_verified: bool,
    pub last_login_at: Option<DateTime<Utc>>,
    pub login_count: i32,
    pub failed_login_attempts: i32,
    pub locked_until: Option<DateTime<Utc>>,
    
    // Audit trail
    pub created_at: Option<DateTime<Utc>>,
    pub created_by: Option<Uuid>,
    pub updated_at: Option<DateTime<Utc>>,
    pub updated_by: Option<Uuid>,
}

// Admin session model (matches admin.admin_sessions table exactly)
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct AdminSession {
    pub id: Uuid,
    pub admin_id: Uuid,
    
    // Session data
    pub token_hash: String,
    pub refresh_token_hash: Option<String>,
    
    // Session metadata
    pub ip_address: Option<IpNetwork>,
    pub user_agent: Option<String>,
    pub device_fingerprint: Option<String>,
    
    // Session lifecycle
    pub expires_at: DateTime<Utc>,
    pub last_accessed_at: Option<DateTime<Utc>>,
    pub is_active: bool,
    
    // Audit
    pub created_at: Option<DateTime<Utc>>,
    pub invalidated_at: Option<DateTime<Utc>>,
    pub invalidated_reason: Option<String>,
}

// Admin invitation token model (matches admin.admin_invitation_tokens table exactly)
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct AdminInvitationToken {
    pub id: Uuid,
    pub email: String,
    pub token: String,
    
    // Invitation details
    pub role_id: i32,
    pub invited_by: Uuid,
    pub invitation_message: Option<String>,
    
    // Token lifecycle
    pub expires_at: DateTime<Utc>,
    pub used_at: Option<DateTime<Utc>>,
    pub used_by_ip: Option<IpNetwork>,
    
    // Status tracking
    pub status: String, // pending, accepted, expired, revoked
    
    // Audit
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
}

// Admin password reset token model (matches admin.admin_password_reset_tokens table exactly)
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct AdminPasswordResetToken {
    pub id: Uuid,
    pub admin_id: Uuid,
    pub token: String,
    
    // Token lifecycle
    pub expires_at: DateTime<Utc>,
    pub used_at: Option<DateTime<Utc>>,
    pub used_by_ip: Option<IpNetwork>,
    
    // Status
    pub is_used: bool,
    
    // Audit
    pub created_at: Option<DateTime<Utc>>,
    pub requested_by_ip: Option<IpNetwork>,
}

// Admin audit log model (matches admin.admin_audit_logs table exactly)
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct AdminAuditLog {
    pub id: Uuid,
    
    // Who performed the action
    pub admin_id: Option<Uuid>,
    pub admin_email: Option<String>,
    
    // What action was performed
    pub action: String,
    pub resource_type: Option<String>,
    pub resource_id: Option<String>,
    
    // Action details
    pub description: String,
    pub details: Option<serde_json::Value>,
    
    // Context
    pub ip_address: Option<IpNetwork>,
    pub user_agent: Option<String>,
    pub session_id: Option<Uuid>,
    
    // Security and compliance
    pub severity: String, // debug, info, warning, error, critical
    pub tags: Option<Vec<String>>, // Array of tags
    
    // Tamper detection
    pub checksum: Option<String>,
    pub previous_log_id: Option<Uuid>,
    
    // Timestamp (immutable)
    pub timestamp: DateTime<Utc>,
}

// =====================================================================================
// ADMIN REQUEST/RESPONSE MODELS
// These are used for API endpoints and don't directly map to database tables
// =====================================================================================

// Admin authentication models
#[derive(Debug, Serialize, Deserialize)]
pub struct AdminLoginRequest {
    pub email: String,
    pub password: String,
    pub mfa_token: Option<String>, // TOTP token if MFA is enabled
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AdminLoginResponse {
    pub access_token: String,
    pub refresh_token: String,
    pub expires_in: i64, // milliseconds
    pub admin: AdminInfo,
}

// Admin profile information (returned in auth responses)
#[derive(Debug, Serialize, Deserialize)]
pub struct AdminInfo {
    pub id: String,
    pub email: String,
    pub first_name: Option<String>,
    pub last_name: Option<String>,
    pub role: String,
    pub role_level: i32,
    pub permissions: Vec<String>,
    pub last_login: Option<DateTime<Utc>>,
    pub mfa_enabled: bool,
    pub account_status: String,
}

// Admin account creation/update models
#[derive(Debug, Serialize, Deserialize)]
pub struct CreateAdminRequest {
    pub email: String,
    pub first_name: Option<String>,
    pub last_name: Option<String>,
    pub role: String, // role_name from admin_roles
    pub send_invitation: Option<bool>, // Default true
    pub custom_permissions: Option<Vec<String>>,
    pub ip_restrictions: Option<Vec<IpNetwork>>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UpdateAdminRequest {
    pub first_name: Option<String>,
    pub last_name: Option<String>,
    pub role: Option<String>,
    pub status: Option<String>,
    pub custom_permissions: Option<Vec<String>>,
    pub ip_restrictions: Option<Vec<IpNetwork>>,
}

// Admin invitation models
#[derive(Debug, Serialize, Deserialize)]
pub struct AdminInvitationRequest {
    pub email: String,
    pub role: String, // role_name
    pub first_name: Option<String>,
    pub last_name: Option<String>,
    pub expires_in_days: Option<i32>, // Default 7 days
    pub message: Option<String>, // Personal invitation message
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AcceptInvitationRequest {
    pub password: String,
    pub confirm_password: String,
    pub first_name: Option<String>, // If not provided in invitation
    pub last_name: Option<String>,  // If not provided in invitation
}

// Admin change password model
#[derive(Debug, Serialize, Deserialize)]
pub struct AdminChangePasswordRequest {
    pub current_password: String,
    pub new_password: String,
    pub confirm_password: String,
}

// Admin password reset models
#[derive(Debug, Serialize, Deserialize)]
pub struct AdminPasswordResetRequest {
    pub email: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AdminPasswordResetConfirmRequest {
    pub token: String,
    pub new_password: String,
    pub confirm_password: String,
}

// Admin audit log query models
#[derive(Debug, Serialize, Deserialize)]
pub struct AdminAuditLogQuery {
    pub page: Option<i32>,
    pub limit: Option<i32>,
    pub admin_id: Option<Uuid>,
    pub action: Option<String>,
    pub resource_type: Option<String>,
    pub start_date: Option<DateTime<Utc>>,
    pub end_date: Option<DateTime<Utc>>,
    pub severity: Option<String>,
    pub ip_address: Option<IpNetwork>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AdminAuditLogResponse {
    pub logs: Vec<AdminAuditLog>,
    pub pagination: PaginationInfo,
}

// Dashboard metrics model
#[derive(Debug, Serialize, Deserialize)]
pub struct AdminDashboardMetrics {
    pub summary: DashboardSummary,
    pub recent_activity: Vec<RecentActivity>,
    pub system_health: SystemHealth,
    pub alerts: Vec<SystemAlert>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct DashboardSummary {
    pub total_users: i64,
    pub total_families: i64,
    pub total_children: i64,
    pub active_sessions: i64,
    pub content_items: i64,
    pub pending_moderation: i64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct RecentActivity {
    pub activity_type: String,
    pub timestamp: DateTime<Utc>,
    pub description: String,
    pub details: Option<serde_json::Value>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct SystemHealth {
    pub api_response_time_ms: i32,
    pub database_connections: i32,
    pub cache_hit_rate: f32,
    pub error_rate: f32,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct SystemAlert {
    pub level: String, // info, warning, error, critical
    pub message: String,
    pub timestamp: DateTime<Utc>,
    pub details: Option<serde_json::Value>,
}

// Pagination helper
#[derive(Debug, Serialize, Deserialize)]
pub struct PaginationInfo {
    pub page: i32,
    pub limit: i32,
    pub total: i64,
    pub total_pages: i32,
}

// =====================================================================================
// ADMIN ENUMS AND CONSTANTS
// =====================================================================================

// Admin role names (matching database)
pub mod admin_roles {
    pub const SUPPORT_ADMINISTRATOR: &str = "support_administrator";
    pub const ANALYTICS_ADMINISTRATOR: &str = "analytics_administrator"; 
    pub const CONTENT_ADMINISTRATOR: &str = "content_administrator";
    pub const PLATFORM_ADMINISTRATOR: &str = "platform_administrator";
    pub const ROOT_ADMINISTRATOR: &str = "root_administrator";
}

// Admin account status
pub mod admin_status {
    pub const PENDING: &str = "pending";
    pub const ACTIVE: &str = "active";
    pub const DISABLED: &str = "disabled";
    pub const LOCKED: &str = "locked";
}

// Invitation status
pub mod invitation_status {
    pub const PENDING: &str = "pending";
    pub const ACCEPTED: &str = "accepted";
    pub const EXPIRED: &str = "expired";
    pub const REVOKED: &str = "revoked";
}

// Audit log severity levels
pub mod audit_severity {
    pub const DEBUG: &str = "debug";
    pub const INFO: &str = "info";
    pub const WARNING: &str = "warning";
    pub const ERROR: &str = "error";
    pub const CRITICAL: &str = "critical";
}

// Common admin actions (for audit logging)
pub mod admin_actions {
    // Authentication actions
    pub const LOGIN: &str = "admin_login";
    pub const LOGIN_FAILED: &str = "admin_login_failed";
    pub const LOGOUT: &str = "admin_logout";
    pub const PASSWORD_CHANGED: &str = "admin_password_changed";
    pub const PASSWORD_RESET_REQUESTED: &str = "admin_password_reset_requested";
    pub const PASSWORD_RESET_COMPLETED: &str = "admin_password_reset_completed";
    
    // Account management actions
    pub const ACCOUNT_CREATED: &str = "admin_account_created";
    pub const ACCOUNT_UPDATED: &str = "admin_account_updated";
    pub const ACCOUNT_DISABLED: &str = "admin_account_disabled";
    pub const ACCOUNT_DELETED: &str = "admin_account_deleted";
    pub const ACCOUNT_LOCKED: &str = "admin_account_locked";
    pub const ACCOUNT_UNLOCKED: &str = "admin_account_unlocked";
    
    // Invitation actions
    pub const INVITATION_SENT: &str = "admin_invitation_sent";
    pub const INVITATION_ACCEPTED: &str = "admin_invitation_accepted";
    pub const INVITATION_REVOKED: &str = "admin_invitation_revoked";
    
    // User management actions (when admins manage family users)
    pub const USER_VIEWED: &str = "user_account_viewed";
    pub const USER_UPDATED: &str = "user_account_updated";
    pub const USER_DISABLED: &str = "user_account_disabled";
    pub const FAMILY_VIEWED: &str = "family_viewed";
    pub const FAMILY_UPDATED: &str = "family_updated";
    
    // Content management actions
    pub const CONTENT_APPROVED: &str = "content_approved";
    pub const CONTENT_REJECTED: &str = "content_rejected";
    pub const CONTENT_MODERATED: &str = "content_moderated";
    
    // System actions
    pub const SYSTEM_CONFIG_UPDATED: &str = "system_config_updated";
    pub const SYSTEM_MAINTENANCE: &str = "system_maintenance";
}

// =====================================================================================
// HELPER IMPLEMENTATIONS
// =====================================================================================

impl AdminAccount {
    // Check if account is currently locked
    pub fn is_locked(&self) -> bool {
        self.status == admin_status::LOCKED ||
        (self.locked_until.is_some() && 
         self.locked_until.unwrap() > Utc::now())
    }
    
    // Check if account is active and can authenticate
    pub fn can_authenticate(&self) -> bool {
        self.status == admin_status::ACTIVE && 
        !self.is_locked() &&
        self.password_hash.is_some()
    }
    
    // Get full name for display
    pub fn full_name(&self) -> String {
        match (&self.first_name, &self.last_name) {
            (Some(first), Some(last)) => format!("{} {}", first, last),
            (Some(first), None) => first.clone(),
            (None, Some(last)) => last.clone(),
            (None, None) => self.email.clone(),
        }
    }
}

impl AdminSession {
    // Check if session is currently valid
    pub fn is_valid(&self) -> bool {
        self.is_active && self.expires_at > Utc::now()
    }
    
    // Check if session needs refresh (expires within 5 minutes)
    pub fn needs_refresh(&self) -> bool {
        let five_minutes = chrono::Duration::minutes(5);
        self.expires_at < Utc::now() + five_minutes
    }
}

impl AdminInvitationToken {
    // Check if invitation is still valid
    pub fn is_valid(&self) -> bool {
        self.status == invitation_status::PENDING && 
        self.expires_at > Utc::now()
    }
    
    // Check if invitation is expired
    pub fn is_expired(&self) -> bool {
        self.expires_at <= Utc::now()
    }
}

impl AdminAuditLog {
    // Create a new audit log entry
    pub fn new(
        admin_id: Option<Uuid>,
        admin_email: Option<String>,
        action: String,
        description: String,
    ) -> Self {
        Self {
            id: Uuid::new_v4(),
            admin_id,
            admin_email,
            action,
            resource_type: None,
            resource_id: None,
            description,
            details: None,
            ip_address: None,
            user_agent: None,
            session_id: None,
            severity: audit_severity::INFO.to_string(),
            tags: None,
            checksum: None,
            previous_log_id: None,
            timestamp: Utc::now(),
        }
    }
    
    // Add details to audit log
    pub fn with_details(mut self, details: serde_json::Value) -> Self {
        self.details = Some(details);
        self
    }
    
    // Add severity to audit log
    pub fn with_severity(mut self, severity: &str) -> Self {
        self.severity = severity.to_string();
        self
    }
    
    // Add resource information
    pub fn with_resource(mut self, resource_type: &str, resource_id: &str) -> Self {
        self.resource_type = Some(resource_type.to_string());
        self.resource_id = Some(resource_id.to_string());
        self
    }
}

// =====================================================================================
// ADMIN ERROR TYPES
// =====================================================================================

#[derive(Debug, thiserror::Error)]
pub enum AdminError {
    #[error("Admin authentication failed: {0}")]
    AuthenticationFailed(String),
    
    #[error("Admin authorization failed: {0}")]
    AuthorizationFailed(String),
    
    #[error("Admin account not found")]
    AccountNotFound,
    
    #[error("Admin account is locked")]
    AccountLocked,
    
    #[error("Admin account is disabled")]
    AccountDisabled,
    
    #[error("Admin invitation is invalid or expired")]
    InvalidInvitation,
    
    #[error("Admin permission denied: {0}")]
    PermissionDenied(String),
    
    #[error("Admin validation error: {0}")]
    ValidationError(String),
    
    #[error("Admin MFA required")]
    MfaRequired,
    
    #[error("Admin MFA token invalid")]
    InvalidMfaToken,
    
    #[error("Admin database error: {0}")]
    DatabaseError(#[from] sqlx::Error),
    
    #[error("Admin internal error: {0}")]
    InternalError(#[from] anyhow::Error),
}

impl AdminError {
    pub fn to_http_status(&self) -> u16 {
        match self {
            AdminError::AuthenticationFailed(_) => 401,
            AdminError::AuthorizationFailed(_) => 403,
            AdminError::AccountNotFound => 404,
            AdminError::AccountLocked => 423,
            AdminError::AccountDisabled => 403,
            AdminError::InvalidInvitation => 400,
            AdminError::PermissionDenied(_) => 403,
            AdminError::ValidationError(_) => 400,
            AdminError::MfaRequired => 428, // Precondition Required
            AdminError::InvalidMfaToken => 401,
            AdminError::DatabaseError(_) => 500,
            AdminError::InternalError(_) => 500,
        }
    }
}