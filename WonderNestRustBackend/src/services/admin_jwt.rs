use chrono::{Duration, Utc};
use jsonwebtoken::{decode, encode, Algorithm, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use std::env;
use uuid::Uuid;

use crate::models::{AdminAccount, AdminRole, AdminPermission, TokenPair};

// =====================================================================================
// ADMIN JWT SERVICE
// Handles JWT token generation and validation specifically for admin accounts.
// Completely separate from family user JWT tokens with admin-specific claims.
// =====================================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AdminClaims {
    pub sub: String,          // Subject (admin ID)
    pub iss: String,          // Issuer
    pub aud: String,          // Audience (admin-specific)
    pub iat: i64,             // Issued at
    pub exp: i64,             // Expires at
    pub jti: String,          // JWT ID (unique nonce)
    
    // Admin-specific claims
    #[serde(rename = "adminId")]
    pub admin_id: String,
    pub email: String,
    pub role: String,         // Role name (e.g., "root_administrator")
    pub role_level: i32,      // Role level (1-5)
    pub permissions: Vec<String>, // List of permission names
    pub is_root_admin: bool,
    pub mfa_verified: bool,   // Whether MFA was completed for this session
    
    // Security claims
    pub login_count: i32,     // Helps detect token replay attacks
    pub ip_hash: Option<String>, // Hash of source IP for validation
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AdminRefreshClaims {
    pub sub: String,          // Subject (admin ID)
    pub iss: String,          // Issuer
    pub aud: String,          // Audience (admin refresh)
    pub iat: i64,             // Issued at
    pub exp: i64,             // Expires at
    pub jti: String,          // JWT ID (unique nonce)
    
    #[serde(rename = "type")]
    pub token_type: String,   // Always "refresh"
    #[serde(rename = "adminId")]
    pub admin_id: String,
    pub login_count: i32,     // Must match the access token
}

#[derive(Clone)]
pub struct AdminJwtService {
    secret: Vec<u8>,
    issuer: String,
    audience: String,
    access_token_expires_in_ms: i64,
    refresh_token_expires_in_ms: i64,
}

impl AdminJwtService {
    pub fn new() -> Self {
        // Use separate admin JWT secret if available, fallback to main JWT secret
        let secret = env::var("ADMIN_JWT_SECRET")
            .or_else(|_| env::var("JWT_SECRET"))
            .unwrap_or_else(|_| "your-super-secret-admin-jwt-key-change-this-in-production".to_string())
            .into_bytes();
            
        let issuer = env::var("ADMIN_JWT_ISSUER")
            .unwrap_or_else(|_| "wondernest-admin-api".to_string());
            
        let audience = env::var("ADMIN_JWT_AUDIENCE")
            .unwrap_or_else(|_| "wondernest-admin-portal".to_string());
        
        // Admin tokens expire faster for security: 1 hour access, 7 days refresh
        let access_token_expires_in_ms = env::var("ADMIN_JWT_EXPIRES_IN")
            .unwrap_or_else(|_| "3600000".to_string()) // 1 hour
            .parse()
            .unwrap_or(3600000);
        
        let refresh_token_expires_in_ms = env::var("ADMIN_JWT_REFRESH_EXPIRES_IN")
            .unwrap_or_else(|_| "604800000".to_string()) // 7 days
            .parse()
            .unwrap_or(604800000);

        Self {
            secret,
            issuer,
            audience,
            access_token_expires_in_ms,
            refresh_token_expires_in_ms,
        }
    }
    
    // Generate admin JWT token pair with role and permission claims
    pub fn generate_admin_token(
        &self, 
        admin: &AdminAccount, 
        role: &AdminRole, 
        permissions: &[AdminPermission],
        mfa_verified: bool,
        client_ip: Option<&str>,
    ) -> anyhow::Result<TokenPair> {
        let now = Utc::now();
        let access_jti = Uuid::new_v4().to_string();
        let refresh_jti = Uuid::new_v4().to_string();
        
        let access_expires_at = now + Duration::milliseconds(self.access_token_expires_in_ms);
        let refresh_expires_at = now + Duration::milliseconds(self.refresh_token_expires_in_ms);
        
        // Create IP hash for security validation (optional)
        let ip_hash = client_ip.map(|ip| {
            use sha2::{Sha256, Digest};
            let mut hasher = Sha256::new();
            hasher.update(ip.as_bytes());
            hasher.update(&self.secret); // Salt with JWT secret
            format!("{:x}", hasher.finalize())[..16].to_string() // First 16 chars
        });
        
        // Build permission list
        let permission_names: Vec<String> = permissions.iter()
            .filter(|p| p.is_active)
            .map(|p| p.permission_name.clone())
            .collect();
        
        // Create access token claims
        let access_claims = AdminClaims {
            sub: admin.id.to_string(),
            iss: self.issuer.clone(),
            aud: self.audience.clone(),
            iat: now.timestamp(),
            exp: access_expires_at.timestamp(),
            jti: access_jti,
            admin_id: admin.id.to_string(),
            email: admin.email.clone(),
            role: role.role_name.clone(),
            role_level: role.role_level,
            permissions: permission_names,
            is_root_admin: admin.is_root_admin,
            mfa_verified,
            login_count: admin.login_count,
            ip_hash,
        };
        
        // Create refresh token claims
        let refresh_claims = AdminRefreshClaims {
            sub: admin.id.to_string(),
            iss: self.issuer.clone(),
            aud: format!("{}-refresh", self.audience),
            iat: now.timestamp(),
            exp: refresh_expires_at.timestamp(),
            jti: refresh_jti,
            token_type: "refresh".to_string(),
            admin_id: admin.id.to_string(),
            login_count: admin.login_count,
        };
        
        let header = Header::new(Algorithm::HS256);
        let encoding_key = EncodingKey::from_secret(&self.secret);
        
        let access_token = encode(&header, &access_claims, &encoding_key)?;
        let refresh_token = encode(&header, &refresh_claims, &encoding_key)?;
        
        Ok(TokenPair {
            access_token,
            refresh_token,
            expires_in: self.access_token_expires_in_ms,
        })
    }
    
    // Verify and decode admin access token
    pub fn verify_admin_token(&self, token: &str) -> anyhow::Result<AdminClaims> {
        let decoding_key = DecodingKey::from_secret(&self.secret);
        
        let mut validation = Validation::new(Algorithm::HS256);
        validation.set_issuer(&[&self.issuer]);
        validation.set_audience(&[&self.audience]);
        
        let token_data = decode::<AdminClaims>(token, &decoding_key, &validation)?;
        Ok(token_data.claims)
    }
    
    // Verify and decode admin refresh token
    pub fn verify_admin_refresh_token(&self, token: &str) -> anyhow::Result<AdminRefreshClaims> {
        let decoding_key = DecodingKey::from_secret(&self.secret);
        
        let mut validation = Validation::new(Algorithm::HS256);
        validation.set_issuer(&[&self.issuer]);
        validation.set_audience(&[&format!("{}-refresh", self.audience)]);
        
        let token_data = decode::<AdminRefreshClaims>(token, &decoding_key, &validation)?;
        
        if token_data.claims.token_type != "refresh" {
            return Err(anyhow::anyhow!("Invalid admin token type"));
        }
        
        Ok(token_data.claims)
    }
    
    // Extract admin ID from token without full validation (for logging/debugging)
    pub fn extract_admin_id_from_token(&self, token: &str) -> Option<String> {
        match jsonwebtoken::decode::<AdminClaims>(
            token,
            &DecodingKey::from_secret(&self.secret),
            &Validation::default()
        ) {
            Ok(token_data) => Some(token_data.claims.admin_id),
            Err(_) => None,
        }
    }
    
    // Extract admin role from token without full validation
    pub fn extract_admin_role_from_token(&self, token: &str) -> Option<String> {
        match jsonwebtoken::decode::<AdminClaims>(
            token,
            &DecodingKey::from_secret(&self.secret),
            &Validation::default()
        ) {
            Ok(token_data) => Some(token_data.claims.role),
            Err(_) => None,
        }
    }
    
    // Extract admin permissions from token without full validation
    pub fn extract_admin_permissions_from_token(&self, token: &str) -> Option<Vec<String>> {
        match jsonwebtoken::decode::<AdminClaims>(
            token,
            &DecodingKey::from_secret(&self.secret),
            &Validation::default()
        ) {
            Ok(token_data) => Some(token_data.claims.permissions),
            Err(_) => None,
        }
    }
    
    // Validate IP hash in token (additional security check)
    pub fn validate_token_ip(&self, claims: &AdminClaims, client_ip: &str) -> bool {
        match &claims.ip_hash {
            Some(token_ip_hash) => {
                // Recreate IP hash and compare
                use sha2::{Sha256, Digest};
                let mut hasher = Sha256::new();
                hasher.update(client_ip.as_bytes());
                hasher.update(&self.secret);
                let computed_hash = format!("{:x}", hasher.finalize())[..16].to_string();
                
                *token_ip_hash == computed_hash
            }
            None => true, // No IP restriction in token
        }
    }
    
    // Check if token requires MFA and is properly verified
    pub fn is_mfa_verified(&self, claims: &AdminClaims) -> bool {
        claims.mfa_verified
    }
    
    // Get token expiry time for session management
    pub fn get_token_expiry(&self, claims: &AdminClaims) -> chrono::DateTime<Utc> {
        chrono::DateTime::from_timestamp(claims.exp, 0)
            .unwrap_or_else(|| Utc::now())
    }
    
    // Check if admin has specific permission
    pub fn has_permission(&self, claims: &AdminClaims, permission: &str) -> bool {
        claims.permissions.contains(&permission.to_string())
    }
    
    // Check if admin has minimum role level
    pub fn has_min_role_level(&self, claims: &AdminClaims, min_level: i32) -> bool {
        claims.role_level >= min_level
    }
    
    // Generate a new token with updated permissions (for role changes)
    pub fn refresh_admin_token_with_new_permissions(
        &self,
        old_claims: &AdminClaims,
        new_permissions: &[AdminPermission],
    ) -> anyhow::Result<String> {
        let now = Utc::now();
        let expires_at = now + Duration::milliseconds(self.access_token_expires_in_ms);
        
        let permission_names: Vec<String> = new_permissions.iter()
            .filter(|p| p.is_active)
            .map(|p| p.permission_name.clone())
            .collect();
        
        let new_claims = AdminClaims {
            sub: old_claims.sub.clone(),
            iss: old_claims.iss.clone(),
            aud: old_claims.aud.clone(),
            iat: now.timestamp(),
            exp: expires_at.timestamp(),
            jti: Uuid::new_v4().to_string(), // New JWT ID
            admin_id: old_claims.admin_id.clone(),
            email: old_claims.email.clone(),
            role: old_claims.role.clone(),
            role_level: old_claims.role_level,
            permissions: permission_names, // Updated permissions
            is_root_admin: old_claims.is_root_admin,
            mfa_verified: old_claims.mfa_verified,
            login_count: old_claims.login_count,
            ip_hash: old_claims.ip_hash.clone(),
        };
        
        let header = Header::new(Algorithm::HS256);
        let encoding_key = EncodingKey::from_secret(&self.secret);
        
        Ok(encode(&header, &new_claims, &encoding_key)?)
    }
}

// =====================================================================================
// ADMIN JWT MIDDLEWARE HELPERS
// =====================================================================================

// Extract admin claims from request (for use in middleware)
pub fn extract_admin_claims_from_token(token: &str) -> anyhow::Result<AdminClaims> {
    let service = AdminJwtService::new();
    service.verify_admin_token(token)
}

// Validate admin token and return claims (comprehensive validation)
pub fn validate_admin_token_comprehensive(
    token: &str,
    client_ip: Option<&str>,
    require_mfa: bool,
) -> anyhow::Result<AdminClaims> {
    let service = AdminJwtService::new();
    let claims = service.verify_admin_token(token)?;
    
    // Additional validations
    if require_mfa && !claims.mfa_verified {
        return Err(anyhow::anyhow!("MFA verification required"));
    }
    
    // Validate IP if present
    if let Some(ip) = client_ip {
        if !service.validate_token_ip(&claims, ip) {
            return Err(anyhow::anyhow!("Token IP validation failed"));
        }
    }
    
    Ok(claims)
}

// =====================================================================================
// ADMIN TOKEN UTILITIES
// =====================================================================================

// Create token hash for database storage (consistent with admin sessions)
pub fn create_admin_token_hash(token: &str) -> String {
    use sha2::{Sha256, Digest};
    let mut hasher = Sha256::new();
    hasher.update(token.as_bytes());
    format!("{:x}", hasher.finalize())
}

// Check if admin token is close to expiry (for automatic refresh)
pub fn is_admin_token_near_expiry(claims: &AdminClaims, threshold_minutes: i64) -> bool {
    let threshold = chrono::Duration::minutes(threshold_minutes);
    let expiry = chrono::DateTime::from_timestamp(claims.exp, 0)
        .unwrap_or_else(|| Utc::now());
    
    expiry < Utc::now() + threshold
}

// Extract admin info for audit logging
pub fn extract_admin_info_for_audit(claims: &AdminClaims) -> (Uuid, String) {
    let admin_id = Uuid::parse_str(&claims.admin_id)
        .unwrap_or_else(|_| Uuid::nil());
    
    (admin_id, claims.email.clone())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::models::{AdminAccount, AdminRole, AdminPermission};
    
    fn create_test_admin() -> AdminAccount {
        AdminAccount {
            id: Uuid::new_v4(),
            email: "test@wondernest.com".to_string(),
            password_hash: Some("hashed_password".to_string()),
            first_name: Some("Test".to_string()),
            last_name: Some("Admin".to_string()),
            role_id: 5,
            custom_permissions: serde_json::Value::Array(vec![]),
            status: "active".to_string(),
            is_root_admin: true,
            mfa_enabled: false,
            mfa_secret: None,
            ip_restrictions: None,
            allowed_hours: None,
            email_verified: true,
            last_login_at: None,
            login_count: 1,
            failed_login_attempts: 0,
            locked_until: None,
            created_at: Utc::now(),
            created_by: None,
            updated_at: Utc::now(),
            updated_by: None,
        }
    }
    
    fn create_test_role() -> AdminRole {
        AdminRole {
            id: 5,
            role_name: "root_administrator".to_string(),
            role_level: 5,
            display_name: "Root Administrator".to_string(),
            description: Some("Full system access".to_string()),
            is_active: true,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        }
    }
    
    fn create_test_permissions() -> Vec<AdminPermission> {
        vec![
            AdminPermission {
                id: 1,
                permission_name: "admin_login".to_string(),
                category: "auth".to_string(),
                description: Some("Can log into admin portal".to_string()),
                requires_min_level: 1,
                is_active: true,
                created_at: Utc::now(),
                updated_at: Utc::now(),
            },
            AdminPermission {
                id: 2,
                permission_name: "admin_accounts_manage".to_string(),
                category: "admin_management".to_string(),
                description: Some("Can manage admin accounts".to_string()),
                requires_min_level: 5,
                is_active: true,
                created_at: Utc::now(),
                updated_at: Utc::now(),
            },
        ]
    }
    
    #[test]
    fn test_admin_jwt_generation_and_validation() {
        let service = AdminJwtService::new();
        let admin = create_test_admin();
        let role = create_test_role();
        let permissions = create_test_permissions();
        
        // Generate token
        let token_pair = service.generate_admin_token(
            &admin, 
            &role, 
            &permissions, 
            false, 
            Some("192.168.1.100")
        ).unwrap();
        
        // Verify token
        let claims = service.verify_admin_token(&token_pair.access_token).unwrap();
        
        assert_eq!(claims.admin_id, admin.id.to_string());
        assert_eq!(claims.email, admin.email);
        assert_eq!(claims.role, role.role_name);
        assert_eq!(claims.role_level, role.role_level);
        assert_eq!(claims.permissions.len(), 2);
        assert!(claims.permissions.contains(&"admin_login".to_string()));
        assert!(claims.permissions.contains(&"admin_accounts_manage".to_string()));
        assert_eq!(claims.is_root_admin, true);
        assert_eq!(claims.mfa_verified, false);
    }
    
    #[test]
    fn test_admin_refresh_token_validation() {
        let service = AdminJwtService::new();
        let admin = create_test_admin();
        let role = create_test_role();
        let permissions = create_test_permissions();
        
        let token_pair = service.generate_admin_token(&admin, &role, &permissions, true, None).unwrap();
        let refresh_claims = service.verify_admin_refresh_token(&token_pair.refresh_token).unwrap();
        
        assert_eq!(refresh_claims.admin_id, admin.id.to_string());
        assert_eq!(refresh_claims.token_type, "refresh");
        assert_eq!(refresh_claims.login_count, admin.login_count);
    }
    
    #[test]
    fn test_permission_checking() {
        let service = AdminJwtService::new();
        let admin = create_test_admin();
        let role = create_test_role();
        let permissions = create_test_permissions();
        
        let token_pair = service.generate_admin_token(&admin, &role, &permissions, true, None).unwrap();
        let claims = service.verify_admin_token(&token_pair.access_token).unwrap();
        
        assert!(service.has_permission(&claims, "admin_login"));
        assert!(service.has_permission(&claims, "admin_accounts_manage"));
        assert!(!service.has_permission(&claims, "non_existent_permission"));
        
        assert!(service.has_min_role_level(&claims, 1));
        assert!(service.has_min_role_level(&claims, 5));
        assert!(!service.has_min_role_level(&claims, 6));
    }
}