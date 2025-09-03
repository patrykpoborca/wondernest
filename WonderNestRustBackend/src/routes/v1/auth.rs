use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    routing::post,
    Json, Router,
};

use crate::{
    error::AppResult,
    models::{
        SignupRequest, LoginRequest, RefreshTokenRequest, PinVerificationRequest,
        AuthResponse, PinVerificationResponse, MessageResponse,
    },
    services::{
        AppState,
        auth_service::{AuthService, AuthServiceError},
        validation::{ValidationService, ValidationResultExt},
    },
    db::{UserRepository, FamilyRepository},
};

pub fn router() -> Router<AppState> {
    Router::new()
        // Parent-specific routes (matching Kotlin exact paths)
        .route("/parent/register", post(parent_register))
        .route("/parent/login", post(parent_login))
        .route("/parent/verify-pin", post(parent_verify_pin))
        
        // Generic auth routes (for backward compatibility)
        .route("/register", post(register))
        .route("/login", post(login))
        .route("/session/refresh", post(refresh_session))
}

// Parent-specific registration (matching Kotlin "/parent/register" exactly)
async fn parent_register(
    State(state): State<AppState>,
    Json(raw_request): Json<SignupRequest>,
) -> AppResult<axum::response::Response> {
    tracing::info!("Received parent signup request: email={}, name={:?} {:?}",
        raw_request.email, raw_request.first_name, raw_request.last_name);
    
    let validation_service = ValidationService::new();
    
    // Validate request (matching Kotlin validation exactly)
    let validation_result = validation_service.validate_signup_request(&raw_request);
    if !validation_result.is_valid {
        tracing::warn!("Parent signup validation failed: {:?}", validation_result.errors);
        let error_message = format!("Validation failed: {}", validation_result.errors.join(", "));
        return Ok((StatusCode::BAD_REQUEST, Json(MessageResponse { message: error_message })).into_response());
    }
    
    // Sanitize request (matching Kotlin sanitization exactly)
    let sanitized_request = validation_service.sanitize_signup_request(raw_request);
    tracing::info!("Sanitized parent signup request: {:?}", sanitized_request);
    
    // Create auth service
    let user_repo = UserRepository::new(state.db.clone());
    let family_repo = FamilyRepository::new(state.db.clone());
    let auth_service = AuthService::new(user_repo, family_repo);
    
    // Create parent account with family (matching Kotlin signupParent exactly)
    match auth_service.signup_parent(sanitized_request).await {
        Ok(response) => {
            tracing::info!("Parent signup successful");
            Ok((StatusCode::CREATED, Json(response)).into_response())
        }
        Err(AuthServiceError::ValidationError(msg)) => {
            tracing::warn!("Parent signup validation exception: {}", msg);
            Ok((StatusCode::BAD_REQUEST, Json(MessageResponse { message: msg })).into_response())
        }
        Err(AuthServiceError::DatabaseError(sqlx::Error::Database(db_err))) 
            if db_err.constraint().is_some() => {
            tracing::warn!("Parent signup constraint violation: {:?}", db_err);
            Ok((StatusCode::BAD_REQUEST, Json(MessageResponse { 
                message: "User with this email already exists".to_string() 
            })).into_response())
        }
        Err(err) => {
            tracing::error!("Parent signup error: {:?}", err);
            Ok((StatusCode::INTERNAL_SERVER_ERROR, Json(MessageResponse { 
                message: "Registration failed".to_string() 
            })).into_response())
        }
    }
}

