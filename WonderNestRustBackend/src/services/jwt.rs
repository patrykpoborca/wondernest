use chrono::{Duration, Utc};
use jsonwebtoken::{decode, encode, Algorithm, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use std::env;
use uuid::Uuid;

use crate::models::{TokenPair, User};

#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String,       // Subject (user ID)
    #[serde(rename = "userId")]
    pub user_id: String,
    pub email: String,
    pub role: String,
    pub verified: bool,
    pub nonce: String,     // Unique token identifier
    #[serde(rename = "familyId", skip_serializing_if = "Option::is_none")]
    pub family_id: Option<String>,
    pub iss: String,       // Issuer
    pub aud: String,       // Audience
    pub iat: i64,          // Issued at
    pub exp: i64,          // Expires at
}

#[derive(Debug, Serialize, Deserialize)]
pub struct RefreshClaims {
    pub sub: String,       // Subject (user ID)
    #[serde(rename = "userId")]
    pub user_id: String,
    #[serde(rename = "type")]
    pub token_type: String,
    pub nonce: String,     // Unique token identifier
    #[serde(rename = "familyId", skip_serializing_if = "Option::is_none")]
    pub family_id: Option<String>,
    pub iss: String,       // Issuer
    pub aud: String,       // Audience
    pub iat: i64,          // Issued at
    pub exp: i64,          // Expires at
}

pub struct JwtService {
    secret: Vec<u8>,
    issuer: String,
    audience: String,
    expires_in_ms: i64,
    refresh_expires_in_ms: i64,
}

impl JwtService {
    pub fn new() -> Self {
        let secret = env::var("JWT_SECRET")
            .unwrap_or_else(|_| "your-super-secret-jwt-key-change-this-in-production".to_string())
            .into_bytes();
        let issuer = env::var("JWT_ISSUER").unwrap_or_else(|_| "wondernest-api".to_string());
        let audience = env::var("JWT_AUDIENCE").unwrap_or_else(|_| "wondernest-users".to_string());
        
        // Default to 1 hour for access tokens, 30 days for refresh tokens (matching Kotlin)
        let expires_in_ms = env::var("JWT_EXPIRES_IN")
            .unwrap_or_else(|_| "3600000".to_string())
            .parse()
            .unwrap_or(3600000); // 1 hour
        
        let refresh_expires_in_ms = env::var("JWT_REFRESH_EXPIRES_IN")
            .unwrap_or_else(|_| "2592000000".to_string())
            .parse()
            .unwrap_or(2592000000); // 30 days

        Self {
            secret,
            issuer,
            audience,
            expires_in_ms,
            refresh_expires_in_ms,
        }
    }

    pub fn generate_token(&self, user: &User) -> anyhow::Result<TokenPair> {
        let now = Utc::now();
        let nonce = Uuid::new_v4().to_string();
        let refresh_nonce = Uuid::new_v4().to_string();
        
        let expires_at = now + Duration::milliseconds(self.expires_in_ms);
        let refresh_expires_at = now + Duration::milliseconds(self.refresh_expires_in_ms);

        // Create access token claims (matching Kotlin structure exactly)
        let claims = Claims {
            sub: user.id.to_string(),
            user_id: user.id.to_string(),
            email: user.email.clone(),
            role: user.role.clone(),
            verified: user.email_verified,
            nonce,
            family_id: None, // No family context for regular login
            iss: self.issuer.clone(),
            aud: self.audience.clone(),
            iat: now.timestamp(),
            exp: expires_at.timestamp(),
        };

        // Create refresh token claims
        let refresh_claims = RefreshClaims {
            sub: user.id.to_string(),
            user_id: user.id.to_string(),
            token_type: "refresh".to_string(),
            nonce: refresh_nonce,
            family_id: None,
            iss: self.issuer.clone(),
            aud: format!("{}-refresh", self.audience),
            iat: now.timestamp(),
            exp: refresh_expires_at.timestamp(),
        };

        let header = Header::new(Algorithm::HS256);
        let encoding_key = EncodingKey::from_secret(&self.secret);

        let access_token = encode(&header, &claims, &encoding_key)?;
        let refresh_token = encode(&header, &refresh_claims, &encoding_key)?;

        Ok(TokenPair {
            access_token,
            refresh_token,
            expires_in: self.expires_in_ms,
        })
    }

