use std::sync::Arc;
use uuid::Uuid;
use chrono::Utc;
use serde_json::Value;
use sqlx::PgPool;

use crate::{
    models::{
        ContentSubmission, ContentTemplate, ContentGuideline, ContentValidationResult,
        CreateContentSubmissionRequest, UpdateContentSubmissionRequest, 
        ContentPreviewRequest, ContentPreviewResponse, AIAssistedCreationRequest,
        AIAssistedCreationResponse, ContentSubmissionListResponse, ContentSubmissionSummary,
        CreatorAnalyticsResponse, CreatorActivity, BigDecimal
    },
    error::{AppError, AppResult},
    db::ContentPublishingRepository,
    services::content_validation::ContentValidator,
};

#[derive(Clone)]
pub struct ContentPublishingService {
    pub db: PgPool,
    pub validator: Arc<ContentValidator>,
    pub repository: ContentPublishingRepository,
}

impl ContentPublishingService {
    pub fn new(db: PgPool) -> Self {
        let validator = Arc::new(ContentValidator::new());
        let repository = ContentPublishingRepository::new(db.clone());
        
        Self {
            db,
            validator,
            repository,
        }
    }

    // =============================================================================
    // CONTENT SUBMISSION MANAGEMENT
    // =============================================================================

    pub async fn create_content_submission(
        &self,
        creator_user_id: Uuid,
        request: CreateContentSubmissionRequest,
    ) -> AppResult<ContentSubmission> {
        tracing::info!(
            "Creating content submission '{}' for user: {}", 
            request.title, creator_user_id
        );

        // Validate request
        self.validate_create_submission_request(&request)?;

        // Check if user has creator profile or needs onboarding
        let creator_profile_id = self.repository
            .get_creator_profile_id_by_user(creator_user_id)
            .await?;

        // Prepare submission data
        let submission = ContentSubmission {
            id: Uuid::new_v4(),
            creator_user_id,
            creator_profile_id,
            title: request.title,
            description: request.description,
            content_type: Some(request.content_type),
            template_id: request.template_id,
            ai_assisted: Some(false),
            ai_generation_percentage: Some(BigDecimal::from(0)),
            original_prompt: None,
            age_range_min: request.age_range_min.unwrap_or(48), // Default to 4 years
            age_range_max: request.age_range_max.unwrap_or(72), // Default to 6 years
            difficulty_level: Some(request.difficulty_level.unwrap_or_else(|| "beginner".to_string())),
            educational_goals: Some(request.educational_goals.unwrap_or_default()),
            vocabulary_words: Some(vec![]),
            learning_objectives: Some(vec![]),
            educational_alignment: Some(serde_json::json!({})),
            content_data: request.content_data.unwrap_or_else(|| serde_json::json!({})),
            asset_urls: Some(serde_json::json!({})),
            estimated_duration_minutes: Some(10),
            status: Some("draft".to_string()),
            submission_date: None,
            automated_safety_check: Some(false),
            safety_check_results: Some(serde_json::json!({})),
            safety_check_score: Some(BigDecimal::from(0)),
            safety_issues: Some(vec![]),
            quality_score: Some(BigDecimal::from(0)),
            readability_score: Some(BigDecimal::from(0)),
            educational_value_score: Some(BigDecimal::from(0)),
            proposed_price: Some(BigDecimal::from(0)),
            licensing_model: Some("single_child".to_string()),
            marketing_description: None,
            search_keywords: Some(vec![]),
            version: Some(1),
            parent_submission_id: None,
            created_at: Some(Utc::now()),
            updated_at: Some(Utc::now()),
            last_saved_at: Some(Utc::now()),
        };

        let created_submission = self.repository.create_submission(submission).await?;

        // Update onboarding progress if this is user's first draft
        self.update_onboarding_progress(creator_user_id, "first_draft_created").await?;

        tracing::info!(
            "Created content submission {} for user {}", 
            created_submission.id, creator_user_id
        );

        Ok(created_submission)
    }

