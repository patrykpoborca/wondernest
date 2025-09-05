use async_trait::async_trait;
use aws_config::{BehaviorVersion, Region};
use aws_sdk_s3::{config::Credentials, primitives::ByteStream, Client};
use bytes::Bytes;
use chrono::{DateTime, Utc};
use std::{collections::HashMap, time::Duration};
use tracing::{debug, error, info};

use super::provider::{FileMetadata, StorageError, StorageProvider, StorageResult};

/// MinIO storage provider configuration
#[derive(Debug, Clone)]
pub struct MinIOConfig {
    pub endpoint: String,
    pub access_key: String,
    pub secret_key: String,
    pub bucket: String,
    pub region: String,
    pub force_path_style: bool,
}

impl Default for MinIOConfig {
    fn default() -> Self {
        Self {
            endpoint: "http://localhost:9000".to_string(),
            access_key: "minioadmin".to_string(),
            secret_key: "minioadmin".to_string(),
            bucket: "wondernest-dev".to_string(),
            region: "us-east-1".to_string(),
            force_path_style: true,
        }
    }
}

/// MinIO storage provider using AWS S3 SDK
pub struct MinIOStorageProvider {
    client: Client,
    bucket: String,
}

impl MinIOStorageProvider {
    /// Create a new MinIO storage provider
    pub async fn new(config: MinIOConfig) -> Result<Self, StorageError> {
        info!("Initializing MinIO storage provider with endpoint: {}", config.endpoint);

        // Create custom credentials
        let credentials = Credentials::new(
            &config.access_key,
            &config.secret_key,
            None, // session token
            None, // expiration
            "wondernest-minio",
        );

        // Build AWS config for MinIO
        let aws_config = aws_config::defaults(BehaviorVersion::latest())
            .region(Region::new(config.region.clone()))
            .credentials_provider(credentials)
            .endpoint_url(&config.endpoint)
            .load()
            .await;

        // Configure S3 client for MinIO
        let s3_config = aws_sdk_s3::config::Builder::from(&aws_config)
            .force_path_style(config.force_path_style)
            .build();

        let client = Client::from_conf(s3_config);

        // Verify bucket exists or create it
        let provider = Self {
            client,
            bucket: config.bucket.clone(),
        };

        // Test connectivity and ensure bucket exists
        provider.ensure_bucket_exists().await?;

        info!("MinIO storage provider initialized successfully");
        Ok(provider)
    }

    /// Ensure the bucket exists, create if it doesn't
    async fn ensure_bucket_exists(&self) -> Result<(), StorageError> {
        debug!("Checking if bucket '{}' exists", self.bucket);

        match self.client.head_bucket().bucket(&self.bucket).send().await {
            Ok(_) => {
                debug!("Bucket '{}' exists", self.bucket);
                Ok(())
            }
            Err(_) => {
                info!("Bucket '{}' doesn't exist, creating it", self.bucket);
                self.client
                    .create_bucket()
                    .bucket(&self.bucket)
                    .send()
                    .await
                    .map_err(|e| {
                        error!("Failed to create bucket '{}': {}", self.bucket, e);
                        StorageError::ConfigError(format!("Failed to create bucket: {}", e))
                    })?;
                
                info!("Bucket '{}' created successfully", self.bucket);
                Ok(())
            }
        }
    }

    /// Convert AWS S3 errors to our storage errors
    fn map_s3_error(error: aws_sdk_s3::error::SdkError<impl std::error::Error>) -> StorageError {
        match error {
            aws_sdk_s3::error::SdkError::ServiceError(service_error) => {
                // Handle specific S3 error codes if needed
                StorageError::NetworkError(format!("S3 service error: {:?}", service_error))
            }
            aws_sdk_s3::error::SdkError::TimeoutError(_) => {
                StorageError::NetworkError("Request timeout".to_string())
            }
            aws_sdk_s3::error::SdkError::DispatchFailure(_) => {
                StorageError::NetworkError("Network dispatch failure".to_string())
            }
            _ => StorageError::Unknown(format!("Unknown S3 error: {:?}", error)),
        }
    }
}

#[async_trait]
impl StorageProvider for MinIOStorageProvider {
    async fn upload(
        &self,
        key: &str,
        data: Bytes,
        content_type: &str,
        metadata: HashMap<String, String>,
    ) -> Result<StorageResult, StorageError> {
        debug!("Uploading object to MinIO: key={}, size={} bytes", key, data.len());

        let size = data.len() as i64;
        let body = ByteStream::from(data.clone());

        let mut request = self
            .client
            .put_object()
            .bucket(&self.bucket)
            .key(key)
            .body(body)
            .content_type(content_type);

        // Add metadata
        for (k, v) in &metadata {
            request = request.metadata(k, v);
        }

        let result = request.send().await.map_err(Self::map_s3_error)?;

        let etag = result.e_tag().unwrap_or("unknown").to_string();
        
        info!("Successfully uploaded object to MinIO: key={}, etag={}", key, etag);

        Ok(StorageResult {
            key: key.to_string(),
            url: None, // MinIO URLs should use presigned URLs for access
            size,
            content_type: content_type.to_string(),
            metadata,
        })
    }

