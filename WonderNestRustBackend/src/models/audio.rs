use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AudioSessionRequest {
    #[serde(rename = "childId")]
    pub child_id: String,
    #[serde(rename = "sessionType")]
    pub session_type: String, // "story", "learning", "free_play"
    pub metadata: Option<serde_json::Value>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AudioSessionResponse {
    #[serde(rename = "sessionId")]
    pub session_id: String,
    #[serde(rename = "childId")]
    pub child_id: String,
    #[serde(rename = "sessionType")]
    pub session_type: String,
    pub status: String, // "active", "ended", "paused"
    #[serde(rename = "startTime")]
    pub start_time: String,
    #[serde(rename = "endTime")]
    pub end_time: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AudioMetricsRequest {
    #[serde(rename = "sessionId")]
    pub session_id: String,
    #[serde(rename = "childId")]
    pub child_id: String,
    #[serde(rename = "speechClarity")]
    pub speech_clarity: Option<f64>, // 0.0 to 1.0
    #[serde(rename = "vocabularyUsed")]
    pub vocabulary_used: Option<Vec<String>>,
    #[serde(rename = "sessionDuration")]
    pub session_duration: Option<i32>, // seconds
    #[serde(rename = "engagementLevel")]
    pub engagement_level: Option<f64>, // 0.0 to 1.0
    pub metadata: Option<serde_json::Value>,
}