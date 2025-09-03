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

// Simple game data models for the API routes (matching Kotlin exactly)

// Save game data request (matching Kotlin SaveGameDataRequest)
#[derive(Debug, Serialize, Deserialize)]
pub struct SaveGameDataRequest {
    #[serde(rename = "gameType")]
    pub game_type: String,
    #[serde(rename = "dataKey")]
    pub data_key: String,
    #[serde(rename = "dataValue")]
    pub data_value: serde_json::Value, // Map<String, JsonElement> from Kotlin
}

// Game data response (matching Kotlin GameDataResponse)
#[derive(Debug, Serialize, Deserialize)]
pub struct GameDataResponse {
    pub success: bool,
    pub message: String,
    #[serde(rename = "childId")]
    pub child_id: String,
    #[serde(rename = "gameType")]
    pub game_type: String,
    #[serde(rename = "dataKey")]
    pub data_key: Option<String>,
}

// Game data item (matching Kotlin GameDataItem)
#[derive(Debug, Serialize, Deserialize)]
pub struct GameDataItem {
    pub id: String,
    #[serde(rename = "childId")]
    pub child_id: String,
    #[serde(rename = "gameType")]
    pub game_type: String,
    #[serde(rename = "dataKey")]
    pub data_key: String,
    #[serde(rename = "dataValue")]
    pub data_value: serde_json::Value,
    #[serde(rename = "createdAt")]
    pub created_at: String,
    #[serde(rename = "updatedAt")]
    pub updated_at: String,
}

// Load game data response (matching Kotlin LoadGameDataResponse)
#[derive(Debug, Serialize, Deserialize)]
pub struct LoadGameDataResponse {
    pub success: bool,
    #[serde(rename = "gameData")]
    pub game_data: Vec<GameDataItem>,
}

// Database model for simple game data (matching the games.simple_game_data table)
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct SimpleGameData {
    pub id: Uuid,
    pub child_id: Uuid,
    pub game_type: String,
    pub data_key: String,
    pub data_value: serde_json::Value, // JSONB in PostgreSQL
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}