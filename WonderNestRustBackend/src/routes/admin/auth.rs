use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    routing::post,
    Json, Router,
};
use tracing::{info, warn, error};

use crate::{
    error::AppResult,
    models::{
        AdminLoginRequest, AdminLoginResponse, AdminChangePasswordRequest,
        MessageResponse, AdminError,
    },
    services::AppState,
};

/// Creates the admin authentication router
pub fn router() -> Router<AppState> {
    Router::new()
        .route("/login", post(admin_login))
        .route("/logout", post(admin_logout))
        .route("/refresh", post(admin_refresh))
        // TODO: Add protected routes with middleware
        // .route("/profile", get(get_admin_profile))
        // .route("/profile", put(update_admin_profile))
        // .route("/change-password", post(change_admin_password))
}

/// Admin login endpoint
/// POST /api/admin/auth/login
async fn admin_login(
    State(state): State<AppState>,
    Json(request): Json<AdminLoginRequest>,
) -> AppResult<axum::response::Response> {
    info!("Admin login attempt: email={}", request.email);
    
    // Extract client IP for security logging
    // TODO: Extract from headers once middleware is implemented
    let client_ip = None;
    let user_agent = None;
    
    match state.admin_auth.login_admin(request, client_ip, user_agent).await {
        Ok(response) => {
            info!("Admin login successful: email={}", response.admin.email);
            Ok((StatusCode::OK, Json(response)).into_response())
        }
        Err(AdminError::AuthenticationFailed(msg)) => {
            warn!("Admin login failed: {}", msg);
            let error_message = MessageResponse {
                message: "Invalid email or password".to_string(),
            };
            Ok((StatusCode::UNAUTHORIZED, Json(error_message)).into_response())
        }
        Err(AdminError::AccountLocked) => {
            warn!("Admin login failed: account locked");
            let error_message = MessageResponse {
                message: "Account is currently locked".to_string(),
            };
            Ok((StatusCode::FORBIDDEN, Json(error_message)).into_response())
        }
        Err(AdminError::AccountDisabled) => {
            warn!("Admin login failed: account disabled");
            let error_message = MessageResponse {
                message: "Account has been disabled".to_string(),
            };
            Ok((StatusCode::FORBIDDEN, Json(error_message)).into_response())
        }
        Err(AdminError::DatabaseError(db_err)) => {
            error!("Admin login database error: {}", db_err);
            let error_message = MessageResponse {
                message: "Internal server error".to_string(),
            };
            Ok((StatusCode::INTERNAL_SERVER_ERROR, Json(error_message)).into_response())
        }
        Err(e) => {
            error!("Admin login unexpected error: {:?}", e);
            let error_message = MessageResponse {
                message: "Internal server error".to_string(),
            };
            Ok((StatusCode::INTERNAL_SERVER_ERROR, Json(error_message)).into_response())
        }
    }
}

/// Admin logout endpoint
/// POST /api/admin/auth/logout
async fn admin_logout(
    State(state): State<AppState>,
    // TODO: Extract admin session from middleware
) -> AppResult<axum::response::Response> {
    info!("Admin logout requested");
    
    // TODO: Implement session invalidation once middleware is ready
    // For now, return success (client should discard token)
    
    let response = MessageResponse {
        message: "Logged out successfully".to_string(),
    };
    
    Ok((StatusCode::OK, Json(response)).into_response())
}

/// Admin token refresh endpoint
/// POST /api/admin/auth/refresh
async fn admin_refresh(
    State(state): State<AppState>,
    // TODO: Extract refresh token from request body or headers
) -> AppResult<axum::response::Response> {
    info!("Admin token refresh requested");
    
    // TODO: Implement token refresh once JWT service is integrated
    // For now, return not implemented
    
    let error_message = MessageResponse {
        message: "Token refresh not yet implemented".to_string(),
    };
    
    Ok((StatusCode::NOT_IMPLEMENTED, Json(error_message)).into_response())
}

// TODO: Protected routes to be implemented with authentication middleware
/*
async fn get_admin_profile(
    State(state): State<AppState>,
    // admin: AdminClaims, // TODO: Add admin claims extractor
) -> AppResult<axum::response::Response> {
    // Implementation pending
}

async fn update_admin_profile(
    State(state): State<AppState>,
    // admin: AdminClaims,
    Json(request): Json<UpdateAdminProfileRequest>,
) -> AppResult<axum::response::Response> {
    // Implementation pending
}

async fn change_admin_password(
    State(state): State<AppState>,
    // admin: AdminClaims,
    Json(request): Json<AdminChangePasswordRequest>,
) -> AppResult<axum::response::Response> {
    // Implementation pending
}
*/