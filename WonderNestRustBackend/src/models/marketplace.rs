use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

// Use BigDecimal directly from the bigdecimal crate for serde support
pub use bigdecimal::BigDecimal;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct CreatorProfile {
    pub id: Uuid,
    pub user_id: Uuid,
    
    // Creator information
    pub display_name: String,
    pub bio: Option<String>,
    pub avatar_url: Option<String>,
    pub cover_image_url: Option<String>,
    pub website_url: Option<String>,
    pub social_links: serde_json::Value,
    
    // Credentials and verification
    pub verified_educator: bool,
    pub educator_credentials: serde_json::Value,
    pub content_specialties: Vec<String>,
    pub languages_supported: Vec<String>,
    
    // Creator tier and status
    pub tier: String,
    pub tier_updated_at: Option<DateTime<Utc>>,
    
    // Performance metrics
    pub total_sales: i32,
    pub total_revenue: BigDecimal,
    pub average_rating: BigDecimal,
    pub total_ratings: i32,
    pub content_count: i32,
    pub follower_count: i32,
    
    // Monthly metrics (for tier evaluation)
    pub monthly_sales: i32,
    pub monthly_revenue: BigDecimal,
    pub last_metrics_update: DateTime<Utc>,
    
    // Payment information (encrypted in application layer)
    pub payment_method: Option<String>,
    pub payment_details: serde_json::Value, // Encrypted
    pub tax_information: serde_json::Value, // Encrypted
    pub w9_on_file: bool,
    
    // Platform relationship
    pub revenue_share_percentage: BigDecimal,
    pub custom_contract: bool,
    pub featured_creator: bool,
    pub featured_until: Option<DateTime<Utc>>,
    
    // Account status
    pub account_status: String,
    pub suspension_reason: Option<String>,
    pub suspension_until: Option<DateTime<Utc>>,
    
    // Timestamps
    pub creator_since: DateTime<Utc>,
    pub last_content_published: Option<DateTime<Utc>>,
    pub last_payout_at: Option<DateTime<Utc>>,
    pub next_payout_eligible: Option<DateTime<Utc>>,
    
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateCreatorProfileRequest {
    pub display_name: String,
    pub bio: Option<String>,
    pub content_specialties: Vec<String>,
    pub languages_supported: Vec<String>,
    pub website_url: Option<String>,
    pub social_links: Option<serde_json::Value>,
}

// For working with the existing marketplace_listings structure
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct MarketplaceListing {
    pub id: Uuid,
    pub template_id: Uuid,
    pub seller_id: Uuid,
    pub price: BigDecimal,
    pub original_price: Option<BigDecimal>,
    pub currency: Option<String>,
    pub status: Option<String>,
    pub moderation_notes: Option<String>,
    pub rating: Option<BigDecimal>,
    pub review_count: Option<i32>,
    pub purchase_count: Option<i32>,
    pub revenue_total: Option<BigDecimal>,
    pub marketing_title: Option<String>,
    pub marketing_description: Option<String>,
    pub featured_image_url: Option<String>,
    pub preview_pages: Option<Vec<i32>>,
    pub search_keywords: Option<Vec<String>>,
    pub featured_start: Option<DateTime<Utc>>,
    pub featured_end: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ChildLibrary {
    pub id: Uuid,
    pub child_id: Uuid,
    pub marketplace_item_id: Uuid,
    
    // Purchase tracking
    pub purchased_by: Uuid,
    pub purchase_date: DateTime<Utc>,
    pub purchase_price: BigDecimal,
    pub licensing_type: String,
    
    // Access and progress
    pub first_accessed: Option<DateTime<Utc>>,
    pub last_accessed: Option<DateTime<Utc>>,
    pub total_play_time_minutes: i32,
    pub completion_percentage: BigDecimal,
    pub favorite: bool,
    
    // Organization
    pub custom_collections: Vec<Uuid>,
    pub tags: Vec<String>,
    pub parent_rating: Option<i32>,
    pub parent_notes: Option<String>,
    
    // Offline and sync
    pub downloaded: bool,
    pub download_date: Option<DateTime<Utc>>,
    pub offline_available: bool,
    pub sync_status: String,
    
    // Usage tracking
    pub session_count: i32,
    pub average_session_minutes: BigDecimal,
    pub skill_progress: serde_json::Value,
    pub vocabulary_learned: Vec<String>,
    
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ChildCollection {
    pub id: Uuid,
    pub child_id: Uuid,
    
    // Collection details
    pub name: String,
    pub description: Option<String>,
    pub color_theme: String,
    pub icon_name: String,
    
    // Organization
    pub display_order: i32,
    pub is_system_collection: bool,
    pub parent_created: bool,
    
    // Sharing and collaboration
    pub shared_with_siblings: bool,
    pub collaborative: bool,
    
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct CollectionItem {
    pub id: Uuid,
    pub collection_id: Uuid,
    pub library_item_id: Uuid,
    
    // Organization within collection
    pub display_order: i32,
    pub added_date: DateTime<Utc>,
    pub added_by: Option<Uuid>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct PurchaseTransaction {
    pub id: Uuid,
    
    // Transaction identification
    pub transaction_id: String,
    pub parent_user_id: Uuid,
    pub marketplace_item_id: Uuid,
    
    // Purchase details
    pub item_price: BigDecimal,
    pub discount_amount: BigDecimal,
    pub tax_amount: BigDecimal,
    pub total_amount: BigDecimal,
    pub currency_code: String,
    
    // Payment processing
    pub payment_method: String,
    pub payment_processor: String,
    pub processor_transaction_id: Option<String>,
    
    // License and access
    pub licensing_type: String,
    pub target_children: Vec<Uuid>,
    pub family_license: bool,
    
    // Status tracking
    pub status: String,
    pub failure_reason: Option<String>,
    
    // Revenue sharing
    pub creator_share: BigDecimal,
    pub platform_share: BigDecimal,
    pub creator_payout_status: String,
    
    // Timestamps
    pub initiated_at: DateTime<Utc>,
    pub completed_at: Option<DateTime<Utc>>,
    pub refunded_at: Option<DateTime<Utc>>,
    
    // Audit trail
    pub ip_address: Option<String>,
    pub user_agent: Option<String>,
    pub referer_url: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ContentReview {
    pub id: Uuid,
    pub marketplace_item_id: Uuid,
    pub reviewer_user_id: Uuid,
    
    // Review content
    pub rating: i32,
    pub title: Option<String>,
    pub review_text: Option<String>,
    
    // Categorized ratings
    pub educational_value: Option<i32>,
    pub age_appropriateness: Option<i32>,
    pub engagement_level: Option<i32>,
    pub technical_quality: Option<i32>,
    
    // Context
    pub child_age_when_reviewed: Option<i32>,
    pub usage_duration_days: Option<i32>,
    pub would_recommend: bool,
    
    // Moderation
    pub flagged_inappropriate: bool,
    pub moderation_status: String,
    pub moderated_by: Option<Uuid>,
    
    // Helpfulness tracking
    pub helpful_votes: i32,
    pub total_votes: i32,
    
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct SubscriptionPlan {
    pub id: Uuid,
    
    // Plan details
    pub name: String,
    pub description: Option<String>,
    pub price_monthly: BigDecimal,
    pub price_yearly: Option<BigDecimal>,
    
    // Features and limits
    pub content_access_level: String,
    pub max_children: i32,
    pub offline_content_gb: i32,
    
    // Creator benefits
    pub creator_tools_access: bool,
    pub analytics_access_level: String,
    pub priority_support: bool,
    
    // Plan status
    pub active: bool,
    pub available_for_signup: bool,
    
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct UserSubscription {
    pub id: Uuid,
    pub user_id: Uuid,
    pub plan_id: Uuid,
    
    // Subscription details
    pub status: String,
    pub billing_cycle: String,
    
    // Pricing (locked at subscription time)
    pub locked_price: BigDecimal,
    pub currency_code: String,
    
    // Billing
    pub next_billing_date: Option<chrono::NaiveDate>,
    pub last_payment_date: Option<chrono::NaiveDate>,
    pub payment_method_id: Option<String>,
    
    // Trial and promotions
    pub trial_until: Option<chrono::NaiveDate>,
    pub promotional_price: Option<BigDecimal>,
    pub promotional_until: Option<chrono::NaiveDate>,
    
    // Lifecycle
    pub subscribed_at: DateTime<Utc>,
    pub cancelled_at: Option<DateTime<Utc>>,
    pub suspended_at: Option<DateTime<Utc>>,
    
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// Request/Response DTOs

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MarketplaceBrowseRequest {
    pub content_type: Option<Vec<String>>,
    pub age_range_min: Option<i32>,
    pub age_range_max: Option<i32>,
    pub age_range: Option<String>,
    pub search_query: Option<String>,
    pub price_min: Option<BigDecimal>,
    pub price_max: Option<BigDecimal>,
    pub price_range: Option<String>,
    pub featured_only: Option<bool>,
    pub creator_tiers: Option<Vec<String>>,
    pub sort_by: Option<String>, // "popularity", "rating", "price", "newest"
    pub page: Option<i32>,
    pub limit: Option<i32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MarketplaceBrowseResponse {
    pub items: Vec<MarketplaceItemSummary>,
    pub total_count: i64,
    pub page: i32,
    pub total_pages: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MarketplaceItemSummary {
    pub id: Uuid,
    pub title: String,
    pub price: BigDecimal,
    pub rating: Option<BigDecimal>,
    pub review_count: Option<i32>,
    pub featured_image_url: Option<String>,
    pub creator_name: String,
    pub creator_tier: String,
    pub content_type: String,
    pub age_range: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PurchaseRequest {
    pub marketplace_item_id: Uuid,
    pub target_children: Vec<Uuid>,
    pub payment_method_id: String,
    pub billing_address: Option<serde_json::Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PurchaseResponse {
    pub transaction_id: String,
    pub status: String,
    pub total_amount: BigDecimal,
    pub library_items_created: Vec<Uuid>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateReviewRequest {
    pub marketplace_item_id: Uuid,
    pub rating: i32,
    pub title: Option<String>,
    pub review_text: Option<String>,
    pub educational_value: Option<i32>,
    pub age_appropriateness: Option<i32>,
    pub engagement_level: Option<i32>,
    pub technical_quality: Option<i32>,
    pub child_age_when_reviewed: Option<i32>,
    pub would_recommend: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateCollectionRequest {
    pub child_id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub color_theme: Option<String>,
    pub icon_name: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LibraryStatsResponse {
    pub total_items: i64,
    pub favorites_count: i64,
    pub total_play_time_hours: f64,
    pub completion_rate: f64,
    pub recent_activities: Vec<LibraryActivity>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LibraryActivity {
    pub item_title: String,
    pub activity_type: String, // "purchased", "completed", "favorite_added"
    pub timestamp: DateTime<Utc>,
    pub play_time_minutes: Option<i32>,
}