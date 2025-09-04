use axum::{
    extract::{Multipart, Path, Query, State},
    http::StatusCode,
    middleware,
    response::IntoResponse,
    routing::{delete, get, post},
    Json, Router,
};
use chrono::Utc;
use uuid::Uuid;

use crate::{
    extractors::AuthClaims,
    error::{AppError, AppResult},
    middleware::auth::{auth_middleware},
    models::{
        FileDeleteSuccessResponse, FileListSuccessResponse, FileQueryParams,
        FileUploadSuccessResponse, FileUsageResponse, UploadedFileDto,
    },
    services::AppState,
};

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/", get(list_files))
        .route("/upload", post(upload_file))
        .route("/:file_id", get(get_file_metadata))
        .route("/:file_id/download", get(download_file))
        .route("/:file_id/usage", get(check_file_usage))
        .route("/:file_id", delete(delete_file))
        .layer(middleware::from_fn(auth_middleware))
}

// Upload file
async fn upload_file(
    State(_state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    mut _multipart: Multipart,
) -> AppResult<impl IntoResponse> {
    // Claims are already extracted via AuthClaims extractor
    tracing::info!("File upload request from user: {}", claims.user_id);

    // TODO: PRODUCTION - Implement proper file upload

    // Mock response for development
    let file_id = Uuid::new_v4().to_string();
    let response = FileUploadSuccessResponse {
        data: UploadedFileDto {
            id: file_id.clone(),
            original_name: "example.jpg".to_string(),
            mime_type: "image/jpeg".to_string(),
            file_size: 1024000,
            category: "images".to_string(),
            url: format!("/api/v1/files/{}/download", file_id),
            uploaded_at: Utc::now().to_rfc3339(),
            metadata: None,
        },
    };

    Ok((StatusCode::CREATED, Json(response)))
}

// Get file metadata
async fn get_file_metadata(
    State(_state): State<AppState>,
    Path(file_id): Path<String>,
    AuthClaims(claims): AuthClaims,
) -> AppResult<impl IntoResponse> {
    tracing::info!("File metadata request from user: {}", claims.user_id);

    // Validate file ID format
    if Uuid::parse_str(&file_id).is_err() {
        return Err(AppError::BadRequest("Invalid file ID format".to_string()));
    }

    // Mock response
    let mock_file = UploadedFileDto {
        id: file_id.clone(),
        original_name: "example.jpg".to_string(),
        mime_type: "image/jpeg".to_string(),
        file_size: 1024000,
        category: "images".to_string(),
        url: format!("/api/v1/files/{}/download", file_id),
        uploaded_at: Utc::now().to_rfc3339(),
        metadata: None,
    };

    Ok((StatusCode::OK, Json(mock_file)))
}

// Download file
async fn download_file(
    State(_state): State<AppState>,
    Path(file_id): Path<String>,
    AuthClaims(claims): AuthClaims,
) -> AppResult<impl IntoResponse> {
    tracing::info!("File download request from user: {}", claims.user_id);

    // Validate file ID format
    if Uuid::parse_str(&file_id).is_err() {
        return Err(AppError::BadRequest("Invalid file ID format".to_string()));
    }

    // TODO: PRODUCTION - Implement actual file download
    Ok((
        StatusCode::OK,
        "File download would happen here in production",
    ))
}

// Check file usage
async fn check_file_usage(
    State(_state): State<AppState>,
    Path(file_id): Path<String>,
    AuthClaims(claims): AuthClaims,
) -> AppResult<impl IntoResponse> {
    tracing::info!("File usage check from user: {}", claims.user_id);

    // Validate file ID format
    if Uuid::parse_str(&file_id).is_err() {
        return Err(AppError::BadRequest("Invalid file ID format".to_string()));
    }

    let mock_usage = FileUsageResponse {
        is_used: false,
        stories: vec![],
    };

    Ok((StatusCode::OK, Json(mock_usage)))
}

// Delete file
async fn delete_file(
    State(_state): State<AppState>,
    Path(file_id): Path<String>,
    AuthClaims(claims): AuthClaims,
) -> AppResult<impl IntoResponse> {
    tracing::info!("File delete request from user: {}", claims.user_id);

    // Validate file ID format
    if Uuid::parse_str(&file_id).is_err() {
        return Err(AppError::BadRequest("Invalid file ID format".to_string()));
    }

    // TODO: PRODUCTION - Implement actual file deletion

    let response = FileDeleteSuccessResponse {
        message: "File deleted successfully - TODO: Implement deletion".to_string(),
    };

    Ok((StatusCode::OK, Json(response)))
}

// List files
async fn list_files(
    State(_state): State<AppState>,
    Query(params): Query<FileQueryParams>,
    AuthClaims(claims): AuthClaims,
) -> AppResult<impl IntoResponse> {
    tracing::info!("File list request from user: {}", claims.user_id);

    let _limit = params.limit.unwrap_or(100);
    let _offset = params.offset.unwrap_or(0);

    // TODO: PRODUCTION - Query actual files from database

    // Mock response
    let mock_files = vec![
        UploadedFileDto {
            id: Uuid::new_v4().to_string(),
            original_name: "image1.jpg".to_string(),
            mime_type: "image/jpeg".to_string(),
            file_size: 512000,
            category: params.category.clone().unwrap_or("images".to_string()),
            url: "/api/v1/files/1/download".to_string(),
            uploaded_at: Utc::now().to_rfc3339(),
            metadata: None,
        },
        UploadedFileDto {
            id: Uuid::new_v4().to_string(),
            original_name: "image2.png".to_string(),
            mime_type: "image/png".to_string(),
            file_size: 256000,
            category: params.category.unwrap_or("images".to_string()),
            url: "/api/v1/files/2/download".to_string(),
            uploaded_at: Utc::now().to_rfc3339(),
            metadata: None,
        },
    ];

    let response = FileListSuccessResponse {
        data: mock_files,
    };

    Ok((StatusCode::OK, Json(response)))
}