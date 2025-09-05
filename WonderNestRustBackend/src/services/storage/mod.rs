pub mod config;
pub mod minio_provider;
pub mod provider;
pub mod s3_provider;

// Primary exports
pub use config::{StorageConfigBuilder, StorageProviderConfig};
pub use minio_provider::{MinIOConfig, MinIOStorageProvider};
pub use provider::{FileMetadata, StorageError, StorageProvider, StorageResult};
pub use s3_provider::{S3Config, S3StorageProvider};