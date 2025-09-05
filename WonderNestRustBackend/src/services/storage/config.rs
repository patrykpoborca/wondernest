use std::sync::Arc;
use tracing::{info, warn};

use super::{
    minio_provider::{MinIOConfig, MinIOStorageProvider},
    provider::{StorageError, StorageProvider},
    s3_provider::{S3Config, S3StorageProvider},
};

/// Storage provider configuration enum
#[derive(Debug, Clone)]
pub enum StorageProviderConfig {
    MinIO(MinIOConfig),
    S3(S3Config),
}

impl StorageProviderConfig {
    /// Create storage provider configuration from environment variables
    pub fn from_env() -> Result<Self, StorageError> {
        let provider_type = std::env::var("STORAGE_PROVIDER").unwrap_or_else(|_| {
            info!("STORAGE_PROVIDER not set, defaulting to MinIO for development");
            "minio".to_string()
        });

        match provider_type.to_lowercase().as_str() {
            "minio" => Ok(StorageProviderConfig::MinIO(MinIOConfig::from_env()?)),
            "s3" => Ok(StorageProviderConfig::S3(S3Config::from_env()?)),
            _ => {
                warn!("Unknown storage provider '{}', defaulting to MinIO", provider_type);
                Ok(StorageProviderConfig::MinIO(MinIOConfig::from_env()?))
            }
        }
    }

    /// Create a storage provider instance from this configuration
    pub async fn create_provider(&self) -> Result<Arc<dyn StorageProvider>, StorageError> {
        match self {
            StorageProviderConfig::MinIO(config) => {
                info!("Creating MinIO storage provider");
                let provider = MinIOStorageProvider::new(config.clone()).await?;
                Ok(Arc::new(provider))
            }
            StorageProviderConfig::S3(config) => {
                info!("Creating S3 storage provider");
                let provider = S3StorageProvider::new(config.clone()).await?;
                Ok(Arc::new(provider))
            }
        }
    }
}

impl MinIOConfig {
    /// Create MinIO configuration from environment variables
    pub fn from_env() -> Result<Self, StorageError> {
        let endpoint = std::env::var("MINIO_ENDPOINT").unwrap_or_else(|_| {
            info!("MINIO_ENDPOINT not set, using default: http://localhost:9000");
            "http://localhost:9000".to_string()
        });

        let access_key = std::env::var("MINIO_ACCESS_KEY").unwrap_or_else(|_| {
            info!("MINIO_ACCESS_KEY not set, using default: minioadmin");
            "minioadmin".to_string()
        });

        let secret_key = std::env::var("MINIO_SECRET_KEY").unwrap_or_else(|_| {
            info!("MINIO_SECRET_KEY not set, using default: minioadmin");
            "minioadmin".to_string()
        });

        let bucket = std::env::var("MINIO_BUCKET").unwrap_or_else(|_| {
            info!("MINIO_BUCKET not set, using default: wondernest-dev");
            "wondernest-dev".to_string()
        });

        let region = std::env::var("MINIO_REGION").unwrap_or_else(|_| {
            "us-east-1".to_string()
        });

        let force_path_style = std::env::var("MINIO_FORCE_PATH_STYLE")
            .unwrap_or_else(|_| "true".to_string())
            .parse()
            .unwrap_or(true);

        Ok(Self {
            endpoint,
            access_key,
            secret_key,
            bucket,
            region,
            force_path_style,
        })
    }

    /// Create MinIO configuration for testing
    pub fn for_testing() -> Self {
        Self {
            endpoint: "http://localhost:9000".to_string(),
            access_key: "test-access-key".to_string(),
            secret_key: "test-secret-key".to_string(),
            bucket: "test-bucket".to_string(),
            region: "us-east-1".to_string(),
            force_path_style: true,
        }
    }
}

impl S3Config {
    /// Create S3 configuration from environment variables
    pub fn from_env() -> Result<Self, StorageError> {
        let region = std::env::var("AWS_REGION")
            .or_else(|_| std::env::var("S3_REGION"))
            .unwrap_or_else(|_| {
                info!("AWS_REGION/S3_REGION not set, using default: us-east-1");
                "us-east-1".to_string()
            });

        let bucket = std::env::var("S3_BUCKET").map_err(|_| {
            StorageError::ConfigError("S3_BUCKET environment variable is required for S3 storage".to_string())
        })?;

        // Optional explicit credentials (will fall back to IAM roles/default credential chain)
        let access_key = std::env::var("AWS_ACCESS_KEY_ID").ok();
        let secret_key = std::env::var("AWS_SECRET_ACCESS_KEY").ok();

        if access_key.is_none() || secret_key.is_none() {
            info!("AWS credentials not provided via environment variables, will use default credential chain (IAM roles, etc.)");
        }

        Ok(Self {
            region,
            bucket,
            access_key,
            secret_key,
        })
    }

    /// Create S3 configuration for testing
    pub fn for_testing() -> Self {
        Self {
            region: "us-east-1".to_string(),
            bucket: "test-bucket".to_string(),
            access_key: Some("test-access-key".to_string()),
            secret_key: Some("test-secret-key".to_string()),
        }
    }
}

/// Storage configuration builder for different environments
pub struct StorageConfigBuilder;

impl StorageConfigBuilder {
    /// Create development configuration (MinIO)
    pub fn development() -> StorageProviderConfig {
        StorageProviderConfig::MinIO(MinIOConfig::default())
    }

    /// Create production configuration (S3)
    pub fn production(bucket: String, region: String) -> StorageProviderConfig {
        StorageProviderConfig::S3(S3Config {
            region,
            bucket,
            access_key: None, // Use IAM roles in production
            secret_key: None,
        })
    }

    /// Create testing configuration (MinIO with test settings)
    pub fn testing() -> StorageProviderConfig {
        StorageProviderConfig::MinIO(MinIOConfig::for_testing())
    }

    /// Create configuration from environment variables
    pub fn from_environment() -> Result<StorageProviderConfig, StorageError> {
        StorageProviderConfig::from_env()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_development_config() {
        let config = StorageConfigBuilder::development();
        match config {
            StorageProviderConfig::MinIO(minio_config) => {
                assert_eq!(minio_config.endpoint, "http://localhost:9000");
                assert_eq!(minio_config.bucket, "wondernest-dev");
            }
            _ => panic!("Expected MinIO config for development"),
        }
    }

    #[test]
    fn test_production_config() {
        let config = StorageConfigBuilder::production(
            "my-production-bucket".to_string(),
            "us-west-2".to_string(),
        );
        match config {
            StorageProviderConfig::S3(s3_config) => {
                assert_eq!(s3_config.bucket, "my-production-bucket");
                assert_eq!(s3_config.region, "us-west-2");
                assert!(s3_config.access_key.is_none());
                assert!(s3_config.secret_key.is_none());
            }
            _ => panic!("Expected S3 config for production"),
        }
    }

    #[test]
    fn test_testing_config() {
        let config = StorageConfigBuilder::testing();
        match config {
            StorageProviderConfig::MinIO(minio_config) => {
                assert_eq!(minio_config.bucket, "test-bucket");
                assert_eq!(minio_config.access_key, "test-access-key");
            }
            _ => panic!("Expected MinIO config for testing"),
        }
    }
}