use axum::{
    extract::Request,
    http::header,
    middleware::Next,
    response::Response,
};
use jsonwebtoken::{decode, DecodingKey, Validation, Algorithm};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::error::AppError;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Claims {
    pub iss: String,  // issuer
    pub aud: String,  // audience
    pub sub: String,  // subject (user_id)
    #[serde(rename = "userId")]
    pub user_id: String,  // Keep compatibility with Kotlin backend
    pub email: String,
    pub role: String,
    pub verified: bool,
    pub nonce: String,
    pub iat: i64,  // issued at
    pub exp: i64,  // expiration
}

pub async fn auth_middleware(
    mut req: Request,
    next: Next,
) -> Result<Response, AppError> {
    // Extract token from Authorization header
    let auth_header = req
        .headers()
        .get(header::AUTHORIZATION)
        .and_then(|h| h.to_str().ok())
        .ok_or(AppError::Unauthorized)?;

    // Check for Bearer prefix
    if !auth_header.starts_with("Bearer ") {
        return Err(AppError::InvalidToken);
    }

    let token = &auth_header[7..]; // Skip "Bearer "

    // Get JWT secret from environment (for compatibility during migration)
    let jwt_secret = std::env::var("JWT_SECRET")
        .unwrap_or_else(|_| "your-super-secret-jwt-key-change-this-in-production".to_string());

    // Decode and validate JWT
    let token_data = decode::<Claims>(
        token,
        &DecodingKey::from_secret(jwt_secret.as_bytes()),
        &Validation::new(Algorithm::HS256),
    )
    .map_err(|e| {
        tracing::debug!("JWT validation failed: {:?}", e);
        match e.kind() {
            jsonwebtoken::errors::ErrorKind::ExpiredSignature => AppError::TokenExpired,
            _ => AppError::InvalidToken,
        }
    })?;

    // Basic validation - for full compatibility validation, we'd need state
    // For now, just validate token format and expiry
    let jwt_issuer = std::env::var("JWT_ISSUER")
        .unwrap_or_else(|_| "wondernest".to_string());
    let jwt_audience = std::env::var("JWT_AUDIENCE")
        .unwrap_or_else(|_| "wondernest-app".to_string());

    // Verify issuer and audience
    if token_data.claims.iss != jwt_issuer {
        tracing::debug!("Invalid issuer: {}", token_data.claims.iss);
        return Err(AppError::InvalidToken);
    }

    if token_data.claims.aud != jwt_audience {
        tracing::debug!("Invalid audience: {}", token_data.claims.aud);
        return Err(AppError::InvalidToken);
    }

    // Parse user_id as UUID to validate format
    let _user_id = Uuid::parse_str(&token_data.claims.user_id)
        .map_err(|_| AppError::InvalidToken)?;

    // Add claims to request extensions for use in handlers
    req.extensions_mut().insert(token_data.claims);

    Ok(next.run(req).await)
}

// Helper function to extract claims from request
pub fn extract_claims(req: &Request) -> Option<&Claims> {
    req.extensions().get::<Claims>()
}