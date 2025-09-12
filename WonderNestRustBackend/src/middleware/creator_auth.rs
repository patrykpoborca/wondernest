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
pub struct CreatorClaims {
    pub iss: String,  // issuer  
    pub aud: String,  // audience
    pub sub: String,  // subject (creator_id)
    #[serde(rename = "creatorId")]
    pub creator_id: String,  // Creator UUID
    pub email: String,
    #[serde(rename = "creatorType")]
    pub creator_type: String, // community, educator, professional, partner
    #[serde(rename = "creatorTier")]
    pub creator_tier: String, // tier_1, tier_2, tier_3, tier_4
    pub status: String, // active, suspended, etc.
    #[serde(rename = "twoFactorEnabled")]
    pub two_factor_enabled: bool,
    pub verified: bool,
    pub nonce: String,
    pub iat: i64,  // issued at
    pub exp: i64,  // expiration
    pub jti: String, // JWT ID for revocation
}

/// Creator authentication middleware for protected creator endpoints
pub async fn creator_auth_middleware(
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

    // Get Creator JWT secret from environment (separate from family auth)
    let creator_jwt_secret = std::env::var("CREATOR_JWT_SECRET")
        .unwrap_or_else(|_| "creator-super-secret-jwt-key-change-this-in-production".to_string());

    // Set up validation - more strict for creators
    let mut validation = Validation::new(Algorithm::HS256);
    validation.set_audience(&["wondernest-creators"]);
    validation.set_issuer(&["wondernest-creator-platform"]);
    validation.validate_exp = true;

    // Decode and validate token
    let token_data = decode::<CreatorClaims>(
        token,
        &DecodingKey::from_secret(creator_jwt_secret.as_bytes()),
        &validation,
    ).map_err(|e| {
        tracing::warn!("Creator token validation failed: {}", e);
        AppError::InvalidToken
    })?;

    let claims = token_data.claims;

    // Additional creator-specific validations
    if !claims.verified {
        return Err(AppError::CreatorNotVerified);
    }

    if claims.status != "active" {
        return Err(AppError::CreatorAccountSuspended);
    }

    // Parse and validate creator_id UUID
    let creator_id = Uuid::parse_str(&claims.creator_id)
        .map_err(|_| AppError::InvalidToken)?;

    // Store creator claims in request extensions for handlers to access
    req.extensions_mut().insert(claims);

    Ok(next.run(req).await)
}

/// Creator tier-based authorization middleware
/// Only allows access to creators with minimum required tier
pub fn creator_tier_middleware(min_tier: &'static str) -> impl Fn(Request, Next) -> std::pin::Pin<Box<dyn std::future::Future<Output = Result<Response, AppError>> + Send>> + Clone {
    move |mut req: Request, next: Next| {
        Box::pin(async move {
            // Get claims from request extensions (set by creator_auth_middleware)
            let claims = req.extensions()
                .get::<CreatorClaims>()
                .ok_or(AppError::Unauthorized)?;

            // Check tier requirements
            let tier_level = match claims.creator_tier.as_str() {
                "tier_1" => 1,
                "tier_2" => 2, 
                "tier_3" => 3,
                "tier_4" => 4,
                _ => 0,
            };

            let required_tier_level = match min_tier {
                "tier_1" => 1,
                "tier_2" => 2,
                "tier_3" => 3,
                "tier_4" => 4,
                _ => 0,
            };

            if tier_level < required_tier_level {
                return Err(AppError::InsufficientCreatorTier);
            }

            Ok(next.run(req).await)
        })
    }
}

/// Creator type-based authorization middleware
/// Only allows access to specific creator types
pub fn creator_type_middleware(allowed_types: Vec<&'static str>) -> impl Fn(Request, Next) -> std::pin::Pin<Box<dyn std::future::Future<Output = Result<Response, AppError>> + Send>> + Clone {
    move |req: Request, next: Next| {
        let allowed_types = allowed_types.clone();
        Box::pin(async move {
            // Get claims from request extensions
            let claims = req.extensions()
                .get::<CreatorClaims>()
                .ok_or(AppError::Unauthorized)?;

            // Check if creator type is allowed
            if !allowed_types.contains(&claims.creator_type.as_str()) {
                return Err(AppError::InsufficientCreatorPermissions);
            }

            Ok(next.run(req).await)
        })
    }
}

