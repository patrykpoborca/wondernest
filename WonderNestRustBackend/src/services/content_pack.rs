use chrono::Utc;
use uuid::Uuid;

use crate::{
    error::AppResult,
    models::{ContentPack, ContentPackCategory, ContentPackSearchRequest, ContentPackSearchResponse},
};

pub struct ContentPackService {
    db: sqlx::PgPool,
}

impl ContentPackService {
    pub fn new(db: sqlx::PgPool) -> Self {
        Self { db }
    }

    pub async fn get_categories(&self) -> AppResult<Vec<ContentPackCategory>> {
        // Mock implementation - return sample categories
        Ok(vec![
            ContentPackCategory {
                id: "animals".to_string(),
                name: "Animals".to_string(),
                icon: "🦁".to_string(),
                description: "Animal themed content".to_string(),
                pack_count: 15,
            },
            ContentPackCategory {
                id: "fantasy".to_string(),
                name: "Fantasy".to_string(),
                icon: "🏰".to_string(),
                description: "Magical and fantasy content".to_string(),
                pack_count: 12,
            },
            ContentPackCategory {
                id: "vehicles".to_string(),
                name: "Vehicles".to_string(),
                icon: "🚗".to_string(),
                description: "Cars, trucks, and transportation".to_string(),
                pack_count: 8,
            },
        ])
    }

    pub async fn get_featured_packs(&self, _user_id: Uuid, limit: i32) -> AppResult<Vec<ContentPack>> {
        // Mock implementation - return sample packs
        let packs = vec![
            ContentPack {
                id: Uuid::new_v4(),
                name: "Safari Animals".to_string(),
                description: "Explore the African savanna with lions, elephants, and giraffes".to_string(),
                category: "animals".to_string(),
                pack_type: "STICKER".to_string(),
                age_min: 3,
                age_max: 8,
                price: 299,
                is_free: false,
                preview_assets: serde_json::json!({
                    "thumbnails": [
                        "https://wondernest.s3.amazonaws.com/packs/safari/thumb1.jpg",
                        "https://wondernest.s3.amazonaws.com/packs/safari/thumb2.jpg"
                    ]
                }),
                educational_goals: vec!["Animal Recognition".to_string(), "Habitat Learning".to_string()],
                tags: vec!["animals".to_string(), "nature".to_string(), "safari".to_string()],
                downloads: 1523,
                rating: 4.8,
                version: "1.0.0".to_string(),
                size_mb: 25,
                created_at: Utc::now(),
                updated_at: Utc::now(),
                publisher_id: None,
                is_featured: true,
                featured_until: Some(Utc::now() + chrono::Duration::days(7)),
            },
            ContentPack {
                id: Uuid::new_v4(),
                name: "Magical Castle".to_string(),
                description: "Build your own fairy tale with princes, dragons, and magic".to_string(),
                category: "fantasy".to_string(),
                pack_type: "STORY".to_string(),
                age_min: 4,
                age_max: 10,
                price: 0,
                is_free: true,
                preview_assets: serde_json::json!({
                    "thumbnails": [
                        "https://wondernest.s3.amazonaws.com/packs/castle/thumb1.jpg"
                    ]
                }),
                educational_goals: vec!["Storytelling".to_string(), "Imagination".to_string()],
                tags: vec!["fantasy".to_string(), "castle".to_string(), "magic".to_string()],
                downloads: 3421,
                rating: 4.9,
                version: "2.1.0".to_string(),
                size_mb: 18,
                created_at: Utc::now(),
                updated_at: Utc::now(),
                publisher_id: None,
                is_featured: true,
                featured_until: Some(Utc::now() + chrono::Duration::days(14)),
            },
            ContentPack {
                id: Uuid::new_v4(),
                name: "Happy Vehicles".to_string(),
                description: "Fun cars, trucks, and trains for transportation adventures".to_string(),
                category: "vehicles".to_string(),
                pack_type: "STICKER".to_string(),
                age_min: 2,
                age_max: 6,
                price: 199,
                is_free: false,
                preview_assets: serde_json::json!({
                    "thumbnails": [
                        "https://wondernest.s3.amazonaws.com/packs/vehicles/thumb1.jpg"
                    ]
                }),
                educational_goals: vec!["Vehicle Recognition".to_string(), "Transportation".to_string()],
                tags: vec!["vehicles".to_string(), "cars".to_string(), "trucks".to_string()],
                downloads: 892,
                rating: 4.6,
                version: "1.2.0".to_string(),
                size_mb: 15,
                created_at: Utc::now(),
                updated_at: Utc::now(),
                publisher_id: None,
                is_featured: false,
                featured_until: None,
            },
        ];

        Ok(packs.into_iter().take(limit as usize).collect())
    }

    pub async fn get_user_owned_packs(&self, _user_id: Uuid, _child_id: Option<Uuid>) -> AppResult<Vec<ContentPack>> {
        // Mock implementation - return empty list for now
        Ok(vec![])
    }

    pub async fn search_packs(&self, request: ContentPackSearchRequest, _user_id: Uuid) -> AppResult<ContentPackSearchResponse> {
        // Mock implementation - return sample results
        let packs = self.get_featured_packs(_user_id, request.size).await?;
        
        Ok(ContentPackSearchResponse {
            total: packs.len() as i64,
            packs,
            page: request.page,
            size: request.size,
            total_pages: 1,
        })
    }

    pub async fn get_pack_by_id(&self, _pack_id: Uuid, _user_id: Uuid) -> AppResult<Option<ContentPack>> {
        // Mock implementation - return a sample pack
        let packs = self.get_featured_packs(_user_id, 1).await?;
        Ok(packs.into_iter().next())
    }
}