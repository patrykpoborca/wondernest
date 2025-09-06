use axum::{
    body::{Bytes, Body},
    extract::{Multipart, Path, Query, State, Request},
    http::{header, StatusCode, HeaderMap},
    middleware,
    response::IntoResponse,
    routing::{delete, get, post, put, patch},
    Json, Router,
};
use sqlx::Row;
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

#[derive(serde::Deserialize)]
pub struct FileMetadataUpdate {
    original_name: Option<String>,
    category: Option<String>,
    tags: Option<String>,
}

#[derive(serde::Deserialize)]
pub struct FileVisibilityUpdate {
    #[serde(rename = "isPublic")]
    is_public: bool,
}

pub fn router() -> Router<AppState> {
    // Create protected routes
    let protected = Router::new()
        .route("/", get(list_files))
        .route("/upload", post(upload_file))
        .route("/:file_id", get(get_file_metadata))
        .route("/:file_id", put(update_file_metadata))
        .route("/:file_id/download", get(download_file))
        .route("/:file_id/usage", get(check_file_usage))
        .route("/:file_id/visibility", patch(update_file_visibility))
        .route("/:file_id", delete(delete_file))
        .layer(middleware::from_fn(auth_middleware));
    
    // Combine public and protected routes
    Router::new()
        .route("/:file_id/public", get(public_download))  // Public endpoint (no auth)
        .route("/:file_id/family", get(family_download))  // Family-accessible endpoint (manual auth)
        .route("/:file_id/signed", get(signed_download))  // Signed URL endpoint (no auth, signature required)
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
    let is_public = params.is_public.unwrap_or(false); // Default to private (family access)
    
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

// Update file metadata (name, category, tags)
async fn update_file_metadata(
    State(state): State<AppState>,
    Path(file_id): Path<String>,
    AuthClaims(claims): AuthClaims,
    Json(update_data): Json<FileMetadataUpdate>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("File metadata update request from user: {} for file: {}", claims.user_id, file_id);

    // Validate file ID format
    let file_uuid = Uuid::parse_str(&file_id).map_err(|_| {
        AppError::BadRequest("Invalid file ID format".to_string())
    })?;

    // Parse user ID
    let user_uuid = Uuid::parse_str(&claims.user_id).map_err(|_| {
        AppError::BadRequest("Invalid user ID format".to_string())
    })?;

    // Validate access using FileAccessController (owner only)
    let _file_info = state.file_access.validate_file_access(
        Some(user_uuid),
        file_uuid,
        true // require_owner = true
    ).await?;

    // For simplicity, we'll handle each case separately with sqlx::query!
    // First get current values 
    let current_file = sqlx::query!(
        "SELECT original_name, category, tags FROM core.uploaded_files WHERE id = $1 AND user_id = $2",
        file_uuid, user_uuid
    )
    .fetch_optional(&state.db)
    .await
    .map_err(|e| {
        tracing::error!("Failed to get current file data: {}", e);
        AppError::DatabaseError(e)
    })?;

    let current_file = current_file.ok_or_else(|| {
        AppError::NotFound("File not found or access denied".to_string())
    })?;

    // Use new values if provided, otherwise keep current values
    let new_original_name = update_data.original_name.unwrap_or(current_file.original_name);
    let new_category = update_data.category.unwrap_or(current_file.category);
    let new_tags = update_data.tags.unwrap_or(current_file.tags.unwrap_or_default().join(","));

    // Update the file
    let updated_file = sqlx::query!(
        r#"
        UPDATE core.uploaded_files 
        SET original_name = $1, category = $2, tags = string_to_array($3, ',')
        WHERE id = $4 AND user_id = $5
        RETURNING id, original_name, mime_type, file_size, category, uploaded_at
        "#,
        new_original_name,
        new_category,
        new_tags,
        file_uuid,
        user_uuid
    )
    .fetch_optional(&state.db)
    .await
    .map_err(|e| {
        tracing::error!("Failed to update file metadata: {}", e);
        AppError::DatabaseError(e)
    })?;

    let updated_file = updated_file.ok_or_else(|| {
        AppError::NotFound("File not found or access denied".to_string())
    })?;

    let file_dto = UploadedFileDto {
        id: updated_file.id.to_string(),
        original_name: updated_file.original_name,
        mime_type: updated_file.mime_type,
        file_size: updated_file.file_size,
        category: updated_file.category,
        url: format!("/api/v1/files/{}/family", updated_file.id),
        uploaded_at: updated_file.uploaded_at.unwrap_or_else(|| Utc::now()).to_rfc3339(),
        metadata: None,
    };

    tracing::info!("Successfully updated file metadata for: {}", file_id);
    Ok((StatusCode::OK, Json(file_dto)))
}

// Update file visibility (public/private toggle)
async fn update_file_visibility(
    State(state): State<AppState>,
    Path(file_id): Path<String>,
    AuthClaims(claims): AuthClaims,
    Json(visibility_data): Json<FileVisibilityUpdate>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("File visibility update request from user: {} for file: {} to public: {}", 
                  claims.user_id, file_id, visibility_data.is_public);

    // Validate file ID format
    let file_uuid = Uuid::parse_str(&file_id).map_err(|_| {
        AppError::BadRequest("Invalid file ID format".to_string())
    })?;

    // Parse user ID
    let user_uuid = Uuid::parse_str(&claims.user_id).map_err(|_| {
        AppError::BadRequest("Invalid user ID format".to_string())
    })?;

    // Validate access using FileAccessController (owner only)
    let _file_info = state.file_access.validate_file_access(
        Some(user_uuid),
        file_uuid,
        true // require_owner = true
    ).await?;

    // Update file visibility
    let updated_file = sqlx::query!(
        r#"
        UPDATE core.uploaded_files 
        SET is_public = $1
        WHERE id = $2 AND user_id = $3
        RETURNING id, original_name, mime_type, file_size, category, is_public, uploaded_at
        "#,
        visibility_data.is_public,
        file_uuid,
        user_uuid
    )
    .fetch_optional(&state.db)
    .await
    .map_err(|e| {
        tracing::error!("Failed to update file visibility: {}", e);
        AppError::DatabaseError(e)
    })?;

    let updated_file = updated_file.ok_or_else(|| {
        AppError::NotFound("File not found or access denied".to_string())
    })?;

    // Determine the appropriate URL based on visibility
    let url = if updated_file.is_public.unwrap_or(false) {
        format!("/api/v1/files/{}/public", file_uuid)
    } else {
        format!("/api/v1/files/{}/family", file_uuid)
    };

    let file_dto = UploadedFileDto {
        id: file_uuid.to_string(),
        original_name: updated_file.original_name,
        mime_type: updated_file.mime_type,
        file_size: updated_file.file_size,
        category: updated_file.category,
        url,
        uploaded_at: updated_file.uploaded_at.unwrap_or_else(|| Utc::now()).to_rfc3339(),
        metadata: None,
    };

    let visibility_status = if visibility_data.is_public { "public" } else { "private" };
    tracing::info!("Successfully updated file visibility to {} for: {}", visibility_status, file_id);
    
    Ok((StatusCode::OK, Json(file_dto)))
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

// Family download endpoint (requires auth, allows family member access)
async fn family_download(
    State(state): State<AppState>,
    Path(file_id): Path<String>,
    req: Request<Body>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Family file download request for file: {}", file_id);

    // Manual JWT validation since this endpoint is outside auth middleware
    let auth_header = req
        .headers()
        .get(header::AUTHORIZATION)
        .and_then(|h| h.to_str().ok())
        .ok_or(AppError::Unauthorized)?;

    // Check for Bearer prefix
    if !auth_header.starts_with("Bearer ") {
        return Err(AppError::InvalidToken);
    }

    let token = &auth_header[7..]; // Skip "Bearer "

    // Get JWT secret and validation params from environment
    let jwt_secret = std::env::var("JWT_SECRET")
        .unwrap_or_else(|_| "your-super-secret-jwt-key-change-this-in-production".to_string());
    let jwt_issuer = std::env::var("JWT_ISSUER")
        .unwrap_or_else(|_| "wondernest-api".to_string());
    let jwt_audience = std::env::var("JWT_AUDIENCE")
        .unwrap_or_else(|_| "wondernest-users".to_string());

    // Configure validation
    let mut validation = jsonwebtoken::Validation::new(jsonwebtoken::Algorithm::HS256);
    validation.set_issuer(&[&jwt_issuer]);
    validation.set_audience(&[&jwt_audience]);

    // Decode and validate JWT
    let token_data = jsonwebtoken::decode::<crate::middleware::auth::Claims>(
        token,
        &jsonwebtoken::DecodingKey::from_secret(jwt_secret.as_bytes()),
        &validation,
    )
    .map_err(|e| {
        tracing::debug!("JWT validation failed: {:?}", e);
        match e.kind() {
            jsonwebtoken::errors::ErrorKind::ExpiredSignature => AppError::TokenExpired,
            _ => AppError::InvalidToken,
        }
    })?;

    let claims = token_data.claims;
    tracing::info!("Family file download request from user: {} for file: {}", claims.user_id, file_id);

    // Validate file ID format
    let file_uuid = Uuid::parse_str(&file_id).map_err(|_| {
        AppError::BadRequest("Invalid file ID format".to_string())
    })?;

    // Parse requesting user ID
    let requesting_user_id = Uuid::parse_str(&claims.user_id).map_err(|_| {
        AppError::BadRequest("Invalid user ID format".to_string())
    })?;

    // Get file metadata with owner info
    let file_record = sqlx::query!(
        r#"
        SELECT uf.id, uf.user_id as owner_id, uf.original_name, uf.mime_type, 
               uf.file_size, uf.file_key, uf.is_public
        FROM core.uploaded_files uf
        WHERE uf.id = $1 AND uf.detached_at IS NULL
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
        AppError::NotFound("File not found".to_string())
    })?;

    // Check if file is public - if so, allow access
    if file_record.is_public.unwrap_or(false) {
        tracing::debug!("File is public, allowing access");
    } else {
        // For private files, check family membership
        let owner_id = file_record.owner_id;

        // If requesting user is the owner, allow access
        if requesting_user_id == owner_id {
            tracing::debug!("User is file owner, allowing access");
        } else {
            // Check if both users are in the same family
            let same_family = sqlx::query_scalar!(
                r#"
                SELECT COUNT(*) > 0
                FROM family.family_members fm1
                JOIN family.family_members fm2 ON fm1.family_id = fm2.family_id
                WHERE fm1.user_id = $1 AND fm2.user_id = $2
                "#,
                requesting_user_id,
                owner_id
            )
            .fetch_one(&state.db)
            .await
            .map_err(|e| {
                tracing::error!("Failed to check family membership: {}", e);
                AppError::DatabaseError(e)
            })?;

            if !same_family.unwrap_or(false) {
                tracing::warn!("User {} attempted to access file owned by {} but they are not in the same family", 
                              requesting_user_id, owner_id);
                return Err(AppError::Forbidden("Access denied: file not accessible to your family".to_string()));
            }

            tracing::debug!("Users are in same family, allowing access");
        }
    }

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

    tracing::info!("Successfully downloaded family file from storage: key={}, size={} bytes", 
                   file_record.file_key, file_data.len());

    let headers = [
        (header::CONTENT_TYPE, file_record.mime_type),
        (header::CONTENT_DISPOSITION, 
         format!("inline; filename=\"{}\"", file_record.original_name)),
        (header::CACHE_CONTROL, "private, max-age=3600".to_string()),
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

    // Validate access using FileAccessController (owner only)
    let _file_info = state.file_access.validate_file_access(
        Some(user_uuid), 
        file_uuid, 
        true // require_owner = true
    ).await?;

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

// Signed URL download endpoint (no auth required, validates signature)
async fn signed_download(
    State(state): State<AppState>,
    Path(file_id): Path<String>,
    Query(params): Query<HashMap<String, String>>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Signed URL file download request for: {}", file_id);

    // Extract payload and signature from query parameters
    let payload = params.get("payload")
        .ok_or_else(|| AppError::BadRequest("Missing payload parameter".to_string()))?;
    
    let signature = params.get("signature")
        .ok_or_else(|| AppError::BadRequest("Missing signature parameter".to_string()))?;

    // Validate file ID format
    let file_uuid = Uuid::parse_str(&file_id).map_err(|_| {
        AppError::BadRequest("Invalid file ID format".to_string())
    })?;

    // Validate the signed URL
    let payload_info = state.signed_url.validate_signed_url(file_uuid, payload, signature)?;

    // Parse user ID from payload
    let user_uuid = Uuid::parse_str(&payload_info.user_id).map_err(|_| {
        AppError::InternalError("Invalid user ID in signed URL".to_string())
    })?;

    // Verify the user has access to this file using FileAccessController
    let can_view = state.file_access.can_view_file(user_uuid, file_uuid).await?;
    if !can_view {
        tracing::warn!("User {} attempted to access file {} with valid signature but lacks permission", 
                      user_uuid, file_uuid);
        return Err(AppError::NotFound("File not found".to_string()));
    }

    // Get file metadata from database
    let file_record = sqlx::query!(
        r#"
        SELECT id, original_name, mime_type, file_size, file_key
        FROM core.uploaded_files
        WHERE id = $1 AND detached_at IS NULL
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

    tracing::info!("Successfully downloaded file via signed URL: key={}, size={} bytes", 
                   file_record.file_key, file_data.len());

    let headers = [
        (header::CONTENT_TYPE, file_record.mime_type),
        (header::CONTENT_DISPOSITION, 
         format!("inline; filename=\"{}\"", file_record.original_name)),
        (header::CACHE_CONTROL, "private, max-age=3600".to_string()),
    ];

    Ok((StatusCode::OK, headers, file_data))
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
        SELECT id, original_name, mime_type, file_size, category, is_public, uploaded_at
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

    // Get user ID for signed URL generation
    let user_uuid = Uuid::parse_str(&claims.user_id).unwrap_or_else(|_| Uuid::nil());

    let file_list: Vec<UploadedFileDto> = files
        .into_iter()
        .map(|f| {
            // Generate appropriate URL based on file visibility
            let url = if f.is_public.unwrap_or(false) {
                format!("/api/v1/files/{}/public", f.id)
            } else {
                // Generate signed URL for private files (24 hour expiry)
                match state.signed_url.generate_signed_url(
                    f.id,
                    user_uuid,
                    "view",
                    "http://localhost:8080", // TODO: Get from config
                    None
                ) {
                    Ok(signed_url) => signed_url,
                    Err(e) => {
                        tracing::error!("Failed to generate signed URL for file {}: {}", f.id, e);
                        // Fallback to family URL (will require manual auth)
                        format!("/api/v1/files/{}/family", f.id)
                    }
                }
            };

            UploadedFileDto {
                id: f.id.to_string(),
                original_name: f.original_name,
                mime_type: f.mime_type,
                file_size: f.file_size,
                category: f.category,
                url,
                uploaded_at: f.uploaded_at.unwrap_or_else(|| Utc::now()).to_rfc3339(),
                metadata: None,
            }
        })
        .collect();

    let response = FileListSuccessResponse {
        data: file_list,
    };

    Ok((StatusCode::OK, Json(response)))
}