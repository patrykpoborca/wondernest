use std::sync::Arc;
use uuid::Uuid;
use chrono::Utc;
use sqlx::PgPool;

use crate::{
    models::{
        ContentModerationQueue, ContentModerationDecision, ContentSubmission,
        ModerationQueueRequest, ModerationQueueResponse, ModerationQueueItem,
        ModerationQueueSummary, ModerationDecisionRequest, BigDecimal
    },
    error::{AppError, AppResult},
    db::ContentPublishingRepository,
};

#[derive(Clone)]
pub struct ContentModerationService {
    pub db: PgPool,
    pub repository: ContentPublishingRepository,
}

impl ContentModerationService {
    pub fn new(db: PgPool) -> Self {
        let repository = ContentPublishingRepository::new(db.clone());
        
        Self {
            db,
            repository,
        }
    }

    // =============================================================================
    // MODERATION QUEUE MANAGEMENT
    // =============================================================================

    pub async fn get_moderation_queue(
        &self,
        request: ModerationQueueRequest,
    ) -> AppResult<ModerationQueueResponse> {
        tracing::info!("Fetching moderation queue with filters: {:?}", request);

        let page = request.page.unwrap_or(1).max(1);
        let limit = request.limit.unwrap_or(20).clamp(1, 100);
        let offset = (page - 1) * limit;

        let (queue_items, total_count) = self.get_queue_items_with_filters(&request, offset, limit).await?;
        let summary = self.get_queue_summary().await?;

        let total_pages = (total_count as f64 / limit as f64).ceil() as i32;

        Ok(ModerationQueueResponse {
            queue_items,
            total_count,
            page,
            total_pages,
            summary,
        })
    }

    pub async fn assign_moderator(
        &self,
        queue_id: Uuid,
        moderator_id: Uuid,
    ) -> AppResult<ContentModerationQueue> {
        tracing::info!("Assigning moderator {} to queue item {}", moderator_id, queue_id);

        let queue_item = self.get_queue_item_by_id(queue_id).await?
            .ok_or_else(|| AppError::NotFound("Moderation queue item not found".to_string()))?;

        if queue_item.assigned_moderator_id.is_some() {
            return Err(AppError::BadRequest("Queue item already assigned".to_string()));
        }

        let updated_item = sqlx::query_as!(
            ContentModerationQueue,
            r#"
            UPDATE games.content_moderation_queue
            SET assigned_moderator_id = $2,
                status = 'assigned',
                review_started_at = $3,
                updated_at = $3
            WHERE id = $1
            RETURNING *
            "#,
            queue_id,
            moderator_id,
            Utc::now()
        )
        .fetch_one(&self.db)
        .await
        .map_err(|e| {
            tracing::error!("Failed to assign moderator: {}", e);
            AppError::DatabaseError(e)
        })?;

        tracing::info!("Successfully assigned moderator {} to queue item {}", moderator_id, queue_id);

        Ok(updated_item)
    }

    pub async fn start_review(
        &self,
        queue_id: Uuid,
        moderator_id: Uuid,
    ) -> AppResult<ContentModerationQueue> {
        tracing::info!("Starting review for queue item {} by moderator {}", queue_id, moderator_id);

        let queue_item = self.get_queue_item_by_id(queue_id).await?
            .ok_or_else(|| AppError::NotFound("Moderation queue item not found".to_string()))?;

        // Verify moderator is assigned to this item
        if queue_item.assigned_moderator_id != Some(moderator_id) {
            return Err(AppError::Forbidden("Not authorized to review this item".to_string()));
        }

        if queue_item.status.as_deref() == Some("in_review") {
            return Err(AppError::BadRequest("Review already in progress".to_string()));
        }

        let now = Utc::now();
        let estimated_completion = now + chrono::Duration::hours(2); // Default 2-hour estimate

        let updated_item = sqlx::query_as!(
            ContentModerationQueue,
            r#"
            UPDATE games.content_moderation_queue
            SET status = 'in_review',
                review_started_at = $2,
                estimated_completion_time = $3,
                updated_at = $2
            WHERE id = $1
            RETURNING *
            "#,
            queue_id,
            now,
            estimated_completion
        )
        .fetch_one(&self.db)
        .await
        .map_err(|e| {
            tracing::error!("Failed to start review: {}", e);
            AppError::DatabaseError(e)
        })?;

        tracing::info!("Successfully started review for queue item {}", queue_id);

        Ok(updated_item)
    }

