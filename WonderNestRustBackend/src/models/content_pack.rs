use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value as JsonValue;
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ContentPack {
    pub id: Uuid,
    pub name: String,
    pub description: String,
    pub category: String,
    pub pack_type: String,
    pub age_min: i32,
    pub age_max: i32,
    pub price: i32,
    pub is_free: bool,
    pub preview_assets: JsonValue,
    pub educational_goals: Vec<String>,
    pub tags: Vec<String>,
    pub downloads: i32,
    pub rating: f32,
    pub version: String,
    pub size_mb: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub publisher_id: Option<Uuid>,
    pub is_featured: bool,
    pub featured_until: Option<DateTime<Utc>>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ContentPackCategory {
    pub id: String,
    pub name: String,
    pub icon: String,
    pub description: String,
    pub pack_count: i32,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ContentPackResponse<T> {
    pub success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub data: Option<T>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CategoriesData {
    pub categories: Vec<ContentPackCategory>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PacksData {
    pub packs: Vec<ContentPack>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ContentPackSearchRequest {
    pub query: Option<String>,
    pub category: Option<String>,
    pub pack_type: Option<String>,
    pub age_min: Option<i32>,
    pub age_max: Option<i32>,
    pub price_min: Option<i32>,
    pub price_max: Option<i32>,
    pub is_free: Option<bool>,
    pub educational_goals: Vec<String>,
    pub sort_by: String,
    pub sort_order: String,
    pub page: i32,
    pub size: i32,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ContentPackSearchResponse {
    pub packs: Vec<ContentPack>,
    pub total: i64,
    pub page: i32,
    pub size: i32,
    pub total_pages: i32,
}