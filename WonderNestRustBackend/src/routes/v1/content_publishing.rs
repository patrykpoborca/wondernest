use axum::{
    extract::{State, Path, Query},
    response::IntoResponse,
    routing::{get, post, put, delete},
    Json, Router,
};
use uuid::Uuid;

use crate::{
    extractors::AuthClaims,
    error::AppResult,
    models::{
        CreateContentSubmissionRequest, UpdateContentSubmissionRequest,
        ContentPreviewRequest, AIAssistedCreationRequest, 
        ContentTemplateListResponse, ContentGuidelinesResponse,
        ContentSubmissionListResponse, BigDecimal
    },
    services::{AppState, content_publishing_service::ContentPublishingService},
};

pub fn router() -> Router<AppState> {
    Router::new()
        // Content submission management
        .route("/submissions", post(create_content_submission))
        .route("/submissions", get(get_creator_submissions))
        .route("/submissions/:submission_id", get(get_submission_by_id))
        .route("/submissions/:submission_id", put(update_content_submission))
        .route("/submissions/:submission_id", delete(delete_submission))
        .route("/submissions/:submission_id/submit", post(submit_for_review))
        .route("/submissions/:submission_id/preview", post(generate_content_preview))
        
        // Content templates and guidelines
        .route("/templates", get(get_content_templates))
        .route("/templates/:template_id", get(get_template_details))
        .route("/guidelines", get(get_content_guidelines))
        
        // AI-assisted content creation
        .route("/ai/create", post(create_ai_assisted_content))
        
        // Creator analytics
        .route("/analytics", get(get_creator_analytics))
}

// =============================================================================
// CONTENT SUBMISSION ENDPOINTS
// =============================================================================

async fn create_content_submission(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Json(request): Json<CreateContentSubmissionRequest>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Creating content submission '{}' for user: {}", request.title, claims.user_id);
    
    let user_id = Uuid::parse_str(&claims.user_id)
        .map_err(|_| crate::error::AppError::BadRequest("Invalid user ID".to_string()))?;
    
    let publishing_service = ContentPublishingService::new(state.db.clone());
    
    let submission = publishing_service.create_content_submission(user_id, request).await
        .map_err(|e| {
            tracing::error!("Failed to create content submission: {}", e);
            crate::error::AppError::InternalError("Failed to create content submission".to_string())
        })?;
    
    Ok(Json(submission))
}

async fn get_creator_submissions(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Query(params): Query<SubmissionListQuery>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Getting content submissions for user: {}", claims.user_id);
    
    let user_id = Uuid::parse_str(&claims.user_id)
        .map_err(|_| crate::error::AppError::BadRequest("Invalid user ID".to_string()))?;
    
    let publishing_service = ContentPublishingService::new(state.db.clone());
    
    let submissions = publishing_service.get_creator_submissions(
        user_id,
        params.page,
        params.limit,
        params.status,
    ).await
        .map_err(|e| {
            tracing::error!("Failed to get creator submissions: {}", e);
            crate::error::AppError::InternalError("Failed to get creator submissions".to_string())
        })?;
    
    Ok(Json(submissions))
}

async fn get_submission_by_id(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Path(submission_id): Path<Uuid>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Getting submission {} for user: {}", submission_id, claims.user_id);
    
    let user_id = Uuid::parse_str(&claims.user_id)
        .map_err(|_| crate::error::AppError::BadRequest("Invalid user ID".to_string()))?;
    
    let publishing_service = ContentPublishingService::new(state.db.clone());
    
    let submission = publishing_service.get_submission_by_id(submission_id, user_id).await
        .map_err(|e| {
            tracing::error!("Failed to get submission: {}", e);
            crate::error::AppError::InternalError("Failed to get submission".to_string())
        })?;
    
    Ok(Json(submission))
}

async fn update_content_submission(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Path(submission_id): Path<Uuid>,
    Json(request): Json<UpdateContentSubmissionRequest>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Updating submission {} for user: {}", submission_id, claims.user_id);
    
    let user_id = Uuid::parse_str(&claims.user_id)
        .map_err(|_| crate::error::AppError::BadRequest("Invalid user ID".to_string()))?;
    
    let publishing_service = ContentPublishingService::new(state.db.clone());
    
    let submission = publishing_service.update_content_submission(submission_id, user_id, request).await
        .map_err(|e| {
            tracing::error!("Failed to update submission: {}", e);
            crate::error::AppError::InternalError("Failed to update submission".to_string())
        })?;
    
    Ok(Json(submission))
}

