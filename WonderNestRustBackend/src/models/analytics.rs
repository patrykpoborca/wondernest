use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct DailyAnalytics {
    pub date: String,
    #[serde(rename = "childId")]
    pub child_id: String,
    #[serde(rename = "totalScreenTime")]
    pub total_screen_time: i32, // minutes
    #[serde(rename = "contentConsumed")]
    pub content_consumed: i32,
    #[serde(rename = "educationalTime")]
    pub educational_time: i32, // minutes
    #[serde(rename = "averageSessionLength")]
    pub average_session_length: i32, // minutes
    #[serde(rename = "mostEngagedCategory")]
    pub most_engaged_category: String,
    #[serde(rename = "completedActivities")]
    pub completed_activities: i32,
    #[serde(rename = "learningProgress")]
    pub learning_progress: f64, // 0.0 to 1.0
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ChildInsights {
    #[serde(rename = "childId")]
    pub child_id: String,
    #[serde(rename = "preferredLearningStyle")]
    pub preferred_learning_style: String,
    #[serde(rename = "strongSubjects")]
    pub strong_subjects: Vec<String>,
    #[serde(rename = "improvementAreas")]
    pub improvement_areas: Vec<String>,
    #[serde(rename = "recommendedActivities")]
    pub recommended_activities: Vec<String>,
    #[serde(rename = "parentalGuidance")]
    pub parental_guidance: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AnalyticsEvent {
    #[serde(rename = "eventType")]
    pub event_type: String,
    #[serde(rename = "childId")]
    pub child_id: String,
    #[serde(rename = "contentId")]
    pub content_id: Option<String>,
    pub duration: Option<i32>,
    #[serde(rename = "eventData")]
    pub event_data: HashMap<String, serde_json::Value>,
    #[serde(rename = "sessionId")]
    pub session_id: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct WeeklyOverview {
    #[serde(rename = "weekStart")]
    pub week_start: String,
    #[serde(rename = "totalScreenTime")]
    pub total_screen_time: i32,
    #[serde(rename = "educationalPercentage")]
    pub educational_percentage: f64,
    #[serde(rename = "averageDailyUsage")]
    pub average_daily_usage: i32,
    #[serde(rename = "topCategories")]
    pub top_categories: Vec<String>,
    #[serde(rename = "completionRate")]
    pub completion_rate: f64,
    #[serde(rename = "parentalInteraction")]
    pub parental_interaction: i32,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ChildMilestones {
    pub age: i32,
    pub milestones: Vec<MilestoneItem>,
    #[serde(rename = "nextGoals")]
    pub next_goals: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct MilestoneItem {
    pub category: String,
    pub description: String,
    pub achieved: bool,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AnalyticsEventResponse {
    pub message: String,
    #[serde(rename = "eventId")]
    pub event_id: String,
    pub timestamp: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AnalyticsGameDataResponse {
    pub data: AnalyticsGameDataContainer,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AnalyticsGameDataContainer {
    #[serde(rename = "gameData")]
    pub game_data: Vec<AnalyticsGameDataItem>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AnalyticsGameDataItem {
    #[serde(rename = "dataKey")]
    pub data_key: String,
    #[serde(rename = "dataValue")]
    pub data_value: String, // JSON string
}