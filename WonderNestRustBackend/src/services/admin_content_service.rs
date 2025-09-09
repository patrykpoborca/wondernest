use crate::error::AppError;
use crate::models::{
    AdminBulkImport, AdminContentStaging, AdminCreator, BulkImportStatus, ContentListRequest,
    ContentListResponse, ContentStatus, CreateAdminCreatorRequest, CreateContentRequest,
    DashboardStatsResponse, PublishContentResponse, UpdateAdminCreatorRequest,
    UpdateContentRequest,
};
use anyhow::Result;
use chrono::Utc;
use sqlx::{PgPool, Row};
use uuid::Uuid;

#[derive(Clone)]
pub struct AdminContentService {
    db: PgPool,
}

impl AdminContentService {
    pub fn new(db: PgPool) -> Self {
        Self { db }
    }

    // =============================================================================
    // ADMIN CREATOR OPERATIONS
    // =============================================================================

    pub async fn create_admin_creator(
        &self,
        request: CreateAdminCreatorRequest,
        created_by: Uuid,
    ) -> Result<AdminCreator, AppError> {
        let creator_type = request.creator_type.unwrap_or(crate::models::CreatorType::Admin);
        let can_publish_directly = request.can_publish_directly.unwrap_or(true);

        let creator = sqlx::query_as!(
            AdminCreator,
            r#"
            INSERT INTO games.admin_creators (
                email, display_name, creator_type, avatar_url, bio, 
                website_url, can_publish_directly, created_by
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            RETURNING id, email, display_name, 
                creator_type as "creator_type: crate::models::CreatorType",
                avatar_url, bio, website_url, is_active, 
                can_publish_directly, created_by, created_at, updated_at
            "#,
            request.email,
            request.display_name,
            creator_type.to_string(),
            request.avatar_url,
            request.bio,
            request.website_url,
            can_publish_directly,
            created_by
        )
        .fetch_one(&self.db)
        .await
        .map_err(|e| match e {
            sqlx::Error::Database(db_err) if db_err.constraint() == Some("admin_creators_email_key") => {
                AppError::BadRequest("Email already exists".to_string())
            }
            _ => AppError::DatabaseError(e.to_string()),
        })?;

        Ok(creator)
    }

    pub async fn get_admin_creator(&self, creator_id: Uuid) -> Result<AdminCreator, AppError> {
        let creator = sqlx::query_as!(
            AdminCreator,
            r#"
            SELECT id, email, display_name, 
                creator_type as "creator_type: crate::models::CreatorType",
                avatar_url, bio, website_url, is_active, 
                can_publish_directly, created_by, created_at, updated_at
            FROM games.admin_creators 
            WHERE id = $1
            "#,
            creator_id
        )
        .fetch_optional(&self.db)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?
        .ok_or_else(|| AppError::NotFound("Creator not found".to_string()))?;

        Ok(creator)
    }

    pub async fn list_admin_creators(&self, active_only: bool) -> Result<Vec<AdminCreator>, AppError> {
        let query = if active_only {
            r#"
            SELECT id, email, display_name, 
                creator_type as "creator_type: crate::models::CreatorType",
                avatar_url, bio, website_url, is_active, 
                can_publish_directly, created_by, created_at, updated_at
            FROM games.admin_creators 
            WHERE is_active = true
            ORDER BY display_name
            "#
        } else {
            r#"
            SELECT id, email, display_name, 
                creator_type as "creator_type: crate::models::CreatorType",
                avatar_url, bio, website_url, is_active, 
                can_publish_directly, created_by, created_at, updated_at
            FROM games.admin_creators 
            ORDER BY display_name
            "#
        };

        let creators = sqlx::query_as::<_, AdminCreator>(query)
            .fetch_all(&self.db)
            .await
            .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        Ok(creators)
    }

    pub async fn update_admin_creator(
        &self,
        creator_id: Uuid,
        request: UpdateAdminCreatorRequest,
    ) -> Result<AdminCreator, AppError> {
        // First check if creator exists
        self.get_admin_creator(creator_id).await?;

        let creator = sqlx::query_as!(
            AdminCreator,
            r#"
            UPDATE games.admin_creators SET
                display_name = COALESCE($2, display_name),
                avatar_url = COALESCE($3, avatar_url),
                bio = COALESCE($4, bio),
                website_url = COALESCE($5, website_url),
                is_active = COALESCE($6, is_active),
                can_publish_directly = COALESCE($7, can_publish_directly),
                updated_at = CURRENT_TIMESTAMP
            WHERE id = $1
            RETURNING id, email, display_name, 
                creator_type as "creator_type: crate::models::CreatorType",
                avatar_url, bio, website_url, is_active, 
                can_publish_directly, created_by, created_at, updated_at
            "#,
            creator_id,
            request.display_name,
            request.avatar_url,
            request.bio,
            request.website_url,
            request.is_active,
            request.can_publish_directly
        )
        .fetch_one(&self.db)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        Ok(creator)
    }

    // =============================================================================
    // CONTENT STAGING OPERATIONS
    // =============================================================================

    pub async fn create_content(&self, request: CreateContentRequest) -> Result<AdminContentStaging, AppError> {
        // Verify creator exists
        self.get_admin_creator(request.creator_id).await?;

        let currency = request.currency.unwrap_or_else(|| "USD".to_string());
        let files_json = serde_json::to_value(&request.files)
            .map_err(|e| AppError::BadRequest(format!("Invalid files data: {}", e)))?;

        let content = sqlx::query_as!(
            AdminContentStaging,
            r#"
            INSERT INTO games.admin_content_staging (
                creator_id, content_type, title, description, content_data,
                files, price, currency, age_range_min, age_range_max,
                tags, search_keywords, bulk_import_batch_id, import_source
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
            RETURNING id, creator_id, 
                content_type as "content_type: crate::models::ContentType",
                title, description, content_data, files, price, currency,
                age_range_min, age_range_max, tags, search_keywords,
                status as "status: crate::models::ContentStatus",
                marketplace_listing_id, published_at, published_by,
                bulk_import_batch_id, import_source, created_at, updated_at
            "#,
            request.creator_id,
            request.content_type.to_string(),
            request.title,
            request.description,
            request.content_data,
            files_json,
            request.price,
            currency,
            request.age_range_min,
            request.age_range_max,
            &request.tags,
            &request.search_keywords,
            request.bulk_import_batch_id,
            request.import_source
        )
        .fetch_one(&self.db)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        Ok(content)
    }

    pub async fn get_content(&self, content_id: Uuid) -> Result<AdminContentStaging, AppError> {
        let content = sqlx::query_as!(
            AdminContentStaging,
            r#"
            SELECT id, creator_id, 
                content_type as "content_type: crate::models::ContentType",
                title, description, content_data, files, price, currency,
                age_range_min, age_range_max, tags, search_keywords,
                status as "status: crate::models::ContentStatus",
                marketplace_listing_id, published_at, published_by,
                bulk_import_batch_id, import_source, created_at, updated_at
            FROM games.admin_content_staging 
            WHERE id = $1
            "#,
            content_id
        )
        .fetch_optional(&self.db)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?
        .ok_or_else(|| AppError::NotFound("Content not found".to_string()))?;

        Ok(content)
    }

    pub async fn list_content(&self, request: ContentListRequest) -> Result<ContentListResponse, AppError> {
        let page = request.page.unwrap_or(1).max(1);
        let limit = request.limit.unwrap_or(20).min(100).max(1);
        let offset = (page - 1) * limit;

        let mut query = String::from(
            r#"
            SELECT id, creator_id, 
                content_type as "content_type: crate::models::ContentType",
                title, description, content_data, files, price, currency,
                age_range_min, age_range_max, tags, search_keywords,
                status as "status: crate::models::ContentStatus",
                marketplace_listing_id, published_at, published_by,
                bulk_import_batch_id, import_source, created_at, updated_at
            FROM games.admin_content_staging 
            WHERE 1=1
            "#,
        );

        let mut count_query = String::from(
            "SELECT COUNT(*) FROM games.admin_content_staging WHERE 1=1"
        );

        // Build WHERE clauses
        let mut conditions = Vec::new();
        let mut params_count = 0;

        if let Some(creator_id) = request.creator_id {
            params_count += 1;
            conditions.push(format!(" AND creator_id = ${}", params_count));
        }

        if let Some(content_type) = request.content_type {
            params_count += 1;
            conditions.push(format!(" AND content_type = ${}", params_count));
        }

        if let Some(status) = request.status {
            params_count += 1;
            conditions.push(format!(" AND status = ${}", params_count));
        }

        if let Some(_search) = request.search {
            params_count += 1;
            conditions.push(format!(
                " AND (title ILIKE ${0} OR description ILIKE ${0})",
                params_count
            ));
        }

        // Add conditions to both queries
        for condition in &conditions {
            query.push_str(condition);
            count_query.push_str(condition);
        }

        // Add ordering
        let sort_by = request.sort_by.unwrap_or_else(|| "created_at".to_string());
        let sort_order = request.sort_order.unwrap_or_else(|| "desc".to_string());
        query.push_str(&format!(" ORDER BY {} {}", sort_by, sort_order));

        // Add pagination
        params_count += 1;
        let limit_param = params_count;
        params_count += 1;
        let offset_param = params_count;
        query.push_str(&format!(" LIMIT ${} OFFSET ${}", limit_param, offset_param));

        // Execute count query first
        let mut count_query_builder = sqlx::query(&count_query);
        let mut query_builder = sqlx::query_as::<_, AdminContentStaging>(&query);

        // Add parameters in the same order
        if let Some(creator_id) = request.creator_id {
            count_query_builder = count_query_builder.bind(creator_id);
            query_builder = query_builder.bind(creator_id);
        }

        if let Some(content_type) = request.content_type {
            count_query_builder = count_query_builder.bind(content_type.to_string());
            query_builder = query_builder.bind(content_type.to_string());
        }

        if let Some(status) = request.status {
            count_query_builder = count_query_builder.bind(status.to_string());
            query_builder = query_builder.bind(status.to_string());
        }

        if let Some(search) = request.search {
            let search_pattern = format!("%{}%", search);
            count_query_builder = count_query_builder.bind(&search_pattern);
            query_builder = query_builder.bind(&search_pattern);
        }

        // Add limit and offset to main query only
        query_builder = query_builder.bind(limit).bind(offset);

        // Execute queries
        let total_count: i64 = count_query_builder
            .fetch_one(&self.db)
            .await
            .map_err(|e| AppError::DatabaseError(e.to_string()))?
            .get(0);

        let items = query_builder
            .fetch_all(&self.db)
            .await
            .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        let total_pages = ((total_count as f64) / (limit as f64)).ceil() as i32;

        Ok(ContentListResponse {
            items,
            total_count,
            page,
            total_pages,
            has_next: page < total_pages,
            has_previous: page > 1,
        })
    }

    pub async fn update_content(
        &self,
        content_id: Uuid,
        request: UpdateContentRequest,
    ) -> Result<AdminContentStaging, AppError> {
        // First check if content exists
        self.get_content(content_id).await?;

        let files_json = if let Some(files) = request.files {
            Some(serde_json::to_value(&files)
                .map_err(|e| AppError::BadRequest(format!("Invalid files data: {}", e)))?)
        } else {
            None
        };

        let content = sqlx::query_as!(
            AdminContentStaging,
            r#"
            UPDATE games.admin_content_staging SET
                title = COALESCE($2, title),
                description = COALESCE($3, description),
                content_data = COALESCE($4, content_data),
                price = COALESCE($5, price),
                currency = COALESCE($6, currency),
                age_range_min = COALESCE($7, age_range_min),
                age_range_max = COALESCE($8, age_range_max),
                tags = COALESCE($9, tags),
                search_keywords = COALESCE($10, search_keywords),
                files = COALESCE($11, files),
                status = COALESCE($12, status::varchar)::varchar,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = $1
            RETURNING id, creator_id, 
                content_type as "content_type: crate::models::ContentType",
                title, description, content_data, files, price, currency,
                age_range_min, age_range_max, tags, search_keywords,
                status as "status: crate::models::ContentStatus",
                marketplace_listing_id, published_at, published_by,
                bulk_import_batch_id, import_source, created_at, updated_at
            "#,
            content_id,
            request.title,
            request.description,
            request.content_data,
            request.price,
            request.currency,
            request.age_range_min,
            request.age_range_max,
            request.tags.as_ref().map(|v| v.as_slice()),
            request.search_keywords.as_ref().map(|v| v.as_slice()),
            files_json,
            request.status.map(|s| s.to_string())
        )
        .fetch_one(&self.db)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        Ok(content)
    }

    pub async fn publish_content(&self, content_id: Uuid, published_by: Uuid) -> Result<PublishContentResponse, AppError> {
        // Get the content to publish
        let content = self.get_content(content_id).await?;

        if content.status == ContentStatus::Published {
            return Err(AppError::BadRequest("Content already published".to_string()));
        }

        // TODO: Implement marketplace listing creation
        // For now, we'll just mark as published without creating marketplace listing
        let published_at = Utc::now();
        
        let updated_content = sqlx::query!(
            r#"
            UPDATE games.admin_content_staging SET
                status = 'published',
                published_at = $2,
                published_by = $3,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = $1
            "#,
            content_id,
            published_at,
            published_by
        )
        .execute(&self.db)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        if updated_content.rows_affected() == 0 {
            return Err(AppError::NotFound("Content not found".to_string()));
        }

        // TODO: Create actual marketplace listing
        let marketplace_listing_id = Uuid::new_v4(); // Placeholder

        Ok(PublishContentResponse {
            content_id,
            marketplace_listing_id,
            status: "published".to_string(),
            published_at,
            marketplace_url: None,
        })
    }

    // =============================================================================
    // BULK OPERATIONS
    // =============================================================================

    pub async fn create_bulk_import(
        &self,
        initiated_by: Uuid,
        import_type: String,
        source_filename: Option<String>,
        total_items: i32,
    ) -> Result<AdminBulkImport, AppError> {
        let batch_id = Uuid::new_v4();

        let bulk_import = sqlx::query_as!(
            AdminBulkImport,
            r#"
            INSERT INTO games.admin_bulk_imports (
                batch_id, initiated_by, import_type, source_filename, total_items
            ) VALUES ($1, $2, $3, $4, $5)
            RETURNING id, batch_id, initiated_by, import_type, source_filename,
                total_items, processed_items, successful_items, failed_items,
                status as "status: crate::models::BulkImportStatus",
                error_log, success_log, started_at, completed_at, created_at, updated_at
            "#,
            batch_id,
            initiated_by,
            import_type,
            source_filename,
            total_items
        )
        .fetch_one(&self.db)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        Ok(bulk_import)
    }

    pub async fn update_bulk_import_progress(
        &self,
        batch_id: Uuid,
        processed: i32,
        successful: i32,
        failed: i32,
        status: Option<BulkImportStatus>,
    ) -> Result<(), AppError> {

        if let Some(status) = status {
            sqlx::query!(
                r#"
                UPDATE games.admin_bulk_imports SET
                    processed_items = $2,
                    successful_items = $3,
                    failed_items = $4,
                    status = $5,
                    completed_at = CASE WHEN $5 IN ('completed', 'failed', 'cancelled') 
                                       THEN CURRENT_TIMESTAMP 
                                       ELSE completed_at END,
                    updated_at = CURRENT_TIMESTAMP
                WHERE batch_id = $1
                "#,
                batch_id,
                processed,
                successful,
                failed,
                status.to_string()
            )
            .execute(&self.db)
            .await
            .map_err(|e| AppError::DatabaseError(e.to_string()))?;
        } else {
            sqlx::query!(
                r#"
                UPDATE games.admin_bulk_imports SET
                    processed_items = $2,
                    successful_items = $3,
                    failed_items = $4,
                    updated_at = CURRENT_TIMESTAMP
                WHERE batch_id = $1
                "#,
                batch_id,
                processed,
                successful,
                failed
            )
            .execute(&self.db)
            .await
            .map_err(|e| AppError::DatabaseError(e.to_string()))?;
        }

        Ok(())
    }

    // =============================================================================
    // DASHBOARD METRICS
    // =============================================================================

    pub async fn get_dashboard_stats(&self) -> Result<DashboardStatsResponse, AppError> {
        let stats = sqlx::query!(
            r#"
            SELECT 
                COUNT(*) as total_content,
                COUNT(CASE WHEN status = 'published' THEN 1 END) as published_content,
                COUNT(CASE WHEN status = 'draft' THEN 1 END) as draft_content,
                COALESCE(AVG(price), 0) as avg_price,
                COALESCE(SUM(price), 0) as total_value
            FROM games.admin_content_staging
            "#
        )
        .fetch_one(&self.db)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        let creator_stats = sqlx::query!(
            r#"
            SELECT 
                COUNT(*) as total_creators,
                COUNT(CASE WHEN is_active = true THEN 1 END) as active_creators
            FROM games.admin_creators
            "#
        )
        .fetch_one(&self.db)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        let recent_uploads = sqlx::query!(
            r#"
            SELECT COUNT(*) as recent_count
            FROM games.admin_content_staging 
            WHERE created_at > CURRENT_TIMESTAMP - INTERVAL '7 days'
            "#
        )
        .fetch_one(&self.db)
        .await
        .map_err(|e| AppError::DatabaseError(e.to_string()))?;

        Ok(DashboardStatsResponse {
            total_content: stats.total_content.unwrap_or(0),
            published_content: stats.published_content.unwrap_or(0),
            draft_content: stats.draft_content.unwrap_or(0),
            total_creators: creator_stats.total_creators.unwrap_or(0),
            active_creators: creator_stats.active_creators.unwrap_or(0),
            recent_uploads: recent_uploads.recent_count.unwrap_or(0),
            avg_price: stats.avg_price.unwrap_or_default().into(),
            total_value: stats.total_value.unwrap_or_default().into(),
        })
    }
}