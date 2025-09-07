use axum::{
    extract::{State, Path, Query},
    response::IntoResponse,
    routing::{get, post, put},
    Json, Router,
};
use uuid::Uuid;

use crate::{
    extractors::AuthClaims,
    error::AppResult,
    models::{
        ModerationQueueRequest, ModerationDecisionRequest
    },
    services::{AppState, content_moderation_service::ContentModerationService},
};

pub fn router() -> Router<AppState> {
    Router::new()
        // Moderation queue management
        .route("/queue", get(get_moderation_queue))
        .route("/queue/:queue_id/assign", post(assign_moderator))
        .route("/queue/:queue_id/start", post(start_review))
        .route("/queue/:queue_id/escalate", post(escalate_submission))
        
        // Moderation decisions
        .route("/submissions/:submission_id/decision", post(submit_moderation_decision))
        .route("/submissions/:submission_id", get(get_submission_for_moderation))
        
        // Moderator workload and analytics
        .route("/workload", get(get_moderator_workload))
        .route("/analytics", get(get_moderation_analytics))
}

// =============================================================================
// MODERATION QUEUE ENDPOINTS
// =============================================================================

async fn get_moderation_queue(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Query(request): Query<ModerationQueueRequest>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Getting moderation queue for moderator: {}", claims.user_id);
    
    // TODO: Verify user has moderator role
    
    let moderation_service = ContentModerationService::new(state.db.clone());
    
    let queue_response = moderation_service.get_moderation_queue(request).await
        .map_err(|e| {
            tracing::error!("Failed to get moderation queue: {}", e);
            crate::error::AppError::InternalError("Failed to get moderation queue".to_string())
        })?;
    
    Ok(Json(queue_response))
}

async fn assign_moderator(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Path(queue_id): Path<Uuid>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Assigning moderator {} to queue item {}", claims.user_id, queue_id);
    
    let moderator_id = Uuid::parse_str(&claims.user_id)
        .map_err(|_| crate::error::AppError::BadRequest("Invalid user ID".to_string()))?;
    
    // TODO: Verify user has moderator role
    
    let moderation_service = ContentModerationService::new(state.db.clone());
    
    let queue_item = moderation_service.assign_moderator(queue_id, moderator_id).await
        .map_err(|e| {
            tracing::error!("Failed to assign moderator: {}", e);
            crate::error::AppError::InternalError("Failed to assign moderator".to_string())
        })?;
    
    Ok(Json(queue_item))
}

async fn start_review(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Path(queue_id): Path<Uuid>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Starting review for queue item {} by moderator {}", queue_id, claims.user_id);
    
    let moderator_id = Uuid::parse_str(&claims.user_id)
        .map_err(|_| crate::error::AppError::BadRequest("Invalid user ID".to_string()))?;
    
    let moderation_service = ContentModerationService::new(state.db.clone());
    
    let queue_item = moderation_service.start_review(queue_id, moderator_id).await
        .map_err(|e| {
            tracing::error!("Failed to start review: {}", e);
            crate::error::AppError::InternalError("Failed to start review".to_string())
        })?;
    
    Ok(Json(queue_item))
}

async fn escalate_submission(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Path(queue_id): Path<Uuid>,
    Json(request): Json<EscalationRequest>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Escalating queue item {} by moderator {}", queue_id, claims.user_id);
    
    let moderator_id = Uuid::parse_str(&claims.user_id)
        .map_err(|_| crate::error::AppError::BadRequest("Invalid user ID".to_string()))?;
    
    let moderation_service = ContentModerationService::new(state.db.clone());
    
    // Get submission ID from queue
    // TODO: This should be more direct - for now using a placeholder approach
    let submission_id = request.submission_id;
    
    moderation_service.escalate_submission(submission_id, moderator_id, request.reason).await
        .map_err(|e| {
            tracing::error!("Failed to escalate submission: {}", e);
            crate::error::AppError::InternalError("Failed to escalate submission".to_string())
        })?;
    
    Ok(Json(serde_json::json!({"message": "Submission escalated successfully"})))
}

// =============================================================================
// MODERATION DECISION ENDPOINTS
// =============================================================================

