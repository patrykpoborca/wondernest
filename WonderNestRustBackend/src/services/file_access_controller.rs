use sqlx::PgPool;
use uuid::Uuid;
use crate::error::{AppError, AppResult};

#[derive(Debug, Clone)]
pub struct FileInfo {
    pub id: Uuid,
    pub owner_id: Uuid,
    pub is_public: bool,
    pub detached_at: Option<chrono::DateTime<chrono::Utc>>,
}

#[derive(Debug, Clone)]
pub struct FamilyMember {
    pub user_id: Uuid,
    pub name: String,
    pub role: String,
}

#[derive(Debug, Clone)]
pub struct FilePermissions {
    pub can_view: bool,
    pub can_edit: bool,
    pub can_delete: bool,
    pub can_change_visibility: bool,
}

#[derive(Clone)]
pub struct FileAccessController {
    pool: PgPool,
}

impl FileAccessController {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// Check if a user can view a specific file
    /// Rules: 
    /// - Public files: anyone can view
    /// - Private files: only family members can view
    /// - Detached files: treated as non-existent
    pub async fn can_view_file(&self, user_id: Uuid, file_id: Uuid) -> AppResult<bool> {
        let file_info = self.get_file_info(file_id).await?
            .ok_or_else(|| AppError::NotFound("File not found".to_string()))?;

        // Detached files are not accessible
        if file_info.detached_at.is_some() {
            return Ok(false);
        }

        // Public files can be viewed by anyone
        if file_info.is_public {
            return Ok(true);
        }

        // For private files, check family membership
        self.are_family_members(user_id, file_info.owner_id).await
    }

    /// Check if a user can edit a specific file
    /// Rule: Only file owner can edit, regardless of family relationships
    pub async fn can_edit_file(&self, user_id: Uuid, file_id: Uuid) -> AppResult<bool> {
        let file_info = self.get_file_info(file_id).await?
            .ok_or_else(|| AppError::NotFound("File not found".to_string()))?;

        // Detached files cannot be edited
        if file_info.detached_at.is_some() {
            return Ok(false);
        }

        Ok(user_id == file_info.owner_id)
    }

    /// Check if a user can delete a specific file
    /// Rule: Only file owner can delete, regardless of family relationships
    pub async fn can_delete_file(&self, user_id: Uuid, file_id: Uuid) -> AppResult<bool> {
        let file_info = self.get_file_info(file_id).await?
            .ok_or_else(|| AppError::NotFound("File not found".to_string()))?;

        // Detached files cannot be deleted again
        if file_info.detached_at.is_some() {
            return Ok(false);
        }

        Ok(user_id == file_info.owner_id)
    }

    /// Get comprehensive permissions for a user on a file
    pub async fn get_file_permissions(
        &self, 
        user_id: Uuid, 
        file_id: Uuid
    ) -> AppResult<FilePermissions> {
        let can_view = self.can_view_file(user_id, file_id).await.unwrap_or(false);
        let can_edit = self.can_edit_file(user_id, file_id).await.unwrap_or(false);
        let can_delete = self.can_delete_file(user_id, file_id).await.unwrap_or(false);
        let can_change_visibility = can_edit; // Only owners can change visibility

        Ok(FilePermissions {
            can_view,
            can_edit,
            can_delete,
            can_change_visibility,
        })
    }

    /// Check if two users are family members
    pub async fn are_family_members(&self, user1_id: Uuid, user2_id: Uuid) -> AppResult<bool> {
        // Same user is always considered family
        if user1_id == user2_id {
            return Ok(true);
        }

        let result = sqlx::query_scalar!(
            r#"
            SELECT COUNT(*) > 0 as are_family_members
            FROM family.family_members fm1
            JOIN family.family_members fm2 ON fm1.family_id = fm2.family_id
            WHERE fm1.user_id = $1 AND fm2.user_id = $2
            "#,
            user1_id,
            user2_id
        )
        .fetch_one(&self.pool)
        .await
        .map_err(|e| {
            tracing::error!("Failed to check family membership: {}", e);
            AppError::DatabaseError(e)
        })?;

        Ok(result.unwrap_or(false))
    }

    /// Get all family members for a user
    pub async fn get_family_members(&self, user_id: Uuid) -> AppResult<Vec<FamilyMember>> {
        let members = sqlx::query!(
            r#"
            SELECT fm2.user_id, u.first_name, u.last_name, fm2.role
            FROM family.family_members fm1
            JOIN family.family_members fm2 ON fm1.family_id = fm2.family_id
            JOIN core.users u ON fm2.user_id = u.id
            WHERE fm1.user_id = $1
            "#,
            user_id
        )
        .fetch_all(&self.pool)
        .await
        .map_err(|e| {
            tracing::error!("Failed to get family members: {}", e);
            AppError::DatabaseError(e)
        })?;

        Ok(members
            .into_iter()
            .map(|row| {
                let full_name = match (row.first_name, row.last_name) {
                    (Some(first), Some(last)) => format!("{} {}", first, last),
                    (Some(first), None) => first,
                    (None, Some(last)) => last,
                    (None, None) => "Unknown".to_string(),
                };
                FamilyMember {
                    user_id: row.user_id,
                    name: full_name,
                    role: row.role.unwrap_or_else(|| "member".to_string()),
                }
            })
            .collect())
    }

