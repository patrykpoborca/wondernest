use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post, put},
    Json, Router,
    middleware,
};
use tracing::{info, warn, error};

use crate::{
    error::AppResult,
    models::{
        AdminLoginRequest, AdminLoginResponse, AdminChangePasswordRequest,
        MessageResponse, AdminError, AdminInfo,
    },
    services::AppState,
    middleware::admin_auth::{admin_auth_middleware, extract_admin_claims},
};

/// Creates the admin authentication router
pub fn router() -> Router<AppState> {
    // Create two separate routers: one for public routes, one for protected routes
    let public_routes = Router::new()
        .route("/login", post(admin_login));
    
    let protected_routes = Router::new()
        .route("/logout", post(admin_logout))
        .route("/refresh", post(admin_refresh))
        .route("/profile", get(get_admin_profile))
        .route("/profile", put(update_admin_profile))
        .route("/change-password", post(change_admin_password))
        .layer(middleware::from_fn(admin_auth_middleware));
    
    // Merge both routers
    public_routes.merge(protected_routes)
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

/// Get admin profile endpoint
/// GET /api/admin/auth/profile
async fn get_admin_profile(
    State(_state): State<AppState>,
    request: axum::extract::Request,
) -> AppResult<axum::response::Response> {
    // Extract admin claims from middleware
    let claims = extract_admin_claims(&request)
        .ok_or(crate::error::AppError::Unauthorized)?;
    
    info!("Admin profile requested: {} ({})", claims.email, claims.admin_id);
    
    // Create admin info response (simplified for now)
    let admin_info = AdminInfo {
        id: claims.admin_id.clone(),
        email: claims.email.clone(),
        first_name: None, // TODO: Get from database
        last_name: None,  // TODO: Get from database
        role: claims.role.clone(),
        role_level: claims.role_level,
        permissions: claims.permissions.clone(),
        last_login: None, // TODO: Get from database
        mfa_enabled: claims.mfa_verified,
        account_status: "active".to_string(), // TODO: Get from database
    };
    
    Ok((StatusCode::OK, Json(admin_info)).into_response())
}

/// Update admin profile endpoint
/// PUT /api/admin/auth/profile
async fn update_admin_profile(
    State(_state): State<AppState>,
    request: axum::extract::Request,
) -> AppResult<axum::response::Response> {
    let claims = extract_admin_claims(&request)
        .ok_or(crate::error::AppError::Unauthorized)?;
    
    info!("Admin profile update requested: {} ({})", claims.email, claims.admin_id);
    
    // TODO: Extract JSON request body and implement profile update
    let response = MessageResponse {
        message: "Profile update not yet implemented".to_string(),
    };
    
    Ok((StatusCode::NOT_IMPLEMENTED, Json(response)).into_response())
}

/// Change admin password endpoint
/// POST /api/admin/auth/change-password
async fn change_admin_password(
    State(_state): State<AppState>,
    request: axum::extract::Request,
) -> AppResult<axum::response::Response> {
    let claims = extract_admin_claims(&request)
        .ok_or(crate::error::AppError::Unauthorized)?;
    
    info!("Admin password change requested: {} ({})", claims.email, claims.admin_id);
    
    // TODO: Extract JSON request body and implement password change
    let response = MessageResponse {
        message: "Password change not yet implemented".to_string(),
    };
    
    Ok((StatusCode::NOT_IMPLEMENTED, Json(response)).into_response())
}