use crate::error::AppError;
use crate::models::admin_content::{
    AdminCreator, AdminContentStaging, AdminBulkImport, AdminSeedingMetrics,
    CreateAdminCreatorRequest, CreateContentRequest, UpdateContentRequest,
    BulkImportStatus, ContentStatus, CreatorType, ContentType,
    PublishContentResponse, ContentListRequest, ContentListResponse, DashboardStatsResponse,
};
use sqlx::PgPool;
use uuid::Uuid;
use chrono::Utc;
use rust_decimal::Decimal;

#[derive(Clone)]
pub struct AdminContentService {
    db: PgPool,
}

impl AdminContentService {
    pub fn new(db: PgPool) -> Self {
        Self { db }
    }

    pub async fn create_admin_creator(
        &self,
        request: CreateAdminCreatorRequest,
        created_by: Uuid,
    ) -> Result<AdminCreator, AppError> {
        let creator = sqlx::query_as::<_, AdminCreator>(
            r#"
            INSERT INTO games.admin_creators (
                email, display_name, creator_type, avatar_url, bio, 
                website_url, can_publish_directly, created_by
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            RETURNING *
            "#
        )
        .bind(&request.email)
        .bind(&request.display_name)
        .bind(request.creator_type.unwrap_or(CreatorType::Admin))
        .bind(&request.avatar_url)
        .bind(&request.bio)
        .bind(&request.website_url)
        .bind(request.can_publish_directly.unwrap_or(true))
        .bind(created_by)
        .fetch_one(&self.db)
        .await
        .map_err(|e| AppError::DatabaseError(e))?;

        Ok(creator)
    }

    pub async fn list_admin_creators(&self, active_only: bool) -> Result<Vec<AdminCreator>, AppError> {
        let query = if active_only {
            sqlx::query_as::<_, AdminCreator>(
                "SELECT * FROM games.admin_creators WHERE is_active = true ORDER BY created_at DESC"
            )
        } else {
            sqlx::query_as::<_, AdminCreator>(
                "SELECT * FROM games.admin_creators ORDER BY created_at DESC"
            )
        };

        let creators = query
            .fetch_all(&self.db)
            .await
            .map_err(|e| AppError::DatabaseError(e))?;

        Ok(creators)
    }

    pub async fn get_admin_creator(&self, creator_id: Uuid) -> Result<AdminCreator, AppError> {
        let creator = sqlx::query_as::<_, AdminCreator>(
            "SELECT * FROM games.admin_creators WHERE id = $1"
        )
        .bind(creator_id)
        .fetch_one(&self.db)
        .await
        .map_err(|e| match e {
            sqlx::Error::RowNotFound => AppError::NotFound("Creator not found".to_string()),
            _ => AppError::DatabaseError(e),
        })?;

        Ok(creator)
    }

    pub async fn create_content(
        &self,
        request: CreateContentRequest,
    ) -> Result<AdminContentStaging, AppError> {
        let files_json = serde_json::to_value(&request.files)
            .map_err(|e| AppError::ValidationError(e.to_string()))?;

        let content = sqlx::query_as::<_, AdminContentStaging>(
            r#"
            INSERT INTO content.admin_content_staging (
                creator_id, content_type, title, description, content_data,
                files, price, currency, age_range_min, age_range_max,
                tags, search_keywords, bulk_import_batch_id, import_source
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
            RETURNING *
            "#
        )
        .bind(request.creator_id)
        .bind(request.content_type)
        .bind(&request.title)
        .bind(&request.description)
        .bind(&request.content_data)
        .bind(files_json)
        .bind(request.price)
        .bind(request.currency.unwrap_or_else(|| "USD".to_string()))
        .bind(request.age_range_min)
        .bind(request.age_range_max)
        .bind(&request.tags)
        .bind(&request.search_keywords)
        .bind(request.bulk_import_batch_id)
        .bind(&request.import_source)
        .fetch_one(&self.db)
        .await
        .map_err(|e| AppError::DatabaseError(e))?;

        Ok(content)
    }

    pub async fn list_content(
        &self,
        request: ContentListRequest,
    ) -> Result<ContentListResponse, AppError> {
        let page = request.page.unwrap_or(1).max(1);
        let limit = request.limit.unwrap_or(25).min(100);
        let offset = (page - 1) * limit;

        // Build dynamic query based on filters
        let mut query = String::from("SELECT * FROM content.admin_content_staging WHERE 1=1");
        let mut count_query = String::from("SELECT COUNT(*) FROM content.admin_content_staging WHERE 1=1");
        let mut bindings = vec![];

        if let Some(creator_id) = request.creator_id {
            query.push_str(&format!(" AND creator_id = ${}", bindings.len() + 1));
            count_query.push_str(&format!(" AND creator_id = ${}", bindings.len() + 1));
            bindings.push(creator_id.to_string());
        }

        if let Some(content_type) = request.content_type {
            query.push_str(&format!(" AND content_type = ${}", bindings.len() + 1));
            count_query.push_str(&format!(" AND content_type = ${}", bindings.len() + 1));
            bindings.push(content_type.to_string());
        }

        if let Some(status) = request.status {
            query.push_str(&format!(" AND status = ${}", bindings.len() + 1));
            count_query.push_str(&format!(" AND status = ${}", bindings.len() + 1));
            bindings.push(status.to_string());
        }

        if let Some(search) = request.search {
            query.push_str(&format!(" AND (title ILIKE ${} OR description ILIKE ${})", 
                bindings.len() + 1, bindings.len() + 1));
            count_query.push_str(&format!(" AND (title ILIKE ${} OR description ILIKE ${})", 
                bindings.len() + 1, bindings.len() + 1));
            bindings.push(format!("%{}%", search));
        }

        // Add sorting
        let sort_by = request.sort_by.unwrap_or_else(|| "created_at".to_string());
        let sort_order = request.sort_order.unwrap_or_else(|| "desc".to_string());
        query.push_str(&format!(" ORDER BY {} {}", sort_by, sort_order));

        // Add pagination
        query.push_str(&format!(" LIMIT {} OFFSET {}", limit, offset));

        // For now, return empty result until we implement dynamic query building
        // This is a simplified version for the MVP
        let items = sqlx::query_as::<_, AdminContentStaging>(
            "SELECT * FROM content.admin_content_staging ORDER BY created_at DESC LIMIT $1 OFFSET $2"
        )
        .bind(limit)
        .bind(offset)
        .fetch_all(&self.db)
        .await
        .map_err(|e| AppError::DatabaseError(e))?;

        let total_count: i64 = sqlx::query_scalar(
            "SELECT COUNT(*) FROM content.admin_content_staging"
        )
        .fetch_one(&self.db)
        .await
        .map_err(|e| AppError::DatabaseError(e))?;

        let total_pages = ((total_count as i32 + limit - 1) / limit).max(1);

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
        // Build dynamic update query based on provided fields
        let mut updates = vec![];
        let mut bind_count = 1;

        if request.title.is_some() {
            updates.push(format!("title = ${}", bind_count));
            bind_count += 1;
        }
        if request.description.is_some() {
            updates.push(format!("description = ${}", bind_count));
            bind_count += 1;
        }
        if request.price.is_some() {
            updates.push(format!("price = ${}", bind_count));
            bind_count += 1;
        }
        if request.status.is_some() {
            updates.push(format!("status = ${}", bind_count));
            bind_count += 1;
        }

        if updates.is_empty() {
            return Err(AppError::ValidationError("No fields to update".to_string()));
        }

        updates.push("updated_at = CURRENT_TIMESTAMP".to_string());
        let query = format!(
            "UPDATE content.admin_content_staging SET {} WHERE id = ${} RETURNING *",
            updates.join(", "),
            bind_count
        );

        // For MVP, just update status if provided
        if let Some(status) = request.status {
            let content = sqlx::query_as::<_, AdminContentStaging>(
                "UPDATE content.admin_content_staging SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *"
            )
            .bind(status)
            .bind(content_id)
            .fetch_one(&self.db)
            .await
            .map_err(|e| match e {
                sqlx::Error::RowNotFound => AppError::NotFound("Content not found".to_string()),
                _ => AppError::DatabaseError(e),
            })?;

            Ok(content)
        } else {
            self.get_content(content_id).await
        }
    }
    
    pub async fn get_content(
        &self,
        content_id: Uuid,
    ) -> Result<AdminContentStaging, AppError> {
        let content = sqlx::query_as::<_, AdminContentStaging>(
            "SELECT * FROM content.admin_content_staging WHERE id = $1"
        )
        .bind(content_id)
        .fetch_one(&self.db)
        .await
        .map_err(|e| match e {
            sqlx::Error::RowNotFound => AppError::NotFound("Content not found".to_string()),
            _ => AppError::DatabaseError(e),
        })?;

        Ok(content)
    }

    pub async fn publish_content(
        &self,
        content_id: Uuid,
        published_by: Uuid,
    ) -> Result<PublishContentResponse, AppError> {
        // Update content status to published
        let content = sqlx::query_as::<_, AdminContentStaging>(
            r#"
            UPDATE content.admin_content_staging 
            SET status = 'published', 
                published_at = CURRENT_TIMESTAMP, 
                published_by = $1,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = $2 
            RETURNING *
            "#
        )
        .bind(published_by)
        .bind(content_id)
        .fetch_one(&self.db)
        .await
        .map_err(|e| match e {
            sqlx::Error::RowNotFound => AppError::NotFound("Content not found".to_string()),
            _ => AppError::DatabaseError(e),
        })?;

        // TODO: Create marketplace listing
        let marketplace_listing_id = Uuid::new_v4(); // Placeholder

        Ok(PublishContentResponse {
            content_id,
            marketplace_listing_id,
            status: "published".to_string(),
            published_at: content.published_at.unwrap_or_else(Utc::now),
            marketplace_url: Some(format!("/marketplace/{}", marketplace_listing_id)),
        })
    }

    pub async fn create_bulk_import(
        &self,
        created_by: Uuid,
        import_type: String,
        filename: Option<String>,
        total_items: i32,
    ) -> Result<AdminBulkImport, AppError> {
        let import = sqlx::query_as::<_, AdminBulkImport>(
            r#"
            INSERT INTO content.admin_bulk_imports (
                initiated_by, import_type, source_filename, total_items
            ) VALUES ($1, $2, $3, $4)
            RETURNING *
            "#
        )
        .bind(created_by)
        .bind(&import_type)
        .bind(&filename)
        .bind(total_items)
        .fetch_one(&self.db)
        .await
        .map_err(|e| AppError::DatabaseError(e))?;

        Ok(import)
    }

    pub async fn update_bulk_import_progress(
        &self,
        batch_id: Uuid,
        processed: i32,
        successful: i32,
        failed: i32,
        status: Option<BulkImportStatus>,
    ) -> Result<(), AppError> {
        let mut query = String::from("UPDATE content.admin_bulk_imports SET ");
        let updates = vec![
            format!("processed_items = {}", processed),
            format!("successful_items = {}", successful),
            format!("failed_items = {}", failed),
            "updated_at = CURRENT_TIMESTAMP".to_string(),
        ];

        if let Some(status) = status {
            sqlx::query(
                r#"
                UPDATE content.admin_bulk_imports 
                SET processed_items = $1, 
                    successful_items = $2, 
                    failed_items = $3,
                    status = $4,
                    completed_at = CASE WHEN $4 IN ('completed', 'failed', 'cancelled') THEN CURRENT_TIMESTAMP ELSE NULL END,
                    updated_at = CURRENT_TIMESTAMP
                WHERE batch_id = $5
                "#
            )
            .bind(processed)
            .bind(successful)
            .bind(failed)
            .bind(status)
            .bind(batch_id)
            .execute(&self.db)
            .await
            .map_err(|e| AppError::DatabaseError(e))?;
        } else {
            sqlx::query(
                r#"
                UPDATE content.admin_bulk_imports 
                SET processed_items = $1, 
                    successful_items = $2, 
                    failed_items = $3,
                    updated_at = CURRENT_TIMESTAMP
                WHERE batch_id = $4
                "#
            )
            .bind(processed)
            .bind(successful)
            .bind(failed)
            .bind(batch_id)
            .execute(&self.db)
            .await
            .map_err(|e| AppError::DatabaseError(e))?;
        }

        Ok(())
    }

    pub async fn update_admin_creator(
        &self,
        creator_id: Uuid,
        request: crate::models::UpdateAdminCreatorRequest,
    ) -> Result<AdminCreator, AppError> {
        // For now, simplified update - just update display_name if provided
        let creator = if let Some(ref display_name) = request.display_name {
            sqlx::query_as::<_, AdminCreator>(
                "UPDATE games.admin_creators SET display_name = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *"
            )
            .bind(display_name)
            .bind(creator_id)
            .fetch_one(&self.db)
            .await
            .map_err(|e| match e {
                sqlx::Error::RowNotFound => AppError::NotFound("Creator not found".to_string()),
                _ => AppError::DatabaseError(e),
            })?
        } else {
            self.get_admin_creator(creator_id).await?
        };
        
        Ok(creator)
    }

    pub async fn get_dashboard_stats(&self) -> Result<DashboardStatsResponse, AppError> {
        // Get total content count
        let total_content: i64 = sqlx::query_scalar(
            "SELECT COUNT(*) FROM content.admin_content_staging"
        )
        .fetch_one(&self.db)
        .await
        .map_err(|e| AppError::DatabaseError(e))?;

        // Get published content count
        let published_content: i64 = sqlx::query_scalar(
            "SELECT COUNT(*) FROM content.admin_content_staging WHERE status = 'published'"
        )
        .fetch_one(&self.db)
        .await
        .map_err(|e| AppError::DatabaseError(e))?;

        // Get draft content count
        let draft_content: i64 = sqlx::query_scalar(
            "SELECT COUNT(*) FROM content.admin_content_staging WHERE status = 'draft'"
        )
        .fetch_one(&self.db)
        .await
        .map_err(|e| AppError::DatabaseError(e))?;

        // Get creator count
        let total_creators: i64 = sqlx::query_scalar(
            "SELECT COUNT(*) FROM games.admin_creators"
        )
        .fetch_one(&self.db)
        .await
        .map_err(|e| AppError::DatabaseError(e))?;

        // Get active creator count
        let active_creators: i64 = sqlx::query_scalar(
            "SELECT COUNT(*) FROM games.admin_creators WHERE is_active = true"
        )
        .fetch_one(&self.db)
        .await
        .map_err(|e| AppError::DatabaseError(e))?;

        // Get recent uploads (last 7 days)
        let recent_uploads: i64 = sqlx::query_scalar(
            "SELECT COUNT(*) FROM content.admin_content_staging WHERE created_at > CURRENT_TIMESTAMP - INTERVAL '7 days'"
        )
        .fetch_one(&self.db)
        .await
        .map_err(|e| AppError::DatabaseError(e))?;

        // Get average price
        let avg_price: Option<Decimal> = sqlx::query_scalar(
            "SELECT AVG(price) FROM content.admin_content_staging WHERE price IS NOT NULL"
        )
        .fetch_one(&self.db)
        .await
        .map_err(|e| AppError::DatabaseError(e))?;

        // Get total value
        let total_value: Option<Decimal> = sqlx::query_scalar(
            "SELECT SUM(price) FROM content.admin_content_staging WHERE price IS NOT NULL"
        )
        .fetch_one(&self.db)
        .await
        .map_err(|e| AppError::DatabaseError(e))?;

        Ok(DashboardStatsResponse {
            total_content,
            published_content,
            draft_content,
            total_creators,
            active_creators,
            recent_uploads,
            avg_price: avg_price.unwrap_or_else(|| Decimal::from(0)),
            total_value: total_value.unwrap_or_else(|| Decimal::from(0)),
        })
    }
}