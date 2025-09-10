use crate::error::AppError;
use crate::models::{
    BulkPublishRequest, ContentListRequest, CreateAdminCreatorRequest,
    CreateContentRequest, CsvContentRow, PublishContentRequest, UpdateAdminCreatorRequest,
    UpdateContentRequest,
};
use crate::services::AppState;
use crate::extractors::AdminClaimsExtractor;
use axum::{
    extract::{Path, Query, State},
    response::Json,
    routing::{get, post, put},
    Router,
};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use uuid::Uuid;

// =============================================================================
// ADMIN CREATOR ROUTES
// =============================================================================

#[derive(Serialize)]
pub struct CreateCreatorResponse {
    pub success: bool,
    pub creator: crate::models::AdminCreator,
}

pub async fn quick_create_creator(
    State(state): State<AppState>,
    AdminClaimsExtractor(claims): AdminClaimsExtractor,
    Json(request): Json<CreateAdminCreatorRequest>,
) -> Result<Json<CreateCreatorResponse>, AppError> {
    
    let service = &state.admin_content;
    let admin_id = Uuid::parse_str(&claims.admin_id)
        .map_err(|_| AppError::BadRequest("Invalid admin ID".to_string()))?;
    let creator = service
        .create_admin_creator(request, admin_id)
        .await?;

    Ok(Json(CreateCreatorResponse {
        success: true,
        creator,
    }))
}

pub async fn list_admin_creators(
    State(state): State<AppState>,
    Query(params): Query<HashMap<String, String>>,
) -> Result<Json<Vec<crate::models::AdminCreator>>, AppError> {
    let service = &state.admin_content;
    let active_only = params
        .get("active_only")
        .and_then(|v| v.parse::<bool>().ok())
        .unwrap_or(true);

    let creators = service.list_admin_creators(active_only).await?;

    Ok(Json(creators))
}

pub async fn get_admin_creator(
    State(state): State<AppState>,
    Path(creator_id): Path<Uuid>,
) -> Result<Json<crate::models::AdminCreator>, AppError> {
    let service = &state.admin_content;
    let creator = service.get_admin_creator(creator_id).await?;

    Ok(Json(creator))
}

pub async fn update_admin_creator(
    State(state): State<AppState>,
    Path(creator_id): Path<Uuid>,
    Json(request): Json<UpdateAdminCreatorRequest>,
) -> Result<Json<crate::models::AdminCreator>, AppError> {
    let service = &state.admin_content;
    let creator = service.update_admin_creator(creator_id, request).await?;

    Ok(Json(creator))
}

// =============================================================================
// CONTENT MANAGEMENT ROUTES
// =============================================================================

#[derive(Serialize)]
pub struct CreateContentResponse {
    pub success: bool,
    pub content: crate::models::AdminContentStaging,
}

pub async fn upload_content(
    State(state): State<AppState>,
    Json(request): Json<CreateContentRequest>,
) -> Result<Json<CreateContentResponse>, AppError> {
    let service = &state.admin_content;
    let content = service.create_content(request).await?;

    Ok(Json(CreateContentResponse {
        success: true,
        content,
    }))
}

pub async fn list_staged_content(
    State(state): State<AppState>,
    Query(params): Query<HashMap<String, String>>,
) -> Result<Json<crate::models::ContentListResponse>, AppError> {
    let service = &state.admin_content;

    // Parse query parameters
    let request = ContentListRequest {
        creator_id: params
            .get("creator_id")
            .and_then(|v| Uuid::parse_str(v).ok()),
        content_type: params
            .get("content_type")
            .and_then(|v| serde_json::from_str(&format!("\"{}\"", v)).ok()),
        status: params
            .get("status")
            .and_then(|v| serde_json::from_str(&format!("\"{}\"", v)).ok()),
        search: params.get("search").cloned(),
        page: params.get("page").and_then(|v| v.parse::<i32>().ok()),
        limit: params.get("limit").and_then(|v| v.parse::<i32>().ok()),
        sort_by: params.get("sort_by").cloned(),
        sort_order: params.get("sort_order").cloned(),
    };

    let response = service.list_content(request).await?;

    Ok(Json(response))
}

