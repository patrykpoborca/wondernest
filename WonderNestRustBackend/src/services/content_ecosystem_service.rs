use uuid::Uuid;
use anyhow::Result;
use chrono::{DateTime, Utc};
use serde_json::Value;

use crate::{
    error::AppResult,
    models::{
        content_ecosystem::{
            ContentCatalogRequest, ContentCatalogResponse, EcosystemContentItem, AgeRange, Pagination,
            FeaturedContentResponse, FeaturedSection, ContentLibraryResponse, LibraryItem, LibraryStats,
            AddToLibraryRequest, AddToLibraryResponse, ContentDownloadResponse, SyncRequest, SyncResponse,
            RecommendationsResponse, FeedbackRequest, DownloadChunk, ContentMetadata, SyncAction,
            RecommendationItem, LocalContentItem
        },
        marketplace::{MarketplaceBrowseRequest, MarketplaceItemSummary}
    },
    db::MarketplaceRepository,
    services::signed_url_service::SignedUrlService,
};

#[derive(Clone)]
pub struct ContentEcosystemService {
    marketplace_repo: MarketplaceRepository,
    signed_url_service: SignedUrlService,
}

impl ContentEcosystemService {
    pub fn new(
        marketplace_repo: MarketplaceRepository,
        signed_url_service: SignedUrlService,
    ) -> Self {
        Self {
            marketplace_repo,
            signed_url_service,
        }
    }

    /// Get content catalog with filtering and pagination
    pub async fn get_content_catalog(&self, request: ContentCatalogRequest) -> AppResult<ContentCatalogResponse> {
        // Transform v2 request to marketplace browse request
        let browse_request = MarketplaceBrowseRequest {
            page: request.page,
            limit: request.limit,
            content_type: request.content_type.as_ref().map(|ct| vec![ct.clone()]),
            age_range_min: request.age_min,
            age_range_max: request.age_max,
            age_range: None,
            search_query: request.search.clone(),
            price_min: None,
            price_max: None,
            price_range: None,
            featured_only: None,
            creator_tiers: None,
            sort_by: request.sort.clone(),
        };

        // Get data from marketplace repository
        let browse_response = self.marketplace_repo.browse_marketplace(&browse_request).await
            .map_err(|e| crate::error::AppError::InternalServerError(format!("Database error: {}", e)))?;

        // Transform marketplace items to ecosystem content items
        let content_items: Vec<EcosystemContentItem> = browse_response.items.into_iter()
            .map(|item| self.marketplace_item_to_ecosystem_item(&item, &request.child_id))
            .collect();

        let total_count = content_items.len() as i64;
        let page = request.page.unwrap_or(1);
        let limit = request.limit.unwrap_or(20);

        Ok(ContentCatalogResponse {
            content: content_items,
            pagination: Pagination {
                page,
                limit,
                total: total_count,
                has_more: ((page * limit) as i64) < total_count,
            },
        })
    }

    /// Get featured and recommended content for a child
    pub async fn get_featured_content(&self, child_id: Uuid) -> AppResult<FeaturedContentResponse> {
        // For now, use the same browse mechanism with different filters
        let featured_request = MarketplaceBrowseRequest {
            page: Some(1),
            limit: Some(5),
            content_type: None,
            age_range_min: Some(3),
            age_range_max: Some(8),
            age_range: Some("3-8".to_string()),
            search_query: None,
            price_min: None,
            price_max: None,
            price_range: None,
            featured_only: Some(true),
            creator_tiers: None,
            sort_by: Some("featured".to_string()),
        };

        let featured_response = self.marketplace_repo.browse_marketplace(&featured_request).await
            .map_err(|e| crate::error::AppError::InternalServerError(format!("Database error: {}", e)))?;

        let featured_content: Vec<EcosystemContentItem> = featured_response.items.into_iter()
            .map(|item| self.marketplace_item_to_ecosystem_item(&item, &child_id))
            .collect();

        // Create different sections (for now, using the same content with different titles)
        Ok(FeaturedContentResponse {
            featured: FeaturedSection {
                title: "Featured This Week".to_string(),
                content: featured_content.clone(),
            },
            recommended: FeaturedSection {
                title: "Recommended for You".to_string(),
                content: featured_content.clone(),
            },
            new_releases: FeaturedSection {
                title: "New This Week".to_string(),
                content: featured_content.clone(),
            },
            trending: FeaturedSection {
                title: "Popular with Kids".to_string(),
                content: featured_content,
            },
        })
    }