// Parent-specific login (matching Kotlin "/parent/login" exactly)
async fn parent_login(
    State(state): State<AppState>,
    body: String, // Raw body to handle potential JSON escaping issues
) -> AppResult<axum::response::Response> {
    // Fix incorrectly escaped special characters from web client (matching Kotlin logic)
    let fixed_body = body.replace("\\!", "!");
    
    // Parse the JSON with lenient settings (matching Kotlin Json configuration)
    let raw_request: LoginRequest = match serde_json::from_str(&fixed_body) {
        Ok(req) => req,
        Err(e) => {
            tracing::warn!("JSON parsing error: {}", e);
            return Ok((StatusCode::BAD_REQUEST, Json(MessageResponse { 
                message: "Invalid JSON format".to_string() 
            })).into_response());
        }
    };
    
    tracing::info!("Received parent login request: email={}", raw_request.email);
    
    let validation_service = ValidationService::new();
    
    // Validate request (matching Kotlin validation exactly)
    if let Err(validation_err) = validation_service.validate_login_request(&raw_request).throw_if_invalid() {
        return Ok((StatusCode::BAD_REQUEST, Json(validation_err.to_message_response())).into_response());
    }
    
    // Sanitize request (matching Kotlin sanitization exactly)
    let sanitized_request = validation_service.sanitize_login_request(raw_request);
    
    // Create auth service
    let user_repo = UserRepository::new(state.db.clone());
    let family_repo = FamilyRepository::new(state.db.clone());
    let auth_service = AuthService::new(user_repo, family_repo);
    
    // Login with family context (matching Kotlin loginParent exactly)
    match auth_service.login_parent(sanitized_request).await {
        Ok(response) => {
            tracing::info!("Parent login successful");
            Ok((StatusCode::OK, Json(response)).into_response())
        }
        Err(AuthServiceError::SecurityError(_)) => {
            Ok((StatusCode::UNAUTHORIZED, Json(MessageResponse { 
                message: "Invalid credentials".to_string() 
            })).into_response())
        }
        Err(err) => {
            tracing::error!("Parent login error: {:?}", err);
            Ok((StatusCode::INTERNAL_SERVER_ERROR, Json(MessageResponse { 
                message: "Login failed".to_string() 
            })).into_response())
        }
    }
}

// PIN verification endpoint (matching Kotlin "/parent/verify-pin" exactly)
async fn parent_verify_pin(
    State(_state): State<AppState>,
    Json(raw_request): Json<PinVerificationRequest>,
) -> AppResult<axum::response::Response> {
    // Basic validation (matching Kotlin validation exactly)
    if raw_request.pin.is_empty() || raw_request.pin.len() != 4 || !raw_request.pin.chars().all(|c| c.is_ascii_digit()) {
        return Ok((StatusCode::BAD_REQUEST, Json(PinVerificationResponse {
            verified: false,
            message: "Invalid PIN format. Must be 4 digits.".to_string(),
            session_token: None,
        })).into_response());
    }
    
    // TODO: PRODUCTION - Implement proper PIN storage and verification
    // For now, we'll use a default PIN for development/demo (matching Kotlin exactly)
    let default_pin = "1234"; // TODO: Remove this and implement proper PIN management
    
    if raw_request.pin == default_pin {
        // Generate a temporary session token for parent mode (matching Kotlin exactly)
        let session_token = format!("parent_mode_{}", chrono::Utc::now().timestamp_millis());
        
        Ok((StatusCode::OK, Json(PinVerificationResponse {
            verified: true,
            message: "PIN verified successfully".to_string(),
            session_token: Some(session_token),
        })).into_response())
    } else {
        tracing::warn!("PIN verification failed");
        Ok((StatusCode::UNAUTHORIZED, Json(PinVerificationResponse {
            verified: false,
            message: "Invalid PIN".to_string(),
            session_token: None,
        })).into_response())
    }
}