/// Helper to extract creator claims from request
pub fn extract_creator_claims(req: &Request) -> Result<&CreatorClaims, AppError> {
    req.extensions()
        .get::<CreatorClaims>()
        .ok_or(AppError::Unauthorized)
}

#[cfg(test)]
mod tests {
    use super::*;
    use jsonwebtoken::{encode, EncodingKey, Header};
    use axum::{body::Body, http::Method};
    use std::collections::HashMap;

    fn create_test_claims() -> CreatorClaims {
        CreatorClaims {
            iss: "wondernest-creator-platform".to_string(),
            aud: "wondernest-creators".to_string(),
            sub: "creator-123".to_string(),
            creator_id: "550e8400-e29b-41d4-a716-446655440000".to_string(),
            email: "creator@example.com".to_string(),
            creator_type: "educator".to_string(),
            creator_tier: "tier_2".to_string(),
            status: "active".to_string(),
            two_factor_enabled: true,
            verified: true,
            nonce: "test-nonce".to_string(),
            iat: chrono::Utc::now().timestamp(),
            exp: chrono::Utc::now().timestamp() + 3600,
            jti: "jwt-id-123".to_string(),
        }
    }

    fn create_test_token(claims: &CreatorClaims) -> String {
        let secret = "creator-super-secret-jwt-key-change-this-in-production";
        encode(
            &Header::default(),
            claims,
            &EncodingKey::from_secret(secret.as_bytes()),
        ).unwrap()
    }

    #[tokio::test]
    async fn test_valid_creator_token() {
        let claims = create_test_claims();
        let token = create_test_token(&claims);
        
        let mut req = Request::builder()
            .method(Method::GET)
            .uri("/")
            .header("Authorization", format!("Bearer {}", token))
            .body(Body::empty())
            .unwrap();

        let next = |req: Request| async move {
            // Verify claims were added to request extensions
            let extracted_claims = req.extensions().get::<CreatorClaims>().unwrap();
            assert_eq!(extracted_claims.creator_id, claims.creator_id);
            Ok(Response::builder().body(Body::empty()).unwrap())
        };

        let result = creator_auth_middleware(req, next).await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_tier_authorization() {
        let mut req = Request::builder()
            .method(Method::GET)
            .uri("/")
            .body(Body::empty())
            .unwrap();

        // Add tier_2 claims to request
        let claims = create_test_claims(); // tier_2
        req.extensions_mut().insert(claims);

        // Test tier_1 requirement (should pass)
        let tier_1_middleware = creator_tier_middleware("tier_1");
        let next = |_: Request| async { Ok(Response::builder().body(Body::empty()).unwrap()) };
        let result = tier_1_middleware(req, next).await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_insufficient_tier() {
        let mut req = Request::builder()
            .method(Method::GET)
            .uri("/")
            .body(Body::empty())
            .unwrap();

        // Add tier_1 claims to request  
        let mut claims = create_test_claims();
        claims.creator_tier = "tier_1".to_string();
        req.extensions_mut().insert(claims);

        // Test tier_3 requirement (should fail)
        let tier_3_middleware = creator_tier_middleware("tier_3");
        let next = |_: Request| async { Ok(Response::builder().body(Body::empty()).unwrap()) };
        let result = tier_3_middleware(req, next).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), AppError::InsufficientCreatorTier));
    }

    #[tokio::test]
    async fn test_creator_type_authorization() {
        let mut req = Request::builder()
            .method(Method::GET)
            .uri("/")
            .body(Body::empty())
            .unwrap();

        let claims = create_test_claims(); // educator type
        req.extensions_mut().insert(claims);

        // Test educator allowed (should pass)
        let type_middleware = creator_type_middleware(vec!["educator", "professional"]);
        let next = |_: Request| async { Ok(Response::builder().body(Body::empty()).unwrap()) };
        let result = type_middleware(req, next).await;
        assert!(result.is_ok());
    }

    #[tokio::test] 
    async fn test_creator_type_denied() {
        let mut req = Request::builder()
            .method(Method::GET)
            .uri("/")
            .body(Body::empty())
            .unwrap();

        let mut claims = create_test_claims();
        claims.creator_type = "community".to_string();
        req.extensions_mut().insert(claims);

        // Test professional-only access (should fail)
        let type_middleware = creator_type_middleware(vec!["professional", "partner"]);
        let next = |_: Request| async { Ok(Response::builder().body(Body::empty()).unwrap()) };
        let result = type_middleware(req, next).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), AppError::InsufficientCreatorPermissions));
    }
}