pub async fn get_content(
    State(state): State<AppState>,
    Path(content_id): Path<Uuid>,
) -> Result<Json<crate::models::AdminContentStaging>, AppError> {
    let service = &state.admin_content;
    let content = service.get_content(content_id).await?;

    Ok(Json(content))
}

pub async fn update_content(
    State(state): State<AppState>,
    Path(content_id): Path<Uuid>,
    Json(request): Json<UpdateContentRequest>,
) -> Result<Json<crate::models::AdminContentStaging>, AppError> {
    let service = &state.admin_content;
    let content = service.update_content(content_id, request).await?;

    Ok(Json(content))
}

// =============================================================================
// PUBLISHING ROUTES
// =============================================================================

pub async fn publish_content(
    State(state): State<AppState>,
    AdminClaimsExtractor(claims): AdminClaimsExtractor,
    Path(content_id): Path<Uuid>,
    Json(_request): Json<PublishContentRequest>,
) -> Result<Json<crate::models::PublishContentResponse>, AppError> {
    
    let service = &state.admin_content;
    let admin_id = Uuid::parse_str(&claims.admin_id)
        .map_err(|_| AppError::BadRequest("Invalid admin ID".to_string()))?;
    let response = service.publish_content(content_id, admin_id).await?;

    Ok(Json(response))
}

pub async fn bulk_publish(
    State(state): State<AppState>,
    AdminClaimsExtractor(claims): AdminClaimsExtractor,
    Json(request): Json<BulkPublishRequest>,
) -> Result<Json<crate::models::BulkPublishResponse>, AppError> {
    
    let service = &state.admin_content;
    
    let mut results = Vec::new();
    let mut successful = 0;
    let mut failed = 0;

    let admin_id = Uuid::parse_str(&claims.admin_id)
        .map_err(|_| AppError::BadRequest("Invalid admin ID".to_string()))?;
    
    for content_id in request.content_ids {
        match service.publish_content(content_id, admin_id).await {
            Ok(response) => {
                successful += 1;
                results.push(crate::models::PublishResult {
                    content_id,
                    success: true,
                    marketplace_listing_id: Some(response.marketplace_listing_id),
                    error: None,
                });
            }
            Err(err) => {
                failed += 1;
                results.push(crate::models::PublishResult {
                    content_id,
                    success: false,
                    marketplace_listing_id: None,
                    error: Some(err.to_string()),
                });
            }
        }
    }

    let response = crate::models::BulkPublishResponse {
        total_requested: results.len() as i32,
        successful,
        failed,
        results,
    };

    Ok(Json(response))
}

// =============================================================================
// BULK IMPORT ROUTES
// =============================================================================

#[derive(Deserialize)]
pub struct BulkUploadCsvRequest {
    pub creator_id: Uuid,
    pub csv_data: String, // CSV as string
    pub filename: Option<String>,
}

#[axum::debug_handler]
pub async fn bulk_upload_csv(
    State(state): State<AppState>,
    AdminClaimsExtractor(claims): AdminClaimsExtractor,
    Json(request): Json<BulkUploadCsvRequest>,
) -> Result<Json<crate::models::BulkImportResponse>, AppError> {
    
    let service = &state.admin_content;

    // Parse CSV
    let mut csv_reader = csv::Reader::from_reader(request.csv_data.as_bytes());
    let mut content_items = Vec::new();
    let mut errors = Vec::new();

    for (row_index, result) in csv_reader.deserialize::<CsvContentRow>().enumerate() {
        match result {
            Ok(row) => {
                match row.to_create_content_request(request.creator_id, None) {
                    Ok(content_request) => content_items.push(content_request),
                    Err(err) => errors.push(format!("Row {}: {}", row_index + 2, err)),
                }
            }
            Err(err) => errors.push(format!("Row {}: CSV parse error - {}", row_index + 2, err)),
        }
    }

    if !errors.is_empty() && content_items.is_empty() {
        return Ok(Json(crate::models::BulkImportResponse {
            batch_id: Uuid::new_v4(),
            status: crate::models::BulkImportStatus::Failed,
            total_items: 0,
            processed_items: 0,
            successful_items: 0,
            failed_items: errors.len() as i32,
            errors,
        }));
    }

    // Create bulk import record
    let admin_id = Uuid::parse_str(&claims.admin_id)
        .map_err(|_| AppError::BadRequest("Invalid admin ID".to_string()))?;
    
    let bulk_import = service
        .create_bulk_import(
            admin_id,
            "csv".to_string(),
            request.filename,
            content_items.len() as i32,
        )
        .await?;

    // Process items
    let mut successful = 0;
    let mut failed = 0;

    for (index, mut item) in content_items.into_iter().enumerate() {
        item.bulk_import_batch_id = Some(bulk_import.batch_id);
        
        match service.create_content(item).await {
            Ok(_) => successful += 1,
            Err(err) => {
                failed += 1;
                errors.push(format!("Item {}: {}", index + 1, err));
            }
        }
    }

    // Update bulk import status
    let final_status = if failed == 0 {
        crate::models::BulkImportStatus::Completed
    } else if successful == 0 {
        crate::models::BulkImportStatus::Failed
    } else {
        crate::models::BulkImportStatus::Completed // Partial success
    };

    service
        .update_bulk_import_progress(
            bulk_import.batch_id,
            successful + failed,
            successful,
            failed,
            Some(final_status.clone()),
        )
        .await?;

    Ok(Json(crate::models::BulkImportResponse {
        batch_id: bulk_import.batch_id,
        status: final_status,
        total_items: bulk_import.total_items.unwrap_or(0),
        processed_items: successful + failed,
        successful_items: successful,
        failed_items: failed,
        errors,
    }))
}

