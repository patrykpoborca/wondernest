use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

// User model matching the core.users table exactly
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct User {
    pub id: Uuid,
    pub email: String,
    pub password_hash: String,
    pub first_name: Option<String>,
    pub last_name: Option<String>,
    pub phone: Option<String>,
    pub email_verified: bool,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub role: String,
    pub pin_hash: Option<String>,
    pub family_id: Option<Uuid>,
}

// User session model matching the core.user_sessions table exactly
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct UserSession {
    pub id: Uuid,
    pub user_id: Uuid,
    pub token_hash: String,
    pub expires_at: DateTime<Utc>,
    pub created_at: DateTime<Utc>,
    pub last_accessed: DateTime<Utc>,
    pub device_info: Option<serde_json::Value>,
}

// Password reset token model matching the core.password_reset_tokens table exactly
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct PasswordResetToken {
    pub id: Uuid,
    pub user_id: Uuid,
    pub token: String,
    pub used: bool,
    pub expires_at: DateTime<Utc>,
    pub created_at: DateTime<Utc>,
}

// Family model matching the family.families table exactly
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Family {
    pub id: Uuid,
    pub name: String, // "The Smith Family"
    pub created_by: Option<Uuid>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// Family member model matching the family.family_members table exactly
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct FamilyMember {
    pub id: Uuid,
    pub family_id: Uuid,
    pub user_id: Uuid,
    pub role: String, // parent, guardian, caregiver
    pub joined_at: DateTime<Utc>,
}

// Child profile model matching the family.child_profiles table exactly
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ChildProfile {
    pub id: Uuid,
    pub family_id: Uuid,
    pub name: String,
    pub nickname: Option<String>,
    pub birth_date: chrono::NaiveDate,
    pub gender: Option<String>,
    pub avatar_url: Option<String>,
    pub interests: Option<Vec<String>>,
    pub favorite_colors: Option<Vec<String>>,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub archived_at: Option<DateTime<Utc>>,
}

// For simplified responses and internal use
#[derive(Debug, Serialize, Deserialize)]
pub struct UserInfo {
    pub id: Uuid,
    pub email: String,
    pub first_name: Option<String>,
    pub last_name: Option<String>,
    pub role: String,
    pub email_verified: bool,
}

impl From<User> for UserInfo {
    fn from(user: User) -> Self {
        Self {
            id: user.id,
            email: user.email,
            first_name: user.first_name,
            last_name: user.last_name,
            role: user.role,
            email_verified: user.email_verified,
        }
    }
}

// For creating new users
#[derive(Debug, Clone)]
pub struct NewUser {
    pub id: Uuid,
    pub email: String,
    pub email_verified: bool,
    pub auth_provider: String,
    pub first_name: Option<String>,
    pub last_name: Option<String>,
    pub timezone: String,
    pub language: String,
    pub status: String,
    pub role: String,
    pub privacy_settings: serde_json::Value,
    pub notification_preferences: serde_json::Value,
    pub parental_consent_verified: bool,
}

impl Default for NewUser {
    fn default() -> Self {
        Self {
            id: Uuid::new_v4(),
            email: String::new(),
            email_verified: false,
            auth_provider: "email".to_string(),
            first_name: None,
            last_name: None,
            timezone: "UTC".to_string(),
            language: "en".to_string(),
            status: "pending_verification".to_string(),
            role: "parent".to_string(),
            privacy_settings: serde_json::json!({}),
            notification_preferences: serde_json::json!({"email": true, "push": true, "sms": false}),
            parental_consent_verified: false,
        }
    }
}