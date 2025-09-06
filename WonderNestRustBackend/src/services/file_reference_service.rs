use sqlx::PgPool;
use uuid::Uuid;
use anyhow::Result;

use crate::models::{
    FileReference, FileReferenceCount, ReferenceTypeCount
};

pub struct FileReferenceService {
    pool: PgPool,
}

impl FileReferenceService {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// Check if a file has any active references
    pub async fn has_references(&self, file_id: Uuid) -> Result<bool> {
        let count = sqlx::query_scalar!(
            "SELECT reference_count FROM core.uploaded_files WHERE id = $1",
            file_id
        )
        .fetch_optional(&self.pool)
        .await?;

        Ok(count.unwrap_or(0) > 0)
    }

    /// Get detailed reference count for a file
    pub async fn get_reference_count(&self, file_id: Uuid) -> Result<FileReferenceCount> {
        // Get total count from the uploaded_files table (maintained by trigger)
        let total_references = sqlx::query_scalar!(
            "SELECT reference_count FROM core.uploaded_files WHERE id = $1",
            file_id
        )
        .fetch_optional(&self.pool)
        .await?
        .unwrap_or(0);

        // Get breakdown by reference type
        let reference_types = sqlx::query!(
            r#"
            SELECT reference_type, COUNT(*) as count
            FROM content.file_references 
            WHERE file_id = $1
            GROUP BY reference_type
            ORDER BY reference_type
            "#,
            file_id
        )
        .fetch_all(&self.pool)
        .await?
        .into_iter()
        .map(|row| ReferenceTypeCount {
            reference_type: row.reference_type,
            count: row.count.unwrap_or(0) as i32,
        })
        .collect();

        Ok(FileReferenceCount {
            file_id,
            total_references,
            reference_types,
        })
    }