async fn submit_moderation_decision(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Path(submission_id): Path<Uuid>,
    Json(request): Json<ModerationDecisionRequest>,
) -> AppResult<impl IntoResponse> {
    tracing::info!(
        "Submitting moderation decision '{}' for submission {} by moderator {}", 
        request.decision, submission_id, claims.user_id
    );
    
    let moderator_id = Uuid::parse_str(&claims.user_id)
        .map_err(|_| crate::error::AppError::BadRequest("Invalid user ID".to_string()))?;
    
    let moderation_service = ContentModerationService::new(state.db.clone());
    
    let decision = moderation_service.submit_moderation_decision(submission_id, moderator_id, request).await
        .map_err(|e| {
            tracing::error!("Failed to submit moderation decision: {}", e);
            crate::error::AppError::InternalError("Failed to submit moderation decision".to_string())
        })?;
    
    Ok(Json(decision))
}

async fn get_submission_for_moderation(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Path(submission_id): Path<Uuid>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Getting submission {} for moderation by {}", submission_id, claims.user_id);
    
    let moderator_id = Uuid::parse_str(&claims.user_id)
        .map_err(|_| crate::error::AppError::BadRequest("Invalid user ID".to_string()))?;
    
    // TODO: Verify moderator has access to this submission
    let publishing_service = crate::services::content_publishing_service::ContentPublishingService::new(state.db.clone());
    
    // For moderation, we bypass the creator-only restriction
    let submission = publishing_service.repository.get_submission_by_id(submission_id).await
        .map_err(|e| {
            tracing::error!("Failed to get submission for moderation: {}", e);
            crate::error::AppError::InternalError("Failed to get submission for moderation".to_string())
        })?
        .ok_or_else(|| crate::error::AppError::NotFound("Submission not found".to_string()))?;
    
    // Return enhanced submission data for moderation
    let moderation_data = ModerationSubmissionResponse {
        submission,
        validation_results: None, // TODO: Get validation results
        creator_history: None,    // TODO: Get creator history
        similar_submissions: vec![], // TODO: Get similar submissions for comparison
    };
    
    Ok(Json(moderation_data))
}

// =============================================================================
// MODERATOR ANALYTICS ENDPOINTS
// =============================================================================

async fn get_moderator_workload(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Getting workload for moderator: {}", claims.user_id);
    
    let moderator_id = Uuid::parse_str(&claims.user_id)
        .map_err(|_| crate::error::AppError::BadRequest("Invalid user ID".to_string()))?;
    
    let moderation_service = ContentModerationService::new(state.db.clone());
    
    let workload = moderation_service.get_moderator_workload(moderator_id).await
        .map_err(|e| {
            tracing::error!("Failed to get moderator workload: {}", e);
            crate::error::AppError::InternalError("Failed to get moderator workload".to_string())
        })?;
    
    Ok(Json(workload))
}

async fn get_moderation_analytics(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Getting moderation analytics for: {}", claims.user_id);
    
    // TODO: Verify user has admin/senior moderator role for system-wide analytics
    
    let analytics = ModerationAnalytics {
        total_submissions_pending: 42, // TODO: Get from DB
        average_queue_time_hours: 2.5,
        approval_rate_percentage: 78.5,
        top_rejection_reasons: vec![
            "Age inappropriate content".to_string(),
            "Poor educational value".to_string(),
            "Grammar and spelling errors".to_string(),
        ],
        moderator_performance: vec![], // TODO: Get moderator performance data
    };
    
    Ok(Json(analytics))
}

// =============================================================================
// REQUEST/RESPONSE TYPES
// =============================================================================

#[derive(Debug, serde::Deserialize)]
struct EscalationRequest {
    submission_id: Uuid,
    reason: String,
}

#[derive(Debug, serde::Serialize)]
struct ModerationSubmissionResponse {
    submission: crate::models::ContentSubmission,
    validation_results: Option<crate::models::ContentValidationResult>,
    creator_history: Option<CreatorModerationHistory>,
    similar_submissions: Vec<Uuid>,
}

#[derive(Debug, serde::Serialize)]
struct CreatorModerationHistory {
    total_submissions: i32,
    approval_rate: f64,
    average_quality_score: f64,
    recent_violations: Vec<String>,
}

#[derive(Debug, serde::Serialize)]
struct ModerationAnalytics {
    total_submissions_pending: i32,
    average_queue_time_hours: f64,
    approval_rate_percentage: f64,
    top_rejection_reasons: Vec<String>,
    moderator_performance: Vec<ModeratorPerformance>,
}

#[derive(Debug, serde::Serialize)]
struct ModeratorPerformance {
    moderator_id: Uuid,
    moderator_name: String,
    items_reviewed: i32,
    average_review_time_minutes: f64,
    approval_rate: f64,
    consistency_score: f64,
}