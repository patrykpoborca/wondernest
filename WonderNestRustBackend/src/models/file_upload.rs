use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct UploadedFileDto {
    pub id: String,
    #[serde(rename = "originalName")]
    pub original_name: String,
    #[serde(rename = "mimeType")]
    pub mime_type: String,
    #[serde(rename = "fileSize")]
    pub file_size: i64,
    pub category: String,
    pub url: String,
    #[serde(rename = "uploadedAt")]
    pub uploaded_at: String,
    pub metadata: Option<serde_json::Value>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FileUploadSuccessResponse {
    pub data: UploadedFileDto,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FileListSuccessResponse {
    pub data: Vec<UploadedFileDto>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FileDeleteSuccessResponse {
    pub message: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FileUsageResponse {
    #[serde(rename = "isUsed")]
    pub is_used: bool,
    pub stories: Vec<String>, // Story IDs where this file is used
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FileErrorResponse {
    pub error: ErrorDetails,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ErrorDetails {
    pub code: String,
    pub message: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FileQueryParams {
    pub category: Option<String>,
    #[serde(rename = "childId")]
    pub child_id: Option<String>,
    pub limit: Option<i32>,
    pub offset: Option<i32>,
    #[serde(rename = "isPublic")]
    pub is_public: Option<bool>,
}