    /// Get appropriate file URL based on user permissions and file visibility
    pub async fn get_appropriate_file_url(
        &self,
        user_id: Option<Uuid>,
        file_info: &FileInfo,
        base_url: &str,
    ) -> String {
        // For public files, always use public URL
        if file_info.is_public {
            return format!("{}/api/v1/files/{}/public", base_url, file_info.id);
        }

        // For private files, use family URL if user is provided
        if user_id.is_some() {
            return format!("{}/api/v1/files/{}/family", base_url, file_info.id);
        }

        // Fallback to public URL (will return 404 for private files)
        format!("{}/api/v1/files/{}/public", base_url, file_info.id)
    }

    /// Get basic file information for permission checking
    async fn get_file_info(&self, file_id: Uuid) -> AppResult<Option<FileInfo>> {
        let result = sqlx::query!(
            r#"
            SELECT id, user_id as owner_id, is_public, detached_at
            FROM core.uploaded_files
            WHERE id = $1
            "#,
            file_id
        )
        .fetch_optional(&self.pool)
        .await
        .map_err(|e| {
            tracing::error!("Failed to get file info: {}", e);
            AppError::DatabaseError(e)
        })?;

        Ok(result.map(|row| FileInfo {
            id: row.id,
            owner_id: row.owner_id,
            is_public: row.is_public.unwrap_or(false),
            detached_at: row.detached_at,
        }))
    }

    /// Validate file access and return appropriate error for security
    /// Returns 404 for private files accessed by non-family members (no information leakage)
    pub async fn validate_file_access(
        &self,
        user_id: Option<Uuid>,
        file_id: Uuid,
        require_owner: bool,
    ) -> AppResult<FileInfo> {
        let file_info = self.get_file_info(file_id).await?
            .ok_or_else(|| AppError::NotFound("File not found".to_string()))?;

        // Detached files are treated as non-existent
        if file_info.detached_at.is_some() {
            return Err(AppError::NotFound("File not found".to_string()));
        }

        // If ownership is required, check that first
        if require_owner {
            let user_id = user_id.ok_or(AppError::Unauthorized)?;
            if user_id != file_info.owner_id {
                return Err(AppError::Forbidden("You don't own this file".to_string()));
            }
            return Ok(file_info);
        }

        // For public files, allow access
        if file_info.is_public {
            return Ok(file_info);
        }

        // For private files, require authentication and family membership
        let user_id = user_id.ok_or(AppError::NotFound("File not found".to_string()))?;
        
        if !self.are_family_members(user_id, file_info.owner_id).await? {
            // Return 404 (not 403) to prevent information leakage
            return Err(AppError::NotFound("File not found".to_string()));
        }

        Ok(file_info)
    }

    /// Get file owner information for enhanced responses
    pub async fn get_file_owner_info(
        &self,
        file_id: Uuid,
        requesting_user_id: Option<Uuid>,
    ) -> AppResult<Option<(String, bool, Option<String>)>> {
        let result = sqlx::query!(
            r#"
            SELECT u.first_name, u.last_name, uf.user_id as owner_id
            FROM core.uploaded_files uf
            JOIN core.users u ON uf.user_id = u.id
            WHERE uf.id = $1 AND uf.detached_at IS NULL
            "#,
            file_id
        )
        .fetch_optional(&self.pool)
        .await
        .map_err(|e| {
            tracing::error!("Failed to get file owner info: {}", e);
            AppError::DatabaseError(e)
        })?;

        if let Some(row) = result {
            let owner_name = match (row.first_name, row.last_name) {
                (Some(first), Some(last)) => format!("{} {}", first, last),
                (Some(first), None) => first,
                (None, Some(last)) => last,
                (None, None) => "Unknown".to_string(),
            };

            let is_owner = requesting_user_id
                .map(|uid| uid == row.owner_id)
                .unwrap_or(false);

            // Get relationship if not owner
            let relationship = if !is_owner && requesting_user_id.is_some() {
                // For now, just return "family" - can be enhanced later with specific relationships
                Some("family".to_string())
            } else {
                None
            };

            Ok(Some((owner_name, is_owner, relationship)))
        } else {
            Ok(None)
        }
    }
}