async fn delete_submission(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Path(submission_id): Path<Uuid>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Deleting submission {} for user: {}", submission_id, claims.user_id);
    
    let user_id = Uuid::parse_str(&claims.user_id)
        .map_err(|_| crate::error::AppError::BadRequest("Invalid user ID".to_string()))?;
    
    let publishing_service = ContentPublishingService::new(state.db.clone());
    
    publishing_service.delete_submission(submission_id, user_id).await
        .map_err(|e| {
            tracing::error!("Failed to delete submission: {}", e);
            crate::error::AppError::InternalError("Failed to delete submission".to_string())
        })?;
    
    Ok(Json(serde_json::json!({"message": "Submission deleted successfully"})))
}

async fn submit_for_review(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Path(submission_id): Path<Uuid>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Submitting content {} for review by user: {}", submission_id, claims.user_id);
    
    let user_id = Uuid::parse_str(&claims.user_id)
        .map_err(|_| crate::error::AppError::BadRequest("Invalid user ID".to_string()))?;
    
    let publishing_service = ContentPublishingService::new(state.db.clone());
    
    let submission = publishing_service.submit_for_review(submission_id, user_id).await
        .map_err(|e| {
            tracing::error!("Failed to submit for review: {}", e);
            crate::error::AppError::InternalError("Failed to submit for review".to_string())
        })?;
    
    Ok(Json(submission))
}

async fn generate_content_preview(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Path(submission_id): Path<Uuid>,
    Json(request): Json<ContentPreviewRequest>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Generating preview for submission {} by user: {}", submission_id, claims.user_id);
    
    let user_id = Uuid::parse_str(&claims.user_id)
        .map_err(|_| crate::error::AppError::BadRequest("Invalid user ID".to_string()))?;
    
    // Verify user can access this submission
    let publishing_service = ContentPublishingService::new(state.db.clone());
    let submission = publishing_service.get_submission_by_id(submission_id, user_id).await?;
    
    // TODO: Implement actual preview generation
    let preview_response = crate::models::PublishingContentPreviewResponse {
        submission_id,
        preview_html: "<div>Preview of the story...</div>".to_string(),
        preview_data: submission.content_data.clone(),
        estimated_reading_time: submission.estimated_duration_minutes.unwrap_or(10),
        preview_assets: vec![],
    };
    
    Ok(Json(preview_response))
}

// =============================================================================
// TEMPLATES AND GUIDELINES ENDPOINTS
// =============================================================================

async fn get_content_templates(
    State(state): State<AppState>,
    AuthClaims(_claims): AuthClaims,
    Query(params): Query<TemplateQuery>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Getting content templates with filters: {:?}", params);
    
    let publishing_service = ContentPublishingService::new(state.db.clone());
    
    let templates = publishing_service.get_content_templates(
        params.category,
        params.age_range_min,
        params.age_range_max,
    ).await
        .map_err(|e| {
            tracing::error!("Failed to get content templates: {}", e);
            crate::error::AppError::InternalError("Failed to get content templates".to_string())
        })?;
    
    // TODO: Transform to proper response format with categories
    let template_responses: Vec<crate::models::ContentTemplateResponse> = templates
        .into_iter()
        .map(|t| crate::models::ContentTemplateResponse {
            id: t.id,
            name: t.name,
            description: t.description,
            category: t.category,
            age_range: format!("{}-{} months", t.age_range_min, t.age_range_max),
            difficulty_level: t.difficulty_level.unwrap_or_else(|| "beginner".to_string()),
            educational_goals: t.educational_goals.unwrap_or_default(),
            usage_count: t.usage_count.unwrap_or(0),
            average_rating: t.average_rating.unwrap_or_else(|| BigDecimal::from(0)),
            preview_image_url: t.preview_image_url,
            estimated_creation_time: 30, // Default estimate
        })
        .collect();
    
    let response = ContentTemplateListResponse {
        templates: template_responses.clone(),
        featured_templates: template_responses.into_iter().filter(|t| t.average_rating.gt(&crate::models::BigDecimal::from(4))).collect(),
        categories: vec![], // TODO: Implement category aggregation
    };
    
    Ok(Json(response))
}

