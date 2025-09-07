use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde_json::json;
use std::fmt;

#[derive(Debug)]
pub enum AppError {
    // Database errors
    DatabaseError(sqlx::Error),
    
    // Authentication errors
    Unauthorized,
    InvalidToken,
    TokenExpired,
    
    // Validation errors
    ValidationError(String),
    BadRequest(String),
    
    // Not found
    NotFound(String),
    
    // Access forbidden
    Forbidden(String),
    
    // Internal errors
    InternalError(String),
    
    // Redis errors
    RedisError(redis::RedisError),
    
    // JWT errors
    JwtError(jsonwebtoken::errors::Error),
    
    // JSON serialization errors
    JsonError(serde_json::Error),
}

impl fmt::Display for AppError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            AppError::DatabaseError(e) => write!(f, "Database error: {}", e),
            AppError::Unauthorized => write!(f, "Unauthorized"),
            AppError::InvalidToken => write!(f, "Invalid token"),
            AppError::TokenExpired => write!(f, "Token expired"),
            AppError::ValidationError(msg) => write!(f, "Validation error: {}", msg),
            AppError::BadRequest(msg) => write!(f, "Bad request: {}", msg),
            AppError::NotFound(msg) => write!(f, "Not found: {}", msg),
            AppError::Forbidden(msg) => write!(f, "Forbidden: {}", msg),
            AppError::InternalError(msg) => write!(f, "Internal error: {}", msg),
            AppError::RedisError(e) => write!(f, "Redis error: {}", e),
            AppError::JwtError(e) => write!(f, "JWT error: {}", e),
            AppError::JsonError(e) => write!(f, "JSON serialization error: {}", e),
        }
    }
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, error_message) = match self {
            AppError::DatabaseError(e) => {
                tracing::error!("Database error: {:?}", e);
                (StatusCode::INTERNAL_SERVER_ERROR, "Database error occurred".to_string())
            }
            AppError::Unauthorized => {
                (StatusCode::UNAUTHORIZED, "Unauthorized".to_string())
            }
            AppError::InvalidToken => {
                (StatusCode::UNAUTHORIZED, "Invalid token".to_string())
            }
            AppError::TokenExpired => {
                (StatusCode::UNAUTHORIZED, "Token expired".to_string())
            }
            AppError::ValidationError(msg) => {
                (StatusCode::BAD_REQUEST, msg)
            }
            AppError::BadRequest(msg) => {
                (StatusCode::BAD_REQUEST, msg)
            }
            AppError::NotFound(msg) => {
                (StatusCode::NOT_FOUND, msg)
            }
            AppError::Forbidden(msg) => {
                (StatusCode::FORBIDDEN, msg)
            }
            AppError::InternalError(msg) => {
                tracing::error!("Internal error: {}", msg);
                (StatusCode::INTERNAL_SERVER_ERROR, "Internal server error".to_string())
            }
            AppError::RedisError(e) => {
                tracing::error!("Redis error: {:?}", e);
                (StatusCode::INTERNAL_SERVER_ERROR, "Cache error occurred".to_string())
            }
            AppError::JwtError(e) => {
                tracing::error!("JWT error: {:?}", e);
                (StatusCode::UNAUTHORIZED, "Authentication error".to_string())
            }
            AppError::JsonError(e) => {
                tracing::error!("JSON serialization error: {:?}", e);
                (StatusCode::INTERNAL_SERVER_ERROR, "Data serialization error".to_string())
            }
        };

        let body = Json(json!({
            "error": error_message,
            "status": status.as_u16(),
        }));

        (status, body).into_response()
    }
}

// Implement conversions
impl From<sqlx::Error> for AppError {
    fn from(e: sqlx::Error) -> Self {
        AppError::DatabaseError(e)
    }
}

impl From<redis::RedisError> for AppError {
    fn from(e: redis::RedisError) -> Self {
        AppError::RedisError(e)
    }
}

impl From<jsonwebtoken::errors::Error> for AppError {
    fn from(e: jsonwebtoken::errors::Error) -> Self {
        AppError::JwtError(e)
    }
}

impl From<serde_json::Error> for AppError {
    fn from(e: serde_json::Error) -> Self {
        AppError::JsonError(e)
    }
}

pub type AppResult<T> = Result<T, AppError>;