    pub async fn update_content_submission(
        &self,
        submission_id: Uuid,
        creator_user_id: Uuid,
        request: UpdateContentSubmissionRequest,
    ) -> AppResult<ContentSubmission> {
        tracing::info!(
            "Updating content submission {} for user: {}", 
            submission_id, creator_user_id
        );

        // Get existing submission and verify ownership
        let mut submission = self.repository.get_submission_by_id(submission_id).await?
            .ok_or_else(|| AppError::NotFound("Content submission not found".to_string()))?;

        if submission.creator_user_id != creator_user_id {
            return Err(AppError::Forbidden("Not authorized to update this submission".to_string()));
        }

        // Check if submission is in editable state
        if !self.is_submission_editable(&submission.status) {
            return Err(AppError::BadRequest(
                format!("Cannot edit submission in '{}' status", submission.status.as_deref().unwrap_or("unknown"))
            ));
        }

        // Update fields if provided
        if let Some(title) = request.title {
            self.validator.validate_title(&title)?;
            submission.title = title;
        }

        if let Some(description) = request.description {
            submission.description = Some(description);
        }

        if let Some(content_data) = request.content_data {
            // Validate content data structure
            let content_type = submission.content_type.as_deref().unwrap_or("story");
            self.validator.validate_content_data(&content_data, content_type)?;
            submission.content_data = content_data;
            submission.last_saved_at = Some(Utc::now());
        }

        if let Some(educational_goals) = request.educational_goals {
            submission.educational_goals = Some(educational_goals);
        }

        if let Some(vocabulary_words) = request.vocabulary_words {
            submission.vocabulary_words = Some(vocabulary_words);
        }

        if let Some(learning_objectives) = request.learning_objectives {
            submission.learning_objectives = Some(learning_objectives);
        }

        if let Some(asset_urls) = request.asset_urls {
            submission.asset_urls = Some(asset_urls);
        }

        if let Some(duration) = request.estimated_duration_minutes {
            if duration > 0 && duration <= 300 { // Max 5 hours
                submission.estimated_duration_minutes = Some(duration);
            }
        }

        if let Some(price) = request.proposed_price {
            if price >= BigDecimal::from(0) && price <= BigDecimal::from(100) {
                submission.proposed_price = Some(price);
            }
        }

        if let Some(description) = request.marketing_description {
            submission.marketing_description = Some(description);
        }

        if let Some(keywords) = request.search_keywords {
            submission.search_keywords = Some(keywords);
        }

        submission.updated_at = Some(Utc::now());

        let updated_submission = self.repository.update_submission(submission).await?;

        tracing::info!(
            "Updated content submission {} for user {}", 
            submission_id, creator_user_id
        );

        Ok(updated_submission)
    }

    pub async fn submit_for_review(
        &self,
        submission_id: Uuid,
        creator_user_id: Uuid,
    ) -> AppResult<ContentSubmission> {
        tracing::info!(
            "Submitting content {} for review by user: {}", 
            submission_id, creator_user_id
        );

        // Get submission and verify ownership
        let mut submission = self.repository.get_submission_by_id(submission_id).await?
            .ok_or_else(|| AppError::NotFound("Content submission not found".to_string()))?;

        if submission.creator_user_id != creator_user_id {
            return Err(AppError::Forbidden("Not authorized to submit this content".to_string()));
        }

        // Validate submission can be submitted
        if submission.status.as_deref() != Some("draft") {
            return Err(AppError::BadRequest(
                format!("Cannot submit content in '{}' status", submission.status.as_deref().unwrap_or("unknown"))
            ));
        }

        // Validate content completeness
        self.validate_submission_completeness(&submission)?;

        // Run automated safety and quality checks
        let validation_result = self.run_automated_validation(&submission).await?;

        // Update submission with validation results
        submission.automated_safety_check = Some(true);
        submission.safety_check_results = Some(serde_json::to_value(&validation_result)?);
        submission.safety_check_score = Some(validation_result.content_safety_score.clone());
        submission.quality_score = Some(validation_result.overall_score.clone());
        submission.status = Some("submitted_for_review".to_string());
        submission.submission_date = Some(Utc::now());
        submission.updated_at = Some(Utc::now());

        // Save validation results separately
        self.repository.save_validation_result(validation_result).await?;

        let updated_submission = self.repository.update_submission(submission).await?;

        // Update onboarding progress
        self.update_onboarding_progress(creator_user_id, "first_submission_completed").await?;

        tracing::info!(
            "Submitted content {} for review", 
            submission_id
        );

        Ok(updated_submission)
    }

