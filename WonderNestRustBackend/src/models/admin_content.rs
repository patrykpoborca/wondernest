use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

// Use Decimal from rust_decimal for PostgreSQL numeric types
use rust_decimal::Decimal;
use std::str::FromStr;

// =============================================================================
// ADMIN CREATOR MODELS
// =============================================================================

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct AdminCreator {
    pub id: Uuid,
    pub email: String,
    pub display_name: String,
    pub creator_type: CreatorType,
    pub avatar_url: Option<String>,
    pub bio: Option<String>,
    pub website_url: Option<String>,
    pub is_active: bool,
    pub can_publish_directly: bool,
    pub created_by: Option<Uuid>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "varchar", rename_all = "lowercase")]
pub enum CreatorType {
    Admin,
    Staff,
    Invited,
    Partner,
}

impl std::fmt::Display for CreatorType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            CreatorType::Admin => write!(f, "admin"),
            CreatorType::Staff => write!(f, "staff"),
            CreatorType::Invited => write!(f, "invited"),
            CreatorType::Partner => write!(f, "partner"),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateAdminCreatorRequest {
    pub email: String,
    pub display_name: String,
    pub creator_type: Option<CreatorType>,
    pub avatar_url: Option<String>,
    pub bio: Option<String>,
    pub website_url: Option<String>,
    pub can_publish_directly: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateAdminCreatorRequest {
    pub display_name: Option<String>,
    pub avatar_url: Option<String>,
    pub bio: Option<String>,
    pub website_url: Option<String>,
    pub is_active: Option<bool>,
    pub can_publish_directly: Option<bool>,
}

// =============================================================================
// CONTENT STAGING MODELS
// =============================================================================

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct AdminContentStaging {
    pub id: Uuid,
    pub creator_id: Uuid,
    pub content_type: ContentType,
    pub title: String,
    pub description: Option<String>,
    pub content_data: serde_json::Value,
    pub files: Option<serde_json::Value>, // File URLs as JSON object
    pub price: Option<Decimal>,
    pub currency: Option<String>,
    pub age_range_min: Option<i32>,
    pub age_range_max: Option<i32>,
    pub tags: Option<Vec<String>>,
    pub search_keywords: Option<Vec<String>>,
    pub status: ContentStatus,
    pub marketplace_listing_id: Option<Uuid>,
    pub published_at: Option<DateTime<Utc>>,
    pub published_by: Option<Uuid>,
    pub bulk_import_batch_id: Option<Uuid>,
    pub import_source: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "varchar", rename_all = "lowercase")]
pub enum ContentType {
    Story,
    StickerPack,
    Game,
    Activity,
    EducationalPack,
    Template,
}

impl std::fmt::Display for ContentType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ContentType::Story => write!(f, "story"),
            ContentType::StickerPack => write!(f, "sticker_pack"),
            ContentType::Game => write!(f, "game"),
            ContentType::Activity => write!(f, "activity"),
            ContentType::EducationalPack => write!(f, "educational_pack"),
            ContentType::Template => write!(f, "template"),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type, PartialEq)]
#[sqlx(type_name = "varchar", rename_all = "lowercase")]
pub enum ContentStatus {
    Draft,
    Ready,
    Published,
    Archived,
}

impl std::fmt::Display for ContentStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ContentStatus::Draft => write!(f, "draft"),
            ContentStatus::Ready => write!(f, "ready"),
            ContentStatus::Published => write!(f, "published"),
            ContentStatus::Archived => write!(f, "archived"),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentFiles {
    pub main: Option<String>,      // Main content file URL
    pub thumbnail: Option<String>, // Thumbnail image URL
    pub additional: Vec<String>,   // Additional files (preview images, etc.)
}

