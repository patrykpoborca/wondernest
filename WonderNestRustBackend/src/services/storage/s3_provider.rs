use async_trait::async_trait;
use aws_config::BehaviorVersion;
use aws_sdk_s3::{primitives::ByteStream, Client};
use bytes::Bytes;
use chrono::{DateTime, Utc};
use std::{collections::HashMap, time::Duration};
use tracing::{debug, error, info};

use super::provider::{FileMetadata, StorageError, StorageProvider, StorageResult};

/// S3 storage provider configuration
#[derive(Debug, Clone)]
pub struct S3Config {
    pub region: String,
    pub bucket: String,
    pub access_key: Option<String>, // Optional for IAM roles
    pub secret_key: Option<String>, // Optional for IAM roles
}

impl Default for S3Config {
    fn default() -> Self {
        Self {
            region: "us-east-1".to_string(),
            bucket: "wondernest-prod".to_string(),
            access_key: None,
            secret_key: None,
        }
    }
}

/// AWS S3 storage provider for production use
pub struct S3StorageProvider {
    client: Client,
    bucket: String,
}

impl S3StorageProvider {
    /// Create a new S3 storage provider
    pub async fn new(config: S3Config) -> Result<Self, StorageError> {
        info!("Initializing S3 storage provider for bucket: {}", config.bucket);

        // Build AWS config - will use IAM roles if credentials not provided
        let mut aws_config_builder = aws_config::defaults(BehaviorVersion::latest())
            .region(aws_config::Region::new(config.region.clone()));

        // Only set explicit credentials if provided (otherwise use IAM roles/default chain)
        if let (Some(access_key), Some(secret_key)) = (&config.access_key, &config.secret_key) {
            let credentials = aws_sdk_s3::config::Credentials::new(
                access_key,
                secret_key,
                None, // session token
                None, // expiration
                "wondernest-s3",
            );
            aws_config_builder = aws_config_builder.credentials_provider(credentials);
        }

        let aws_config = aws_config_builder.load().await;
        let client = Client::new(&aws_config);

        let provider = Self {
            client,
            bucket: config.bucket.clone(),
        };

        // Verify bucket access
        provider.verify_bucket_access().await?;

        info!("S3 storage provider initialized successfully");
        Ok(provider)
    }

    /// Verify we have access to the bucket
    async fn verify_bucket_access(&self) -> Result<(), StorageError> {
        debug!("Verifying access to S3 bucket: {}", self.bucket);

        self.client
            .head_bucket()
            .bucket(&self.bucket)
            .send()
            .await
            .map_err(|e| {
                error!("Failed to access S3 bucket '{}': {}", self.bucket, e);
                StorageError::ConfigError(format!("Cannot access S3 bucket '{}': {}", self.bucket, e))
            })?;

        debug!("S3 bucket access verified: {}", self.bucket);
        Ok(())
    }

    /// Convert AWS S3 errors to our storage errors
    fn map_s3_error(error: aws_sdk_s3::error::SdkError<impl std::error::Error>) -> StorageError {
        match error {
            aws_sdk_s3::error::SdkError::ServiceError(service_error) => {
                // Handle specific S3 error codes
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
impl StorageProvider for S3StorageProvider {
    async fn upload(
        &self,
        key: &str,
        data: Bytes,
        content_type: &str,
        metadata: HashMap<String, String>,
    ) -> Result<StorageResult, StorageError> {
        debug!("Uploading object to S3: key={}, size={} bytes", key, data.len());

        let size = data.len() as i64;
        let body = ByteStream::from(data.clone());

        let mut request = self
            .client
            .put_object()
            .bucket(&self.bucket)
            .key(key)
            .body(body)
            .content_type(content_type)
            .server_side_encryption(aws_sdk_s3::types::ServerSideEncryption::Aes256); // Enable encryption

        // Add metadata
        for (k, v) in &metadata {
            request = request.metadata(k, v);
        }

        let result = request.send().await.map_err(Self::map_s3_error)?;

        let etag = result.e_tag().unwrap_or("unknown").to_string();
        
        info!("Successfully uploaded object to S3: key={}, etag={}", key, etag);

        // For S3, we don't return direct URLs as they should go through presigned URLs
        Ok(StorageResult {
            key: key.to_string(),
            url: None, // S3 objects should use presigned URLs for access
            size,
            content_type: content_type.to_string(),
            metadata,
        })
    }

    async fn download(&self, key: &str) -> Result<Bytes, StorageError> {
        debug!("Downloading object from S3: key={}", key);

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

        info!("Successfully downloaded object from S3: key={}, size={} bytes", key, data.len());
        Ok(data)
    }

    async fn get_presigned_url(
        &self,
        key: &str,
        expiration_seconds: u64,
    ) -> Result<String, StorageError> {
        debug!("Generating presigned URL for S3 object: key={}, expiration={}s", key, expiration_seconds);

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
        info!("Generated presigned URL for S3 object: key={}", key);
        Ok(url)
    }

    async fn delete(&self, key: &str) -> Result<(), StorageError> {
        debug!("Deleting object from S3: key={}", key);

        self.client
            .delete_object()
            .bucket(&self.bucket)
            .key(key)
            .send()
            .await
            .map_err(Self::map_s3_error)?;

        info!("Successfully deleted object from S3: key={}", key);
        Ok(())
    }

    async fn exists(&self, key: &str) -> Result<bool, StorageError> {
        debug!("Checking if object exists in S3: key={}", key);

        match self
            .client
            .head_object()
            .bucket(&self.bucket)
            .key(key)
            .send()
            .await
        {
            Ok(_) => {
                debug!("Object exists in S3: key={}", key);
                Ok(true)
            }
            Err(e) => {
                if let aws_sdk_s3::error::SdkError::ServiceError(service_error) = &e {
                    if service_error.err().is_not_found() {
                        debug!("Object does not exist in S3: key={}", key);
                        return Ok(false);
                    }
                }
                Err(Self::map_s3_error(e))
            }
        }
    }

    async fn get_metadata(&self, key: &str) -> Result<FileMetadata, StorageError> {
        debug!("Getting metadata for S3 object: key={}", key);

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

        info!("Retrieved metadata for S3 object: key={}, size={} bytes", key, size);

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
        debug!("Listing files in S3: prefix={:?}, max_results={}", prefix, max_results);

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
        info!("Listed {} files in S3 with prefix {:?}", files.len(), prefix);
        Ok(files)
    }
}