// Generic signup (matching Kotlin "/signup" exactly)
async fn register(
    State(state): State<AppState>,
    Json(raw_request): Json<SignupRequest>,
) -> AppResult<axum::response::Response> {
    tracing::info!("Received signup request: email={}, firstName={:?}, lastName={:?}",
        raw_request.email, raw_request.first_name, raw_request.last_name);
    
    let validation_service = ValidationService::new();
    
    // Validate request (matching Kotlin validation exactly)
    let validation_result = validation_service.validate_signup_request(&raw_request);
    if !validation_result.is_valid {
        tracing::warn!("Signup validation failed: {:?}", validation_result.errors);
        let error_message = format!("Validation failed: {}", validation_result.errors.join(", "));
        return Ok((StatusCode::BAD_REQUEST, Json(MessageResponse { message: error_message })).into_response());
    }
    
    // Sanitize request (matching Kotlin sanitization exactly)
    let sanitized_request = validation_service.sanitize_signup_request(raw_request);
    tracing::info!("Sanitized signup request: {:?}", sanitized_request);
    
    // Create auth service
    let user_repo = UserRepository::new(state.db.clone());
    let family_repo = FamilyRepository::new(state.db.clone());
    let auth_service = AuthService::new(user_repo, family_repo);
    
    // Create account (matching Kotlin signup exactly)
    match auth_service.signup(sanitized_request).await {
        Ok(response) => {
            tracing::info!("Signup successful");
            Ok((StatusCode::CREATED, Json(response)).into_response())
        }
        Err(AuthServiceError::ValidationError(msg)) => {
            tracing::warn!("Signup validation exception: {}", msg);
            Ok((StatusCode::BAD_REQUEST, Json(MessageResponse { message: msg })).into_response())
        }
        Err(AuthServiceError::DatabaseError(sqlx::Error::Database(db_err))) 
            if db_err.constraint().is_some() => {
            tracing::warn!("Signup constraint violation: {:?}", db_err);
            Ok((StatusCode::BAD_REQUEST, Json(MessageResponse { 
                message: "User with this email already exists".to_string() 
            })).into_response())
        }
        Err(err) => {
            tracing::error!("Signup error: {:?}", err);
            Ok((StatusCode::INTERNAL_SERVER_ERROR, Json(MessageResponse { 
                message: "Registration failed".to_string() 
            })).into_response())
        }
    }
}

// Generic login (matching Kotlin "/login" exactly)
async fn login(
    State(state): State<AppState>,
    Json(raw_request): Json<LoginRequest>,
) -> AppResult<axum::response::Response> {
    let validation_service = ValidationService::new();
    
    // Validate request (matching Kotlin validation exactly)
    if let Err(validation_err) = validation_service.validate_login_request(&raw_request).throw_if_invalid() {
        return Ok((StatusCode::BAD_REQUEST, Json(validation_err.to_message_response())).into_response());
    }
    
    // Sanitize request (matching Kotlin sanitization exactly)
    let sanitized_request = validation_service.sanitize_login_request(raw_request);
    
    // Create auth service
    let user_repo = UserRepository::new(state.db.clone());
    let family_repo = FamilyRepository::new(state.db.clone());
    let auth_service = AuthService::new(user_repo, family_repo);
    
    // Login (matching Kotlin login exactly)
    match auth_service.login(sanitized_request).await {
        Ok(response) => {
            Ok((StatusCode::OK, Json(response)).into_response())
        }
        Err(AuthServiceError::SecurityError(_)) => {
            Ok((StatusCode::UNAUTHORIZED, Json(MessageResponse { 
                message: "Invalid credentials".to_string() 
            })).into_response())
        }
        Err(err) => {
            tracing::error!("Login error: {:?}", err);
            Ok((StatusCode::INTERNAL_SERVER_ERROR, Json(MessageResponse { 
                message: "Login failed".to_string() 
            })).into_response())
        }
    }
}

// Refresh session (matching Kotlin "/session/refresh" exactly)
async fn refresh_session(
    State(state): State<AppState>,
    Json(request): Json<RefreshTokenRequest>,
) -> AppResult<axum::response::Response> {
    let refresh_token = match request.refresh_token {
        Some(token) if !token.is_empty() => token,
        _ => {
            return Ok((StatusCode::BAD_REQUEST, Json(MessageResponse { 
                message: "Refresh token is required".to_string() 
            })).into_response());
        }
    };
    
    // Create auth service
    let user_repo = UserRepository::new(state.db.clone());
    let family_repo = FamilyRepository::new(state.db.clone());
    let auth_service = AuthService::new(user_repo, family_repo);
    
    // Refresh token (matching Kotlin refreshToken exactly)
    match auth_service.refresh_token(&refresh_token).await {
        Ok(response) => {
            Ok((StatusCode::OK, Json(response)).into_response())
        }
        Err(AuthServiceError::SecurityError(_)) => {
            Ok((StatusCode::UNAUTHORIZED, Json(MessageResponse { 
                message: "Invalid refresh token".to_string() 
            })).into_response())
        }
        Err(err) => {
            tracing::error!("Token refresh error: {:?}", err);
            Ok((StatusCode::INTERNAL_SERVER_ERROR, Json(MessageResponse { 
                message: "Token refresh failed".to_string() 
            })).into_response())
        }
    }
}