    // =============================================================================
    // MODERATION DECISIONS
    // =============================================================================

    pub async fn submit_moderation_decision(
        &self,
        submission_id: Uuid,
        moderator_id: Uuid,
        request: ModerationDecisionRequest,
    ) -> AppResult<ContentModerationDecision> {
        tracing::info!(
            "Submitting moderation decision '{}' for submission {} by moderator {}", 
            request.decision, submission_id, moderator_id
        );

        // Validate decision
        self.validate_moderation_decision(&request)?;

        // Get submission and queue item
        let submission = self.repository.get_submission_by_id(submission_id).await?
            .ok_or_else(|| AppError::NotFound("Content submission not found".to_string()))?;

        let queue_item = self.get_queue_item_by_submission_id(submission_id).await?;

        // Verify moderator authorization
        if let Some(queue) = &queue_item {
            if queue.assigned_moderator_id != Some(moderator_id) {
                return Err(AppError::Forbidden("Not authorized to moderate this submission".to_string()));
            }
        }

        // Create moderation decision
        let decision = ContentModerationDecision {
            id: Uuid::new_v4(),
            submission_id,
            queue_item_id: queue_item.as_ref().map(|q| q.id),
            moderator_id,
            moderator_level: "senior".to_string(), // TODO: Get from user profile
            decision: request.decision.clone(),
            overall_rating: request.overall_rating.clone(),
            content_quality_rating: request.content_quality_rating.clone(),
            educational_value_rating: request.educational_value_rating.clone(),
            safety_rating: request.safety_rating.clone(),
            age_appropriateness_rating: request.age_appropriateness_rating.clone(),
            public_feedback: request.public_feedback.clone(),
            private_notes: request.private_notes.clone(),
            suggested_changes: request.suggested_changes.clone(),
            flagged_issues: request.flagged_issues.clone(),
            guidelines_violations: request.guidelines_violations.clone(),
            safety_concerns: request.safety_concerns.clone(),
            requires_creator_action: request.requires_creator_action,
            auto_resubmit: Some(false), // TODO: Determine based on decision type
            created_at: Some(Utc::now()),
        };

        // Save decision
        let saved_decision = self.save_moderation_decision(decision).await?;

        // Update submission status based on decision
        self.update_submission_status_from_decision(&submission, &request).await?;

        // Update queue status
        if let Some(queue) = queue_item {
            self.complete_queue_item(queue.id).await?;
        }

        tracing::info!(
            "Successfully submitted moderation decision for submission {}", 
            submission_id
        );

        Ok(saved_decision)
    }

    pub async fn escalate_submission(
        &self,
        submission_id: Uuid,
        moderator_id: Uuid,
        escalation_reason: String,
    ) -> AppResult<()> {
        tracing::info!("Escalating submission {} by moderator {}", submission_id, moderator_id);

        // Get queue item
        let queue_item = self.get_queue_item_by_submission_id(submission_id).await?
            .ok_or_else(|| AppError::NotFound("Queue item not found".to_string()))?;

        // Verify moderator authorization
        if queue_item.assigned_moderator_id != Some(moderator_id) {
            return Err(AppError::Forbidden("Not authorized to escalate this submission".to_string()));
        }

        // Update queue item
        sqlx::query!(
            r#"
            UPDATE games.content_moderation_queue
            SET status = 'escalated',
                escalated = true,
                escalation_reason = $2,
                assigned_moderator_id = NULL,
                priority_level = 'high',
                updated_at = $3
            WHERE id = $1
            "#,
            queue_item.id,
            escalation_reason,
            Utc::now()
        )
        .execute(&self.db)
        .await
        .map_err(|e| {
            tracing::error!("Failed to escalate submission: {}", e);
            AppError::DatabaseError(e)
        })?;

        tracing::info!("Successfully escalated submission {}", submission_id);

        Ok(())
    }