    pub fn generate_token_with_family_context(&self, user: &User, family_id: Uuid) -> anyhow::Result<TokenPair> {
        let now = Utc::now();
        let nonce = Uuid::new_v4().to_string();
        let refresh_nonce = Uuid::new_v4().to_string();
        
        let expires_at = now + Duration::milliseconds(self.expires_in_ms);
        let refresh_expires_at = now + Duration::milliseconds(self.refresh_expires_in_ms);

        // Create access token claims with family context (matching Kotlin structure exactly)
        let claims = Claims {
            sub: user.id.to_string(),
            user_id: user.id.to_string(),
            email: user.email.clone(),
            role: user.role.clone(),
            verified: user.email_verified,
            nonce,
            family_id: Some(family_id.to_string()),
            iss: self.issuer.clone(),
            aud: self.audience.clone(),
            iat: now.timestamp(),
            exp: expires_at.timestamp(),
        };

        // Create refresh token claims with family context
        let refresh_claims = RefreshClaims {
            sub: user.id.to_string(),
            user_id: user.id.to_string(),
            token_type: "refresh".to_string(),
            nonce: refresh_nonce,
            family_id: Some(family_id.to_string()),
            iss: self.issuer.clone(),
            aud: format!("{}-refresh", self.audience),
            iat: now.timestamp(),
            exp: refresh_expires_at.timestamp(),
        };

        let header = Header::new(Algorithm::HS256);
        let encoding_key = EncodingKey::from_secret(&self.secret);

        let access_token = encode(&header, &claims, &encoding_key)?;
        let refresh_token = encode(&header, &refresh_claims, &encoding_key)?;

        Ok(TokenPair {
            access_token,
            refresh_token,
            expires_in: self.expires_in_ms,
        })
    }

    pub fn verify_token(&self, token: &str) -> anyhow::Result<Claims> {
        let decoding_key = DecodingKey::from_secret(&self.secret);
        
        let mut validation = Validation::new(Algorithm::HS256);
        validation.set_issuer(&[&self.issuer]);
        validation.set_audience(&[&self.audience]);
        
        let token_data = decode::<Claims>(token, &decoding_key, &validation)?;
        Ok(token_data.claims)
    }

    pub fn verify_refresh_token(&self, token: &str) -> anyhow::Result<String> {
        let decoding_key = DecodingKey::from_secret(&self.secret);
        
        let mut validation = Validation::new(Algorithm::HS256);
        validation.set_issuer(&[&self.issuer]);
        validation.set_audience(&[&format!("{}-refresh", self.audience)]);
        
        let token_data = decode::<RefreshClaims>(token, &decoding_key, &validation)?;
        
        if token_data.claims.token_type != "refresh" {
            return Err(anyhow::anyhow!("Invalid token type"));
        }
        
        Ok(token_data.claims.user_id)
    }

    pub fn extract_user_id_from_token(&self, token: &str) -> Option<String> {
        // Decode without validation for extraction (matching Kotlin behavior)
        match jsonwebtoken::decode::<Claims>(
            token, 
            &DecodingKey::from_secret(&self.secret), 
            &Validation::default()
        ) {
            Ok(token_data) => Some(token_data.claims.user_id),
            Err(_) => None,
        }
    }

    pub fn extract_role_from_token(&self, token: &str) -> Option<String> {
        match jsonwebtoken::decode::<Claims>(
            token, 
            &DecodingKey::from_secret(&self.secret), 
            &Validation::default()
        ) {
            Ok(token_data) => Some(token_data.claims.role),
            Err(_) => None,
        }
    }

    pub fn extract_family_id_from_token(&self, token: &str) -> Option<String> {
        match jsonwebtoken::decode::<Claims>(
            token, 
            &DecodingKey::from_secret(&self.secret), 
            &Validation::default()
        ) {
            Ok(token_data) => token_data.claims.family_id,
            Err(_) => None,
        }
    }
}