impl Default for ContentFiles {
    fn default() -> Self {
        Self {
            main: None,
            thumbnail: None,
            additional: Vec::new(),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateContentRequest {
    pub creator_id: Uuid,
    pub content_type: ContentType,
    pub title: String,
    pub description: Option<String>,
    pub content_data: serde_json::Value,
    pub price: Decimal,
    pub currency: Option<String>,
    pub age_range_min: Option<i32>,
    pub age_range_max: Option<i32>,
    pub tags: Vec<String>,
    pub search_keywords: Vec<String>,
    pub files: ContentFiles,
    pub bulk_import_batch_id: Option<Uuid>,
    pub import_source: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateContentRequest {
    pub title: Option<String>,
    pub description: Option<String>,
    pub content_data: Option<serde_json::Value>,
    pub price: Option<Decimal>,
    pub currency: Option<String>,
    pub age_range_min: Option<i32>,
    pub age_range_max: Option<i32>,
    pub tags: Option<Vec<String>>,
    pub search_keywords: Option<Vec<String>>,
    pub files: Option<ContentFiles>,
    pub status: Option<ContentStatus>,
}

// =============================================================================
// BULK IMPORT MODELS
// =============================================================================

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct AdminBulkImport {
    pub id: Uuid,
    pub batch_id: Uuid,
    pub initiated_by: Uuid,
    pub import_type: String,
    pub source_filename: Option<String>,
    pub total_items: Option<i32>,
    pub processed_items: Option<i32>,
    pub successful_items: Option<i32>,
    pub failed_items: Option<i32>,
    pub status: Option<BulkImportStatus>,
    pub error_log: Option<serde_json::Value>,
    pub success_log: Option<serde_json::Value>,
    pub started_at: Option<DateTime<Utc>>,
    pub completed_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "varchar", rename_all = "lowercase")]
pub enum BulkImportStatus {
    Processing,
    Completed,
    Failed,
    Cancelled,
}

impl std::fmt::Display for BulkImportStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            BulkImportStatus::Processing => write!(f, "processing"),
            BulkImportStatus::Completed => write!(f, "completed"),
            BulkImportStatus::Failed => write!(f, "failed"),
            BulkImportStatus::Cancelled => write!(f, "cancelled"),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BulkImportRequest {
    pub import_type: String,
    pub source_filename: Option<String>,
    pub items: Vec<CreateContentRequest>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BulkImportResponse {
    pub batch_id: Uuid,
    pub status: BulkImportStatus,
    pub total_items: i32,
    pub processed_items: i32,
    pub successful_items: i32,
    pub failed_items: i32,
    pub errors: Vec<String>,
}

// =============================================================================
// CONTENT PUBLISHING MODELS
// =============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PublishContentRequest {
    pub content_id: Uuid,
    pub publish_now: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PublishContentResponse {
    pub content_id: Uuid,
    pub marketplace_listing_id: Uuid,
    pub status: String,
    pub published_at: DateTime<Utc>,
    pub marketplace_url: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BulkPublishRequest {
    pub content_ids: Vec<Uuid>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BulkPublishResponse {
    pub total_requested: i32,
    pub successful: i32,
    pub failed: i32,
    pub results: Vec<PublishResult>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PublishResult {
    pub content_id: Uuid,
    pub success: bool,
    pub marketplace_listing_id: Option<Uuid>,
    pub error: Option<String>,
}

// =============================================================================
// DASHBOARD METRICS MODELS
// =============================================================================

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct AdminSeedingMetrics {
    pub seed_date: chrono::NaiveDate,
    pub content_type: String,
    pub status: String,
    pub import_source: Option<String>,
    pub items_count: i64,
    pub published_count: i64,
    pub avg_price: Option<Decimal>,
    pub min_price: Option<Decimal>,
    pub max_price: Option<Decimal>,
    pub creators_used: Vec<Uuid>,
    pub first_created: DateTime<Utc>,
    pub last_created: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentListRequest {
    pub creator_id: Option<Uuid>,
    pub content_type: Option<ContentType>,
    pub status: Option<ContentStatus>,
    pub search: Option<String>,
    pub page: Option<i32>,
    pub limit: Option<i32>,
    pub sort_by: Option<String>, // "created_at", "updated_at", "title", "price"
    pub sort_order: Option<String>, // "asc", "desc"
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentListResponse {
    pub items: Vec<AdminContentStaging>,
    pub total_count: i64,
    pub page: i32,
    pub total_pages: i32,
    pub has_next: bool,
    pub has_previous: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DashboardStatsResponse {
    pub total_content: i64,
    pub published_content: i64,
    pub draft_content: i64,
    pub total_creators: i64,
    pub active_creators: i64,
    pub recent_uploads: i64,
    pub avg_price: Decimal,
    pub total_value: Decimal,
}

// =============================================================================
// CSV IMPORT MODELS
// =============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CsvContentRow {
    pub title: String,
    pub description: Option<String>,
    pub content_type: String,
    pub price: String, // Will be parsed to BigDecimal
    pub age_min: Option<String>, // Will be parsed to i32
    pub age_max: Option<String>, // Will be parsed to i32
    pub tags: String, // Comma-separated tags
    pub main_file: Option<String>, // File path or URL
    pub thumbnail_file: Option<String>, // File path or URL
}

impl CsvContentRow {
    pub fn to_create_content_request(
        &self,
        creator_id: Uuid,
        batch_id: Option<Uuid>,
    ) -> Result<CreateContentRequest, String> {
        let content_type = match self.content_type.to_lowercase().as_str() {
            "story" => ContentType::Story,
            "sticker_pack" => ContentType::StickerPack,
            "game" => ContentType::Game,
            "activity" => ContentType::Activity,
            "educational_pack" => ContentType::EducationalPack,
            "template" => ContentType::Template,
            _ => return Err(format!("Invalid content type: {}", self.content_type)),
        };

        let price = Decimal::from_str(&self.price)
            .map_err(|_| format!("Invalid price: {}", self.price))?;

        let age_range_min = if let Some(age_str) = &self.age_min {
            Some(age_str.parse::<i32>()
                .map_err(|_| format!("Invalid age_min: {}", age_str))?)
        } else {
            None
        };

        let age_range_max = if let Some(age_str) = &self.age_max {
            Some(age_str.parse::<i32>()
                .map_err(|_| format!("Invalid age_max: {}", age_str))?)
        } else {
            None
        };

        let tags: Vec<String> = self.tags
            .split(',')
            .map(|tag| tag.trim().to_string())
            .filter(|tag| !tag.is_empty())
            .collect();

        let search_keywords = tags.clone(); // Use tags as search keywords for now

        let files = ContentFiles {
            main: self.main_file.clone(),
            thumbnail: self.thumbnail_file.clone(),
            additional: Vec::new(),
        };

        Ok(CreateContentRequest {
            creator_id,
            content_type,
            title: self.title.clone(),
            description: self.description.clone(),
            content_data: serde_json::json!({}), // Empty for now
            price,
            currency: Some("USD".to_string()),
            age_range_min,
            age_range_max,
            tags,
            search_keywords,
            files,
            bulk_import_batch_id: batch_id,
            import_source: Some("csv".to_string()),
        })
    }
}