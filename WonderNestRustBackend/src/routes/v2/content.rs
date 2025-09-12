use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::Json,
    routing::{get, post},
    Router,
};
use serde::Deserialize;
use uuid::Uuid;

use crate::{
    error::AppResult,
    models::{
        ContentCatalogRequest, ContentCatalogResponse, EcosystemContentItem, AgeRange, Pagination,
        FeaturedContentResponse, FeaturedSection, ContentLibraryResponse, LibraryItem,
        LibraryStats, AddToLibraryRequest, AddToLibraryResponse, ContentDownloadResponse,
        SyncRequest, SyncResponse, RecommendationsResponse, FeedbackRequest, ContentError,
        DownloadChunk, ContentMetadata, SyncAction, RecommendationItem,
    },
    services::{AppState, content_ecosystem_service::ContentEcosystemService},
    db::MarketplaceRepository,
};
use chrono::{DateTime, Utc};

// =============================================================================
// QUERY PARAMS HELPER
// =============================================================================

#[derive(Debug, Deserialize)]
pub struct CatalogQueryParams {
    pub child_id: Uuid,
    #[serde(rename = "type")]
    pub content_type: Option<String>,
    pub category: Option<String>,
    pub age_min: Option<i32>,
    pub age_max: Option<i32>,
    pub search: Option<String>,
    pub sort: Option<String>,
    pub page: Option<i32>,
    pub limit: Option<i32>,
}

#[derive(Debug, Deserialize)]
pub struct FeaturedQueryParams {
    pub child_id: Uuid,
}

#[derive(Debug, Deserialize)]
pub struct RecommendationsQueryParams {
    pub child_id: Uuid,
    pub count: Option<i32>,
    pub exclude_owned: Option<bool>,
}

// =============================================================================
// ROUTE HANDLERS
// =============================================================================

/// GET /api/v2/content/catalog
/// Browse available content with filtering and pagination
pub async fn get_content_catalog(
    State(state): State<AppState>,
    Query(params): Query<CatalogQueryParams>,
) -> AppResult<Json<ContentCatalogResponse>> {
    // Create content ecosystem service
    let marketplace_repo = MarketplaceRepository::new(state.db.clone());
    let signed_url_service = crate::services::signed_url_service::SignedUrlService::new(
        "temp-secret-key".to_string(), // TODO: Move to config
        Some(24) // 24 hour expiry
    );
    let content_service = ContentEcosystemService::new(marketplace_repo, signed_url_service);
    
    // Convert query params to request model
    let request = ContentCatalogRequest {
        child_id: params.child_id,
        content_type: params.content_type,
        category: params.category,
        age_min: params.age_min,
        age_max: params.age_max,
        search: params.search,
        sort: params.sort,
        page: params.page,
        limit: params.limit,
    };
    
    // Get real data from service
    let response = content_service.get_content_catalog(request).await?;
    Ok(Json(response))
}

/// GET /api/v2/content/featured
/// Get featured and recommended content for a child
pub async fn get_featured_content(
    State(_state): State<AppState>,
    Query(params): Query<FeaturedQueryParams>,
) -> AppResult<Json<FeaturedContentResponse>> {
    let mock_featured = generate_mock_featured_content(&params.child_id);
    Ok(Json(mock_featured))
}

/// GET /api/v2/content/library/{child_id}
/// Get all content owned by a specific child
pub async fn get_content_library(
    State(_state): State<AppState>,
    Path(child_id): Path<Uuid>,
) -> AppResult<Json<ContentLibraryResponse>> {
    let mock_library = generate_mock_content_library(&child_id);
    Ok(Json(mock_library))
}

/// POST /api/v2/content/library/{child_id}/add
/// Add content to a child's library (purchase or grant)
pub async fn add_to_library(
    State(_state): State<AppState>,
    Path(child_id): Path<Uuid>,
    Json(request): Json<AddToLibraryRequest>,
) -> AppResult<Json<AddToLibraryResponse>> {
    // For Phase 1, simulate successful addition
    let mock_response = simulate_add_to_library(&child_id, &request);
    Ok(Json(mock_response))
}

/// GET /api/v2/content/download/{content_id}
/// Get download URL and metadata for content
pub async fn get_content_download(
    State(_state): State<AppState>,
    Path(content_id): Path<Uuid>,
) -> AppResult<Json<ContentDownloadResponse>> {
    let mock_download = generate_mock_download_info(&content_id);
    Ok(Json(mock_download))
}

/// POST /api/v2/content/sync
/// Synchronize content library with server
pub async fn sync_content(
    State(_state): State<AppState>,
    Json(request): Json<SyncRequest>,
) -> AppResult<Json<SyncResponse>> {
    let mock_sync = generate_mock_sync_response(&request);
    Ok(Json(mock_sync))
}

