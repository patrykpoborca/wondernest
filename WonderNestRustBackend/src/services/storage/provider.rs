use async_trait::async_trait;
use bytes::Bytes;
use chrono::{DateTime, Utc};
use std::collections::HashMap;
use thiserror::Error;

/// Storage provider trait for file operations
#[async_trait]
pub trait StorageProvider: Send + Sync {
    /// Upload a file to storage
    async fn upload(
        &self,
        key: &str,
        data: Bytes,
        content_type: &str,
        metadata: HashMap<String, String>,
    ) -> Result<StorageResult, StorageError>;

    /// Download a file from storage
    async fn download(&self, key: &str) -> Result<Bytes, StorageError>;

    /// Get a presigned URL for direct access
    async fn get_presigned_url(
        &self,
        key: &str,
        expiration_seconds: u64,
    ) -> Result<String, StorageError>;

    /// Delete a file from storage
    async fn delete(&self, key: &str) -> Result<(), StorageError>;

    /// Check if a file exists
    async fn exists(&self, key: &str) -> Result<bool, StorageError>;

    /// Get file metadata
    async fn get_metadata(&self, key: &str) -> Result<FileMetadata, StorageError>;

    /// List files with optional prefix
    async fn list_files(
        &self,
        prefix: Option<&str>,
        max_results: usize,
    ) -> Result<Vec<FileMetadata>, StorageError>;
}

/// Result of a storage operation
#[derive(Debug, Clone)]
pub struct StorageResult {
    pub key: String,
    pub url: Option<String>,
    pub size: i64,
    pub content_type: String,
    pub metadata: HashMap<String, String>,
}

/// File metadata
#[derive(Debug, Clone)]
pub struct FileMetadata {
    pub key: String,
    pub size: i64,
    pub content_type: String,
    pub last_modified: DateTime<Utc>,
    pub metadata: HashMap<String, String>,
}

/// Storage errors
#[derive(Error, Debug)]
pub enum StorageError {
    #[error("File not found: {0}")]
    NotFound(String),

    #[error("Access denied: {0}")]
    AccessDenied(String),

    #[error("Invalid key: {0}")]
    InvalidKey(String),

    #[error("Upload failed: {0}")]
    UploadFailed(String),

    #[error("Download failed: {0}")]
    DownloadFailed(String),

    #[error("Delete failed: {0}")]
    DeleteFailed(String),

    #[error("Network error: {0}")]
    NetworkError(String),

    #[error("Configuration error: {0}")]
    ConfigError(String),

    #[error("IO error: {0}")]
    IoError(#[from] std::io::Error),

    #[error("Unknown error: {0}")]
    Unknown(String),
}