use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use rust_decimal::Decimal;

// =============================================================================
// CONTENT CATALOG MODELS  
// =============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentCatalogRequest {
    pub child_id: Uuid,
    #[serde(rename = "type")]
    pub content_type: Option<String>,
    pub category: Option<String>,
    pub age_min: Option<i32>,
    pub age_max: Option<i32>,
    pub search: Option<String>,
    pub sort: Option<String>, // popular, newest, rating, alphabetical
    pub page: Option<i32>,
    pub limit: Option<i32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EcosystemContentItem {
    pub id: Uuid,
    #[serde(rename = "type")]
    pub content_type: String,
    pub title: String,
    pub description: String,
    pub thumbnail_url: String,
    pub age_range: AgeRange,
    pub rating: f64,
    pub price: i32, // Price in cents
    pub currency: String,
    pub is_free: bool,
    pub is_owned: bool,
    pub download_size: i64,
    pub metadata: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AgeRange {
    pub min: i32,
    pub max: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Pagination {
    pub page: i32,
    pub limit: i32,
    pub total: i64,
    pub has_more: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentCatalogResponse {
    pub content: Vec<EcosystemContentItem>,
    pub pagination: Pagination,
}

// =============================================================================
// FEATURED CONTENT MODELS
// =============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FeaturedSection {
    pub title: String,
    pub content: Vec<EcosystemContentItem>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FeaturedContentResponse {
    pub featured: FeaturedSection,
    pub recommended: FeaturedSection,
    pub new_releases: FeaturedSection,
    pub trending: FeaturedSection,
}

// =============================================================================
// CONTENT LIBRARY MODELS
// =============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LibraryItem {
    pub content_id: Uuid,
    pub acquired_at: DateTime<Utc>,
    pub last_used: Option<DateTime<Utc>>,
    pub usage_count: i32,
    pub is_favorite: bool,
    pub download_status: String, // downloaded, downloading, pending
    pub local_path: Option<String>,
    pub content: EcosystemContentItem,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LibraryStats {
    pub total_items: i32,
    pub total_size: i64,
    pub favorites: i32,
    pub recently_used: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentLibraryResponse {
    pub owned_content: Vec<LibraryItem>,
    pub statistics: LibraryStats,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AddToLibraryRequest {
    pub content_id: Uuid,
    pub acquisition_type: String, // purchase, grant, subscription
    pub payment_method: Option<String>, // parent_wallet, subscription, free
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AddToLibraryResponse {
    pub success: bool,
    pub library_item: LibraryItem,
}

// =============================================================================
// CONTENT DOWNLOAD MODELS
// =============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DownloadChunk {
    pub id: i32,
    pub url: String,
    pub size: i64,
    pub hash: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentMetadata {
    pub version: String,
    pub dependencies: Vec<String>,
    pub install_size: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentDownloadResponse {
    pub download_url: String,
    pub expires_at: DateTime<Utc>,
    pub content_hash: String,
    pub chunks: Vec<DownloadChunk>,
    pub metadata: ContentMetadata,
}

// =============================================================================
// SYNC MODELS
// =============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LocalContentItem {
    pub content_id: Uuid,
    pub version: String,
    pub last_modified: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncRequest {
    pub child_id: Uuid,
    pub device_id: String,
    pub local_content: Vec<LocalContentItem>,
    pub storage_available: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncAction {
    pub content_id: Uuid,
    pub version: Option<String>,
    pub priority: String, // high, medium, low
    pub reason: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncResponse {
    pub to_download: Vec<SyncAction>,
    pub to_delete: Vec<SyncAction>,
    pub sync_token: String,
}

// =============================================================================
// RECOMMENDATION MODELS
// =============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecommendationItem {
    pub content: EcosystemContentItem,
    pub reason: String,
    pub confidence: f64,
    pub explanation: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecommendationsResponse {
    pub recommendations: Vec<RecommendationItem>,
    pub interests_detected: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FeedbackRequest {
    pub child_id: Uuid,
    pub content_id: Uuid,
    pub feedback_type: String, // like, dislike, rating, usage
    pub value: Option<i32>,
    pub metadata: Option<serde_json::Value>,
}

// =============================================================================
// ERROR TYPES
// =============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentError {
    pub error: String,
    pub message: String,
    pub code: Option<i32>,
}

impl ContentError {
    pub fn new(error: &str, message: &str) -> Self {
        Self {
            error: error.to_string(),
            message: message.to_string(),
            code: None,
        }
    }
    
    pub fn with_code(error: &str, message: &str, code: i32) -> Self {
        Self {
            error: error.to_string(),
            message: message.to_string(),
            code: Some(code),
        }
    }
}