/// GET /api/v2/content/recommendations
/// Get AI-powered content recommendations
pub async fn get_recommendations(
    State(_state): State<AppState>,
    Query(params): Query<RecommendationsQueryParams>,
) -> AppResult<Json<RecommendationsResponse>> {
    let mock_recommendations = generate_mock_recommendations(&params);
    Ok(Json(mock_recommendations))
}

/// POST /api/v2/content/feedback
/// Submit feedback on content for improving recommendations
pub async fn submit_feedback(
    State(_state): State<AppState>,
    Json(request): Json<FeedbackRequest>,
) -> AppResult<StatusCode> {
    // For Phase 1, just acknowledge receipt
    tracing::info!("Received feedback for content {} from child {}", 
                  request.content_id, request.child_id);
    Ok(StatusCode::OK)
}

// =============================================================================
// MOCK DATA GENERATORS (Phase 1 Implementation)
// =============================================================================

fn generate_mock_content_catalog(params: &CatalogQueryParams) -> ContentCatalogResponse {
    let page = params.page.unwrap_or(1);
    let limit = params.limit.unwrap_or(20).min(100);
    
    // Generate some mock content items
    let mock_items = vec![
        EcosystemContentItem {
            id: Uuid::new_v4(),
            content_type: "sticker_pack".to_string(),
            title: "Animal Friends Sticker Pack".to_string(),
            description: "Cute animal stickers for your stories".to_string(),
            thumbnail_url: "https://cdn.wondernest.app/thumbnails/animals.png".to_string(),
            age_range: AgeRange { min: 3, max: 8 },
            rating: 4.8,
            price: 299, // $2.99
            currency: "USD".to_string(),
            is_free: false,
            is_owned: false,
            download_size: 15728640, // ~15MB
            metadata: serde_json::json!({
                "sticker_count": 48,
                "themes": ["animals", "nature"],
                "educational_goals": ["creativity", "vocabulary"]
            }),
        },
        EcosystemContentItem {
            id: Uuid::new_v4(),
            content_type: "character_pack".to_string(),
            title: "Superhero Character Pack".to_string(),
            description: "Amazing superheroes for your adventure stories".to_string(),
            thumbnail_url: "https://cdn.wondernest.app/thumbnails/superheroes.png".to_string(),
            age_range: AgeRange { min: 5, max: 10 },
            rating: 4.6,
            price: 399, // $3.99
            currency: "USD".to_string(),
            is_free: false,
            is_owned: true,
            download_size: 22651392, // ~22MB
            metadata: serde_json::json!({
                "character_count": 12,
                "themes": ["adventure", "heroes"],
                "educational_goals": ["storytelling", "imagination"]
            }),
        },
        EcosystemContentItem {
            id: Uuid::new_v4(),
            content_type: "story".to_string(),
            title: "The Magic Forest".to_string(),
            description: "An interactive story about forest creatures".to_string(),
            thumbnail_url: "https://cdn.wondernest.app/thumbnails/forest.png".to_string(),
            age_range: AgeRange { min: 4, max: 7 },
            rating: 4.9,
            price: 0,
            currency: "USD".to_string(),
            is_free: true,
            is_owned: false,
            download_size: 8388608, // ~8MB
            metadata: serde_json::json!({
                "duration_minutes": 15,
                "themes": ["nature", "friendship"],
                "educational_goals": ["reading", "empathy"]
            }),
        },
    ];

    ContentCatalogResponse {
        content: mock_items,
        pagination: Pagination {
            page,
            limit,
            total: 145, // Mock total count
            has_more: page * limit < 145,
        },
    }
}

fn generate_mock_featured_content(child_id: &Uuid) -> FeaturedContentResponse {
    let sample_content = EcosystemContentItem {
        id: Uuid::new_v4(),
        content_type: "sticker_pack".to_string(),
        title: "Weekly Featured Pack".to_string(),
        description: "This week's special collection".to_string(),
        thumbnail_url: "https://cdn.wondernest.app/thumbnails/featured.png".to_string(),
        age_range: AgeRange { min: 3, max: 8 },
        rating: 4.7,
        price: 199,
        currency: "USD".to_string(),
        is_free: false,
        is_owned: false,
        download_size: 12582912,
        metadata: serde_json::json!({}),
    };

    FeaturedContentResponse {
        featured: FeaturedSection {
            title: "Weekly Picks".to_string(),
            content: vec![sample_content.clone()],
        },
        recommended: FeaturedSection {
            title: "Based on your interests".to_string(),
            content: vec![sample_content.clone()],
        },
        new_releases: FeaturedSection {
            title: "New This Week".to_string(),
            content: vec![sample_content.clone()],
        },
        trending: FeaturedSection {
            title: "Popular with Kids".to_string(),
            content: vec![sample_content],
        },
    }
}