    /// Get all references for a file
    pub async fn get_file_references(&self, file_id: Uuid) -> Result<Vec<FileReference>> {
        let references = sqlx::query_as!(
            FileReference,
            r#"
            SELECT id, file_id, reference_type, reference_id, created_at
            FROM content.file_references
            WHERE file_id = $1
            ORDER BY created_at DESC
            "#,
            file_id
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(references)
    }

    /// Add a reference to a file
    pub async fn add_reference(
        &self,
        file_id: Uuid,
        reference_type: &str,
        reference_id: Uuid,
    ) -> Result<FileReference> {
        let reference = sqlx::query_as!(
            FileReference,
            r#"
            INSERT INTO content.file_references (file_id, reference_type, reference_id)
            VALUES ($1, $2, $3)
            ON CONFLICT (file_id, reference_type, reference_id) DO NOTHING
            RETURNING id, file_id, reference_type, reference_id, created_at
            "#,
            file_id,
            reference_type,
            reference_id
        )
        .fetch_one(&self.pool)
        .await?;

        Ok(reference)
    }

    /// Remove a reference from a file
    pub async fn remove_reference(
        &self,
        file_id: Uuid,
        reference_type: &str,
        reference_id: Uuid,
    ) -> Result<bool> {
        let result = sqlx::query!(
            r#"
            DELETE FROM content.file_references
            WHERE file_id = $1 AND reference_type = $2 AND reference_id = $3
            "#,
            file_id,
            reference_type,
            reference_id
        )
        .execute(&self.pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    /// Check for orphaned files (no owner, no references)
    pub async fn find_orphaned_files(&self, limit: Option<i64>) -> Result<Vec<Uuid>> {
        let limit = limit.unwrap_or(100);
        
        let file_ids = sqlx::query_scalar!(
            r#"
            SELECT id
            FROM core.uploaded_files
            WHERE user_id IS NULL 
                AND detached_at IS NOT NULL
                AND reference_count = 0
                AND is_system_image = false
            ORDER BY detached_at ASC
            LIMIT $1
            "#,
            limit
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(file_ids)
    }

    /// Check specific content types for file references
    /// This method checks beyond the file_references table for direct column references
    pub async fn check_direct_references(&self, file_id: Uuid) -> Result<Vec<String>> {
        let mut reference_types = Vec::new();

        // Check for story content (stories table - check if file_id appears in content)
        // This is a simple text search - in production you'd want a more sophisticated approach
        let story_count = sqlx::query_scalar!(
            "SELECT COUNT(*) FROM content.stories WHERE content LIKE '%' || $1 || '%'",
            file_id.to_string()
        )
        .fetch_one(&self.pool)
        .await?
        .unwrap_or(0);

        if story_count > 0 {
            reference_types.push("story_content".to_string());
        }

        // Check for marketplace featured images (check if file URL contains file_id)
        let marketplace_count = sqlx::query_scalar!(
            "SELECT COUNT(*) FROM games.marketplace_listings WHERE featured_image_url LIKE '%' || $1 || '%'",
            file_id.to_string()
        )
        .fetch_one(&self.pool)
        .await?
        .unwrap_or(0);

        if marketplace_count > 0 {
            reference_types.push("marketplace_featured_image".to_string());
        }

        // Note: Profile pictures and child avatars would be checked here
        // when those columns are added to the database schema
        // For now, these are commented out:
        // - core.users.profile_picture_id
        // - family.child_profiles.avatar_file_id

        Ok(reference_types)
    }

    /// Get comprehensive reference information (both tracked and direct references)
    pub async fn get_comprehensive_references(&self, file_id: Uuid) -> Result<Vec<String>> {
        let mut all_references = Vec::new();

        // Get tracked references
        let tracked_refs = self.get_file_references(file_id).await?;
        for reference in tracked_refs {
            all_references.push(reference.reference_type);
        }

        // Get direct references
        let direct_refs = self.check_direct_references(file_id).await?;
        all_references.extend(direct_refs);

        // Remove duplicates and sort
        all_references.sort();
        all_references.dedup();

        Ok(all_references)
    }

    /// Validate that all references in the file_references table are still valid
    pub async fn validate_references(&self, file_id: Uuid) -> Result<Vec<String>> {
        let references = self.get_file_references(file_id).await?;
        let mut invalid_references = Vec::new();

        for reference in references {
            let is_valid = match reference.reference_type.as_str() {
                "story" => {
                    sqlx::query_scalar!(
                        "SELECT COUNT(*) FROM content.stories WHERE id = $1",
                        reference.reference_id
                    )
                    .fetch_one(&self.pool)
                    .await?
                    .unwrap_or(0) > 0
                },
                "marketplace_listing" => {
                    sqlx::query_scalar!(
                        "SELECT COUNT(*) FROM games.marketplace_listings WHERE id = $1",
                        reference.reference_id
                    )
                    .fetch_one(&self.pool)
                    .await?
                    .unwrap_or(0) > 0
                },
                "user_profile" => {
                    sqlx::query_scalar!(
                        "SELECT COUNT(*) FROM core.users WHERE id = $1",
                        reference.reference_id
                    )
                    .fetch_one(&self.pool)
                    .await?
                    .unwrap_or(0) > 0
                },
                "child_profile" => {
                    sqlx::query_scalar!(
                        "SELECT COUNT(*) FROM family.child_profiles WHERE id = $1",
                        reference.reference_id
                    )
                    .fetch_one(&self.pool)
                    .await?
                    .unwrap_or(0) > 0
                },
                // For direct content references like story_content, marketplace_featured_image
                // we assume they're valid since they were detected by our direct reference checks
                "story_content" | "marketplace_featured_image" => true,
                _ => true, // Unknown reference types are assumed valid
            };

            if !is_valid {
                invalid_references.push(format!(
                    "{}:{}", 
                    reference.reference_type, 
                    reference.reference_id
                ));
            }
        }

        Ok(invalid_references)
    }

    /// Clean up invalid references for a file
    pub async fn cleanup_invalid_references(&self, file_id: Uuid) -> Result<i32> {
        let invalid_refs = self.validate_references(file_id).await?;
        let mut cleaned_count = 0;

        for invalid_ref in invalid_refs {
            let parts: Vec<&str> = invalid_ref.split(':').collect();
            if parts.len() == 2 {
                let reference_type = parts[0];
                let reference_id = Uuid::parse_str(parts[1])?;
                
                if self.remove_reference(file_id, reference_type, reference_id).await? {
                    cleaned_count += 1;
                }
            }
        }

        Ok(cleaned_count)
    }
}