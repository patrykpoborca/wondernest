use axum::{
    extract::{State, Path, Query},
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use uuid::Uuid;

use crate::{
    extractors::AuthClaims,
    error::AppResult,
    models::{
        MarketplaceBrowseRequest, CreateCreatorProfileRequest, PurchaseRequest,
        CreateReviewRequest, CreateCollectionRequest
    },
    services::{AppState, content_pack_service::ContentPackCreateRequest},
    db::MarketplaceRepository,
};

pub fn router() -> Router<AppState> {
    Router::new()
        // Creator profile management
        .route("/creator/profile", post(create_creator_profile))
        .route("/creator/profile", get(get_creator_profile))
        
        // Content pack management
        .route("/content-packs", post(create_content_pack))
        
        // Marketplace browsing
        .route("/browse", get(browse_marketplace))
        .route("/items/:item_id", get(get_marketplace_item))
        
        // Purchasing
        .route("/purchase", post(purchase_item))
        
        // Child library management
        .route("/library/:child_id", get(get_child_library))
        .route("/library/:child_id/stats", get(get_library_stats))
        
        // Collections
        .route("/collections", post(create_collection))
        .route("/collections/:child_id", get(get_child_collections))
        
        // Reviews
        .route("/reviews", post(create_review))
        .route("/items/:item_id/reviews", get(get_item_reviews))
}

async fn create_creator_profile(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Json(request): Json<CreateCreatorProfileRequest>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Creating creator profile for user: {}", claims.user_id);
    
    let user_id = Uuid::parse_str(&claims.user_id)
        .map_err(|_| crate::error::AppError::BadRequest("Invalid user ID".to_string()))?;
    
    let marketplace_repo = MarketplaceRepository::new(state.db.clone());
    
    let profile = marketplace_repo.create_creator_profile(user_id, &request).await
        .map_err(|e| {
            tracing::error!("Failed to create creator profile: {}", e);
            crate::error::AppError::InternalError("Failed to create creator profile".to_string())
        })?;
    
    Ok(Json(profile))
}

async fn get_creator_profile(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Getting creator profile for user: {}", claims.user_id);
    
    let user_id = Uuid::parse_str(&claims.user_id)
        .map_err(|_| crate::error::AppError::BadRequest("Invalid user ID".to_string()))?;
    
    let marketplace_repo = MarketplaceRepository::new(state.db.clone());
    
    match marketplace_repo.get_creator_profile(user_id).await {
        Ok(Some(profile)) => Ok(Json(profile)),
        Ok(None) => Err(crate::error::AppError::NotFound("Creator profile not found".to_string())),
        Err(e) => {
            tracing::error!("Failed to get creator profile: {}", e);
            Err(crate::error::AppError::InternalError("Failed to get creator profile".to_string()))
        }
    }
}

async fn browse_marketplace(
    State(state): State<AppState>,
    AuthClaims(_claims): AuthClaims,
    Query(request): Query<MarketplaceBrowseRequest>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Browsing marketplace with filters: {:?}", request);
    
    let marketplace_repo = MarketplaceRepository::new(state.db.clone());
    
    let response = marketplace_repo.browse_marketplace(&request).await
        .map_err(|e| {
            tracing::error!("Failed to browse marketplace: {}", e);
            crate::error::AppError::InternalError("Failed to browse marketplace".to_string())
        })?;
    
    Ok(Json(response))
}

async fn get_marketplace_item(
    State(state): State<AppState>,
    AuthClaims(_claims): AuthClaims,
    Path(item_id): Path<Uuid>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Getting marketplace item: {}", item_id);
    
    let marketplace_repo = MarketplaceRepository::new(state.db.clone());
    
    match marketplace_repo.get_marketplace_item(item_id).await {
        Ok(Some(item)) => Ok(Json(item)),
        Ok(None) => Err(crate::error::AppError::NotFound("Marketplace item not found".to_string())),
        Err(e) => {
            tracing::error!("Failed to get marketplace item: {}", e);
            Err(crate::error::AppError::InternalError("Failed to get marketplace item".to_string()))
        }
    }
}

async fn purchase_item(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Json(request): Json<PurchaseRequest>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Processing purchase for user: {}", claims.user_id);
    
    let user_id = Uuid::parse_str(&claims.user_id)
        .map_err(|_| crate::error::AppError::BadRequest("Invalid user ID".to_string()))?;
    
    // Validate that user has family access and children belong to their family
    let family_id = match claims.family_id {
        Some(id) => Uuid::parse_str(&id).map_err(|_| crate::error::AppError::BadRequest("Invalid family ID".to_string()))?,
        None => return Err(crate::error::AppError::BadRequest("No family associated with user".to_string())),
    };
    
    let marketplace_repo = MarketplaceRepository::new(state.db.clone());
    
    let response = marketplace_repo.purchase_item(user_id, &request).await
        .map_err(|e| {
            tracing::error!("Failed to process purchase: {}", e);
            crate::error::AppError::InternalError("Failed to process purchase".to_string())
        })?;
    
    Ok(Json(response))
}

async fn get_child_library(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Path(child_id): Path<Uuid>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Getting library for child: {}", child_id);
    
    // Validate family access
    let _family_id = match claims.family_id {
        Some(id) => Uuid::parse_str(&id).map_err(|_| crate::error::AppError::BadRequest("Invalid family ID".to_string()))?,
        None => return Err(crate::error::AppError::BadRequest("No family associated with user".to_string())),
    };
    
    let marketplace_repo = MarketplaceRepository::new(state.db.clone());
    
    let library = marketplace_repo.get_child_library(child_id).await
        .map_err(|e| {
            tracing::error!("Failed to get child library: {}", e);
            crate::error::AppError::InternalError("Failed to get child library".to_string())
        })?;
    
    Ok(Json(library))
}

async fn get_library_stats(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Path(child_id): Path<Uuid>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Getting library stats for child: {}", child_id);
    
    // Validate family access
    let _family_id = match claims.family_id {
        Some(id) => Uuid::parse_str(&id).map_err(|_| crate::error::AppError::BadRequest("Invalid family ID".to_string()))?,
        None => return Err(crate::error::AppError::BadRequest("No family associated with user".to_string())),
    };
    
    let marketplace_repo = MarketplaceRepository::new(state.db.clone());
    
    let stats = marketplace_repo.get_library_stats(child_id).await
        .map_err(|e| {
            tracing::error!("Failed to get library stats: {}", e);
            crate::error::AppError::InternalError("Failed to get library stats".to_string())
        })?;
    
    Ok(Json(stats))
}

async fn create_collection(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Json(request): Json<CreateCollectionRequest>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Creating collection for child: {}", request.child_id);
    
    // Validate family access
    let _family_id = match claims.family_id {
        Some(id) => Uuid::parse_str(&id).map_err(|_| crate::error::AppError::BadRequest("Invalid family ID".to_string()))?,
        None => return Err(crate::error::AppError::BadRequest("No family associated with user".to_string())),
    };
    
    let marketplace_repo = MarketplaceRepository::new(state.db.clone());
    
    let collection = marketplace_repo.create_collection(&request).await
        .map_err(|e| {
            tracing::error!("Failed to create collection: {}", e);
            crate::error::AppError::InternalError("Failed to create collection".to_string())
        })?;
    
    Ok(Json(collection))
}

async fn get_child_collections(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Path(child_id): Path<Uuid>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Getting collections for child: {}", child_id);
    
    // Validate family access
    let _family_id = match claims.family_id {
        Some(id) => Uuid::parse_str(&id).map_err(|_| crate::error::AppError::BadRequest("Invalid family ID".to_string()))?,
        None => return Err(crate::error::AppError::BadRequest("No family associated with user".to_string())),
    };
    
    let marketplace_repo = MarketplaceRepository::new(state.db.clone());
    
    let collections = marketplace_repo.get_child_collections(child_id).await
        .map_err(|e| {
            tracing::error!("Failed to get child collections: {}", e);
            crate::error::AppError::InternalError("Failed to get child collections".to_string())
        })?;
    
    Ok(Json(collections))
}

async fn create_review(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Json(request): Json<CreateReviewRequest>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Creating review for item: {}", request.marketplace_item_id);
    
    let user_id = Uuid::parse_str(&claims.user_id)
        .map_err(|_| crate::error::AppError::BadRequest("Invalid user ID".to_string()))?;
    
    let marketplace_repo = MarketplaceRepository::new(state.db.clone());
    
    let review = marketplace_repo.create_review(user_id, &request).await
        .map_err(|e| {
            tracing::error!("Failed to create review: {}", e);
            crate::error::AppError::InternalError("Failed to create review".to_string())
        })?;
    
    Ok(Json(review))
}

async fn get_item_reviews(
    State(state): State<AppState>,
    AuthClaims(_claims): AuthClaims,
    Path(item_id): Path<Uuid>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Getting reviews for item: {}", item_id);
    
    let marketplace_repo = MarketplaceRepository::new(state.db.clone());
    
    let reviews = marketplace_repo.get_reviews_for_item(item_id).await
        .map_err(|e| {
            tracing::error!("Failed to get item reviews: {}", e);
            crate::error::AppError::InternalError("Failed to get item reviews".to_string())
        })?;
    
    Ok(Json(reviews))
}

async fn create_content_pack(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Json(request): Json<ContentPackCreateRequest>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Creating content pack '{}' for user: {}", request.title, claims.user_id);
    
    let user_id = Uuid::parse_str(&claims.user_id)
        .map_err(|_| crate::error::AppError::BadRequest("Invalid user ID".to_string()))?;
    
    let response = state.content_pack.create_content_pack(user_id, request).await
        .map_err(|e| {
            tracing::error!("Failed to create content pack: {}", e);
            crate::error::AppError::InternalError("Failed to create content pack".to_string())
        })?;
    
    Ok(Json(response))
}