    /// Get all content owned by a specific child
    pub async fn get_content_library(&self, child_id: Uuid) -> AppResult<ContentLibraryResponse> {
        // Get child's owned content from database
        let owned_content = self.marketplace_repo.get_child_library(child_id).await
            .map_err(|e| crate::error::AppError::InternalServerError(format!("Database error: {}", e)))?;

        let library_items: Vec<LibraryItem> = owned_content.into_iter()
            .map(|item| LibraryItem {
                content_id: item.marketplace_item_id,
                acquired_at: item.purchase_date,
                last_used: item.last_accessed,
                usage_count: item.total_play_time_minutes,
                is_favorite: item.favorite,
                download_status: "downloaded".to_string(), // Default assumption
                local_path: None, // Not available in ChildLibrary
                content: EcosystemContentItem {
                    id: item.marketplace_item_id,
                    content_type: "story".to_string(), // Default for now
                    title: "Library Item".to_string(), // Would need to join with marketplace_listings
                    description: "Content from your library".to_string(),
                    thumbnail_url: "".to_string(),
                    age_range: AgeRange { min: 3, max: 8 },
                    rating: 4.5,
                    price: 0, // Already purchased
                    currency: "USD".to_string(),
                    is_free: false,
                    is_owned: true,
                    download_size: 10485760, // 10MB default
                    metadata: serde_json::json!({}),
                },
            })
            .collect();

        let stats = LibraryStats {
            total_items: library_items.len() as i32,
            total_size: library_items.iter().map(|item| item.content.download_size).sum(),
            favorites: library_items.iter().filter(|item| item.is_favorite).count() as i32,
            recently_used: library_items.iter().filter(|item| {
                item.last_used.map_or(false, |last_used| {
                    (Utc::now() - last_used).num_days() <= 7
                })
            }).count() as i32,
        };

        Ok(ContentLibraryResponse {
            owned_content: library_items,
            statistics: stats,
        })
    }

    /// Add content to a child's library (purchase or grant)
    pub async fn add_to_library(&self, child_id: Uuid, request: AddToLibraryRequest) -> AppResult<AddToLibraryResponse> {
        // For now, simulate adding to library
        // In a full implementation, this would handle payment processing
        let library_item = LibraryItem {
            content_id: request.content_id,
            acquired_at: Utc::now(),
            last_used: None,
            usage_count: 0,
            is_favorite: false,
            download_status: "pending".to_string(),
            local_path: None,
            content: EcosystemContentItem {
                id: request.content_id,
                content_type: "story".to_string(),
                title: "New Content".to_string(),
                description: "Newly acquired content".to_string(),
                thumbnail_url: "".to_string(),
                age_range: AgeRange { min: 3, max: 8 },
                rating: 4.0,
                price: 0,
                currency: "USD".to_string(),
                is_free: false,
                is_owned: true,
                download_size: 10485760,
                metadata: serde_json::json!({}),
            },
        };

        Ok(AddToLibraryResponse {
            success: true,
            library_item,
        })
    }

    /// Get download URL and metadata for content
    pub async fn get_content_download(&self, content_id: Uuid) -> AppResult<ContentDownloadResponse> {
        // For now, generate a mock download URL since we don't have a user context
        // In a real implementation, this would need user_id from the request context
        let download_url = format!("https://cdn.wondernest.app/content/{}/download", content_id);

        Ok(ContentDownloadResponse {
            download_url,
            expires_at: Utc::now() + chrono::Duration::hours(1),
            content_hash: format!("sha256:{}", hex::encode(content_id.as_bytes())),
            chunks: vec![
                DownloadChunk {
                    id: 1,
                    url: format!("https://cdn.wondernest.app/chunks/{}/1", content_id),
                    size: 1048576,
                    hash: "sha256:chunk1".to_string(),
                }
            ],
            metadata: ContentMetadata {
                version: "1.0.0".to_string(),
                dependencies: vec![],
                install_size: 15728640,
            },
        })
    }

