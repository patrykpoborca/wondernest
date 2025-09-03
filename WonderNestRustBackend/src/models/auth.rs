use serde::{Deserialize, Serialize};
use uuid::Uuid;

// Request structures (matching Kotlin exactly)
#[derive(Debug, Serialize, Deserialize)]
pub struct SignupRequest {
    pub email: String,
    pub password: String,
    pub name: Option<String>, // Combined name for Flutter compatibility
    #[serde(rename = "firstName")]
    pub first_name: Option<String>,
    #[serde(rename = "lastName")]
    pub last_name: Option<String>,
    #[serde(rename = "phoneNumber")]
    pub phone_number: Option<String>,
    #[serde(rename = "countryCode")]
    pub country_code: String,
    pub timezone: String,
    pub language: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct LoginRequest {
    pub email: String,
    pub password: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct RefreshTokenRequest {
    #[serde(rename = "refreshToken")]
    pub refresh_token: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PinVerificationRequest {
    pub pin: String,
}

// Response structures (matching Kotlin exactly)
#[derive(Debug, Serialize, Deserialize)]
pub struct AuthResponse {
    pub success: bool,
    pub data: AuthData,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AuthData {
    #[serde(rename = "userId")]
    pub user_id: String,
    pub email: String,
    #[serde(rename = "accessToken")]
    pub access_token: String,
    #[serde(rename = "refreshToken")]
    pub refresh_token: String,
    #[serde(rename = "expiresIn")]
    pub expires_in: i64,
    #[serde(rename = "hasPin")]
    pub has_pin: bool,
    #[serde(rename = "requiresPinSetup")]
    pub requires_pin_setup: bool,
    pub children: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PinVerificationResponse {
    pub verified: bool,
    pub message: String,
    #[serde(rename = "sessionToken", skip_serializing_if = "Option::is_none")]
    pub session_token: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct MessageResponse {
    pub message: String,
}

// Internal structures
#[derive(Debug, Clone)]
pub struct TokenPair {
    pub access_token: String,
    pub refresh_token: String,
    pub expires_in: i64,
}

// Default implementations to match Kotlin behavior
impl Default for SignupRequest {
    fn default() -> Self {
        Self {
            email: String::new(),
            password: String::new(),
            name: None,
            first_name: None,
            last_name: None,
            phone_number: None,
            country_code: "US".to_string(),
            timezone: "UTC".to_string(),
            language: "en".to_string(),
        }
    }
}

impl AuthResponse {
    pub fn success(data: AuthData) -> Self {
        Self {
            success: true,
            data,
        }
    }
}