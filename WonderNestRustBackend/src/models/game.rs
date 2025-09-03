use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value as JsonValue;
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct GameRegistry {
    pub id: Uuid,
    pub game_identifier: String,
    pub name: String,
    pub description: String,
    pub category: String,
    pub age_min: i32,
    pub age_max: i32,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ChildGameInstance {
    pub id: Uuid,
    pub child_id: Uuid,
    pub game_id: Uuid,
    pub is_enabled: bool,
    pub unlocked_at: DateTime<Utc>,
    pub last_played: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ChildGameData {
    pub id: Uuid,
    pub child_game_instance_id: Uuid,
    pub save_data: JsonValue,
    pub version: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}