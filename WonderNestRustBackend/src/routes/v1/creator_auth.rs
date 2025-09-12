use axum::{
    extract::{State, Extension},
    http::StatusCode,
    middleware,
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};

use crate::{
    error::{AppError, AppResult},
    middleware::creator_auth::{creator_auth_middleware, CreatorClaims},
    models::{
        creator::{
            CreatorRegisterRequest, CreatorLoginRequest, CreatorRefreshTokenRequest,
            CreatorLoginResponse, CreatorRefreshResponse, Enable2FARequest, Enable2FAResponse,
        },
        MessageResponse,
    },
    services::{
        AppState,
        creator_service::{CreatorService, CreatorServiceError},
    },
};

pub fn router() -> Router<AppState> {
    // Protected routes that require creator JWT authentication
    let protected_routes = Router::new()
        .route("/logout", post(logout))
        .route("/me", get(get_current_creator))
        .route("/2fa/enable", post(enable_2fa))
        .route("/2fa/disable", post(disable_2fa))
        .layer(middleware::from_fn(creator_auth_middleware));

    Router::new()
        // Public auth routes
        .route("/register", post(register))
        .route("/login", post(login))
        .route("/refresh", post(refresh_token))
        .route("/verify-email", post(verify_email))
        .route("/forgot-password", post(forgot_password))
        .route("/reset-password", post(reset_password))
        
        // Protected routes
        .merge(protected_routes)
}

/// Creator registration endpoint
/// 
/// Creates a new creator account with email verification required.
/// Creators must verify their email before they can submit applications.
async fn register(
    State(app_state): State<AppState>,
    Json(request): Json<CreatorRegisterRequest>,
) -> AppResult<impl IntoResponse> {
    // Check if email already exists
    if CreatorService::email_exists(&app_state.db, &request.email).await? {
        return Err(AppError::CreatorEmailAlreadyExists);
    }

    // Create creator account
    let creator = CreatorService::create_creator_account(&app_state.db, request).await?;

    // Send verification email (async)
    CreatorService::send_verification_email(&app_state.db, &creator.id, &creator.email).await?;

    Ok((StatusCode::CREATED, Json(serde_json::json!({
        "creatorId": creator.id,
        "email": creator.email,
        "verificationRequired": true,
        "nextSteps": ["verify_email", "complete_application"]
    }))))
}

/// Creator login endpoint
///
/// Authenticates a creator and returns JWT tokens.
/// Supports 2FA if enabled for the creator account.
async fn login(
    State(app_state): State<AppState>,
    Json(request): Json<CreatorLoginRequest>,
) -> AppResult<impl IntoResponse> {
    // Authenticate creator
    let auth_result = CreatorService::authenticate_creator(
        &app_state.db,
        &app_state.redis,
        request
    ).await;

    match auth_result {
        Ok(response) => Ok((StatusCode::OK, Json(response))),
        Err(CreatorServiceError::TwoFactorRequired) => {
            Ok((StatusCode::PRECONDITION_REQUIRED, Json(CreatorLoginResponse {
                access_token: String::new(),
                refresh_token: String::new(),
                creator_id: Uuid::nil(),
                tier: String::new(),
                requires_2fa: true,
            })))
        }
        Err(e) => Err(e.into()),
    }
}

/// Refresh JWT token endpoint
///
/// Issues new access and refresh tokens using a valid refresh token.
async fn refresh_token(
    State(app_state): State<AppState>,
    Json(request): Json<CreatorRefreshTokenRequest>,
) -> AppResult<impl IntoResponse> {
    let response = CreatorService::refresh_token(
        &app_state.db,
        &app_state.redis,
        &request.refresh_token
    ).await?;

    Ok((StatusCode::OK, Json(response)))
}

/// Logout endpoint
///
/// Invalidates the current session and revokes tokens.
async fn logout(
    State(app_state): State<AppState>,
    req: axum::extract::Request,
) -> AppResult<impl IntoResponse> {
    // Get creator claims from middleware
    let claims = req.extensions()
        .get::<CreatorClaims>()
        .ok_or(AppError::Unauthorized)?;

    // Revoke session
    CreatorService::revoke_session(
        &app_state.db,
        &app_state.redis,
        &claims.creator_id,
        &claims.jti
    ).await?;

    Ok((StatusCode::NO_CONTENT, Json(MessageResponse {
        message: "Logged out successfully".to_string(),
    })))
}

/// Get current creator information
///
/// Returns the authenticated creator's profile information.
async fn get_current_creator(
    State(app_state): State<AppState>,
    req: axum::extract::Request,
) -> AppResult<impl IntoResponse> {
    // Get creator claims from middleware
    let claims = req.extensions()
        .get::<CreatorClaims>()
        .ok_or(AppError::Unauthorized)?;

    let creator_id = Uuid::parse_str(&claims.creator_id)
        .map_err(|_| AppError::InvalidToken)?;

    // Get creator account
    let creator = CreatorService::get_creator_by_id(&app_state.db, creator_id).await?
        .ok_or(AppError::NotFound("Creator not found".to_string()))?;

    Ok((StatusCode::OK, Json(creator)))
}

