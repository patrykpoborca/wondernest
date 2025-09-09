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
        AdminRefreshTokenRequest, MessageResponse, AdminError, AdminInfo,
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
    request: axum::extract::Request,
) -> AppResult<axum::response::Response> {
    info!("Admin logout requested");
    
    // Extract admin claims from middleware
    let claims = extract_admin_claims(&request)
        .ok_or(crate::error::AppError::Unauthorized)?;
    
    // Extract authorization header to get access token
    let auth_header = request.headers()
        .get(axum::http::header::AUTHORIZATION)
        .and_then(|h| h.to_str().ok())
        .and_then(|h| h.strip_prefix("Bearer "));
    
    let client_ip = None; // TODO: Extract from headers
    
    match auth_header {
        Some(access_token) => {
            match state.admin_auth.logout_admin(
                access_token,
                Some(uuid::Uuid::parse_str(&claims.admin_id).map_err(|_| crate::error::AppError::Unauthorized)?),
                client_ip
            ).await {
                Ok(_) => {
                    info!("Admin logout successful: {} ({})", claims.email, claims.admin_id);
                    let response = MessageResponse {
                        message: "Logged out successfully".to_string(),
                    };
                    Ok((StatusCode::OK, Json(response)).into_response())
                }
                Err(e) => {
                    error!("Admin logout error: {:?}", e);
                    // Even if logout fails, return success to client
                    let response = MessageResponse {
                        message: "Logged out successfully".to_string(),
                    };
                    Ok((StatusCode::OK, Json(response)).into_response())
                }
            }
        }
        None => {
            warn!("Admin logout without access token");
            let response = MessageResponse {
                message: "Logged out successfully".to_string(),
            };
            Ok((StatusCode::OK, Json(response)).into_response())
        }
    }
}

/// Admin token refresh endpoint
/// POST /api/admin/auth/refresh
async fn admin_refresh(
    State(state): State<AppState>,
    Json(request): Json<AdminRefreshTokenRequest>,
) -> AppResult<axum::response::Response> {
    info!("Admin token refresh requested");
    
    // Extract client IP for security logging
    // TODO: Extract from headers once middleware is implemented
    let client_ip = None;
    
    match state.admin_auth.refresh_admin_token(&request.refresh_token, client_ip).await {
        Ok(response) => {
            info!("Admin token refresh successful");
            Ok((StatusCode::OK, Json(response)).into_response())
        }
        Err(AdminError::AuthenticationFailed(msg)) => {
            warn!("Admin token refresh failed: {}", msg);
            let error_message = MessageResponse {
                message: "Invalid refresh token".to_string(),
            };
            Ok((StatusCode::UNAUTHORIZED, Json(error_message)).into_response())
        }
        Err(AdminError::AccountNotFound) => {
            warn!("Admin token refresh failed: account not found");
            let error_message = MessageResponse {
                message: "Invalid refresh token".to_string(),
            };
            Ok((StatusCode::UNAUTHORIZED, Json(error_message)).into_response())
        }
        Err(AdminError::AccountDisabled) => {
            warn!("Admin token refresh failed: account disabled");
            let error_message = MessageResponse {
                message: "Account has been disabled".to_string(),
            };
            Ok((StatusCode::FORBIDDEN, Json(error_message)).into_response())
        }
        Err(AdminError::DatabaseError(db_err)) => {
            error!("Admin token refresh database error: {}", db_err);
            let error_message = MessageResponse {
                message: "Internal server error".to_string(),
            };
            Ok((StatusCode::INTERNAL_SERVER_ERROR, Json(error_message)).into_response())
        }
        Err(e) => {
            error!("Admin token refresh unexpected error: {:?}", e);
            let error_message = MessageResponse {
                message: "Internal server error".to_string(),
            };
            Ok((StatusCode::INTERNAL_SERVER_ERROR, Json(error_message)).into_response())
        }
    }
}