    // =============================================================================
    // QUEUE ANALYTICS
    // =============================================================================

    pub async fn get_moderator_workload(&self, moderator_id: Uuid) -> AppResult<ModeratorWorkload> {
        let workload = sqlx::query!(
            r#"
            SELECT 
                COUNT(*) FILTER (WHERE status = 'assigned') as assigned_items,
                COUNT(*) FILTER (WHERE status = 'in_review') as in_review_items,
                COUNT(*) FILTER (WHERE status = 'completed') as completed_today,
                AVG(review_duration_minutes) FILTER (WHERE status = 'completed' AND actual_completion_time >= CURRENT_DATE) as avg_review_time
            FROM games.content_moderation_queue
            WHERE assigned_moderator_id = $1
            "#,
            moderator_id
        )
        .fetch_one(&self.db)
        .await
        .map_err(|e| {
            tracing::error!("Failed to get moderator workload: {}", e);
            AppError::DatabaseError(e)
        })?;

        Ok(ModeratorWorkload {
            assigned_items: workload.assigned_items.unwrap_or(0) as i32,
            in_review_items: workload.in_review_items.unwrap_or(0) as i32,
            completed_today: workload.completed_today.unwrap_or(0) as i32,
            average_review_time_minutes: workload.avg_review_time.map(|t| BigDecimal::try_from(t).unwrap_or_default()).unwrap_or_default(),
        })
    }

    // =============================================================================
    // PRIVATE HELPER METHODS
    // =============================================================================

    async fn get_queue_items_with_filters(
        &self,
        request: &ModerationQueueRequest,
        offset: i32,
        limit: i32,
    ) -> AppResult<(Vec<ModerationQueueItem>, i64)> {
        // This is a simplified version - in practice, you'd build dynamic queries based on filters
        let items = sqlx::query!(
            r#"
            SELECT 
                q.id as queue_id,
                s.id as submission_id,
                s.title as submission_title,
                u.first_name || ' ' || u.last_name as creator_name,
                s.content_type,
                q.priority_level,
                q.status,
                EXTRACT(EPOCH FROM (NOW() - q.created_at))/3600 as time_in_queue_hours,
                COALESCE(s.safety_check_score, 0) as safety_check_score,
                s.safety_issues
            FROM games.content_moderation_queue q
            JOIN games.content_submissions s ON q.submission_id = s.id
            JOIN core.users u ON s.creator_user_id = u.id
            WHERE ($1::text IS NULL OR q.status = $1)
            AND ($2::text IS NULL OR q.priority_level = $2)
            AND ($3::boolean IS NULL OR ($3 = true AND q.assigned_moderator_id = $4) OR ($3 = false))
            ORDER BY 
                CASE q.priority_level 
                    WHEN 'urgent' THEN 1
                    WHEN 'high' THEN 2
                    WHEN 'normal' THEN 3
                    ELSE 4
                END,
                q.created_at ASC
            LIMIT $5 OFFSET $6
            "#,
            request.status.as_deref(),
            request.priority.as_deref(),
            request.assigned_to_me,
            request.assigned_to_me.map(|_| Uuid::nil()), // TODO: Pass actual moderator ID
            limit as i64,
            offset as i64
        )
        .fetch_all(&self.db)
        .await
        .map_err(|e| {
            tracing::error!("Failed to get queue items: {}", e);
            AppError::DatabaseError(e)
        })?;

        let queue_items: Vec<ModerationQueueItem> = items
            .into_iter()
            .map(|row| ModerationQueueItem {
                queue_id: row.queue_id,
                submission_id: row.submission_id,
                submission_title: row.submission_title,
                creator_name: row.creator_name.unwrap_or_else(|| "Unknown".to_string()),
                content_type: row.content_type.unwrap_or_else(|| "story".to_string()),
                priority_level: row.priority_level.unwrap_or_else(|| "normal".to_string()),
                status: row.status.unwrap_or_else(|| "pending_assignment".to_string()),
                time_in_queue_hours: row.time_in_queue_hours
                    .map(|bd| bd.to_string().parse::<f64>().unwrap_or(0.0))
                    .unwrap_or(0.0),
                estimated_review_time_minutes: 60, // Default estimate
                safety_check_score: row.safety_check_score.unwrap_or_default(),
                automated_flags: row.safety_issues.unwrap_or_default(),
            })
            .collect();

        // Get total count (simplified)
        let total_count = sqlx::query_scalar!(
            "SELECT COUNT(*) FROM games.content_moderation_queue"
        )
        .fetch_one(&self.db)
        .await
        .map_err(|e| {
            tracing::error!("Failed to count queue items: {}", e);
            AppError::DatabaseError(e)
        })?
        .unwrap_or(0);

        Ok((queue_items, total_count))
    }