fn generate_mock_content_library(child_id: &Uuid) -> ContentLibraryResponse {
    let sample_content = EcosystemContentItem {
        id: Uuid::new_v4(),
        content_type: "sticker_pack".to_string(),
        title: "My Sticker Collection".to_string(),
        description: "Your personal sticker pack".to_string(),
        thumbnail_url: "https://cdn.wondernest.app/thumbnails/mystickers.png".to_string(),
        age_range: AgeRange { min: 3, max: 8 },
        rating: 4.5,
        price: 0,
        currency: "USD".to_string(),
        is_free: true,
        is_owned: true,
        download_size: 5242880,
        metadata: serde_json::json!({}),
    };

    let library_item = LibraryItem {
        content_id: sample_content.id,
        acquired_at: Utc::now(),
        last_used: Some(Utc::now()),
        usage_count: 45,
        is_favorite: true,
        download_status: "downloaded".to_string(),
        local_path: Some("/content/stickers/mystickers".to_string()),
        content: sample_content,
    };

    ContentLibraryResponse {
        owned_content: vec![library_item],
        statistics: LibraryStats {
            total_items: 23,
            total_size: 157286400,
            favorites: 5,
            recently_used: 8,
        },
    }
}

fn simulate_add_to_library(child_id: &Uuid, request: &AddToLibraryRequest) -> AddToLibraryResponse {
    let mock_content = EcosystemContentItem {
        id: request.content_id,
        content_type: "sticker_pack".to_string(),
        title: "New Content Item".to_string(),
        description: "Newly acquired content".to_string(),
        thumbnail_url: "https://cdn.wondernest.app/thumbnails/new.png".to_string(),
        age_range: AgeRange { min: 3, max: 8 },
        rating: 4.0,
        price: 299,
        currency: "USD".to_string(),
        is_free: false,
        is_owned: true,
        download_size: 10485760,
        metadata: serde_json::json!({}),
    };

    let library_item = LibraryItem {
        content_id: request.content_id,
        acquired_at: Utc::now(),
        last_used: None,
        usage_count: 0,
        is_favorite: false,
        download_status: "pending".to_string(),
        local_path: None,
        content: mock_content,
    };

    AddToLibraryResponse {
        success: true,
        library_item,
    }
}

fn generate_mock_download_info(content_id: &Uuid) -> ContentDownloadResponse {
    ContentDownloadResponse {
        download_url: "https://cdn.wondernest.app/signed/content123".to_string(),
        expires_at: Utc::now() + chrono::Duration::hours(1),
        content_hash: "sha256:abc123def456".to_string(),
        chunks: vec![
            DownloadChunk {
                id: 1,
                url: "https://cdn.wondernest.app/chunks/1".to_string(),
                size: 1048576,
                hash: "sha256:chunk1".to_string(),
            }
        ],
        metadata: ContentMetadata {
            version: "1.2.0".to_string(),
            dependencies: vec!["base_pack_v1".to_string()],
            install_size: 15728640,
        },
    }
}

fn generate_mock_sync_response(request: &SyncRequest) -> SyncResponse {
    SyncResponse {
        to_download: vec![
            SyncAction {
                content_id: Uuid::new_v4(),
                version: Some("1.2.0".to_string()),
                priority: "high".to_string(),
                reason: "update_available".to_string(),
            }
        ],
        to_delete: vec![],
        sync_token: "sync_token_v2".to_string(),
    }
}

fn generate_mock_recommendations(params: &RecommendationsQueryParams) -> RecommendationsResponse {
    let sample_content = EcosystemContentItem {
        id: Uuid::new_v4(),
        content_type: "story".to_string(),
        title: "Recommended Story".to_string(),
        description: "A story just for you".to_string(),
        thumbnail_url: "https://cdn.wondernest.app/thumbnails/rec.png".to_string(),
        age_range: AgeRange { min: 4, max: 7 },
        rating: 4.8,
        price: 0,
        currency: "USD".to_string(),
        is_free: true,
        is_owned: false,
        download_size: 6291456,
        metadata: serde_json::json!({}),
    };

    RecommendationsResponse {
        recommendations: vec![
            RecommendationItem {
                content: sample_content,
                reason: "based_on_interest".to_string(),
                confidence: 0.92,
                explanation: "Because you love animal stories".to_string(),
            }
        ],
        interests_detected: vec!["animals".to_string(), "adventure".to_string(), "creativity".to_string()],
    }
}

// =============================================================================
// ROUTER SETUP
// =============================================================================

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/catalog", get(get_content_catalog))
        .route("/featured", get(get_featured_content))
        .route("/library/:child_id", get(get_content_library))
        .route("/library/:child_id/add", post(add_to_library))
        .route("/download/:content_id", get(get_content_download))
        .route("/sync", post(sync_content))
        .route("/recommendations", get(get_recommendations))
        .route("/feedback", post(submit_feedback))
}