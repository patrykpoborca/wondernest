use chrono::Utc;
use sqlx::PgPool;
use std::str::FromStr;
use uuid::Uuid;

// Use BigDecimal directly from the bigdecimal crate
use bigdecimal::BigDecimal;

use crate::models::{
    CreatorProfile, CreateCreatorProfileRequest, MarketplaceListing, ChildLibrary, ChildCollection,
    CollectionItem, PurchaseTransaction, ContentReview, SubscriptionPlan, UserSubscription,
    MarketplaceBrowseRequest, MarketplaceBrowseResponse, MarketplaceItemSummary,
    PurchaseRequest, PurchaseResponse, CreateReviewRequest, CreateCollectionRequest,
    LibraryStatsResponse
};

pub struct MarketplaceRepository {
    pool: PgPool,
}

impl MarketplaceRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    // Creator Profile Operations
    pub async fn create_creator_profile(&self, user_id: Uuid, request: &CreateCreatorProfileRequest) -> anyhow::Result<CreatorProfile> {
        let now = Utc::now();
        
        let profile = sqlx::query_as::<_, CreatorProfile>(
            r#"
            INSERT INTO games.creator_profiles (
                id, user_id, display_name, bio, content_specialties, languages_supported,
                website_url, social_links, tier, created_at, updated_at, creator_since
            ) VALUES (
                gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7, 'hobbyist', $8, $9, $10
            )
            RETURNING *
            "#
        )
        .bind(user_id)
        .bind(&request.display_name)
        .bind(&request.bio)
        .bind(&request.content_specialties)
        .bind(&request.languages_supported)
        .bind(&request.website_url)
        .bind(&request.social_links)
        .bind(now)
        .bind(now)
        .bind(now)
        .fetch_one(&self.pool)
        .await?;

        Ok(profile)
    }

    pub async fn get_creator_profile(&self, user_id: Uuid) -> anyhow::Result<Option<CreatorProfile>> {
        let profile = sqlx::query_as::<_, CreatorProfile>(
            r#"
            SELECT * FROM games.creator_profiles 
            WHERE user_id = $1 AND account_status = 'active'
            "#
        )
        .bind(user_id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(profile)
    }

    // Marketplace Listings Operations
    pub async fn browse_marketplace(&self, request: &MarketplaceBrowseRequest) -> anyhow::Result<MarketplaceBrowseResponse> {
        let limit = request.limit.unwrap_or(20) as i64;
        let offset = ((request.page.unwrap_or(1) - 1) * request.limit.unwrap_or(20)) as i64;

        // Simplified approach - using basic query for now
        let items = sqlx::query!(
            r#"
            SELECT 
                ml.id, 
                COALESCE(ml.marketing_title, 'Untitled') as title,
                ml.price,
                ml.rating,
                ml.review_count,
                ml.featured_image_url,
                COALESCE(cp.display_name, 'Unknown Creator') as creator_name,
                COALESCE(cp.tier, 'hobbyist') as creator_tier,
                'educational' as content_type,
                '3-6' as age_range
            FROM games.marketplace_listings ml
            LEFT JOIN games.creator_profiles cp ON ml.seller_id = cp.user_id
            WHERE COALESCE(ml.status, 'pending') = 'approved'
            ORDER BY ml.created_at DESC
            LIMIT $1 OFFSET $2
            "#,
            limit,
            offset
        )
        .fetch_all(&self.pool)
        .await?;

        let summaries: Vec<MarketplaceItemSummary> = items.into_iter().map(|row| {
            MarketplaceItemSummary {
                id: row.id,
                title: row.title.unwrap_or("Untitled".to_string()),
                price: row.price.clone(),
                rating: row.rating.clone(),
                review_count: row.review_count,
                featured_image_url: row.featured_image_url,
                creator_name: row.creator_name.unwrap_or("Unknown Creator".to_string()),
                creator_tier: row.creator_tier.unwrap_or("hobbyist".to_string()),
                content_type: row.content_type.unwrap_or("educational".to_string()),
                age_range: row.age_range.unwrap_or("3-6".to_string()),
            }
        }).collect();

        // Get total count
        let total_count: i64 = sqlx::query_scalar!(
            "SELECT COUNT(*) FROM games.marketplace_listings ml WHERE COALESCE(ml.status, 'pending') = 'approved'"
        )
        .fetch_one(&self.pool)
        .await?
        .unwrap_or(0);

        let page = request.page.unwrap_or(1);
        let total_pages = ((total_count as f64) / (limit as f64)).ceil() as i32;

        Ok(MarketplaceBrowseResponse {
            items: summaries,
            total_count,
            page,
            total_pages,
        })
    }

    pub async fn get_marketplace_item(&self, item_id: Uuid) -> anyhow::Result<Option<MarketplaceListing>> {
        let item = sqlx::query_as::<_, MarketplaceListing>(
            r#"
            SELECT * FROM games.marketplace_listings 
            WHERE id = $1 AND status = 'approved'
            "#
        )
        .bind(item_id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(item)
    }

    // Child Library Operations
    pub async fn purchase_item(&self, parent_user_id: Uuid, request: &PurchaseRequest) -> anyhow::Result<PurchaseResponse> {
        let transaction_id = format!("txn_{}", Uuid::new_v4());
        let now = Utc::now();

        // Get marketplace item details
        let item = self.get_marketplace_item(request.marketplace_item_id).await?
            .ok_or_else(|| anyhow::anyhow!("Marketplace item not found"))?;

        // Start transaction
        let mut tx = self.pool.begin().await?;

        // Create purchase transaction
        let _transaction = sqlx::query_as::<_, PurchaseTransaction>(
            r#"
            INSERT INTO games.purchase_transactions (
                id, transaction_id, parent_user_id, marketplace_item_id,
                item_price, discount_amount, tax_amount, total_amount, currency_code,
                payment_method, payment_processor, licensing_type, target_children,
                family_license, status, creator_share, platform_share,
                creator_payout_status, initiated_at
            ) VALUES (
                gen_random_uuid(), $1, $2, $3, $4, 0.00, 0.00, $4, 'USD',
                'stripe', 'stripe', 'family', $5, true, 'completed',
                $6, $7, 'pending', $8
            )
            RETURNING *
            "#
        )
        .bind(&transaction_id)
        .bind(parent_user_id)
        .bind(request.marketplace_item_id)
        .bind(&item.price)
        .bind(&request.target_children)
        .bind(&item.price * &BigDecimal::from_str("0.75").unwrap()) // 75% to creator
        .bind(&item.price * &BigDecimal::from_str("0.25").unwrap()) // 25% platform
        .bind(now)
        .fetch_one(&mut *tx)
        .await?;

        // Create child library entries
        let mut library_items = Vec::new();
        for child_id in &request.target_children {
            let library_item = sqlx::query_as::<_, ChildLibrary>(
                r#"
                INSERT INTO games.child_libraries (
                    id, child_id, marketplace_item_id, purchased_by, purchase_date,
                    purchase_price, licensing_type
                ) VALUES (
                    gen_random_uuid(), $1, $2, $3, $4, $5, 'family'
                )
                RETURNING *
                "#
            )
            .bind(child_id)
            .bind(request.marketplace_item_id)
            .bind(parent_user_id)
            .bind(now)
            .bind(&item.price)
            .fetch_one(&mut *tx)
            .await?;

            library_items.push(library_item.id);
        }

        tx.commit().await?;

        Ok(PurchaseResponse {
            transaction_id,
            status: "completed".to_string(),
            total_amount: item.price.clone(),
            library_items_created: library_items,
        })
    }

    pub async fn get_child_library(&self, child_id: Uuid) -> anyhow::Result<Vec<ChildLibrary>> {
        let items = sqlx::query_as::<_, ChildLibrary>(
            r#"
            SELECT * FROM games.child_libraries 
            WHERE child_id = $1
            ORDER BY purchase_date DESC
            "#
        )
        .bind(child_id)
        .fetch_all(&self.pool)
        .await?;

        Ok(items)
    }

    // Collection Operations
    pub async fn create_collection(&self, request: &CreateCollectionRequest) -> anyhow::Result<ChildCollection> {
        let now = Utc::now();

        let collection = sqlx::query_as::<_, ChildCollection>(
            r#"
            INSERT INTO games.child_collections (
                id, child_id, name, description, color_theme, icon_name, created_at, updated_at
            ) VALUES (
                gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7
            )
            RETURNING *
            "#
        )
        .bind(request.child_id)
        .bind(&request.name)
        .bind(&request.description)
        .bind(request.color_theme.as_ref().unwrap_or(&"blue".to_string()))
        .bind(request.icon_name.as_ref().unwrap_or(&"folder".to_string()))
        .bind(now)
        .bind(now)
        .fetch_one(&self.pool)
        .await?;

        Ok(collection)
    }

    pub async fn get_child_collections(&self, child_id: Uuid) -> anyhow::Result<Vec<ChildCollection>> {
        let collections = sqlx::query_as::<_, ChildCollection>(
            r#"
            SELECT * FROM games.child_collections 
            WHERE child_id = $1
            ORDER BY display_order ASC, created_at ASC
            "#
        )
        .bind(child_id)
        .fetch_all(&self.pool)
        .await?;

        Ok(collections)
    }

    // Review Operations
    pub async fn create_review(&self, reviewer_id: Uuid, request: &CreateReviewRequest) -> anyhow::Result<ContentReview> {
        let now = Utc::now();

        let review = sqlx::query_as::<_, ContentReview>(
            r#"
            INSERT INTO games.content_reviews (
                id, marketplace_item_id, reviewer_user_id, rating, title, review_text,
                educational_value, age_appropriateness, engagement_level, technical_quality,
                child_age_when_reviewed, would_recommend, moderation_status, created_at, updated_at
            ) VALUES (
                gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, 'approved', $12, $13
            )
            RETURNING *
            "#
        )
        .bind(request.marketplace_item_id)
        .bind(reviewer_id)
        .bind(request.rating)
        .bind(&request.title)
        .bind(&request.review_text)
        .bind(request.educational_value)
        .bind(request.age_appropriateness)
        .bind(request.engagement_level)
        .bind(request.technical_quality)
        .bind(request.child_age_when_reviewed)
        .bind(request.would_recommend.unwrap_or(true))
        .bind(now)
        .bind(now)
        .fetch_one(&self.pool)
        .await?;

        Ok(review)
    }

    pub async fn get_reviews_for_item(&self, item_id: Uuid) -> anyhow::Result<Vec<ContentReview>> {
        let reviews = sqlx::query_as::<_, ContentReview>(
            r#"
            SELECT * FROM games.content_reviews 
            WHERE marketplace_item_id = $1 AND moderation_status = 'approved'
            ORDER BY created_at DESC
            "#
        )
        .bind(item_id)
        .fetch_all(&self.pool)
        .await?;

        Ok(reviews)
    }

    // Analytics and Stats
    pub async fn get_library_stats(&self, child_id: Uuid) -> anyhow::Result<LibraryStatsResponse> {
        // Get basic stats
        let stats = sqlx::query!(
            r#"
            SELECT 
                COUNT(*) as total_items,
                COUNT(*) FILTER (WHERE favorite = true) as favorites_count,
                COALESCE(SUM(total_play_time_minutes), 0) as total_play_time_minutes,
                COALESCE(AVG(completion_percentage), 0) as avg_completion
            FROM games.child_libraries 
            WHERE child_id = $1
            "#,
            child_id
        )
        .fetch_one(&self.pool)
        .await?;

        let total_play_time_hours = stats.total_play_time_minutes.unwrap_or(0) as f64 / 60.0;
        let completion_rate = stats.avg_completion.unwrap_or(BigDecimal::from_str("0").unwrap()).to_string().parse::<f64>().unwrap_or(0.0);

        // Get recent activities (simplified)
        let recent_activities = Vec::new(); // Would implement with proper query

        Ok(LibraryStatsResponse {
            total_items: stats.total_items.unwrap_or(0),
            favorites_count: stats.favorites_count.unwrap_or(0),
            total_play_time_hours,
            completion_rate,
            recent_activities,
        })
    }
}