async fn get_template_details(
    State(state): State<AppState>,
    AuthClaims(_claims): AuthClaims,
    Path(template_id): Path<Uuid>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Getting template details for: {}", template_id);
    
    let publishing_service = ContentPublishingService::new(state.db.clone());
    
    let template = publishing_service.get_template_by_id(template_id).await
        .map_err(|e| {
            tracing::error!("Failed to get template: {}", e);
            crate::error::AppError::InternalError("Failed to get template".to_string())
        })?
        .ok_or_else(|| crate::error::AppError::NotFound("Template not found".to_string()))?;
    
    Ok(Json(template))
}

async fn get_content_guidelines(
    State(state): State<AppState>,
    AuthClaims(_claims): AuthClaims,
    Query(params): Query<GuidelinesQuery>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Getting content guidelines with filters: {:?}", params);
    
    let publishing_service = ContentPublishingService::new(state.db.clone());
    
    let guidelines = publishing_service.get_content_guidelines(
        params.category,
        params.mandatory_only,
    ).await
        .map_err(|e| {
            tracing::error!("Failed to get content guidelines: {}", e);
            crate::error::AppError::InternalError("Failed to get content guidelines".to_string())
        })?;
    
    let guideline_responses: Vec<crate::models::ContentGuidelineResponse> = guidelines
        .into_iter()
        .map(|g| crate::models::ContentGuidelineResponse {
            id: g.id,
            title: g.title,
            category: g.category,
            description: g.description,
            mandatory: g.mandatory.unwrap_or(true),
            applies_to: g.applies_to_content_types.unwrap_or_default(),
            examples: g.examples.unwrap_or_else(|| serde_json::Value::Object(serde_json::Map::new())),
        })
        .collect();
    
    let mandatory_count = guideline_responses.iter().filter(|g| g.mandatory).count() as i32;
    let last_updated = chrono::Utc::now(); // TODO: Get actual last updated from DB
    
    let response = ContentGuidelinesResponse {
        guidelines: guideline_responses,
        mandatory_count,
        last_updated,
    };
    
    Ok(Json(response))
}

// =============================================================================
// AI-ASSISTED CONTENT CREATION
// =============================================================================

async fn create_ai_assisted_content(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Json(request): Json<AIAssistedCreationRequest>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Creating AI-assisted content for user: {}", claims.user_id);
    
    let user_id = Uuid::parse_str(&claims.user_id)
        .map_err(|_| crate::error::AppError::BadRequest("Invalid user ID".to_string()))?;
    
    let publishing_service = ContentPublishingService::new(state.db.clone());
    
    let response = publishing_service.create_ai_assisted_content(user_id, request).await
        .map_err(|e| {
            tracing::error!("Failed to create AI-assisted content: {}", e);
            crate::error::AppError::InternalError("Failed to create AI-assisted content".to_string())
        })?;
    
    Ok(Json(response))
}

// =============================================================================
// CREATOR ANALYTICS
// =============================================================================

async fn get_creator_analytics(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Getting creator analytics for user: {}", claims.user_id);
    
    let user_id = Uuid::parse_str(&claims.user_id)
        .map_err(|_| crate::error::AppError::BadRequest("Invalid user ID".to_string()))?;
    
    let publishing_service = ContentPublishingService::new(state.db.clone());
    
    let analytics = publishing_service.get_creator_analytics(user_id).await
        .map_err(|e| {
            tracing::error!("Failed to get creator analytics: {}", e);
            crate::error::AppError::InternalError("Failed to get creator analytics".to_string())
        })?;
    
    Ok(Json(analytics))
}

// =============================================================================
// QUERY PARAMETERS
// =============================================================================

#[derive(Debug, serde::Deserialize)]
struct SubmissionListQuery {
    page: Option<i32>,
    limit: Option<i32>,
    status: Option<String>,
}

#[derive(Debug, serde::Deserialize)]
struct TemplateQuery {
    category: Option<String>,
    age_range_min: Option<i32>,
    age_range_max: Option<i32>,
}

#[derive(Debug, serde::Deserialize)]
struct GuidelinesQuery {
    category: Option<String>,
    mandatory_only: Option<bool>,
}