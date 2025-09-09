use axum::{
    extract::Request,
    http::header,
    middleware::Next,
    response::Response,
};
use jsonwebtoken::{decode, DecodingKey, Validation, Algorithm};
use uuid::Uuid;
use tracing::{debug, warn};

use crate::{
    error::AppError,
    services::admin_jwt::AdminClaims,
};

// =====================================================================================
// ADMIN AUTHENTICATION MIDDLEWARE
// Handles JWT validation for admin endpoints only. Completely separate from
// family user authentication to ensure proper privilege separation.
// =====================================================================================

/// Admin authentication middleware that validates admin JWT tokens
/// This middleware is specifically for admin endpoints and uses admin-specific claims
pub async fn admin_auth_middleware(
    mut req: Request,
    next: Next,
) -> Result<Response, AppError> {
    debug!("Admin auth middleware: validating admin token");
    
    // Extract token from Authorization header
    let auth_header = req
        .headers()
        .get(header::AUTHORIZATION)
        .and_then(|h| h.to_str().ok())
        .ok_or_else(|| {
            warn!("Admin auth: Missing Authorization header");
            AppError::Unauthorized
        })?;

    // Check for Bearer prefix
    if !auth_header.starts_with("Bearer ") {
        warn!("Admin auth: Invalid Authorization header format");
        return Err(AppError::InvalidToken);
    }

    let token = &auth_header[7..]; // Skip "Bearer "

    // Get admin JWT configuration from environment
    let admin_jwt_secret = std::env::var("ADMIN_JWT_SECRET")
        .or_else(|_| std::env::var("JWT_SECRET")) // Fallback to regular JWT_SECRET during development
        .unwrap_or_else(|_| "admin-super-secret-jwt-key-change-this-in-production".to_string());

    let admin_jwt_issuer = std::env::var("ADMIN_JWT_ISSUER")
        .unwrap_or_else(|_| "wondernest-admin-api".to_string());
    
    let admin_jwt_audience = std::env::var("ADMIN_JWT_AUDIENCE")
        .unwrap_or_else(|_| "wondernest-admin-portal".to_string());

    // Configure validation for admin tokens
    let mut validation = Validation::new(Algorithm::HS256);
    validation.set_issuer(&[&admin_jwt_issuer]);
    validation.set_audience(&[&admin_jwt_audience]);
    
    // Additional security: require specific claims
    validation.validate_exp = true;
    validation.validate_nbf = true;

    // Decode and validate admin JWT
    let token_data = decode::<AdminClaims>(
        token,
        &DecodingKey::from_secret(admin_jwt_secret.as_bytes()),
        &validation,
    )
    .map_err(|e| {
        debug!("Admin JWT validation failed: {:?}", e);
        match e.kind() {
            jsonwebtoken::errors::ErrorKind::ExpiredSignature => {
                warn!("Admin auth: Token expired");
                AppError::TokenExpired
            },
            jsonwebtoken::errors::ErrorKind::InvalidIssuer => {
                warn!("Admin auth: Invalid token issuer");
                AppError::InvalidToken
            },
            jsonwebtoken::errors::ErrorKind::InvalidAudience => {
                warn!("Admin auth: Invalid token audience");
                AppError::InvalidToken
            },
            _ => {
                warn!("Admin auth: Token validation failed - {:?}", e.kind());
                AppError::InvalidToken
            },
        }
    })?;

    // Validate admin_id format
    let _admin_id = Uuid::parse_str(&token_data.claims.admin_id)
        .map_err(|_| {
            warn!("Admin auth: Invalid admin_id format in token");
            AppError::InvalidToken
        })?;

    // Additional security checks for admin tokens
    if !token_data.claims.mfa_verified && requires_mfa(&req) {
        warn!("Admin auth: MFA required but not verified");
        return Err(AppError::MfaRequired);
    }

    // Log admin access for audit trail
    debug!("Admin authenticated: {} ({}), role: {}, level: {}", 
           token_data.claims.email, 
           token_data.claims.admin_id,
           token_data.claims.role,
           token_data.claims.role_level);

    // Add admin claims to request extensions for use in handlers
    req.extensions_mut().insert(token_data.claims);

    Ok(next.run(req).await)
}

/// Admin authorization middleware that checks role permissions
/// This should be layered after admin_auth_middleware
pub async fn admin_authz_middleware(
    required_level: i32,
) -> impl Fn(Request, Next) -> std::pin::Pin<Box<dyn std::future::Future<Output = Result<Response, AppError>> + Send>> + Clone {
    move |req: Request, next: Next| {
        let req_level = required_level;
        Box::pin(async move {
            // Get admin claims from previous middleware
            let claims = req.extensions().get::<AdminClaims>()
                .ok_or_else(|| {
                    warn!("Admin authz: No admin claims found in request");
                    AppError::Unauthorized
                })?;

            // Check role level
            if claims.role_level < req_level {
                warn!("Admin authz: Insufficient role level. Required: {}, Has: {}", 
                      req_level, claims.role_level);
                return Err(AppError::InsufficientPermissions);
            }

            // Root admin bypass
            if claims.is_root_admin {
                debug!("Admin authz: Root admin access granted");
                return Ok(next.run(req).await);
            }

            debug!("Admin authz: Access granted for role level {}", claims.role_level);
            Ok(next.run(req).await)
        })
    }
}

/// Permission-based authorization middleware
/// Checks if admin has specific permission
pub async fn admin_permission_middleware(
    required_permission: String,
) -> impl Fn(Request, Next) -> std::pin::Pin<Box<dyn std::future::Future<Output = Result<Response, AppError>> + Send>> + Clone {
    move |req: Request, next: Next| {
        let permission = required_permission.clone();
        Box::pin(async move {
            // Get admin claims from previous middleware
            let claims = req.extensions().get::<AdminClaims>()
                .ok_or_else(|| {
                    warn!("Admin permission: No admin claims found in request");
                    AppError::Unauthorized
                })?;

            // Root admin bypass
            if claims.is_root_admin {
                debug!("Admin permission: Root admin access granted");
                return Ok(next.run(req).await);
            }

            // Check if admin has the required permission
            if !claims.permissions.contains(&permission) {
                warn!("Admin permission: Missing required permission '{}' for admin {}", 
                      permission, claims.email);
                return Err(AppError::InsufficientPermissions);
            }

            debug!("Admin permission: Access granted for permission '{}'", permission);
            Ok(next.run(req).await)
        })
    }
}

/// Helper function to extract admin claims from request
pub fn extract_admin_claims(req: &Request) -> Option<&AdminClaims> {
    req.extensions().get::<AdminClaims>()
}

/// Check if the current endpoint requires MFA
/// This is a simple check that can be extended with more sophisticated logic
fn requires_mfa(req: &Request) -> bool {
    let path = req.uri().path();
    
    // High-security operations that always require MFA
    let mfa_required_paths = [
        "/api/admin/accounts",      // Account management
        "/api/admin/invitations",   // Invitation management  
        "/api/admin/audit",         // Audit log access
        "/api/admin/system",        // System configuration
    ];
    
    mfa_required_paths.iter().any(|&mfa_path| path.starts_with(mfa_path))
}

// =====================================================================================
// MIDDLEWARE HELPER FUNCTIONS FOR ROUTE BUILDING
// =====================================================================================

// Simply export the middleware function directly - users can call axum::middleware::from_fn themselves