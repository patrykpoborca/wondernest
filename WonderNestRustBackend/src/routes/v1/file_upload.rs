use axum::{
    body::Bytes,
    extract::{Multipart, Path, Query, State},
    http::{header, StatusCode},
    middleware,
    response::IntoResponse,
    routing::{delete, get, post},
    Json, Router,
};
use chrono::Utc;
use std::collections::HashMap;
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
    // Create protected routes
    let protected = Router::new()
        .route("/", get(list_files))
        .route("/upload", post(upload_file))
        .route("/:file_id", get(get_file_metadata))
        .route("/:file_id/download", get(download_file))
        .route("/:file_id/usage", get(check_file_usage))
        .route("/:file_id", delete(delete_file))
        .layer(middleware::from_fn(auth_middleware));
    
    // Combine public and protected routes
    Router::new()
        .route("/:file_id/public", get(public_download))  // Public endpoint
        .merge(protected)  // Protected endpoints
}

// Upload file
async fn upload_file(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    mut multipart: Multipart,
) -> AppResult<impl IntoResponse> {
    tracing::info!("File upload request from user: {}", claims.user_id);

    let mut file_data: Option<Bytes> = None;
    let mut file_name: Option<String> = None;
    let mut content_type: Option<String> = None;

    // Process multipart form
    tracing::debug!("Starting to process multipart form data");
    while let Some(field) = multipart.next_field().await.map_err(|e| {
        tracing::error!("Failed to get multipart field: {}", e);
        tracing::error!("Error details: {:?}", e);
        AppError::BadRequest(format!("Invalid multipart data: {}", e))
    })? {
        let name = field.name().unwrap_or("").to_string();
        
        if name == "file" {
            // Get file metadata
            file_name = field.file_name().map(|s| s.to_string());
            content_type = field.content_type().map(|s| s.to_string());
            
            // Read file data
            file_data = Some(field.bytes().await.map_err(|e| {
                tracing::error!("Failed to read file data: {}", e);
                AppError::BadRequest("Failed to read file data".to_string())
            })?);
        }
    }

    // Ensure we have file data
    let file_data = file_data.ok_or_else(|| {
        AppError::BadRequest("No file data provided".to_string())
    })?;
    
    let file_name = file_name.unwrap_or_else(|| "unnamed_file".to_string());
    let content_type = content_type.unwrap_or_else(|| "application/octet-stream".to_string());

    // Generate unique file ID
    let file_id = Uuid::new_v4();
    let file_size = file_data.len() as i64;

    // Validate file size (10MB limit for now)
    if file_size > 10 * 1024 * 1024 {
        return Err(AppError::BadRequest("File too large. Maximum size is 10MB".to_string()));
    }

    // Validate MIME type (basic check for now)
    let allowed_types = vec![
        "image/jpeg", "image/jpg", "image/png", "image/gif", "image/webp",
        "application/pdf", "text/plain"
    ];
    
    if !allowed_types.contains(&content_type.as_str()) {
        return Err(AppError::BadRequest(format!("File type {} not allowed", content_type)));
    }

    // Store file metadata in database
    // TODO: Get these from multipart form fields if needed
    let category = "game_asset".to_string();
    let is_public = false;
    
    // Upload file to storage
    let storage_key = format!("uploads/{}/{}", claims.user_id, file_id);
    let metadata = HashMap::new(); // Could include user-specific metadata
    
    let upload_result = state.storage.upload(
        &storage_key,
        file_data,
        &content_type,
        metadata,
    ).await.map_err(|e| {
        tracing::error!("Failed to upload file to storage: {}", e);
        AppError::InternalError(format!("File upload failed: {}", e))
    })?;
    
    tracing::info!("Successfully uploaded file to storage: key={}, size={} bytes", storage_key, upload_result.size);
    
    // Insert into database
    let file_record = sqlx::query!(
        r#"
        INSERT INTO core.uploaded_files (
            id, user_id, original_name, mime_type, file_size, 
            file_key, category, is_public, storage_provider
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        RETURNING id, original_name, mime_type, file_size, category, uploaded_at
        "#,
        file_id,
        Uuid::parse_str(&claims.user_id).unwrap_or_else(|_| Uuid::nil()),
        file_name,
        content_type,
        file_size,
        storage_key,
        category,
        is_public,
        "minio"  // Now using actual storage provider
    )
    .fetch_one(&state.db)
    .await
    .map_err(|e| {
        tracing::error!("Failed to save file metadata: {}", e);
        AppError::DatabaseError(e)
    })?;

    // Generate a presigned URL for immediate access
    let presigned_url = state.storage.get_presigned_url(&storage_key, 3600).await // 1 hour expiry
        .map_err(|e| {
            tracing::error!("Failed to generate presigned URL: {}", e);
            AppError::InternalError("Failed to generate file access URL".to_string())
        })?;
    
    let response = FileUploadSuccessResponse {
        data: UploadedFileDto {
            id: file_id.to_string(),
            original_name: file_record.original_name,
            mime_type: file_record.mime_type,
            file_size: file_record.file_size,
            category: file_record.category,
            url: presigned_url, // Use presigned URL instead of local endpoint
            uploaded_at: file_record.uploaded_at.unwrap_or_else(|| Utc::now()).to_rfc3339(),
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
    State(state): State<AppState>,
    Path(file_id): Path<String>,
    AuthClaims(claims): AuthClaims,
) -> AppResult<impl IntoResponse> {
    tracing::info!("File download request from user: {}", claims.user_id);

    // Validate file ID format
    let file_uuid = Uuid::parse_str(&file_id).map_err(|_| {
        AppError::BadRequest("Invalid file ID format".to_string())
    })?;

    // Get file metadata from database
    let file_record = sqlx::query!(
        r#"
        SELECT id, user_id, original_name, mime_type, file_size, 
               file_key, is_public
        FROM core.uploaded_files
        WHERE id = $1 AND (is_public = true OR user_id = $2)
        "#,
        file_uuid,
        Uuid::parse_str(&claims.user_id).unwrap_or_else(|_| Uuid::nil())
    )
    .fetch_optional(&state.db)
    .await
    .map_err(|e| {
        tracing::error!("Failed to get file metadata: {}", e);
        AppError::DatabaseError(e)
    })?;

    let file_record = file_record.ok_or_else(|| {
        AppError::NotFound("File not found".to_string())
    })?;

    // Download file from storage
    let file_data = state.storage.download(&file_record.file_key).await
        .map_err(|e| {
            tracing::error!("Failed to download file from storage: {}", e);
            match e {
                crate::services::storage::StorageError::NotFound(_) => {
                    AppError::NotFound("File not found in storage".to_string())
                }
                _ => AppError::InternalError("Failed to retrieve file".to_string())
            }
        })?;

    tracing::info!("Successfully downloaded file from storage: key={}, size={} bytes", 
                   file_record.file_key, file_data.len());

    let headers = [
        (header::CONTENT_TYPE, file_record.mime_type),
        (header::CONTENT_DISPOSITION, 
         format!("inline; filename=\"{}\"", file_record.original_name)),
    ];

    Ok((StatusCode::OK, headers, file_data))
}

// Public download endpoint (no auth required for public files)
async fn public_download(
    State(state): State<AppState>,
    Path(file_id): Path<String>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Public file download request for: {}", file_id);

    // Validate file ID format
    let file_uuid = Uuid::parse_str(&file_id).map_err(|_| {
        AppError::BadRequest("Invalid file ID format".to_string())
    })?;

    // Get file metadata - only allow public files
    let file_record = sqlx::query!(
        r#"
        SELECT id, original_name, mime_type, file_size, 
               file_key, is_public
        FROM core.uploaded_files
        WHERE id = $1 AND is_public = true
        "#,
        file_uuid
    )
    .fetch_optional(&state.db)
    .await
    .map_err(|e| {
        tracing::error!("Failed to get file metadata: {}", e);
        AppError::DatabaseError(e)
    })?;

    let file_record = file_record.ok_or_else(|| {
        AppError::NotFound("File not found or not public".to_string())
    })?;

    // Download file from storage
    let file_data = state.storage.download(&file_record.file_key).await
        .map_err(|e| {
            tracing::error!("Failed to download file from storage: {}", e);
            match e {
                crate::services::storage::StorageError::NotFound(_) => {
                    AppError::NotFound("File not found in storage".to_string())
                }
                _ => AppError::InternalError("Failed to retrieve file".to_string())
            }
        })?;

    tracing::info!("Successfully downloaded public file from storage: key={}, size={} bytes", 
                   file_record.file_key, file_data.len());

    let headers = [
        (header::CONTENT_TYPE, file_record.mime_type),
        (header::CONTENT_DISPOSITION, 
         format!("inline; filename=\"{}\"", file_record.original_name)),
        (header::CACHE_CONTROL, "public, max-age=3600".to_string()),
    ];

    Ok((StatusCode::OK, headers, file_data))
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
    State(state): State<AppState>,
    Query(params): Query<FileQueryParams>,
    AuthClaims(claims): AuthClaims,
) -> AppResult<impl IntoResponse> {
    tracing::info!("File list request from user: {}", claims.user_id);

    let limit = params.limit.unwrap_or(100).min(100) as i64;
    let offset = params.offset.unwrap_or(0) as i64;

    // Build query that works with optional category
    let files = sqlx::query!(
        r#"
        SELECT id, original_name, mime_type, file_size, category, uploaded_at
        FROM core.uploaded_files
        WHERE user_id = $1 
          AND ($2::text IS NULL OR category = $2)
        ORDER BY uploaded_at DESC
        LIMIT $3 OFFSET $4
        "#,
        Uuid::parse_str(&claims.user_id).unwrap_or_else(|_| Uuid::nil()),
        params.category.as_deref(),
        limit,
        offset
    )
    .fetch_all(&state.db)
    .await
    .map_err(|e| {
        tracing::error!("Failed to list files: {}", e);
        AppError::DatabaseError(e)
    })?;

    let file_list: Vec<UploadedFileDto> = files
        .into_iter()
        .map(|f| UploadedFileDto {
            id: f.id.to_string(),
            original_name: f.original_name,
            mime_type: f.mime_type,
            file_size: f.file_size,
            category: f.category,
            url: format!("/api/v1/files/{}/public", f.id),
            uploaded_at: f.uploaded_at.unwrap_or_else(|| Utc::now()).to_rfc3339(),
            metadata: None,
        })
        .collect();

    let response = FileListSuccessResponse {
        data: file_list,
    };

    Ok((StatusCode::OK, Json(response)))
}