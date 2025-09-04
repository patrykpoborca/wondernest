use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ContentItem {
    pub id: String,
    pub title: String,
    pub description: String,
    pub category: String,
    #[serde(rename = "ageRating")]
    pub age_rating: i32,
    pub duration: i32, // minutes
    #[serde(rename = "thumbnailUrl")]
    pub thumbnail_url: String,
    #[serde(rename = "contentUrl")]
    pub content_url: String,
    pub tags: Vec<String>,
    #[serde(rename = "isEducational")]
    pub is_educational: bool,
    pub difficulty: String, // "easy", "medium", "hard"
    #[serde(rename = "createdAt")]
    pub created_at: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ContentCategory {
    pub id: String,
    pub name: String,
    pub description: String,
    pub icon: String,
    pub color: String,
    #[serde(rename = "minAge")]
    pub min_age: i32,
    #[serde(rename = "maxAge")]
    pub max_age: i32,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ContentResponse {
    pub items: Vec<ContentItem>,
    #[serde(rename = "totalItems")]
    pub total_items: i32,
    #[serde(rename = "currentPage")]
    pub current_page: i32,
    #[serde(rename = "totalPages")]
    pub total_pages: i32,
    pub categories: Vec<ContentCategory>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ContentRecommendationsResponse {
    #[serde(rename = "childId")]
    pub child_id: String,
    pub recommendations: Vec<ContentItem>,
    pub reason: String,
    #[serde(rename = "generatedAt")]
    pub generated_at: i64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ContentCategoriesResponse {
    pub categories: Vec<ContentCategory>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ContentEngagementRequest {
    #[serde(rename = "contentId")]
    pub content_id: String,
    #[serde(rename = "childId")]
    pub child_id: String,
    #[serde(rename = "engagementType")]
    pub engagement_type: String, // "view", "like", "complete", "share"
    pub duration: Option<i32>, // seconds watched/engaged
    pub metadata: Option<serde_json::Value>,
}