    async fn download(&self, key: &str) -> Result<Bytes, StorageError> {
        debug!("Downloading object from MinIO: key={}", key);

        let response = self
            .client
            .get_object()
            .bucket(&self.bucket)
            .key(key)
            .send()
            .await
            .map_err(|e| {
                if let aws_sdk_s3::error::SdkError::ServiceError(service_error) = &e {
                    if service_error.err().is_no_such_key() {
                        return StorageError::NotFound(key.to_string());
                    }
                }
                Self::map_s3_error(e)
            })?;

        let data = response
            .body
            .collect()
            .await
            .map_err(|e| StorageError::DownloadFailed(format!("Failed to read object body: {}", e)))?
            .into_bytes();

        info!("Successfully downloaded object from MinIO: key={}, size={} bytes", key, data.len());
        Ok(data)
    }

    async fn get_presigned_url(
        &self,
        key: &str,
        expiration_seconds: u64,
    ) -> Result<String, StorageError> {
        debug!("Generating presigned URL for key={}, expiration={}s", key, expiration_seconds);

        let presigned_request = self
            .client
            .get_object()
            .bucket(&self.bucket)
            .key(key)
            .presigned(
                aws_sdk_s3::presigning::PresigningConfig::expires_in(
                    Duration::from_secs(expiration_seconds)
                ).map_err(|e| StorageError::ConfigError(format!("Invalid expiration time: {}", e)))?
            )
            .await
            .map_err(|e| StorageError::ConfigError(format!("Failed to generate presigned URL: {}", e)))?;

        let url = presigned_request.uri().to_string();
        info!("Generated presigned URL for key={}", key);
        Ok(url)
    }

    async fn delete(&self, key: &str) -> Result<(), StorageError> {
        debug!("Deleting object from MinIO: key={}", key);

        self.client
            .delete_object()
            .bucket(&self.bucket)
            .key(key)
            .send()
            .await
            .map_err(Self::map_s3_error)?;

        info!("Successfully deleted object from MinIO: key={}", key);
        Ok(())
    }

    async fn exists(&self, key: &str) -> Result<bool, StorageError> {
        debug!("Checking if object exists in MinIO: key={}", key);

        match self
            .client
            .head_object()
            .bucket(&self.bucket)
            .key(key)
            .send()
            .await
        {
            Ok(_) => {
                debug!("Object exists in MinIO: key={}", key);
                Ok(true)
            }
            Err(e) => {
                if let aws_sdk_s3::error::SdkError::ServiceError(service_error) = &e {
                    if service_error.err().is_not_found() {
                        debug!("Object does not exist in MinIO: key={}", key);
                        return Ok(false);
                    }
                }
                Err(Self::map_s3_error(e))
            }
        }
    }

    async fn get_metadata(&self, key: &str) -> Result<FileMetadata, StorageError> {
        debug!("Getting metadata for object in MinIO: key={}", key);

        let response = self
            .client
            .head_object()
            .bucket(&self.bucket)
            .key(key)
            .send()
            .await
            .map_err(|e| {
                if let aws_sdk_s3::error::SdkError::ServiceError(service_error) = &e {
                    if service_error.err().is_not_found() {
                        return StorageError::NotFound(key.to_string());
                    }
                }
                Self::map_s3_error(e)
            })?;

        let size = response.content_length().unwrap_or(0);
        let content_type = response.content_type().unwrap_or("application/octet-stream").to_string();
        let last_modified = response
            .last_modified()
            .map(|dt| DateTime::from_timestamp(dt.as_secs_f64() as i64, 0).unwrap_or_default())
            .unwrap_or_else(Utc::now);

        let metadata = response
            .metadata()
            .map(|m| m.iter().map(|(k, v)| (k.clone(), v.clone())).collect())
            .unwrap_or_default();

        info!("Retrieved metadata for object in MinIO: key={}, size={} bytes", key, size);

        Ok(FileMetadata {
            key: key.to_string(),
            size,
            content_type,
            last_modified,
            metadata,
        })
    }

    async fn list_files(
        &self,
        prefix: Option<&str>,
        max_results: usize,
    ) -> Result<Vec<FileMetadata>, StorageError> {
        debug!("Listing files in MinIO: prefix={:?}, max_results={}", prefix, max_results);

        let mut request = self
            .client
            .list_objects_v2()
            .bucket(&self.bucket)
            .max_keys(max_results as i32);

        if let Some(prefix) = prefix {
            request = request.prefix(prefix);
        }

        let response = request.send().await.map_err(Self::map_s3_error)?;

        let files: Result<Vec<_>, StorageError> = response
            .contents()
            .iter()
            .map(|object| {
                let key = object.key().unwrap_or("").to_string();
                let size = object.size().unwrap_or(0);
                let last_modified = object
                    .last_modified()
                    .map(|dt| DateTime::from_timestamp(dt.as_secs_f64() as i64, 0).unwrap_or_default())
                    .unwrap_or_else(Utc::now);

                // Note: ListObjects doesn't return content-type or metadata
                // For full metadata, need to make individual HeadObject calls
                Ok(FileMetadata {
                    key,
                    size,
                    content_type: "application/octet-stream".to_string(), // Default, would need HeadObject for actual type
                    last_modified,
                    metadata: HashMap::new(),
                })
            })
            .collect();

        let files = files?;
        info!("Listed {} files in MinIO with prefix {:?}", files.len(), prefix);
        Ok(files)
    }
}