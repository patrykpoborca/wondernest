use axum::{
    extract::{State, Path, Query},
    http::StatusCode,
    middleware,
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use chrono::Utc;
use serde::Deserialize;

use crate::{
    extractors::AuthClaims,
    error::{AppError, AppResult},
    middleware::auth::{auth_middleware},
    models::{
        ContentItem, ContentCategory, ContentResponse, ContentRecommendationsResponse,
        ContentCategoriesResponse, ContentEngagementRequest, MessageResponse,
    },
    services::AppState,
};

#[derive(Debug, Deserialize)]
pub struct ContentQueryParams {
    pub category: Option<String>,
    #[serde(rename = "ageGroup")]
    pub age_group: Option<i32>,
    pub page: Option<i32>,
    pub limit: Option<i32>,
}

pub fn router() -> Router<AppState> {
    let content_routes = Router::new()
        .route("/", get(get_content_library))
        .route("/library", get(legacy_content_library))
        .route("/recommendations/:child_id", get(get_content_recommendations))
        .route("/engagement", post(track_content_engagement))
        .route("/:content_id", get(get_content_item));

    let categories_routes = Router::new()
        .route("/", get(get_content_categories));

    Router::new()
        .nest("/content", content_routes)
        .nest("/categories", categories_routes)
        .layer(middleware::from_fn(auth_middleware))
}

// Get content library with filtering (matching Kotlin endpoint exactly)
async fn get_content_library(
    State(_state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Query(params): Query<ContentQueryParams>,
) -> AppResult<axum::response::Response> {
    // Extract user claims from JWT middleware
    let _claims_check = &claims;

    let page = params.page.unwrap_or(1);
    let limit = params.limit.unwrap_or(20);

    // TODO: PRODUCTION - Replace with real content from database
    let mock_content = generate_mock_content(params.age_group, params.category.as_deref());
    let total_items = mock_content.len() as i32;
    let start_index = ((page - 1) * limit) as usize;
    let end_index = std::cmp::min(start_index + limit as usize, mock_content.len());

    let paginated_content = if start_index < mock_content.len() {
        mock_content[start_index..end_index].to_vec()
    } else {
        vec![]
    };

    let response = ContentResponse {
        items: paginated_content.clone(),
        total_items,
        current_page: page,
        total_pages: (total_items + limit - 1) / limit,
        categories: get_mock_categories(),
    };

    tracing::info!("Returned {} content items for family", paginated_content.len());

    Ok((StatusCode::OK, Json(response)).into_response())
}

// Legacy endpoint for backward compatibility (matching Kotlin endpoint exactly)
async fn legacy_content_library(
    State(_state): State<AppState>,
) -> AppResult<axum::response::Response> {
    Ok((StatusCode::OK, Json(MessageResponse {
        message: "Use /content instead of /content/library".to_string()
    })).into_response())
}

// Get content recommendations for a child (matching Kotlin endpoint exactly)
async fn get_content_recommendations(
    State(_state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Path(child_id): Path<String>,
) -> AppResult<axum::response::Response> {
    // Extract user claims from JWT middleware
    let _claims_check = &claims;

    if child_id.is_empty() {
        return Ok((StatusCode::BAD_REQUEST, Json(MessageResponse {
            message: "Child ID is required".to_string()
        })).into_response());
    }

    // TODO: PRODUCTION - Implement personalized recommendations based on:
    // - Child's age and interests
    // - Previous content engagement
    // - Educational goals
    // - Content preferences

    // For now, return mock recommendations
    let recommendations = generate_mock_recommendations(&child_id);

    let response = ContentRecommendationsResponse {
        child_id: child_id.clone(),
        recommendations,
        reason: "Based on age-appropriate content and interests".to_string(),
        generated_at: Utc::now().timestamp_millis(),
    };

    tracing::info!("Generated content recommendations for child: {}", child_id);

    Ok((StatusCode::OK, Json(response)).into_response())
}

// Track content engagement (matching Kotlin endpoint exactly)
async fn track_content_engagement(
    State(_state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Json(_engagement): Json<ContentEngagementRequest>,
) -> AppResult<axum::response::Response> {
    // Extract user claims from JWT middleware
    let _claims_check = &claims;

    // TODO: PRODUCTION - Implement content engagement tracking
    Ok((StatusCode::CREATED, Json(MessageResponse {
        message: "Content engagement tracked - TODO: Implement analytics".to_string()
    })).into_response())
}

// Get specific content item (matching Kotlin endpoint exactly)
async fn get_content_item(
    State(_state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Path(content_id): Path<String>,
) -> AppResult<axum::response::Response> {
    // Extract user claims from JWT middleware
    let _claims_check = &claims;

    if content_id.is_empty() {
        return Ok((StatusCode::BAD_REQUEST, Json(MessageResponse {
            message: "Content ID is required".to_string()
        })).into_response());
    }

    // TODO: PRODUCTION - Fetch from database and check family access permissions
    let content_item = find_mock_content_by_id(&content_id);
    
    match content_item {
        Some(item) => {
            tracing::info!("Retrieved content item: {}", content_id);
            Ok((StatusCode::OK, Json(item)).into_response())
        }
        None => {
            Ok((StatusCode::NOT_FOUND, Json(MessageResponse {
                message: "Content not found".to_string()
            })).into_response())
        }
    }
}

// Get content categories (matching Kotlin endpoint exactly)
async fn get_content_categories(
    State(_state): State<AppState>,
    AuthClaims(claims): AuthClaims,
) -> AppResult<axum::response::Response> {
    // Extract user claims from JWT middleware
    let _claims_check = &claims;

    let categories = get_mock_categories();
    let response = ContentCategoriesResponse { categories: categories.clone() };
    
    tracing::info!("Retrieved {} content categories", categories.len());
    
    Ok((StatusCode::OK, Json(response)).into_response())
}

// TODO: PRODUCTION - Replace these mock functions with real database queries
fn generate_mock_content(age_group: Option<i32>, category: Option<&str>) -> Vec<ContentItem> {
    let base_content = vec![
        ContentItem {
            id: "content_1".to_string(),
            title: "Learning Colors with Animals".to_string(),
            description: "Fun way to learn colors through animal friends".to_string(),
            category: "educational".to_string(),
            age_rating: 3,
            duration: 10,
            thumbnail_url: "/thumbnails/colors_animals.jpg".to_string(),
            content_url: "/content/colors_animals.mp4".to_string(),
            tags: vec!["colors".to_string(), "animals".to_string(), "learning".to_string()],
            is_educational: true,
            difficulty: "easy".to_string(),
            created_at: "2024-01-15T10:00:00Z".to_string(),
        },
        ContentItem {
            id: "content_2".to_string(),
            title: "Adventure Island Stories".to_string(),
            description: "Exciting adventures on a magical island".to_string(),
            category: "stories".to_string(),
            age_rating: 5,
            duration: 15,
            thumbnail_url: "/thumbnails/adventure_island.jpg".to_string(),
            content_url: "/content/adventure_island.mp4".to_string(),
            tags: vec!["adventure".to_string(), "story".to_string(), "imagination".to_string()],
            is_educational: false,
            difficulty: "medium".to_string(),
            created_at: "2024-01-16T14:30:00Z".to_string(),
        },
        ContentItem {
            id: "content_3".to_string(),
            title: "Math Puzzles for Kids".to_string(),
            description: "Interactive math problems and puzzles".to_string(),
            category: "educational".to_string(),
            age_rating: 6,
            duration: 20,
            thumbnail_url: "/thumbnails/math_puzzles.jpg".to_string(),
            content_url: "/content/math_puzzles.mp4".to_string(),
            tags: vec!["math".to_string(), "puzzles".to_string(), "problem-solving".to_string()],
            is_educational: true,
            difficulty: "medium".to_string(),
            created_at: "2024-01-17T09:15:00Z".to_string(),
        },
    ];

    base_content.into_iter()
        .filter(|content| {
            (age_group.is_none() || content.age_rating <= age_group.unwrap() + 2) &&
            (category.is_none() || content.category == category.unwrap())
        })
        .collect()
}

fn generate_mock_recommendations(child_id: &str) -> Vec<ContentItem> {
    // TODO: PRODUCTION - Implement actual recommendation algorithm
    generate_mock_content(None, None).into_iter().take(5).collect()
}

fn get_mock_categories() -> Vec<ContentCategory> {
    vec![
        ContentCategory {
            id: "educational".to_string(),
            name: "Educational".to_string(),
            description: "Learn while you play".to_string(),
            icon: "🎓".to_string(),
            color: "#4CAF50".to_string(),
            min_age: 3,
            max_age: 12,
        },
        ContentCategory {
            id: "stories".to_string(),
            name: "Stories".to_string(),
            description: "Amazing tales and adventures".to_string(),
            icon: "📚".to_string(),
            color: "#FF9800".to_string(),
            min_age: 4,
            max_age: 10,
        },
        ContentCategory {
            id: "music".to_string(),
            name: "Music".to_string(),
            description: "Songs and musical activities".to_string(),
            icon: "🎵".to_string(),
            color: "#E91E63".to_string(),
            min_age: 2,
            max_age: 8,
        },
        ContentCategory {
            id: "art".to_string(),
            name: "Art & Craft".to_string(),
            description: "Creative drawing and crafts".to_string(),
            icon: "🎨".to_string(),
            color: "#9C27B0".to_string(),
            min_age: 4,
            max_age: 12,
        },
        ContentCategory {
            id: "science".to_string(),
            name: "Science".to_string(),
            description: "Explore the world around us".to_string(),
            icon: "🔬".to_string(),
            color: "#2196F3".to_string(),
            min_age: 5,
            max_age: 12,
        },
    ]
}

fn find_mock_content_by_id(content_id: &str) -> Option<ContentItem> {
    generate_mock_content(None, None).into_iter()
        .find(|item| item.id == content_id)
}