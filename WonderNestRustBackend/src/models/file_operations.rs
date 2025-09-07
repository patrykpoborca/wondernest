use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum FileOperation {
    /// File was completely removed from storage and database
    HardDeleted,
    /// File ownership was removed but file preserved due to active references
    SoftDetached,
    /// File cannot be deleted due to protection rules
    Protected,
    /// File was already processed (deleted or detached)
    AlreadyDeleted,
    /// Operation failed due to error
    Failed,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileOperationResponse {
    pub file_id: Uuid,
    pub operation: FileOperation,
    pub reason: Option<String>,
    pub references_count: Option<i32>,
    pub reference_types: Option<Vec<String>>,
    pub storage_freed: Option<i64>, // bytes freed from storage
    pub timestamp: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct FileReference {
    pub id: Uuid,
    pub file_id: Uuid,
    pub reference_type: String,
    pub reference_id: Uuid,
    pub created_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileReferenceCount {
    pub file_id: Uuid,
    pub total_references: i32,
    pub reference_types: Vec<ReferenceTypeCount>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ReferenceTypeCount {
    pub reference_type: String,
    pub count: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BatchFileOperationRequest {
    pub file_ids: Vec<Uuid>,
    pub force_delete: Option<bool>, // Admin only: ignore references
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BatchFileOperationResponse {
    pub operations: Vec<FileOperationResponse>,
    pub total_processed: usize,
    pub total_storage_freed: i64,
    pub summary: BatchOperationSummary,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BatchOperationSummary {
    pub hard_deleted: i32,
    pub soft_detached: i32,
    pub protected: i32,
    pub failed: i32,
    pub already_deleted: i32,
}

impl FileOperationResponse {
    pub fn new(file_id: Uuid, operation: FileOperation) -> Self {
        Self {
            file_id,
            operation,
            reason: None,
            references_count: None,
            reference_types: None,
            storage_freed: None,
            timestamp: Utc::now(),
        }
    }

    pub fn with_reason(mut self, reason: impl Into<String>) -> Self {
        self.reason = Some(reason.into());
        self
    }

    pub fn with_references(mut self, count: i32, types: Vec<String>) -> Self {
        self.references_count = Some(count);
        self.reference_types = Some(types);
        self
    }

    pub fn with_storage_freed(mut self, bytes: i64) -> Self {
        self.storage_freed = Some(bytes);
        self
    }
}

impl Default for BatchOperationSummary {
    fn default() -> Self {
        Self {
            hard_deleted: 0,
            soft_detached: 0,
            protected: 0,
            failed: 0,
            already_deleted: 0,
        }
    }
}

impl BatchOperationSummary {
    pub fn add_operation(&mut self, operation: &FileOperation) {
        match operation {
            FileOperation::HardDeleted => self.hard_deleted += 1,
            FileOperation::SoftDetached => self.soft_detached += 1,
            FileOperation::Protected => self.protected += 1,
            FileOperation::Failed => self.failed += 1,
            FileOperation::AlreadyDeleted => self.already_deleted += 1,
        }
    }
}

// Enhanced uploaded file model with detachment fields
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UploadedFileWithReferences {
    pub id: Uuid,
    pub user_id: Uuid,
    pub child_id: Option<Uuid>,
    pub file_key: String,
    pub original_name: String,
    pub mime_type: String,
    pub file_size: i64,
    pub storage_provider: String,
    pub url: Option<String>,
    pub is_public: Option<bool>,
    pub category: String,
    pub metadata: serde_json::Value,
    pub uploaded_at: Option<DateTime<Utc>>,
    pub accessed_at: Option<DateTime<Utc>>,
    pub deleted_at: Option<DateTime<Utc>>,
    pub detached_at: Option<DateTime<Utc>>,
    pub detached_by: Option<Uuid>,
    pub detachment_reason: Option<String>,
    pub reference_count: i32,
    pub tags: Vec<String>,
    pub tag_count: Option<i32>,
    pub is_system_image: Option<bool>,
    pub is_deleted: Option<bool>,
    pub ai_analyzed: Option<bool>,
    pub ai_description: Option<String>,
    pub detected_content_type: Option<String>,
    pub ai_safety_approved: Option<bool>,
}

#[derive(Debug, thiserror::Error)]
pub enum FileOperationError {
    #[error("File not found: {file_id}")]
    FileNotFound { file_id: Uuid },
    
    #[error("Access denied: User {user_id} does not own file {file_id}")]
    AccessDenied { user_id: Uuid, file_id: Uuid },
    
    #[error("File is protected and cannot be deleted: {reason}")]
    ProtectedFile { reason: String },
    
    #[error("Storage operation failed: {message}")]
    StorageError { message: String },
    
    #[error("Database operation failed: {message}")]
    DatabaseError { message: String },
    
    #[error("Reference counting failed: {message}")]
    ReferenceCountError { message: String },
}