/// Get admin profile endpoint
/// GET /api/admin/auth/profile
async fn get_admin_profile(
    State(state): State<AppState>,
    request: axum::extract::Request,
) -> AppResult<axum::response::Response> {
    // Extract admin claims from middleware
    let claims = extract_admin_claims(&request)
        .ok_or(crate::error::AppError::Unauthorized)?;
    
    info!("Admin profile requested: {} ({})", claims.email, claims.admin_id);
    
    let admin_id = uuid::Uuid::parse_str(&claims.admin_id)
        .map_err(|_| crate::error::AppError::Unauthorized)?;
    
    match state.admin_auth.get_admin_profile(admin_id).await {
        Ok(admin) => {
            let admin_info = AdminInfo {
                id: admin.id.to_string(),
                email: admin.email,
                first_name: admin.first_name,
                last_name: admin.last_name,
                role: "admin".to_string(), // TODO: Load actual role from admin.role_id
                role_level: 1, // TODO: Load actual role level from admin.role_id
                permissions: vec![], // TODO: Load actual permissions from admin.role_id
                last_login: admin.last_login_at,
                mfa_enabled: admin.mfa_secret.is_some(),
                account_status: admin.status,
            };
            Ok((StatusCode::OK, Json(admin_info)).into_response())
        }
        Err(AdminError::AccountNotFound) => {
            warn!("Admin profile not found: {}", claims.admin_id);
            let error_message = MessageResponse {
                message: "Admin account not found".to_string(),
            };
            Ok((StatusCode::NOT_FOUND, Json(error_message)).into_response())
        }
        Err(AdminError::DatabaseError(db_err)) => {
            error!("Admin profile database error: {}", db_err);
            let error_message = MessageResponse {
                message: "Internal server error".to_string(),
            };
            Ok((StatusCode::INTERNAL_SERVER_ERROR, Json(error_message)).into_response())
        }
        Err(e) => {
            error!("Admin profile unexpected error: {:?}", e);
            let error_message = MessageResponse {
                message: "Internal server error".to_string(),
            };
            Ok((StatusCode::INTERNAL_SERVER_ERROR, Json(error_message)).into_response())
        }
    }
}

/// Update admin profile endpoint
/// PUT /api/admin/auth/profile
async fn update_admin_profile(
    State(state): State<AppState>,
    request: axum::extract::Request,
) -> AppResult<axum::response::Response> {
    // Extract claims first before consuming the request
    let claims = extract_admin_claims(&request)
        .ok_or(crate::error::AppError::Unauthorized)?
        .clone();
    
    info!("Admin profile update requested: {} ({})", claims.email, claims.admin_id);
    
    let admin_id = uuid::Uuid::parse_str(&claims.admin_id)
        .map_err(|_| crate::error::AppError::Unauthorized)?;
    
    // Now extract the request body
    let (_, body) = request.into_parts();
    let body_bytes = axum::body::to_bytes(body, usize::MAX).await
        .map_err(|_| crate::error::AppError::BadRequest("Failed to read request body".to_string()))?;
    
    let update_request: crate::models::UpdateAdminRequest = serde_json::from_slice(&body_bytes)
        .map_err(|e| crate::error::AppError::BadRequest(format!("Invalid request body: {}", e)))?;
    
    let client_ip = None; // TODO: Extract from headers
    
    match state.admin_auth.update_admin_profile(admin_id, update_request, client_ip).await {
        Ok(updated_admin) => {
            let admin_info = AdminInfo {
                id: updated_admin.id.to_string(),
                email: updated_admin.email,
                first_name: updated_admin.first_name,
                last_name: updated_admin.last_name,
                role: "admin".to_string(), // TODO: Load actual role from admin.role_id
                role_level: 1, // TODO: Load actual role level from admin.role_id 
                permissions: vec![], // TODO: Load actual permissions from admin.role_id
                last_login: updated_admin.last_login_at,
                mfa_enabled: updated_admin.mfa_secret.is_some(),
                account_status: updated_admin.status,
            };
            Ok((StatusCode::OK, Json(admin_info)).into_response())
        }
        Err(AdminError::AccountNotFound) => {
            warn!("Admin account not found for update: {}", claims.admin_id);
            let error_message = MessageResponse {
                message: "Admin account not found".to_string(),
            };
            Ok((StatusCode::NOT_FOUND, Json(error_message)).into_response())
        }
        Err(AdminError::ValidationError(msg)) => {
            warn!("Admin profile update validation error: {}", msg);
            let error_message = MessageResponse {
                message: msg,
            };
            Ok((StatusCode::BAD_REQUEST, Json(error_message)).into_response())
        }
        Err(AdminError::DatabaseError(db_err)) => {
            error!("Admin profile update database error: {}", db_err);
            let error_message = MessageResponse {
                message: "Internal server error".to_string(),
            };
            Ok((StatusCode::INTERNAL_SERVER_ERROR, Json(error_message)).into_response())
        }
        Err(e) => {
            error!("Admin profile update unexpected error: {:?}", e);
            let error_message = MessageResponse {
                message: "Internal server error".to_string(),
            };
            Ok((StatusCode::INTERNAL_SERVER_ERROR, Json(error_message)).into_response())
        }
    }
}