    /// Synchronize content library with server
    pub async fn sync_content(&self, request: SyncRequest) -> AppResult<SyncResponse> {
        // Compare local content with server state
        let mut to_download = Vec::new();
        let mut to_delete = Vec::new();

        // For now, return empty sync (Phase 1 implementation)
        Ok(SyncResponse {
            to_download,
            to_delete,
            sync_token: format!("sync_{}", Utc::now().timestamp()),
        })
    }

    /// Get AI-powered content recommendations
    pub async fn get_recommendations(&self, child_id: Uuid, count: Option<i32>, exclude_owned: Option<bool>) -> AppResult<RecommendationsResponse> {
        let limit = count.unwrap_or(10);
        
        // Use marketplace browse for recommendations
        let request = MarketplaceBrowseRequest {
            page: Some(1),
            limit: Some(limit),
            content_type: None,
            age_range_min: Some(3),
            age_range_max: Some(8),
            age_range: Some("3-8".to_string()),
            search_query: None,
            price_min: None,
            price_max: None,
            price_range: None,
            featured_only: None,
            creator_tiers: None,
            sort_by: Some("rating".to_string()),
        };

        let response = self.marketplace_repo.browse_marketplace(&request).await
            .map_err(|e| crate::error::AppError::InternalServerError(format!("Database error: {}", e)))?;

        let recommendations: Vec<RecommendationItem> = response.items.into_iter()
            .map(|item| RecommendationItem {
                content: self.marketplace_item_to_ecosystem_item(&item, &child_id),
                reason: "based_on_age".to_string(),
                confidence: 0.85,
                explanation: "Perfect for your age group".to_string(),
            })
            .collect();

        Ok(RecommendationsResponse {
            recommendations,
            interests_detected: vec!["creativity".to_string(), "storytelling".to_string()],
        })
    }

    /// Submit feedback on content for improving recommendations
    pub async fn submit_feedback(&self, request: FeedbackRequest) -> AppResult<()> {
        // Log feedback for recommendation algorithm improvement
        tracing::info!(
            "Content feedback received: child_id={}, content_id={}, type={}, value={:?}",
            request.child_id,
            request.content_id,
            request.feedback_type,
            request.value
        );

        // In a full implementation, this would update recommendation models
        Ok(())
    }

    /// Helper function to convert marketplace item to ecosystem content item
    fn marketplace_item_to_ecosystem_item(&self, item: &MarketplaceItemSummary, child_id: &Uuid) -> EcosystemContentItem {
        EcosystemContentItem {
            id: item.id,
            content_type: item.content_type.clone(),
            title: item.title.clone(),
            description: format!("Created by {}", item.creator_name),
            thumbnail_url: item.featured_image_url.clone().unwrap_or_else(|| "".to_string()),
            age_range: self.parse_age_range(&item.age_range),
            rating: item.rating.as_ref()
                .and_then(|r| r.to_string().parse().ok())
                .unwrap_or(0.0),
            price: item.price.to_string().parse::<i32>().unwrap_or(0),
            currency: "USD".to_string(),
            is_free: item.price.to_string().parse::<f32>().unwrap_or(0.0) == 0.0,
            is_owned: false, // Would need to check child's library
            download_size: 10485760, // Default 10MB
            metadata: serde_json::json!({
                "creator_name": item.creator_name,
                "creator_tier": item.creator_tier,
                "review_count": item.review_count
            }),
        }
    }

    /// Parse age range string to AgeRange struct
    fn parse_age_range(&self, age_range_str: &str) -> AgeRange {
        if let Some((min_str, max_str)) = age_range_str.split_once('-') {
            let min = min_str.parse().unwrap_or(3);
            let max = max_str.parse().unwrap_or(8);
            AgeRange { min, max }
        } else {
            AgeRange { min: 3, max: 8 }
        }
    }
}