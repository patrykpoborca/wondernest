use axum::{
    extract::{Query, State, Path},
    response::IntoResponse,
    routing::get,
    Json, Router,
};
use uuid::Uuid;

use crate::{
    extractors::AuthClaims,
    error::AppResult,
    models::{ContentPackResponse, CategoriesData, PacksData, ContentPackSearchRequest},
    services::{AppState, content_pack::ContentPackService},
};

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/categories", get(get_categories))
        .route("/featured", get(get_featured))
        .route("/owned", get(get_owned))
        .route("/", get(search_packs))
        .route("/:pack_id", get(get_pack_by_id))
}

async fn get_categories(
    State(state): State<AppState>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Content-packs: Getting categories");
    
    let service = ContentPackService::new(state.db.clone());
    let categories = service.get_categories().await?;
    
    tracing::info!("Content-packs: Retrieved {} categories", categories.len());
    
    Ok(Json(ContentPackResponse {
        success: true,
        data: Some(CategoriesData { categories }),
        error: None,
    }))
}

async fn get_featured(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Query(params): Query<std::collections::HashMap<String, String>>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Content-packs: Getting featured packs");
    
    let _claims_check = &claims;
    
    let user_id = Uuid::parse_str(&claims.user_id)
        .map_err(|_| crate::error::AppError::InvalidToken)?;
    
    tracing::info!("Content-packs: Parsed User ID: {}", user_id);
    
    let limit = params
        .get("limit")
        .and_then(|s| s.parse::<i32>().ok())
        .unwrap_or(10);
    
    let service = ContentPackService::new(state.db.clone());
    let packs = service.get_featured_packs(user_id, limit).await?;
    
    tracing::info!("Content-packs: Retrieved {} featured packs", packs.len());
    
    Ok(Json(ContentPackResponse {
        success: true,
        data: Some(PacksData { packs }),
        error: None,
    }))
}

async fn get_owned(
    State(state): State<AppState>,
    Query(params): Query<std::collections::HashMap<String, String>>,
    AuthClaims(claims): AuthClaims,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Content-packs: Getting owned packs");
    
    let _claims_check = &claims;
    
    let user_id = Uuid::parse_str(&claims.user_id)
        .map_err(|_| crate::error::AppError::InvalidToken)?;
    
    let child_id = params
        .get("childId")
        .and_then(|s| Uuid::parse_str(s).ok());
    
    let service = ContentPackService::new(state.db.clone());
    let packs = service.get_user_owned_packs(user_id, child_id).await?;
    
    tracing::info!("Content-packs: Retrieved {} owned packs", packs.len());
    
    Ok(Json(ContentPackResponse {
        success: true,
        data: Some(PacksData { packs }),
        error: None,
    }))
}

async fn search_packs(
    State(state): State<AppState>,
    Query(params): Query<std::collections::HashMap<String, String>>,
    AuthClaims(claims): AuthClaims,
) -> AppResult<impl IntoResponse> {
    let _claims_check = &claims;
    
    let user_id = Uuid::parse_str(&claims.user_id)
        .map_err(|_| crate::error::AppError::InvalidToken)?;
    
    // Build search request from query params
    let search_request = ContentPackSearchRequest {
        query: params.get("query").cloned(),
        category: params.get("category").cloned(),
        pack_type: params.get("packType").cloned(),
        age_min: params.get("ageMin").and_then(|s| s.parse().ok()),
        age_max: params.get("ageMax").and_then(|s| s.parse().ok()),
        price_min: params.get("priceMin").and_then(|s| s.parse().ok()),
        price_max: params.get("priceMax").and_then(|s| s.parse().ok()),
        is_free: params.get("isFree").and_then(|s| s.parse().ok()),
        educational_goals: params.get("educationalGoals")
            .map(|s| s.split(',').map(String::from).collect())
            .unwrap_or_default(),
        sort_by: params.get("sortBy").cloned().unwrap_or_else(|| "popularity".to_string()),
        sort_order: params.get("sortOrder").cloned().unwrap_or_else(|| "desc".to_string()),
        page: params.get("page").and_then(|s| s.parse().ok()).unwrap_or(0),
        size: params.get("size").and_then(|s| s.parse().ok()).unwrap_or(20),
    };
    
    let service = ContentPackService::new(state.db.clone());
    let response = service.search_packs(search_request, user_id).await?;
    
    Ok(Json(ContentPackResponse {
        success: true,
        data: Some(response),
        error: None,
    }))
}

async fn get_pack_by_id(
    State(state): State<AppState>,
    Path(pack_id): Path<Uuid>,
    AuthClaims(claims): AuthClaims,
) -> AppResult<impl IntoResponse> {
    let _claims_check = &claims;
    
    let user_id = Uuid::parse_str(&claims.user_id)
        .map_err(|_| crate::error::AppError::InvalidToken)?;
    
    let service = ContentPackService::new(state.db.clone());
    let pack = service.get_pack_by_id(pack_id, user_id).await?;
    
    match pack {
        Some(p) => Ok(Json(ContentPackResponse {
            success: true,
            data: Some(p),
            error: None,
        })),
        None => Err(crate::error::AppError::NotFound("Pack not found".to_string())),
    }
}