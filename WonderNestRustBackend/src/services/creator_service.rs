use sqlx::PgPool;
use redis::aio::ConnectionManager;
use uuid::Uuid;
use chrono::{Duration, Utc};
use ipnetwork::IpNetwork;

use crate::{
    error::{AppError, AppResult},
    models::creator::{
        CreatorRegisterRequest, CreatorLoginRequest, CreatorLoginResponse, 
        CreatorRefreshResponse, CreatorAccount, Enable2FAResponse,
        CreatorStatus, CreatorType, CreatorTier,
    },
    services::{
        password::PasswordService,
        jwt::JwtService,
    },
};

/// Error types specific to creator service operations
#[derive(Debug, thiserror::Error)]
pub enum CreatorServiceError {
    #[error("Two-factor authentication required")]
    TwoFactorRequired,
    
    #[error("Invalid credentials")]
    InvalidCredentials,
    
    #[error("Creator not found")]
    CreatorNotFound,
    
    #[error("Email already exists")]
    EmailAlreadyExists,
    
    #[error("Account not verified")]
    AccountNotVerified,
    
    #[error("Account suspended")]
    AccountSuspended,
    
    #[error("Invalid verification token")]
    InvalidVerificationToken,
    
    #[error("Database error: {0}")]
    DatabaseError(#[from] sqlx::Error),
    
    #[error("Redis error: {0}")]
    RedisError(#[from] redis::RedisError),
    
    #[error("Internal error: {0}")]
    InternalError(String),
}

impl From<CreatorServiceError> for AppError {
    fn from(e: CreatorServiceError) -> Self {
        match e {
            CreatorServiceError::TwoFactorRequired => AppError::MfaRequired,
            CreatorServiceError::InvalidCredentials => AppError::Unauthorized,
            CreatorServiceError::CreatorNotFound => AppError::NotFound("Creator not found".to_string()),
            CreatorServiceError::EmailAlreadyExists => AppError::CreatorEmailAlreadyExists,
            CreatorServiceError::AccountNotVerified => AppError::CreatorNotVerified,
            CreatorServiceError::AccountSuspended => AppError::CreatorAccountSuspended,
            CreatorServiceError::InvalidVerificationToken => AppError::BadRequest("Invalid verification token".to_string()),
            CreatorServiceError::DatabaseError(e) => AppError::DatabaseError(e),
            CreatorServiceError::RedisError(e) => AppError::RedisError(e),
            CreatorServiceError::InternalError(msg) => AppError::InternalError(msg),
        }
    }
}

/// Service for managing creator accounts and authentication
pub struct CreatorService;

impl CreatorService {
    /// Create a new creator account
    /// 
    /// This is the first step in creator onboarding. The account is created
    /// with email verification required before they can proceed to application.
    pub async fn create_creator_account(
        pool: &PgPool,
        request: CreatorRegisterRequest,
    ) -> AppResult<CreatorAccount> {
        tracing::info!("Creating creator account for email: {}", request.email);
        
        // Check if email already exists
        if Self::email_exists(pool, &request.email).await? {
            return Err(AppError::CreatorEmailAlreadyExists);
        }
        
        // Hash the password
        let password_service = PasswordService::new();
        let hashed_password = password_service.hash_password(&request.password)
            .map_err(|e| AppError::InternalError(format!("Password hashing failed: {}", e)))?;
        
        let creator_id = Uuid::new_v4();
        let now = chrono::Utc::now();
        
        // Insert into database
        let record = sqlx::query!(
            r#"
            INSERT INTO creators.creator_accounts (
                id, email, password_hash, first_name, last_name, display_name, 
                country, status, creator_type, creator_tier, two_factor_enabled,
                terms_accepted, created_at, updated_at
            ) VALUES (
                $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $13
            ) RETURNING 
                id, email, email_verified, first_name, last_name, display_name,
                bio, country, status as "status: CreatorStatus", 
                creator_type as "creator_type: CreatorType",
                creator_tier as "creator_tier: CreatorTier",
                two_factor_enabled, avatar_url, cover_image_url, website_url,
                social_links, content_specialties, languages_supported, 
                target_age_groups, terms_accepted, created_at
            "#,
            creator_id,
            request.email,
            hashed_password,
            request.first_name,
            request.last_name,
            request.display_name,
            request.country,
            CreatorStatus::PendingVerification as CreatorStatus,
            CreatorType::Community as CreatorType,
            CreatorTier::Tier1 as CreatorTier,
            false,
            request.accept_terms,
            now
        )
        .fetch_one(pool)
        .await
        .map_err(|e| {
            tracing::error!("Failed to create creator account: {}", e);
            AppError::DatabaseError(e)
        })?;
        
        Ok(CreatorAccount {
            id: record.id,
            email: record.email,
            email_verified: record.email_verified,
            first_name: record.first_name,
            last_name: record.last_name,
            display_name: record.display_name,
            bio: record.bio,
            country: record.country,
            status: record.status,
            creator_type: record.creator_type,
            creator_tier: record.creator_tier,
            two_factor_enabled: record.two_factor_enabled,
            avatar_url: record.avatar_url,
            cover_image_url: record.cover_image_url,
            website_url: record.website_url,
            social_links: record.social_links
                .and_then(|v| serde_json::from_value(v).ok())
                .unwrap_or_default(),
            content_specialties: record.content_specialties.unwrap_or_default(),
            languages_supported: record.languages_supported.unwrap_or_default(),
            target_age_groups: record.target_age_groups.unwrap_or_default(),
            terms_accepted: record.terms_accepted,
            created_at: record.created_at.unwrap_or(now),
        })
    }

    /// Check if an email already exists in the creator system
    pub async fn email_exists(pool: &PgPool, email: &str) -> AppResult<bool> {
        tracing::debug!("Checking if creator email exists: {}", email);
        
        let result = sqlx::query!(
            "SELECT EXISTS(SELECT 1 FROM creators.creator_accounts WHERE email = $1)",
            email
        )
        .fetch_one(pool)
        .await
        .map_err(|e| AppError::DatabaseError(e))?;
        
        Ok(result.exists.unwrap_or(false))
    }

    /// Send email verification to a creator
    pub async fn send_verification_email(
        pool: &PgPool,
        creator_id: &Uuid,
        email: &str,
    ) -> AppResult<()> {
        tracing::info!("Sending verification email to creator: {}", email);
        
        // TODO: Implement email sending logic
        // For MVP, we'll just log this action
        
        Ok(())
    }

    /// Authenticate a creator with email and password
    /// 
    /// Returns JWT tokens if authentication succeeds, or requires 2FA if enabled.
    pub async fn authenticate_creator(
        pool: &PgPool,
        redis: &ConnectionManager,
        request: CreatorLoginRequest,
    ) -> Result<CreatorLoginResponse, CreatorServiceError> {
        tracing::info!("Authenticating creator: {}", request.email);
        
        // Get creator account by email
        let creator_record = sqlx::query!(
            r#"
            SELECT id, email, password_hash, email_verified, status as "status: CreatorStatus",
                   creator_tier as "creator_tier: CreatorTier", two_factor_enabled
            FROM creators.creator_accounts 
            WHERE email = $1
            "#,
            request.email
        )
        .fetch_optional(pool)
        .await
        .map_err(CreatorServiceError::DatabaseError)?;
        
        let creator = creator_record.ok_or(CreatorServiceError::InvalidCredentials)?;
        
        // Check if account is verified
        if !creator.email_verified {
            return Err(CreatorServiceError::AccountNotVerified);
        }
        
        // Check if account is suspended
        if creator.status == CreatorStatus::Suspended {
            return Err(CreatorServiceError::AccountSuspended);
        }
        
        // Verify password
        let password_service = PasswordService::new();
        let password_valid = password_service
            .verify_password(&request.password, &creator.password_hash)
            .map_err(|e| CreatorServiceError::InternalError(format!("Password verification failed: {}", e)))?;
        
        if !password_valid {
            return Err(CreatorServiceError::InvalidCredentials);
        }
        
        // Check if 2FA is required
        if creator.two_factor_enabled {
            if request.otp_code.is_none() {
                return Err(CreatorServiceError::TwoFactorRequired);
            }
            
            // TODO: Implement 2FA verification
            // For now, just return that 2FA is required if no code provided
        }
        
        // Generate JWT tokens
        let jwt_service = JwtService::new();
        let creator_id_str = creator.id.to_string();
        
        // Create session record
        let session_id = Uuid::new_v4();
        let expires_at = Utc::now() + Duration::hours(24); // 24 hour refresh token
        
        sqlx::query!(
            r#"
            INSERT INTO creators.creator_sessions 
            (id, creator_id, refresh_token_hash, access_token_jti, expires_at, ip_address)
            VALUES ($1, $2, $3, $4, $5, $6)
            "#,
            session_id,
            creator.id,
            format!("refresh_{}", session_id), // Simplified hash for MVP
            session_id.to_string(),
            expires_at,
            None::<IpNetwork> // TODO: Parse IP address properly for MVP
        )
        .execute(pool)
        .await
        .map_err(CreatorServiceError::DatabaseError)?;
        
        // Generate tokens (using simplified approach for MVP)
        let access_token = format!("creator_access_{}", Uuid::new_v4());
        let refresh_token = format!("creator_refresh_{}", session_id);
        
        Ok(CreatorLoginResponse {
            access_token,
            refresh_token,
            creator_id: creator.id,
            tier: format!("{:?}", creator.creator_tier).to_lowercase(),
            requires_2fa: creator.two_factor_enabled && request.otp_code.is_none(),
        })
    }

    /// Refresh JWT tokens using a refresh token
    pub async fn refresh_token(
        pool: &PgPool,
        redis: &ConnectionManager,
        refresh_token: &str,
    ) -> AppResult<CreatorRefreshResponse> {
        tracing::debug!("Refreshing creator token");
        
        // TODO: Implement token refresh logic
        
        Ok(CreatorRefreshResponse {
            access_token: "new_stub_access_token".to_string(),
            refresh_token: "new_stub_refresh_token".to_string(),
        })
    }

    /// Revoke a creator session
    pub async fn revoke_session(
        pool: &PgPool,
        redis: &ConnectionManager,
        creator_id: &str,
        jti: &str,
    ) -> AppResult<()> {
        tracing::info!("Revoking creator session: {}", creator_id);
        
        // TODO: Implement session revocation
        
        Ok(())
    }

    /// Get creator by ID
    pub async fn get_creator_by_id(
        pool: &PgPool,
        creator_id: Uuid,
    ) -> AppResult<Option<CreatorAccount>> {
        tracing::debug!("Getting creator by ID: {}", creator_id);
        
        let record = sqlx::query!(
            r#"
            SELECT id, email, email_verified, first_name, last_name, display_name,
                   bio, country, status as "status: CreatorStatus", 
                   creator_type as "creator_type: CreatorType",
                   creator_tier as "creator_tier: CreatorTier",
                   two_factor_enabled, avatar_url, cover_image_url, website_url,
                   social_links, content_specialties, languages_supported, 
                   target_age_groups, terms_accepted, created_at
            FROM creators.creator_accounts 
            WHERE id = $1
            "#,
            creator_id
        )
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::DatabaseError(e))?;
        
        Ok(record.map(|r| CreatorAccount {
            id: r.id,
            email: r.email,
            email_verified: r.email_verified,
            first_name: r.first_name,
            last_name: r.last_name,
            display_name: r.display_name,
            bio: r.bio,
            country: r.country,
            status: r.status,
            creator_type: r.creator_type,
            creator_tier: r.creator_tier,
            two_factor_enabled: r.two_factor_enabled,
            avatar_url: r.avatar_url,
            cover_image_url: r.cover_image_url,
            website_url: r.website_url,
            social_links: r.social_links
                .and_then(|v| serde_json::from_value(v).ok())
                .unwrap_or_default(),
            content_specialties: r.content_specialties.unwrap_or_default(),
            languages_supported: r.languages_supported.unwrap_or_default(),
            target_age_groups: r.target_age_groups.unwrap_or_default(),
            terms_accepted: r.terms_accepted,
            created_at: r.created_at.unwrap_or_else(|| Utc::now()),
        }))
    }

    /// Verify creator email with verification token
    pub async fn verify_email(pool: &PgPool, token: &str) -> AppResult<bool> {
        tracing::info!("Verifying creator email with token");
        
        // TODO: Implement email verification logic
        
        Ok(true)
    }

    /// Verify creator password
    pub async fn verify_password(
        pool: &PgPool,
        creator_id: Uuid,
        password: &str,
    ) -> AppResult<bool> {
        tracing::debug!("Verifying creator password");
        
        // TODO: Implement password verification
        
        Ok(true)
    }

    /// Enable 2FA for creator
    pub async fn enable_2fa(
        pool: &PgPool,
        creator_id: Uuid,
    ) -> AppResult<Enable2FAResponse> {
        tracing::info!("Enabling 2FA for creator: {}", creator_id);
        
        // TODO: Implement 2FA setup
        
        Ok(Enable2FAResponse {
            secret: "STUB2FASECRET".to_string(),
            qr_code: "data:image/png;base64,stub_qr_code".to_string(),
            backup_codes: vec![
                "12345678".to_string(),
                "87654321".to_string(),
            ],
        })
    }

    /// Disable 2FA for creator
    pub async fn disable_2fa(pool: &PgPool, creator_id: Uuid) -> AppResult<()> {
        tracing::info!("Disabling 2FA for creator: {}", creator_id);
        
        // TODO: Implement 2FA disable
        
        Ok(())
    }

    /// Verify 2FA for disable operation
    pub async fn verify_2fa_for_disable(
        pool: &PgPool,
        creator_id: Uuid,
        password: &str,
        otp_code: &str,
    ) -> AppResult<bool> {
        tracing::debug!("Verifying 2FA for disable operation");
        
        // TODO: Implement 2FA verification
        
        Ok(true)
    }

    /// Send password reset email
    pub async fn send_password_reset_email(
        pool: &PgPool,
        email: &str,
    ) -> AppResult<()> {
        tracing::info!("Sending password reset email to: {}", email);
        
        // TODO: Implement password reset email
        
        Ok(())
    }

    /// Reset password with token
    pub async fn reset_password(
        pool: &PgPool,
        token: &str,
        new_password: &str,
    ) -> AppResult<bool> {
        tracing::info!("Resetting creator password");
        
        // TODO: Implement password reset
        
        Ok(true)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::models::creator::CreatorType;

    #[tokio::test]
    async fn test_creator_service_stubs() {
        // Basic test to ensure service methods compile and run
        assert!(true);
    }

    #[test]
    fn test_error_conversion() {
        let creator_error = CreatorServiceError::TwoFactorRequired;
        let app_error: AppError = creator_error.into();
        
        match app_error {
            AppError::MfaRequired => assert!(true),
            _ => panic!("Unexpected error conversion"),
        }
    }
}