// =============================================================================
// FILE UPLOAD ROUTES
// =============================================================================

#[derive(Serialize)]
pub struct PreSignedUrlResponse {
    pub upload_url: String,
    pub file_key: String,
    pub public_url: String,
    pub expires_in: u64,
}

pub async fn get_upload_url(
    State(state): State<AppState>,
    Query(params): Query<HashMap<String, String>>,
) -> Result<Json<PreSignedUrlResponse>, AppError> {
    let content_type = params
        .get("content_type")
        .unwrap_or(&"application/octet-stream".to_string())
        .clone();
    let file_extension = params.get("file_extension").cloned().unwrap_or_default();

    // Generate unique file key
    let file_key = format!(
        "admin-content/{}/{}{}",
        chrono::Utc::now().format("%Y/%m/%d"),
        Uuid::new_v4(),
        if file_extension.starts_with('.') {
            file_extension
        } else if !file_extension.is_empty() {
            format!(".{}", file_extension)
        } else {
            String::new()
        }
    );

    // Get presigned URL for upload
    let upload_url = state
        .storage
        .get_presigned_url(&file_key, 3600) // 1 hour expiry
        .await
        .map_err(|e| AppError::InternalError(format!("Failed to generate upload URL: {}", e)))?;

    // Generate public URL (for CDN access after upload)
    let public_url = format!("https://cdn.wondernest.com/{}", file_key);

    Ok(Json(PreSignedUrlResponse {
        upload_url,
        file_key,
        public_url,
        expires_in: 3600,
    }))
}

// =============================================================================
// DASHBOARD & METRICS ROUTES
// =============================================================================

pub async fn get_dashboard_stats(
    State(state): State<AppState>,
) -> Result<Json<crate::models::DashboardStatsResponse>, AppError> {
    let service = &state.admin_content;
    let stats = service.get_dashboard_stats().await?;

    Ok(Json(stats))
}

// =============================================================================
// ROUTE REGISTRATION
// =============================================================================

pub fn routes() -> Router<AppState> {
    Router::new()
        // Creator management
        .route("/creators/quick-create", post(quick_create_creator))
        .route("/creators/list", get(list_admin_creators))
        .route("/creators/:creator_id", get(get_admin_creator))
        .route("/creators/:creator_id", put(update_admin_creator))
        
        // Content management
        .route("/content/upload", post(upload_content))
        .route("/content/list", get(list_staged_content))
        .route("/content/:content_id", get(get_content))
        .route("/content/:content_id", put(update_content))
        
        // Publishing
        .route("/content/:content_id/publish", post(publish_content))
        .route("/content/bulk-publish", post(bulk_publish))
        
        // Bulk operations
        .route("/content/bulk-upload-csv", post(bulk_upload_csv))
        
        // File upload
        .route("/upload-url", get(get_upload_url))
        
        // Dashboard
        .route("/dashboard/stats", get(get_dashboard_stats))
        .layer(axum::middleware::from_fn(crate::middleware::admin_auth::admin_auth_middleware))
}