/// Email verification endpoint
///
/// Verifies creator email using verification token sent via email.
async fn verify_email(
    State(app_state): State<AppState>,
    Json(request): Json<EmailVerificationRequest>,
) -> AppResult<impl IntoResponse> {
    let result = CreatorService::verify_email(
        &app_state.db,
        &request.token
    ).await?;

    if result {
        Ok((StatusCode::OK, Json(MessageResponse {
            message: "Email verified successfully. You can now submit your creator application.".to_string(),
        })))
    } else {
        Err(AppError::BadRequest("Invalid or expired verification token".to_string()))
    }
}

/// Enable 2FA endpoint
///
/// Enables two-factor authentication for the creator account.
async fn enable_2fa(
    State(app_state): State<AppState>,
    Extension(claims): Extension<CreatorClaims>,
    Json(request): Json<Enable2FARequest>,
) -> AppResult<impl IntoResponse> {

    let creator_id = Uuid::parse_str(&claims.creator_id)
        .map_err(|_| AppError::InvalidToken)?;

    // Verify current password
    let password_valid = CreatorService::verify_password(
        &app_state.db,
        creator_id,
        &request.password
    ).await?;

    if !password_valid {
        return Err(AppError::BadRequest("Invalid password".to_string()));
    }

    // Generate 2FA secret and backup codes
    let response = CreatorService::enable_2fa(&app_state.db, creator_id).await?;

    Ok((StatusCode::OK, Json(response)))
}

/// Disable 2FA endpoint
///
/// Disables two-factor authentication for the creator account.
async fn disable_2fa(
    State(app_state): State<AppState>,
    Extension(claims): Extension<CreatorClaims>,
    Json(request): Json<Disable2FARequest>,
) -> AppResult<impl IntoResponse> {

    let creator_id = Uuid::parse_str(&claims.creator_id)
        .map_err(|_| AppError::InvalidToken)?;

    // Verify current password and 2FA code
    let auth_valid = CreatorService::verify_2fa_for_disable(
        &app_state.db,
        creator_id,
        &request.password,
        &request.otp_code
    ).await?;

    if !auth_valid {
        return Err(AppError::BadRequest("Invalid password or 2FA code".to_string()));
    }

    // Disable 2FA
    CreatorService::disable_2fa(&app_state.db, creator_id).await?;

    Ok((StatusCode::OK, Json(MessageResponse {
        message: "Two-factor authentication disabled successfully".to_string(),
    })))
}

/// Forgot password endpoint
///
/// Sends password reset email to creator.
async fn forgot_password(
    State(app_state): State<AppState>,
    Json(request): Json<ForgotPasswordRequest>,
) -> AppResult<impl IntoResponse> {
    // Always return success to prevent email enumeration
    let _ = CreatorService::send_password_reset_email(
        &app_state.db,
        &request.email
    ).await;

    Ok((StatusCode::OK, Json(MessageResponse {
        message: "If a creator account with that email exists, a password reset link has been sent.".to_string(),
    })))
}

/// Reset password endpoint
///
/// Resets creator password using reset token.
async fn reset_password(
    State(app_state): State<AppState>,
    Json(request): Json<ResetPasswordRequest>,
) -> AppResult<impl IntoResponse> {
    let result = CreatorService::reset_password(
        &app_state.db,
        &request.token,
        &request.new_password
    ).await?;

    if result {
        Ok((StatusCode::OK, Json(MessageResponse {
            message: "Password reset successfully. You can now log in with your new password.".to_string(),
        })))
    } else {
        Err(AppError::BadRequest("Invalid or expired reset token".to_string()))
    }
}

// Additional request/response types for auth endpoints
#[derive(Debug, Serialize, Deserialize)]
struct EmailVerificationRequest {
    pub token: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct Disable2FARequest {
    pub password: String,
    #[serde(rename = "otpCode")]
    pub otp_code: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct ForgotPasswordRequest {
    pub email: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct ResetPasswordRequest {
    pub token: String,
    #[serde(rename = "newPassword")]
    pub new_password: String,
}

use serde::{Serialize, Deserialize};
use uuid::Uuid;
use serde_json::json;

#[cfg(test)]
mod tests {
    use super::*;
    use axum_test::TestServer;
    use serde_json::json;

    // Integration tests would go here
    // Testing the full creator auth flow
    
    #[tokio::test]
    async fn test_creator_registration_flow() {
        // Test the creator registration endpoint
        // This would require setting up a test database and app state
    }

    #[tokio::test]
    async fn test_creator_login_flow() {
        // Test the creator login endpoint
    }

    #[tokio::test]
    async fn test_2fa_flow() {
        // Test enabling and using 2FA
    }

    #[tokio::test]
    async fn test_password_reset_flow() {
        // Test password reset functionality
    }
}