    pub async fn get_creator_submissions(
        &self,
        creator_user_id: Uuid,
        page: Option<i32>,
        limit: Option<i32>,
        status_filter: Option<String>,
    ) -> AppResult<ContentSubmissionListResponse> {
        let page = page.unwrap_or(1).max(1);
        let limit = limit.unwrap_or(10).clamp(1, 50);
        let offset = (page - 1) * limit;

        let (submissions, total_count) = self.repository
            .get_submissions_by_creator(creator_user_id, offset, limit, status_filter)
            .await?;

        let submission_summaries: Vec<ContentSubmissionSummary> = submissions
            .into_iter()
            .map(|s| ContentSubmissionSummary {
                id: s.id,
                title: s.title,
                content_type: s.content_type.unwrap_or_else(|| "story".to_string()),
                status: s.status.unwrap_or_else(|| "draft".to_string()),
                created_at: s.created_at.unwrap_or_else(|| Utc::now()),
                last_updated: s.updated_at.unwrap_or_else(|| Utc::now()),
                quality_score: s.quality_score.unwrap_or_else(|| BigDecimal::from(0)),
                template_name: None, // TODO: Join with template name
                estimated_duration_minutes: s.estimated_duration_minutes.unwrap_or(10),
            })
            .collect();

        let total_pages = (total_count as f64 / limit as f64).ceil() as i32;

        // Get status counts for the creator
        let status_counts = self.repository
            .get_creator_status_counts(creator_user_id)
            .await?;

        Ok(ContentSubmissionListResponse {
            submissions: submission_summaries,
            total_count,
            page,
            total_pages,
            status_counts: serde_json::to_value(status_counts)?,
        })
    }

    pub async fn get_submission_by_id(
        &self,
        submission_id: Uuid,
        requester_user_id: Uuid,
    ) -> AppResult<ContentSubmission> {
        let submission = self.repository.get_submission_by_id(submission_id).await?
            .ok_or_else(|| AppError::NotFound("Content submission not found".to_string()))?;

        // Verify access (creator or moderator)
        if submission.creator_user_id != requester_user_id {
            // TODO: Check if user is moderator
            return Err(AppError::Forbidden("Not authorized to view this submission".to_string()));
        }

        Ok(submission)
    }

    pub async fn delete_submission(
        &self,
        submission_id: Uuid,
        creator_user_id: Uuid,
    ) -> AppResult<()> {
        tracing::info!(
            "Deleting content submission {} by user: {}", 
            submission_id, creator_user_id
        );

        let submission = self.repository.get_submission_by_id(submission_id).await?
            .ok_or_else(|| AppError::NotFound("Content submission not found".to_string()))?;

        if submission.creator_user_id != creator_user_id {
            return Err(AppError::Forbidden("Not authorized to delete this submission".to_string()));
        }

        // Only allow deletion of drafts and rejected submissions
        if !matches!(submission.status.as_deref(), Some("draft") | Some("rejected") | Some("withdrawn")) {
            return Err(AppError::BadRequest(
                "Cannot delete submission in current status".to_string()
            ));
        }

        self.repository.delete_submission(submission_id).await?;

        tracing::info!("Deleted content submission {}", submission_id);

        Ok(())
    }

    // =============================================================================
    // CONTENT TEMPLATES
    // =============================================================================

    pub async fn get_content_templates(
        &self,
        category: Option<String>,
        age_range_min: Option<i32>,
        age_range_max: Option<i32>,
    ) -> AppResult<Vec<ContentTemplate>> {
        self.repository
            .get_content_templates(category, age_range_min, age_range_max)
            .await
    }

    pub async fn get_template_by_id(&self, template_id: Uuid) -> AppResult<Option<ContentTemplate>> {
        self.repository.get_template_by_id(template_id).await
    }

    // =============================================================================
    // CONTENT GUIDELINES
    // =============================================================================

    pub async fn get_content_guidelines(
        &self,
        category: Option<String>,
        mandatory_only: Option<bool>,
    ) -> AppResult<Vec<ContentGuideline>> {
        self.repository
            .get_content_guidelines(category, mandatory_only)
            .await
    }

    // =============================================================================
    // CREATOR ANALYTICS
    // =============================================================================

    pub async fn get_creator_analytics(
        &self,
        creator_user_id: Uuid,
    ) -> AppResult<CreatorAnalyticsResponse> {
        let stats = self.repository.get_creator_stats(creator_user_id).await?;
        let recent_activities = self.repository.get_creator_recent_activities(creator_user_id).await?;

        let activities: Vec<CreatorActivity> = recent_activities
            .into_iter()
            .map(|a| CreatorActivity {
                activity_type: a.activity_type,
                submission_title: a.submission_title,
                timestamp: a.timestamp,
                details: a.details,
            })
            .collect();

        Ok(CreatorAnalyticsResponse {
            total_submissions: stats.total_submissions,
            approved_submissions: stats.approved_submissions,
            pending_submissions: stats.pending_submissions,
            rejected_submissions: stats.rejected_submissions,
            approval_rate: stats.approval_rate,
            average_quality_score: stats.average_quality_score,
            total_drafts: stats.total_drafts,
            average_creation_time_hours: stats.average_creation_time_hours,
            recent_activities: activities,
        })
    }

    // =============================================================================
    // AI INTEGRATION
    // =============================================================================

