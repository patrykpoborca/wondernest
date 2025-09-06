use chrono::{DateTime, Utc};
use hmac::{Hmac, Mac};
use sha2::Sha256;
use uuid::Uuid;
use base64::{Engine as _, engine::general_purpose};
use serde::{Deserialize, Serialize};
use crate::error::{AppError, AppResult};

type HmacSha256 = Hmac<Sha256>;

#[derive(Clone)]
pub struct SignedUrlService {
    secret_key: String,
    default_expiry_hours: i64,
}

#[derive(Serialize, Deserialize)]
pub struct SignedUrlPayload {
    pub file_id: String,
    pub user_id: String,
    pub expires_at: DateTime<Utc>,
    pub action: String, // "view" or "download"
}

impl SignedUrlService {
    pub fn new(secret_key: String, default_expiry_hours: Option<i64>) -> Self {
        Self {
            secret_key,
            default_expiry_hours: default_expiry_hours.unwrap_or(24), // 24 hours default
        }
    }

    /// Generate a signed URL for family file access
    pub fn generate_signed_url(
        &self,
        file_id: Uuid,
        user_id: Uuid,
        action: &str,
        base_url: &str,
        expiry_hours: Option<i64>,
    ) -> AppResult<String> {
        let expires_at = Utc::now() + chrono::Duration::hours(
            expiry_hours.unwrap_or(self.default_expiry_hours)
        );

        let payload = SignedUrlPayload {
            file_id: file_id.to_string(),
            user_id: user_id.to_string(),
            expires_at,
            action: action.to_string(),
        };

        // Serialize payload to JSON
        let payload_json = serde_json::to_string(&payload).map_err(|e| {
            tracing::error!("Failed to serialize signed URL payload: {}", e);
            AppError::InternalError("Failed to generate signed URL".to_string())
        })?;

        // Encode payload as base64
        let payload_b64 = general_purpose::URL_SAFE_NO_PAD.encode(payload_json.as_bytes());

        // Generate HMAC signature
        let signature = self.generate_signature(&payload_b64)?;

        // Construct final signed URL
        let signed_url = format!(
            "{}/api/v1/files/{}/signed?payload={}&signature={}",
            base_url.trim_end_matches('/'),
            file_id,
            payload_b64,
            signature
        );

        tracing::debug!("Generated signed URL for file {} (expires: {})", file_id, expires_at);
        Ok(signed_url)
    }

    /// Validate a signed URL and return the file info if valid
    pub fn validate_signed_url(
        &self,
        file_id: Uuid,
        payload_b64: &str,
        signature: &str,
    ) -> AppResult<SignedUrlPayload> {
        // Verify signature first
        let expected_signature = self.generate_signature(payload_b64)?;
        if !self.constant_time_compare(&expected_signature, signature) {
            tracing::warn!("Invalid signature for signed URL: file_id={}", file_id);
            return Err(AppError::Unauthorized);
        }

        // Decode and parse payload
        let payload_json = general_purpose::URL_SAFE_NO_PAD
            .decode(payload_b64)
            .map_err(|e| {
                tracing::warn!("Failed to decode signed URL payload: {}", e);
                AppError::BadRequest("Invalid signed URL format".to_string())
            })?;

        let payload_str = String::from_utf8(payload_json).map_err(|e| {
            tracing::warn!("Signed URL payload is not valid UTF-8: {}", e);
            AppError::BadRequest("Invalid signed URL format".to_string())
        })?;

        let payload: SignedUrlPayload = serde_json::from_str(&payload_str).map_err(|e| {
            tracing::warn!("Failed to parse signed URL payload: {}", e);
            AppError::BadRequest("Invalid signed URL format".to_string())
        })?;

        // Verify file ID matches
        let payload_file_id = Uuid::parse_str(&payload.file_id).map_err(|_| {
            AppError::BadRequest("Invalid file ID in signed URL".to_string())
        })?;

        if payload_file_id != file_id {
            tracing::warn!("File ID mismatch in signed URL: expected={}, got={}", file_id, payload_file_id);
            return Err(AppError::BadRequest("File ID mismatch".to_string()));
        }

        // Check expiration
        if payload.expires_at < Utc::now() {
            tracing::info!("Signed URL expired for file {}: expired at {}", file_id, payload.expires_at);
            return Err(AppError::Forbidden("Signed URL has expired".to_string()));
        }

        tracing::debug!("Successfully validated signed URL for file {} by user {}", file_id, payload.user_id);
        Ok(payload)
    }

    /// Generate HMAC signature for payload
    fn generate_signature(&self, payload: &str) -> AppResult<String> {
        let mut mac = HmacSha256::new_from_slice(self.secret_key.as_bytes()).map_err(|e| {
            tracing::error!("Failed to create HMAC: {}", e);
            AppError::InternalError("Signature generation failed".to_string())
        })?;

        mac.update(payload.as_bytes());
        let signature_bytes = mac.finalize().into_bytes();
        let signature = general_purpose::URL_SAFE_NO_PAD.encode(signature_bytes);
        
        Ok(signature)
    }

    /// Constant-time string comparison to prevent timing attacks
    fn constant_time_compare(&self, a: &str, b: &str) -> bool {
        if a.len() != b.len() {
            return false;
        }

        let a_bytes = a.as_bytes();
        let b_bytes = b.as_bytes();
        let mut result = 0u8;

        for i in 0..a_bytes.len() {
            result |= a_bytes[i] ^ b_bytes[i];
        }

        result == 0
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use uuid::Uuid;

    #[test]
    fn test_generate_and_validate_signed_url() {
        let service = SignedUrlService::new("test-secret-key".to_string(), Some(1));
        let file_id = Uuid::new_v4();
        let user_id = Uuid::new_v4();
        
        let signed_url = service.generate_signed_url(
            file_id,
            user_id,
            "view",
            "http://localhost:8080",
            None,
        ).unwrap();

        // Extract payload and signature from URL
        let url_parts: Vec<&str> = signed_url.split(&['?', '&']).collect();
        let mut payload = "";
        let mut signature = "";
        
        for part in url_parts {
            if part.starts_with("payload=") {
                payload = &part[8..];
            } else if part.starts_with("signature=") {
                signature = &part[10..];
            }
        }

        // Validate the signed URL
        let validated_payload = service.validate_signed_url(file_id, payload, signature).unwrap();
        assert_eq!(validated_payload.file_id, file_id.to_string());
        assert_eq!(validated_payload.user_id, user_id.to_string());
        assert_eq!(validated_payload.action, "view");
    }

    #[test]
    fn test_signature_verification_fails_with_wrong_key() {
        let service1 = SignedUrlService::new("secret-key-1".to_string(), Some(1));
        let service2 = SignedUrlService::new("secret-key-2".to_string(), Some(1));
        
        let file_id = Uuid::new_v4();
        let user_id = Uuid::new_v4();
        
        let signed_url = service1.generate_signed_url(
            file_id,
            user_id,
            "view",
            "http://localhost:8080",
            None,
        ).unwrap();

        // Extract payload and signature
        let url_parts: Vec<&str> = signed_url.split(&['?', '&']).collect();
        let mut payload = "";
        let mut signature = "";
        
        for part in url_parts {
            if part.starts_with("payload=") {
                payload = &part[8..];
            } else if part.starts_with("signature=") {
                signature = &part[10..];
            }
        }

        // Try to validate with different service (different key)
        let result = service2.validate_signed_url(file_id, payload, signature);
        assert!(result.is_err());
    }
}