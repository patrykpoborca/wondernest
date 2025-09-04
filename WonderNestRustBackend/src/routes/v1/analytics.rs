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
use uuid::Uuid;

use crate::{
    extractors::AuthClaims,
    error::{AppError, AppResult},
    middleware::auth::{auth_middleware},
    models::{
        DailyAnalytics, ChildInsights, WeeklyOverview, ChildMilestones, MilestoneItem,
        AnalyticsEvent, AnalyticsEventResponse, AnalyticsGameDataResponse, AnalyticsGameDataContainer, 
        AnalyticsGameDataItem, MessageResponse,
    },
    services::AppState,
};

#[derive(Debug, Deserialize)]
pub struct AnalyticsQueryParams {
    #[serde(rename = "childId")]
    pub child_id: Option<String>,
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/daily", get(get_daily_analytics))
        .route("/children/:child_id/daily", get(legacy_daily_analytics))
        .route("/children/:child_id/insights", get(get_child_insights))
        .route("/children/:child_id/milestones", get(get_child_milestones))
        .route("/children/:child_id/events", get(get_analytics_events))
        .route("/weekly", get(get_weekly_overview))
        .route("/events", post(track_analytics_event))
        .layer(middleware::from_fn(auth_middleware))
}

// Daily analytics for a specific child (matching Kotlin endpoint exactly)
async fn get_daily_analytics(
    State(_state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Query(params): Query<AnalyticsQueryParams>,
) -> AppResult<axum::response::Response> {
    // Claims are already extracted via AuthClaims extractor
    let _claims_check = &claims;

    let child_id = params.child_id.ok_or_else(|| {
        AppError::BadRequest("Child ID is required".to_string())
    })?;

    // TODO: PRODUCTION - Fetch real analytics from database
    let mock_analytics = generate_mock_daily_analytics(&child_id);
    
    tracing::info!("Generated daily analytics for child: {}", child_id);

    Ok((StatusCode::OK, Json(mock_analytics)).into_response())
}

// Legacy endpoint (matching Kotlin endpoint exactly)
async fn legacy_daily_analytics(
    State(_state): State<AppState>,
) -> AppResult<axum::response::Response> {
    Ok((StatusCode::OK, Json(MessageResponse {
        message: "Use /analytics/daily?childId={childId} instead".to_string()
    })).into_response())
}

// Get child insights (matching Kotlin endpoint exactly)
async fn get_child_insights(
    State(_state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Path(child_id): Path<String>,
) -> AppResult<axum::response::Response> {
    // Claims are already extracted via AuthClaims extractor
    let _claims_check = &claims;

    if child_id.is_empty() {
        return Ok((StatusCode::BAD_REQUEST, Json(MessageResponse {
            message: "Child ID is required".to_string()
        })).into_response());
    }

    // TODO: PRODUCTION - Generate real insights based on child's learning patterns
    let mock_insights = generate_mock_child_insights(&child_id);
    
    tracing::info!("Generated insights for child: {}", child_id);

    Ok((StatusCode::OK, Json(mock_insights)).into_response())
}

// Weekly overview for parent dashboard (matching Kotlin endpoint exactly)
async fn get_weekly_overview(
    State(_state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Query(params): Query<AnalyticsQueryParams>,
) -> AppResult<axum::response::Response> {
    // Extract user claims from JWT middleware
    let _claims_check = &claims;

    let child_id = params.child_id.ok_or_else(|| {
        AppError::BadRequest("Child ID is required".to_string())
    })?;

    // TODO: PRODUCTION - Calculate real weekly overview
    let mock_weekly = generate_mock_weekly_overview(&child_id);
    
    tracing::info!("Generated weekly overview for child: {}", child_id);

    Ok((StatusCode::OK, Json(mock_weekly)).into_response())
}

// Get child milestones (matching Kotlin endpoint exactly)
async fn get_child_milestones(
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

    // TODO: PRODUCTION - Track and return actual developmental milestones
    let mock_milestones = ChildMilestones {
        age: 6,
        milestones: vec![
            MilestoneItem {
                category: "math".to_string(),
                description: "Can count to 100".to_string(),
                achieved: true,
            },
            MilestoneItem {
                category: "reading".to_string(),
                description: "Recognizes sight words".to_string(),
                achieved: true,
            },
            MilestoneItem {
                category: "social".to_string(),
                description: "Shares and takes turns".to_string(),
                achieved: false,
            },
        ],
        next_goals: vec![
            "Practice addition with objects".to_string(),
            "Read simple sentences".to_string(),
            "Practice conflict resolution".to_string(),
        ],
    };

    tracing::info!("Generated milestones for child: {}", child_id);

    Ok((StatusCode::OK, Json(mock_milestones)).into_response())
}

// Get analytics events for a child - for game data retrieval (matching Kotlin exactly)
async fn get_analytics_events(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Path(child_id_param): Path<String>,
) -> AppResult<axum::response::Response> {
    // Extract user claims from JWT middleware
    let _claims_check = &claims;

    if child_id_param.is_empty() {
        return Ok((StatusCode::BAD_REQUEST, Json(MessageResponse {
            message: "Child ID is required".to_string()
        })).into_response());
    }

    tracing::info!("Loading game data for child: {}", child_id_param);

    // Parse UUID
    let child_id = match Uuid::parse_str(&child_id_param) {
        Ok(id) => id,
        Err(_) => {
            return Ok((StatusCode::BAD_REQUEST, Json(MessageResponse {
                message: "Invalid child ID format".to_string()
            })).into_response());
        }
    };

    // TODO: PRODUCTION - Query real game data from database
    // For now, return mock data in the expected format
    let game_data_list: Vec<AnalyticsGameDataItem> = vec![
        AnalyticsGameDataItem {
            data_key: "sticker_project_1".to_string(),
            data_value: r#"{"projectId": "1", "name": "My First Project", "stickers": []}"#.to_string(),
        },
    ];

    let response = AnalyticsGameDataResponse {
        data: AnalyticsGameDataContainer {
            game_data: game_data_list.clone(),
        },
    };

    tracing::info!("Loaded {} projects from backend", game_data_list.len());

    Ok((StatusCode::OK, Json(response)).into_response())
}

// Track analytics events (matching Kotlin endpoint exactly - very complex!)
async fn track_analytics_event(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    body: String, // Raw body for detailed logging like Kotlin
) -> AppResult<axum::response::Response> {
    tracing::info!("=== ANALYTICS EVENT POST REQUEST START ===");
    
    // Extract user claims from JWT middleware
    let _claims_check = &claims;

    tracing::info!("Receiving analytics event...");
    
    // Log raw request body for debugging (matching Kotlin exactly)
    tracing::info!("Raw request body: {}", body);
    tracing::info!("Raw body length: {} characters", body.len());

    // Parse the JSON manually to get better error information (matching Kotlin)
    let event: AnalyticsEvent = match serde_json::from_str(&body) {
        Ok(event) => event,
        Err(json_exception) => {
            tracing::error!("JSON deserialization failed: {}", json_exception);
            tracing::error!("Failed to parse JSON: {}", body);
            return Ok((StatusCode::BAD_REQUEST, Json(MessageResponse {
                message: format!("Invalid JSON format: {}", json_exception)
            })).into_response());
        }
    };

    tracing::info!("Successfully parsed AnalyticsEvent:");
    tracing::info!("  eventType: '{}'", event.event_type);
    tracing::info!("  childId: '{}'", event.child_id);
    tracing::info!("  contentId: '{:?}'", event.content_id);
    tracing::info!("  duration: {:?}", event.duration);
    tracing::info!("  sessionId: '{:?}'", event.session_id);
    tracing::info!("  eventData keys: {:?}", event.event_data.keys().collect::<Vec<_>>());
    tracing::info!("  eventData size: {}", event.event_data.len());

    // Log each eventData field (matching Kotlin exactly)
    for (key, value) in &event.event_data {
        tracing::info!("    eventData['{}']: {}", key, value);
    }

    // Basic validation (matching Kotlin exactly)
    if event.event_type.is_empty() {
        tracing::warn!("Event type is blank");
        return Ok((StatusCode::BAD_REQUEST, Json(MessageResponse {
            message: "Event type is required".to_string()
        })).into_response());
    }

    if event.child_id.is_empty() {
        tracing::warn!("Child ID is blank");
        return Ok((StatusCode::BAD_REQUEST, Json(MessageResponse {
            message: "Child ID is required".to_string()
        })).into_response());
    }

    tracing::info!("All validation passed, processing event...");

    // Special handling for sticker book project saves (matching Kotlin exactly)
    tracing::info!("🎯 CHECKING EVENT TYPE: eventType='{}', gameType='{:?}'", 
        event.event_type, event.event_data.get("gameType"));

    if event.event_type == "save_project" && 
       event.event_data.get("gameType").and_then(|v| v.as_str()) == Some("sticker_book") {
        tracing::info!("🎨 ===== STICKER BOOK SAVE DETECTED =====");
        tracing::info!("🎨 Project save event for child: {}", event.child_id);

        let project_id = event.event_data.get("projectId")
            .and_then(|v| v.as_str())
            .unwrap_or("");
        let full_project_data = event.event_data.get("fullProjectData")
            .and_then(|v| v.as_str())
            .unwrap_or("");

        tracing::info!("🎨 Project ID: {}", project_id);
        tracing::info!("🎨 Full project data length: {} characters", full_project_data.len());

        if !project_id.is_empty() && !full_project_data.is_empty() {
            tracing::info!("🎨 Both projectId and fullProjectData are present - proceeding with save");
            
            // TODO: PRODUCTION - Implement actual database save (matching Kotlin logic exactly)
            // For now, just log the save attempt
            tracing::info!("🎨 ✅ MOCK SAVE sticker project: {} for child: {}", project_id, event.child_id);
        } else {
            tracing::warn!("Missing project ID or full project data in save_project event");
        }
    }

    // Handle project deletions (matching Kotlin exactly)
    if event.event_type == "delete_project" && 
       event.event_data.get("gameType").and_then(|v| v.as_str()) == Some("sticker_book") {
        tracing::info!("Detected sticker book project delete event");
        
        let project_id = event.event_data.get("projectId")
            .and_then(|v| v.as_str())
            .unwrap_or("");
        
        if !project_id.is_empty() {
            // TODO: PRODUCTION - Implement actual database delete
            tracing::info!("🎨 ✅ MOCK DELETE sticker project: {} for child: {}", project_id, event.child_id);
        }
    }

    // TODO: PRODUCTION - Store event in analytics database
    // This would include events like:
    // - content_started, content_completed, content_paused
    // - activity_started, activity_completed
    // - milestone_achieved, struggle_detected
    // - parent_intervention_needed

    let event_id = format!("event_{}", Utc::now().timestamp_millis());
    let timestamp = Utc::now().timestamp_millis().to_string();

    let response = AnalyticsEventResponse {
        message: "Analytics event tracked successfully".to_string(),
        event_id: event_id.clone(),
        timestamp: timestamp.clone(),
    };

    tracing::info!("Sending success response: {:?}", response);
    tracing::info!("Successfully tracked analytics event: {} for child: {}", event.event_type, event.child_id);
    tracing::info!("=== ANALYTICS EVENT POST REQUEST SUCCESS ===");

    Ok((StatusCode::CREATED, Json(response)).into_response())
}

// TODO: PRODUCTION - Replace these mock functions with real analytics calculations
fn generate_mock_daily_analytics(child_id: &str) -> DailyAnalytics {
    DailyAnalytics {
        date: "2024-08-14".to_string(),
        child_id: child_id.to_string(),
        total_screen_time: 45,
        content_consumed: 3,
        educational_time: 30,
        average_session_length: 15,
        most_engaged_category: "educational".to_string(),
        completed_activities: 2,
        learning_progress: 0.75,
    }
}

fn generate_mock_child_insights(child_id: &str) -> ChildInsights {
    ChildInsights {
        child_id: child_id.to_string(),
        preferred_learning_style: "Visual and Interactive".to_string(),
        strong_subjects: vec![
            "Colors and Shapes".to_string(),
            "Animals".to_string(),
            "Numbers".to_string(),
        ],
        improvement_areas: vec![
            "Letter Recognition".to_string(),
            "Fine Motor Skills".to_string(),
        ],
        recommended_activities: vec![
            "Alphabet Tracing".to_string(),
            "Animal Sound Matching".to_string(),
            "Shape Sorting".to_string(),
        ],
        parental_guidance: vec![
            "Encourage more interactive reading sessions".to_string(),
            "Practice writing letters together".to_string(),
            "Use physical objects for counting exercises".to_string(),
        ],
    }
}

fn generate_mock_weekly_overview(child_id: &str) -> WeeklyOverview {
    WeeklyOverview {
        week_start: "2024-08-11".to_string(),
        total_screen_time: 315, // minutes for the week
        educational_percentage: 68.0,
        average_daily_usage: 45,
        top_categories: vec![
            "educational".to_string(),
            "stories".to_string(),
            "music".to_string(),
        ],
        completion_rate: 0.82,
        parental_interaction: 12, // number of parent interactions
    }
}