use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

// Use BigDecimal directly from the bigdecimal crate for serde support
pub use bigdecimal::BigDecimal;

// =============================================================================
// CONTENT TEMPLATES
// =============================================================================

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ContentTemplate {
    pub id: Uuid,
    
    // Template identification
    pub name: String,
    pub description: String,
    pub category: String, // 'story', 'educational_activity', 'interactive_book', 'learning_game'
    
    // Target demographics and difficulty
    pub age_range_min: i32,
    pub age_range_max: i32,
    pub difficulty_level: Option<String>,
    
    // Template structure
    pub prompt_template: String,
    pub structure_guidelines: Option<serde_json::Value>,
    pub required_fields: Option<serde_json::Value>,
    pub optional_fields: Option<serde_json::Value>,
    
    // Educational alignment
    pub educational_goals: Option<Vec<String>>,
    pub vocabulary_focus: Option<Vec<String>>,
    pub learning_outcomes: Option<Vec<String>>,
    
    // Media and preview
    pub preview_image_url: Option<String>,
    pub example_content: Option<serde_json::Value>,
    
    // Usage and metrics
    pub usage_count: Option<i32>,
    pub average_rating: Option<BigDecimal>,
    pub rating_count: Option<i32>,
    
    // Template status
    pub active: Option<bool>,
    pub featured: Option<bool>,
    pub featured_until: Option<DateTime<Utc>>,
    
    // Creation
    pub created_by: Option<Uuid>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ContentGuideline {
    pub id: Uuid,
    
    // Guideline identification
    pub title: String,
    pub category: String, // 'content_policy', 'quality_standards', 'safety_requirements', etc.
    
    // Content
    pub description: String,
    pub detailed_guidelines: String,
    pub examples: Option<serde_json::Value>,
    
    // Applicability
    pub applies_to_content_types: Option<Vec<String>>,
    pub applies_to_age_ranges: Option<serde_json::Value>,
    
    // Policy status
    pub active: Option<bool>,
    pub mandatory: Option<bool>,
    
    // Version control
    pub version: Option<String>,
    pub supersedes: Option<Uuid>,
    
    // Creation
    pub created_by: Option<Uuid>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
}

// =============================================================================
// CONTENT SUBMISSIONS
// =============================================================================

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ContentSubmission {
    pub id: Uuid,
    
    // Creator information
    pub creator_user_id: Uuid,
    pub creator_profile_id: Option<Uuid>,
    
    // Content identification and metadata
    pub title: String,
    pub description: Option<String>,
    pub content_type: Option<String>,
    
    // Template and AI assistance tracking
    pub template_id: Option<Uuid>,
    pub ai_assisted: Option<bool>,
    pub ai_generation_percentage: Option<BigDecimal>,
    pub original_prompt: Option<String>,
    
    // Target audience
    pub age_range_min: i32,
    pub age_range_max: i32,
    pub difficulty_level: Option<String>,
    
    // Educational content
    pub educational_goals: Option<Vec<String>>,
    pub vocabulary_words: Option<Vec<String>>,
    pub learning_objectives: Option<Vec<String>>,
    pub educational_alignment: Option<serde_json::Value>,
    
    // Content structure and data
    pub content_data: serde_json::Value,
    pub asset_urls: Option<serde_json::Value>,
    pub estimated_duration_minutes: Option<i32>,
    
    // Submission workflow status
    pub status: Option<String>,
    pub submission_date: Option<DateTime<Utc>>,
    
    // Content validation and safety
    pub automated_safety_check: Option<bool>,
    pub safety_check_results: Option<serde_json::Value>,
    pub safety_check_score: Option<BigDecimal>,
    pub safety_issues: Option<Vec<String>>,
    
    // Quality assessment
    pub quality_score: Option<BigDecimal>,
    pub readability_score: Option<BigDecimal>,
    pub educational_value_score: Option<BigDecimal>,
    
    // Marketplace preparation
    pub proposed_price: Option<BigDecimal>,
    pub licensing_model: Option<String>,
    pub marketing_description: Option<String>,
    pub search_keywords: Option<Vec<String>>,
    
    // Version control
    pub version: Option<i32>,
    pub parent_submission_id: Option<Uuid>,
    
    // Timestamps
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
    pub last_saved_at: Option<DateTime<Utc>>,
}

// =============================================================================
// CONTENT MODERATION
// =============================================================================

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ContentModerationQueue {
    pub id: Uuid,
    pub submission_id: Uuid,
    
    // Assignment and priority
    pub assigned_moderator_id: Option<Uuid>,
    pub priority_level: Option<String>,
    
    // Moderation workflow status
    pub status: Option<String>,
    
    // Review process tracking
    pub review_started_at: Option<DateTime<Utc>>,
    pub estimated_completion_time: Option<DateTime<Utc>>,
    pub actual_completion_time: Option<DateTime<Utc>>,
    
    // Escalation and special handling
    pub escalated: Option<bool>,
    pub escalation_reason: Option<String>,
    pub special_instructions: Option<String>,
    
    // Metrics
    pub time_in_queue_minutes: Option<i32>,
    pub review_duration_minutes: Option<i32>,
    
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ContentModerationDecision {
    pub id: Uuid,
    pub submission_id: Uuid,
    pub queue_item_id: Option<Uuid>,
    
    // Moderator information
    pub moderator_id: Uuid,
    pub moderator_level: String,
    
    // Decision
    pub decision: String,
    
    // Detailed feedback
    pub overall_rating: Option<BigDecimal>,
    pub content_quality_rating: Option<BigDecimal>,
    pub educational_value_rating: Option<BigDecimal>,
    pub safety_rating: Option<BigDecimal>,
    pub age_appropriateness_rating: Option<BigDecimal>,
    
    // Feedback and suggestions
    pub public_feedback: Option<String>,
    pub private_notes: Option<String>,
    pub suggested_changes: Option<String>,
    pub flagged_issues: Option<Vec<String>>,
    
    // Guidelines compliance
    pub guidelines_violations: Option<serde_json::Value>,
    pub safety_concerns: Option<Vec<String>>,
    
    // Processing
    pub requires_creator_action: Option<bool>,
    pub auto_resubmit: Option<bool>,
    
    pub created_at: Option<DateTime<Utc>>,
}

// =============================================================================
// CONTENT VALIDATION
// =============================================================================

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ContentValidationResult {
    pub id: Uuid,
    pub submission_id: Uuid,
    
    // Validation metadata
    pub validation_version: String,
    pub validation_timestamp: DateTime<Utc>,
    
    // Safety checks
    pub language_appropriateness_score: BigDecimal,
    pub content_safety_score: BigDecimal,
    pub age_appropriateness_score: BigDecimal,
    
    // Content quality analysis
    pub readability_score: BigDecimal,
    pub grammar_score: BigDecimal,
    pub educational_value_score: BigDecimal,
    
    // Detailed results
    pub flagged_words: Vec<String>,
    pub safety_issues: serde_json::Value,
    pub quality_issues: serde_json::Value,
    pub suggestions: serde_json::Value,
    
    // Overall assessment
    pub overall_score: BigDecimal,
    pub passed_automated_checks: bool,
    pub requires_human_review: bool,
    
    // Processing details
    pub processing_time_ms: i32,
    pub validation_errors: Vec<String>,
}

// =============================================================================
// CREATOR ONBOARDING
// =============================================================================

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct CreatorOnboardingProgress {
    pub id: Uuid,
    pub user_id: Uuid,
    
    // Onboarding steps completion
    pub guidelines_read: bool,
    pub guidelines_read_at: Option<DateTime<Utc>>,
    
    pub policy_accepted: bool,
    pub policy_accepted_at: Option<DateTime<Utc>>,
    pub policy_version: Option<String>,
    
    pub template_tutorial_completed: bool,
    pub template_tutorial_completed_at: Option<DateTime<Utc>>,
    
    pub first_draft_created: bool,
    pub first_draft_created_at: Option<DateTime<Utc>>,
    
    pub first_submission_completed: bool,
    pub first_submission_completed_at: Option<DateTime<Utc>>,
    
    // Progress tracking
    pub onboarding_status: String,
    pub completion_percentage: BigDecimal,
    
    // Support and assistance
    pub needs_help: bool,
    pub help_requested_topics: Vec<String>,
    pub assigned_mentor_id: Option<Uuid>,
    
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// =============================================================================
// REQUEST/RESPONSE DTOs
// =============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateContentSubmissionRequest {
    pub title: String,
    pub description: Option<String>,
    pub content_type: String,
    pub template_id: Option<Uuid>,
    pub age_range_min: Option<i32>,
    pub age_range_max: Option<i32>,
    pub difficulty_level: Option<String>,
    pub educational_goals: Option<Vec<String>>,
    pub content_data: Option<serde_json::Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateContentSubmissionRequest {
    pub title: Option<String>,
    pub description: Option<String>,
    pub content_data: Option<serde_json::Value>,
    pub educational_goals: Option<Vec<String>>,
    pub vocabulary_words: Option<Vec<String>>,
    pub learning_objectives: Option<Vec<String>>,
    pub asset_urls: Option<serde_json::Value>,
    pub estimated_duration_minutes: Option<i32>,
    pub proposed_price: Option<BigDecimal>,
    pub marketing_description: Option<String>,
    pub search_keywords: Option<Vec<String>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SubmitForReviewRequest {
    pub submission_id: Uuid,
    pub final_check_completed: bool,
    pub creator_notes: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentPreviewRequest {
    pub submission_id: Uuid,
    pub preview_mode: String, // 'child_view', 'parent_view', 'full_content'
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentPreviewResponse {
    pub submission_id: Uuid,
    pub preview_html: String,
    pub preview_data: serde_json::Value,
    pub estimated_reading_time: i32,
    pub preview_assets: Vec<PreviewAsset>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PreviewAsset {
    pub asset_type: String, // 'image', 'audio', 'video'
    pub asset_url: String,
    pub alt_text: Option<String>,
    pub description: Option<String>,
}

// =============================================================================
// MODERATION DTOs
// =============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModerationQueueRequest {
    pub status: Option<String>,
    pub priority: Option<String>,
    pub assigned_to_me: Option<bool>,
    pub content_type: Option<String>,
    pub age_range_min: Option<i32>,
    pub age_range_max: Option<i32>,
    pub page: Option<i32>,
    pub limit: Option<i32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModerationQueueResponse {
    pub queue_items: Vec<ModerationQueueItem>,
    pub total_count: i64,
    pub page: i32,
    pub total_pages: i32,
    pub summary: ModerationQueueSummary,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModerationQueueItem {
    pub queue_id: Uuid,
    pub submission_id: Uuid,
    pub submission_title: String,
    pub creator_name: String,
    pub content_type: String,
    pub priority_level: String,
    pub status: String,
    pub time_in_queue_hours: f64,
    pub estimated_review_time_minutes: i32,
    pub safety_check_score: BigDecimal,
    pub automated_flags: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModerationQueueSummary {
    pub pending_assignment: i64,
    pub in_review: i64,
    pub pending_decision: i64,
    pub average_queue_time_hours: f64,
    pub high_priority_count: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModerationDecisionRequest {
    pub decision: String, // 'approved', 'rejected', 'request_changes', 'escalate'
    pub overall_rating: Option<BigDecimal>,
    pub content_quality_rating: Option<BigDecimal>,
    pub educational_value_rating: Option<BigDecimal>,
    pub safety_rating: Option<BigDecimal>,
    pub age_appropriateness_rating: Option<BigDecimal>,
    pub public_feedback: Option<String>,
    pub private_notes: Option<String>,
    pub suggested_changes: Option<String>,
    pub flagged_issues: Option<Vec<String>>,
    pub guidelines_violations: Option<serde_json::Value>,
    pub safety_concerns: Option<Vec<String>>,
    pub requires_creator_action: Option<bool>,
}

// =============================================================================
// TEMPLATE AND GUIDELINES DTOs
// =============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentTemplateListResponse {
    pub templates: Vec<ContentTemplateResponse>,
    pub featured_templates: Vec<ContentTemplateResponse>,
    pub categories: Vec<TemplateCategory>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentTemplateResponse {
    pub id: Uuid,
    pub name: String,
    pub description: String,
    pub category: String,
    pub age_range: String,
    pub difficulty_level: String,
    pub educational_goals: Vec<String>,
    pub usage_count: i32,
    pub average_rating: BigDecimal,
    pub preview_image_url: Option<String>,
    pub estimated_creation_time: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TemplateCategory {
    pub category: String,
    pub display_name: String,
    pub description: String,
    pub template_count: i32,
    pub icon: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentGuidelinesResponse {
    pub guidelines: Vec<ContentGuidelineResponse>,
    pub mandatory_count: i32,
    pub last_updated: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentGuidelineResponse {
    pub id: Uuid,
    pub title: String,
    pub category: String,
    pub description: String,
    pub mandatory: bool,
    pub applies_to: Vec<String>,
    pub examples: serde_json::Value,
}

// =============================================================================
// ANALYTICS DTOs
// =============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreatorAnalyticsResponse {
    pub total_submissions: i32,
    pub approved_submissions: i32,
    pub pending_submissions: i32,
    pub rejected_submissions: i32,
    pub approval_rate: BigDecimal,
    pub average_quality_score: BigDecimal,
    pub total_drafts: i32,
    pub average_creation_time_hours: BigDecimal,
    pub recent_activities: Vec<CreatorActivity>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreatorActivity {
    pub activity_type: String, // 'draft_created', 'submitted_for_review', 'approved', 'rejected'
    pub submission_title: String,
    pub timestamp: DateTime<Utc>,
    pub details: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentSubmissionListResponse {
    pub submissions: Vec<ContentSubmissionSummary>,
    pub total_count: i64,
    pub page: i32,
    pub total_pages: i32,
    pub status_counts: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentSubmissionSummary {
    pub id: Uuid,
    pub title: String,
    pub content_type: String,
    pub status: String,
    pub created_at: DateTime<Utc>,
    pub last_updated: DateTime<Utc>,
    pub quality_score: BigDecimal,
    pub template_name: Option<String>,
    pub estimated_duration_minutes: i32,
}

// =============================================================================
// AI INTEGRATION DTOs
// =============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AIAssistedCreationRequest {
    pub template_id: Uuid,
    pub user_inputs: serde_json::Value, // Filled template placeholders
    pub enhancement_preferences: Option<serde_json::Value>,
    pub target_length: Option<String>, // 'short', 'medium', 'long'
    pub include_images: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AIAssistedCreationResponse {
    pub generated_content: serde_json::Value,
    pub suggestions: Vec<ContentSuggestion>,
    pub ai_confidence_score: BigDecimal,
    pub estimated_completion_percentage: BigDecimal,
    pub next_steps: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentSuggestion {
    pub suggestion_type: String, // 'improvement', 'addition', 'enhancement'
    pub target_section: String,
    pub suggestion_text: String,
    pub reasoning: String,
    pub educational_value: Option<String>,
    pub confidence_score: BigDecimal,
}