    pub async fn create_ai_assisted_content(
        &self,
        creator_user_id: Uuid,
        request: AIAssistedCreationRequest,
    ) -> AppResult<AIAssistedCreationResponse> {
        tracing::info!(
            "Creating AI-assisted content for user: {} using template: {}", 
            creator_user_id, request.template_id
        );

        // Get template
        let template = self.repository.get_template_by_id(request.template_id).await?
            .ok_or_else(|| AppError::NotFound("Template not found".to_string()))?;

        // TODO: Integrate with AI service
        // For now, return mock response
        let generated_content = serde_json::json!({
            "title": "AI Generated Story",
            "pages": [
                {
                    "page_number": 1,
                    "content": "Once upon a time, there was a wonderful adventure...",
                    "vocabulary_words": ["adventure", "wonderful"]
                }
            ]
        });

        Ok(AIAssistedCreationResponse {
            generated_content,
            suggestions: vec![],
            ai_confidence_score: BigDecimal::from(85),
            estimated_completion_percentage: BigDecimal::from(75),
            next_steps: vec![
                "Review generated content".to_string(),
                "Add educational goals".to_string(),
                "Upload images".to_string(),
            ],
        })
    }

    // =============================================================================
    // VALIDATION HELPERS
    // =============================================================================

    fn validate_create_submission_request(&self, request: &CreateContentSubmissionRequest) -> AppResult<()> {
        self.validator.validate_title(&request.title)?;

        if let Some(description) = &request.description {
            if description.len() > 1000 {
                return Err(AppError::BadRequest("Description too long (max 1000 characters)".to_string()));
            }
        }

        // Validate content type
        let valid_types = ["story", "interactive_story", "educational_activity", "learning_game"];
        if !valid_types.contains(&request.content_type.as_str()) {
            return Err(AppError::BadRequest("Invalid content type".to_string()));
        }

        // Validate age range
        if let (Some(min), Some(max)) = (request.age_range_min, request.age_range_max) {
            if min >= max || min < 24 || max > 144 { // 2-12 years old
                return Err(AppError::BadRequest("Invalid age range".to_string()));
            }
        }

        Ok(())
    }

    fn validate_submission_completeness(&self, submission: &ContentSubmission) -> AppResult<()> {
        if submission.title.trim().is_empty() {
            return Err(AppError::BadRequest("Title is required".to_string()));
        }

        if submission.content_data == serde_json::json!({}) {
            return Err(AppError::BadRequest("Content data is required".to_string()));
        }

        if submission.educational_goals.as_ref().map_or(true, |goals| goals.is_empty()) {
            return Err(AppError::BadRequest("At least one educational goal is required".to_string()));
        }

        // Validate content based on type
        if let Some(content_type) = &submission.content_type {
            match content_type.as_str() {
                "story" => self.validator.validate_story_content(&submission.content_data)?,
                "interactive_story" => self.validator.validate_interactive_story_content(&submission.content_data)?,
                "educational_activity" => self.validator.validate_educational_activity_content(&submission.content_data)?,
                _ => {}
            }
        }

        Ok(())
    }

    async fn run_automated_validation(
        &self,
        submission: &ContentSubmission,
    ) -> AppResult<ContentValidationResult> {
        tracing::info!("Running automated validation for submission: {}", submission.id);

        // TODO: Implement actual content validation
        // This would include:
        // - Language appropriateness checking
        // - Content safety analysis
        // - Readability analysis
        // - Educational value assessment
        // - COPPA compliance checking

        Ok(ContentValidationResult {
            id: Uuid::new_v4(),
            submission_id: submission.id,
            validation_version: "1.0".to_string(),
            validation_timestamp: Utc::now(),
            language_appropriateness_score: BigDecimal::from(95),
            content_safety_score: BigDecimal::from(98),
            age_appropriateness_score: BigDecimal::from(90),
            readability_score: BigDecimal::from(88),
            grammar_score: BigDecimal::from(92),
            educational_value_score: BigDecimal::from(85),
            flagged_words: vec![],
            safety_issues: serde_json::json!({}),
            quality_issues: serde_json::json!({}),
            suggestions: serde_json::json!({}),
            overall_score: BigDecimal::from(90),
            passed_automated_checks: true,
            requires_human_review: true,
            processing_time_ms: 250,
            validation_errors: vec![],
        })
    }

    fn is_submission_editable(&self, status: &Option<String>) -> bool {
        matches!(status.as_deref(), Some("draft") | Some("pending_changes"))
    }

    async fn update_onboarding_progress(
        &self,
        user_id: Uuid,
        milestone: &str,
    ) -> AppResult<()> {
        // TODO: Implement onboarding progress tracking
        tracing::info!("Updating onboarding progress for user {}: {}", user_id, milestone);
        Ok(())
    }
}