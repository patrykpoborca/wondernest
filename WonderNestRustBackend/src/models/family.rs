use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

// Removed duplicate Family struct - using the one in user.rs which matches DB schema

// Request model for creating child profiles (matching Flutter app request)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateChildRequest {
    pub name: String,
    #[serde(rename = "birthDate")]
    pub birth_date: String, // Date in YYYY-MM-DD format
    pub gender: String,
    pub interests: Vec<String>,
    pub avatar: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Child {
    pub id: Uuid,
    pub family_id: Uuid,
    pub name: String,
    pub birth_date: chrono::NaiveDate,
    pub avatar_url: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}