/// Change admin password endpoint
/// POST /api/admin/auth/change-password
async fn change_admin_password(
    State(state): State<AppState>,
    request: axum::extract::Request,
) -> AppResult<axum::response::Response> {
    // Extract claims first before consuming the request
    let claims = extract_admin_claims(&request)
        .ok_or(crate::error::AppError::Unauthorized)?
        .clone();
    
    info!("Admin password change requested: {} ({})", claims.email, claims.admin_id);
    
    let admin_id = uuid::Uuid::parse_str(&claims.admin_id)
        .map_err(|_| crate::error::AppError::Unauthorized)?;
    
    // Now extract the request body
    let (_, body) = request.into_parts();
    let body_bytes = axum::body::to_bytes(body, usize::MAX).await
        .map_err(|_| crate::error::AppError::BadRequest("Failed to read request body".to_string()))?;
    
    let password_request: AdminChangePasswordRequest = serde_json::from_slice(&body_bytes)
        .map_err(|e| crate::error::AppError::BadRequest(format!("Invalid request body: {}", e)))?;
    
    let client_ip = None; // TODO: Extract from headers
    
    match state.admin_auth.change_admin_password(admin_id, password_request, client_ip).await {
        Ok(true) => {
            info!("Admin password changed successfully: {} ({})", claims.email, claims.admin_id);
            let response = MessageResponse {
                message: "Password changed successfully".to_string(),
            };
            Ok((StatusCode::OK, Json(response)).into_response())
        }
        Ok(false) => {
            error!("Admin password change failed for unknown reason: {} ({})", claims.email, claims.admin_id);
            let error_message = MessageResponse {
                message: "Failed to change password".to_string(),
            };
            Ok((StatusCode::INTERNAL_SERVER_ERROR, Json(error_message)).into_response())
        }
        Err(AdminError::AuthenticationFailed(msg)) => {
            warn!("Admin password change failed - current password incorrect: {} ({})", claims.email, claims.admin_id);
            let error_message = MessageResponse {
                message: "Current password is incorrect".to_string(),
            };
            Ok((StatusCode::BAD_REQUEST, Json(error_message)).into_response())
        }
        Err(AdminError::ValidationError(msg)) => {
            warn!("Admin password change validation error: {} - {}", claims.admin_id, msg);
            let error_message = MessageResponse {
                message: msg,
            };
            Ok((StatusCode::BAD_REQUEST, Json(error_message)).into_response())
        }
        Err(AdminError::AccountNotFound) => {
            warn!("Admin account not found for password change: {}", claims.admin_id);
            let error_message = MessageResponse {
                message: "Admin account not found".to_string(),
            };
            Ok((StatusCode::NOT_FOUND, Json(error_message)).into_response())
        }
        Err(AdminError::DatabaseError(db_err)) => {
            error!("Admin password change database error: {}", db_err);
            let error_message = MessageResponse {
                message: "Internal server error".to_string(),
            };
            Ok((StatusCode::INTERNAL_SERVER_ERROR, Json(error_message)).into_response())
        }
        Err(e) => {
            error!("Admin password change unexpected error: {:?}", e);
            let error_message = MessageResponse {
                message: "Internal server error".to_string(),
            };
            Ok((StatusCode::INTERNAL_SERVER_ERROR, Json(error_message)).into_response())
        }
    }
}