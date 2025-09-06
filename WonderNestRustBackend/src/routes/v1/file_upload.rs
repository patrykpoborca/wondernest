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
use std::{collections::HashMap, error::Error};
use uuid::Uuid;

use crate::{
    extractors::AuthClaims,
    error::{AppError, AppResult},
    middleware::auth::{auth_middleware},
    models::{
        FileListSuccessResponse, FileQueryParams,
        FileUploadSuccessResponse, FileUsageResponse, UploadedFileDto,
        FileOperation, FileOperationResponse,
    },
    services::{AppState, file_reference_service::FileReferenceService},
};

#[derive(serde::Deserialize)]
pub struct FileUploadParams {
    category: Option<String>,
    #[serde(rename = "childId")]
    child_id: Option<String>,
    #[serde(rename = "isPublic")]
    is_public: Option<bool>,
    tags: Option<String>,
}

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
    Query(params): Query<FileUploadParams>,
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
            
            tracing::debug!("Processing file field: name={:?}, content_type={:?}", file_name, content_type);
            
            // Read file data
            match field.bytes().await {
                Ok(bytes) => {
                    tracing::debug!("Successfully read file data: {} bytes", bytes.len());
                    file_data = Some(bytes);
                }
                Err(e) => {
                    tracing::error!("Failed to read file data: {}", e);
                    tracing::error!("Error details: {:?}", e);
                    tracing::error!("Error source: {:?}", e.source());
                    return Err(AppError::BadRequest(format!("Failed to read file data: {}", e)));
                }
            }
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

    // Use parameters from query string
    let category = params.category.unwrap_or_else(|| "game_asset".to_string());
    let is_public = params.is_public.unwrap_or(false);
    
    // Upload file to storage
    let storage_key = format!("uploads/{}/{}", claims.user_id, file_id);
    let mut metadata = HashMap::new();
    
    // Add tags to metadata if provided
    if let Some(tags) = params.tags {
        metadata.insert("tags".to_string(), tags);
    }
    
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
    State(state): State<AppState>,
    Path(file_id): Path<String>,
    AuthClaims(claims): AuthClaims,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Content-aware file delete request from user: {} for file: {}", claims.user_id, file_id);

    // Validate file ID format
    let file_uuid = Uuid::parse_str(&file_id).map_err(|_| {
        AppError::BadRequest("Invalid file ID format".to_string())
    })?;

    // Parse user ID
    let user_uuid = Uuid::parse_str(&claims.user_id).map_err(|_| {
        AppError::BadRequest("Invalid user ID format".to_string())
    })?;

    // Get comprehensive file metadata including detachment info
    let file_record = sqlx::query!(
        r#"
        SELECT id, user_id, original_name, file_key, file_size, reference_count,
               detached_at, detached_by, detachment_reason, is_system_image
        FROM core.uploaded_files
        WHERE id = $1 AND user_id = $2
        "#,
        file_uuid,
        user_uuid
    )
    .fetch_optional(&state.db)
    .await
    .map_err(|e| {
        tracing::error!("Failed to get file metadata: {}", e);
        AppError::DatabaseError(e)
    })?;

    let file_record = file_record.ok_or_else(|| {
        AppError::NotFound("File not found or access denied".to_string())
    })?;

    // Check if file is already detached
    if file_record.detached_at.is_some() {
        let response = FileOperationResponse::new(file_uuid, FileOperation::AlreadyDeleted)
            .with_reason("File was previously detached from your account due to active references");
        return Ok((StatusCode::OK, Json(response)));
    }

    // Check if file is protected (system image)
    if file_record.is_system_image.unwrap_or(false) {
        let response = FileOperationResponse::new(file_uuid, FileOperation::Protected)
            .with_reason("System files cannot be deleted");
        return Ok((StatusCode::FORBIDDEN, Json(response)));
    }

    // Initialize reference service and check for references
    let ref_service = FileReferenceService::new(state.db.clone());
    
    // Get comprehensive reference information
    let reference_types = ref_service.get_comprehensive_references(file_uuid).await
        .map_err(|e| {
            tracing::error!("Failed to check file references: {}", e);
            AppError::InternalError("Failed to check file references".to_string())
        })?;
    
    let reference_count = file_record.reference_count;
    
    // Decide on operation type
    if reference_count > 0 || !reference_types.is_empty() {
        // File has references - perform soft detachment
        tracing::info!("File has {} references of types {:?}, performing soft detachment", 
                      reference_count, reference_types);
        
        let now = Utc::now();
        let detachment_reason = format!(
            "Has {} active references: {}", 
            reference_count + reference_types.len() as i32,
            reference_types.join(", ")
        );
        
        // Update file to mark as detached (remove ownership but keep file)
        sqlx::query!(
            r#"
            UPDATE core.uploaded_files 
            SET user_id = NULL, 
                detached_at = $1, 
                detached_by = $2,
                detachment_reason = $3
            WHERE id = $4
            "#,
            now,
            user_uuid,
            detachment_reason,
            file_uuid
        )
        .execute(&state.db)
        .await
        .map_err(|e| {
            tracing::error!("Failed to detach file: {}", e);
            AppError::DatabaseError(e)
        })?;

        tracing::info!("Successfully detached file: {} ({})", file_record.original_name, file_id);

        let response = FileOperationResponse::new(file_uuid, FileOperation::SoftDetached)
            .with_reason("File detached from your account but preserved due to active references")
            .with_references(reference_count, reference_types);
        
        Ok((StatusCode::OK, Json(response)))
        
    } else {
        // No references - perform hard deletion
        tracing::info!("File has no references, performing hard deletion");
        
        let storage_freed = file_record.file_size;
        
        // Delete file from storage first
        match state.storage.delete(&file_record.file_key).await {
            Ok(_) => {
                tracing::info!("Successfully deleted file from storage: {}", file_record.file_key);
            }
            Err(e) => {
                tracing::warn!("Failed to delete file from storage (will continue with database deletion): {}", e);
                // Continue with database deletion even if storage deletion fails
                // This handles cases where the file was already manually deleted from storage
            }
        }

        // Delete file record from database
        let deleted_rows = sqlx::query!(
            r#"
            DELETE FROM core.uploaded_files
            WHERE id = $1 AND user_id = $2
            "#,
            file_uuid,
            user_uuid
        )
        .execute(&state.db)
        .await
        .map_err(|e| {
            tracing::error!("Failed to delete file from database: {}", e);
            AppError::DatabaseError(e)
        })?;

        if deleted_rows.rows_affected() == 0 {
            let response = FileOperationResponse::new(file_uuid, FileOperation::Failed)
                .with_reason("File not found or already deleted");
            return Ok((StatusCode::NOT_FOUND, Json(response)));
        }

        tracing::info!("Successfully hard deleted file: {} ({})", file_record.original_name, file_id);

        let response = FileOperationResponse::new(file_uuid, FileOperation::HardDeleted)
            .with_reason(format!("File '{}' completely removed", file_record.original_name))
            .with_storage_freed(storage_freed);

        Ok((StatusCode::OK, Json(response)))
    }
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