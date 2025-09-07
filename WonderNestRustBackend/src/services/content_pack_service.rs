use std::collections::HashMap;
use uuid::Uuid;
use chrono::Utc;
use serde::{Deserialize, Serialize};
use anyhow::Result;

use crate::{
    error::{AppError, AppResult},
    services::{
        file_reference_service::FileReferenceService,
        signed_url_service::SignedUrlService,
    },
    db::MarketplaceRepository,
    models::marketplace::BigDecimal,
};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentPackCreateRequest {
    pub title: String,
    pub description: String,
    pub price: BigDecimal,
    pub file_ids: Vec<Uuid>,
    pub content_type: String, // "story", "game", "activity", etc.
    pub age_range_min: i32,   // months
    pub age_range_max: i32,   // months
    pub tags: Vec<String>,
    pub preview_image_id: Option<Uuid>, // Main preview image
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentPackManifest {
    pub id: Uuid,
    pub title: String,
    pub description: String,
    pub content_type: String,
    pub age_range: String,
    pub assets: Vec<ContentPackAsset>,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentPackAsset {
    pub id: Uuid,
    pub original_name: String,
    pub content_type: String,
    pub size_bytes: i64,
    pub asset_type: String, // "image", "audio", "video", "data"
    pub signed_url: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentPackResponse {
    pub marketplace_listing_id: Uuid,
    pub manifest: ContentPackManifest,
    pub status: String, // "draft", "pending_review", "approved"
}

#[derive(Clone)]
pub struct ContentPackService {
    file_service: FileReferenceService,
    signed_url_service: SignedUrlService,
    marketplace_repo: MarketplaceRepository,
}

impl ContentPackService {
    pub fn new(
        file_service: FileReferenceService, 
        signed_url_service: SignedUrlService,
        marketplace_repo: MarketplaceRepository,
    ) -> Self {
        Self {
            file_service,
            signed_url_service,
            marketplace_repo,
        }
    }

    /// Create a content pack from uploaded files and create marketplace listing
    pub async fn create_content_pack(
        &self,
        creator_user_id: Uuid,
        request: ContentPackCreateRequest,
    ) -> AppResult<ContentPackResponse> {
        tracing::info!("Creating content pack '{}' for creator: {}", request.title, creator_user_id);

        // Validate all files belong to the creator
        self.validate_file_ownership(creator_user_id, &request.file_ids).await?;

        // Get file details for manifest creation
        let file_details = self.file_service.get_files_by_ids(&request.file_ids).await
            .map_err(|e| {
                tracing::error!("Failed to get file details: {}", e);
                AppError::InternalError("Failed to retrieve file information".to_string())
            })?;

        // Create content pack assets with signed URLs
        let mut assets = Vec::new();
        let base_url = "http://localhost:8080"; // TODO: Get from config

        for file in &file_details {
            let signed_url = self.signed_url_service.generate_signed_url(
                file.id,
                creator_user_id,
                "view",
                base_url,
                Some(24 * 7), // 7 days for content pack assets
            )?;

            let content_type = file.detected_content_type.clone()
                .or_else(|| Some(file.mime_type.clone()))
                .unwrap_or_else(|| "application/octet-stream".to_string());
                
            assets.push(ContentPackAsset {
                id: file.id,
                original_name: file.original_name.clone(),
                content_type: content_type.clone(),
                size_bytes: file.file_size,
                asset_type: self.determine_asset_type(&Some(content_type)),
                signed_url,
            });
        }

        // Create marketplace listing
        // Note: This is a simplified approach - we'll need to create a proper content pack table
        // and link it to marketplace_listings in a future iteration
        let marketplace_listing_id = Uuid::new_v4();
        
        // Create manifest
        let manifest = ContentPackManifest {
            id: marketplace_listing_id,
            title: request.title.clone(),
            description: request.description.clone(),
            content_type: request.content_type.clone(),
            age_range: format!("{}-{} months", request.age_range_min, request.age_range_max),
            assets,
            created_at: Utc::now(),
        };

        // Store content pack metadata (simplified - would typically create marketplace listing)
        tracing::info!("Content pack '{}' created successfully with {} assets", 
                      request.title, request.file_ids.len());

        Ok(ContentPackResponse {
            marketplace_listing_id,
            manifest,
            status: "draft".to_string(),
        })
    }

    /// Get content pack manifest for a child's purchased content
    pub async fn get_content_pack_for_child(
        &self,
        child_id: Uuid,
        content_pack_id: Uuid,
    ) -> AppResult<ContentPackManifest> {
        tracing::info!("Getting content pack {} for child {}", content_pack_id, child_id);

        // Verify child has access to this content pack via their library
        let library_items = self.marketplace_repo.get_child_library(child_id).await
            .map_err(|e| {
                tracing::error!("Failed to get child library: {}", e);
                AppError::InternalError("Failed to verify content access".to_string())
            })?;

        let has_access = library_items.iter()
            .any(|item| item.marketplace_item_id == content_pack_id);

        if !has_access {
            tracing::warn!("Child {} does not have access to content pack {}", child_id, content_pack_id);
            return Err(AppError::Forbidden("Access denied to content pack".to_string()));
        }

        // For now, return a placeholder manifest
        // In a full implementation, we would retrieve the actual content pack data
        let manifest = ContentPackManifest {
            id: content_pack_id,
            title: "Sample Content Pack".to_string(),
            description: "A sample content pack for testing".to_string(),
            content_type: "educational".to_string(),
            age_range: "36-72 months".to_string(),
            assets: Vec::new(), // Would populate with actual assets
            created_at: Utc::now(),
        };

        Ok(manifest)
    }

    /// Generate signed URLs for all assets in a content pack
    pub async fn get_content_pack_assets(
        &self,
        child_id: Uuid,
        content_pack_id: Uuid,
        user_id: Uuid,
    ) -> AppResult<Vec<ContentPackAsset>> {
        tracing::info!("Getting assets for content pack {} for child {}", content_pack_id, child_id);

        // Verify access (similar to get_content_pack_for_child)
        let library_items = self.marketplace_repo.get_child_library(child_id).await
            .map_err(|e| {
                tracing::error!("Failed to get child library: {}", e);
                AppError::InternalError("Failed to verify content access".to_string())
            })?;

        let has_access = library_items.iter()
            .any(|item| item.marketplace_item_id == content_pack_id);

        if !has_access {
            return Err(AppError::Forbidden("Access denied to content pack".to_string()));
        }

        // TODO: Implement actual asset retrieval
        // For now, return empty list
        Ok(Vec::new())
    }

    /// Validate that all files belong to the specified user
    async fn validate_file_ownership(&self, user_id: Uuid, file_ids: &[Uuid]) -> AppResult<()> {
        for file_id in file_ids {
            // Use file service to check ownership
            match self.file_service.get_file_by_id(*file_id).await {
                Ok(Some(file)) => {
                    if file.user_id != user_id {
                        tracing::warn!("User {} attempted to use file {} owned by {}", 
                                      user_id, file_id, file.user_id);
                        return Err(AppError::Forbidden("Access denied to specified file".to_string()));
                    }
                }
                Ok(None) => {
                    tracing::warn!("File {} not found during ownership validation", file_id);
                    return Err(AppError::NotFound("Specified file not found".to_string()));
                }
                Err(e) => {
                    tracing::error!("Failed to validate file ownership: {}", e);
                    return Err(AppError::InternalError("Failed to validate file access".to_string()));
                }
            }
        }
        Ok(())
    }

    /// Determine asset type based on content type
    fn determine_asset_type(&self, content_type: &Option<String>) -> String {
        match content_type.as_ref().map(|s| s.as_str()) {
            Some(ct) if ct.starts_with("image/") => "image".to_string(),
            Some(ct) if ct.starts_with("audio/") => "audio".to_string(),
            Some(ct) if ct.starts_with("video/") => "video".to_string(),
            Some("application/json") => "data".to_string(),
            Some("text/plain") => "data".to_string(),
            _ => "data".to_string(),
        }
    }

    /// Update content pack usage tracking when accessed by games
    pub async fn track_content_usage(
        &self,
        child_id: Uuid,
        content_pack_id: Uuid,
        game_id: String,
        session_duration_minutes: i32,
    ) -> AppResult<()> {
        tracing::info!("Tracking usage: child={}, content_pack={}, game={}, duration={}min", 
                      child_id, content_pack_id, game_id, session_duration_minutes);

        // TODO: Implement usage tracking
        // This would update the child_libraries table with usage statistics
        // and potentially create entries in analytics tables

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_determine_asset_type() {
        let service = ContentPackService {
            file_service: todo!(),
            signed_url_service: todo!(),
            marketplace_repo: todo!(),
        };

        assert_eq!(service.determine_asset_type(&Some("image/png".to_string())), "image");
        assert_eq!(service.determine_asset_type(&Some("audio/mp3".to_string())), "audio");
        assert_eq!(service.determine_asset_type(&Some("video/mp4".to_string())), "video");
        assert_eq!(service.determine_asset_type(&Some("application/json".to_string())), "data");
        assert_eq!(service.determine_asset_type(&None), "data");
    }
}