    async fn get_queue_summary(&self) -> AppResult<ModerationQueueSummary> {
        let summary = sqlx::query!(
            r#"
            SELECT 
                COUNT(*) FILTER (WHERE status = 'pending_assignment') as pending_assignment,
                COUNT(*) FILTER (WHERE status = 'in_review') as in_review,
                COUNT(*) FILTER (WHERE status = 'pending_decision') as pending_decision,
                COUNT(*) FILTER (WHERE priority_level = 'high') as high_priority_count,
                AVG(time_in_queue_minutes) FILTER (WHERE status != 'completed')/60.0 as avg_queue_time_hours
            FROM games.content_moderation_queue
            WHERE status != 'completed'
            "#
        )
        .fetch_one(&self.db)
        .await
        .map_err(|e| {
            tracing::error!("Failed to get queue summary: {}", e);
            AppError::DatabaseError(e)
        })?;

        Ok(ModerationQueueSummary {
            pending_assignment: summary.pending_assignment.unwrap_or(0),
            in_review: summary.in_review.unwrap_or(0),
            pending_decision: summary.pending_decision.unwrap_or(0),
            average_queue_time_hours: summary.avg_queue_time_hours
                .map(|bd| bd.to_string().parse::<f64>().unwrap_or(0.0))
                .unwrap_or(0.0),
            high_priority_count: summary.high_priority_count.unwrap_or(0),
        })
    }

    async fn get_queue_item_by_id(&self, queue_id: Uuid) -> AppResult<Option<ContentModerationQueue>> {
        let item = sqlx::query_as!(
            ContentModerationQueue,
            "SELECT * FROM games.content_moderation_queue WHERE id = $1",
            queue_id
        )
        .fetch_optional(&self.db)
        .await
        .map_err(|e| {
            tracing::error!("Failed to get queue item: {}", e);
            AppError::DatabaseError(e)
        })?;

        Ok(item)
    }

    async fn get_queue_item_by_submission_id(&self, submission_id: Uuid) -> AppResult<Option<ContentModerationQueue>> {
        let item = sqlx::query_as!(
            ContentModerationQueue,
            "SELECT * FROM games.content_moderation_queue WHERE submission_id = $1",
            submission_id
        )
        .fetch_optional(&self.db)
        .await
        .map_err(|e| {
            tracing::error!("Failed to get queue item by submission: {}", e);
            AppError::DatabaseError(e)
        })?;

        Ok(item)
    }

    async fn save_moderation_decision(&self, decision: ContentModerationDecision) -> AppResult<ContentModerationDecision> {
        let saved_decision = sqlx::query_as!(
            ContentModerationDecision,
            r#"
            INSERT INTO games.content_moderation_decisions (
                id, submission_id, queue_item_id, moderator_id, moderator_level, decision,
                overall_rating, content_quality_rating, educational_value_rating,
                safety_rating, age_appropriateness_rating, public_feedback, private_notes,
                suggested_changes, flagged_issues, guidelines_violations, safety_concerns,
                requires_creator_action, auto_resubmit, created_at
            ) VALUES (
                $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20
            ) RETURNING *
            "#,
            decision.id,
            decision.submission_id,
            decision.queue_item_id,
            decision.moderator_id,
            decision.moderator_level,
            decision.decision,
            decision.overall_rating,
            decision.content_quality_rating,
            decision.educational_value_rating,
            decision.safety_rating,
            decision.age_appropriateness_rating,
            decision.public_feedback,
            decision.private_notes,
            decision.suggested_changes,
            decision.flagged_issues.as_ref().map(|v| v.as_slice()),
            decision.guidelines_violations.as_ref(),
            decision.safety_concerns.as_ref().map(|v| v.as_slice()),
            decision.requires_creator_action,
            decision.auto_resubmit,
            decision.created_at
        )
        .fetch_one(&self.db)
        .await
        .map_err(|e| {
            tracing::error!("Failed to save moderation decision: {}", e);
            AppError::DatabaseError(e)
        })?;

        Ok(saved_decision)
    }

    async fn update_submission_status_from_decision(
        &self,
        submission: &ContentSubmission,
        request: &ModerationDecisionRequest,
    ) -> AppResult<()> {
        let new_status = match request.decision.as_str() {
            "approved" => "approved",
            "rejected" => "rejected",
            "request_changes" => "pending_changes",
            "escalate" => "under_review",
            _ => return Err(AppError::BadRequest("Invalid moderation decision".to_string())),
        };

        sqlx::query!(
            "UPDATE games.content_submissions SET status = $2, updated_at = $3 WHERE id = $1",
            submission.id,
            new_status,
            Utc::now()
        )
        .execute(&self.db)
        .await
        .map_err(|e| {
            tracing::error!("Failed to update submission status: {}", e);
            AppError::DatabaseError(e)
        })?;

        Ok(())
    }

    async fn complete_queue_item(&self, queue_id: Uuid) -> AppResult<()> {
        let now = Utc::now();

        sqlx::query!(
            r#"
            UPDATE games.content_moderation_queue
            SET status = 'completed',
                actual_completion_time = $2,
                review_duration_minutes = EXTRACT(EPOCH FROM ($2 - review_started_at))/60,
                updated_at = $2
            WHERE id = $1
            "#,
            queue_id,
            now
        )
        .execute(&self.db)
        .await
        .map_err(|e| {
            tracing::error!("Failed to complete queue item: {}", e);
            AppError::DatabaseError(e)
        })?;

        Ok(())
    }

    fn validate_moderation_decision(&self, request: &ModerationDecisionRequest) -> AppResult<()> {
        let valid_decisions = ["approved", "rejected", "request_changes", "escalate"];
        if !valid_decisions.contains(&request.decision.as_str()) {
            return Err(AppError::BadRequest("Invalid moderation decision".to_string()));
        }

        // Validate ratings if provided
        if let Some(rating) = &request.overall_rating {
            if *rating < BigDecimal::from(0) || *rating > BigDecimal::from(5) {
                return Err(AppError::BadRequest("Overall rating must be between 0 and 5".to_string()));
            }
        }

        // Require feedback for rejections
        if request.decision == "rejected" && request.public_feedback.is_none() {
            return Err(AppError::BadRequest("Public feedback is required for rejections".to_string()));
        }

        // Require escalation reason for escalations
        if request.decision == "escalate" && request.private_notes.is_none() {
            return Err(AppError::BadRequest("Private notes required for escalations".to_string()));
        }

        Ok(())
    }
}

// =============================================================================
// HELPER TYPES
// =============================================================================

#[derive(Debug, Clone, serde::Serialize)]
pub struct ModeratorWorkload {
    pub assigned_items: i32,
    pub in_review_items: i32,
    pub completed_today: i32,
    pub average_review_time_minutes: BigDecimal,
}