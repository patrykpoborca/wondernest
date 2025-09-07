use sqlx::{PgPool, Row, postgres::PgRow};
use uuid::Uuid;
use chrono::{DateTime, Utc};
use serde_json::Value;
use std::collections::HashMap;

use crate::{
    models::{
        ContentSubmission, ContentTemplate, ContentGuideline, ContentValidationResult,
        ContentModerationQueue, ContentModerationDecision, CreatorOnboardingProgress,
        BigDecimal
    },
    error::{AppError, AppResult},
};

#[derive(Debug, Clone)]
pub struct ContentPublishingRepository {
    pub db: PgPool,
}

impl ContentPublishingRepository {
    pub fn new(db: PgPool) -> Self {
        Self { db }
    }

    // =============================================================================
    // CONTENT SUBMISSIONS
    // =============================================================================

    pub async fn create_submission(&self, submission: ContentSubmission) -> AppResult<ContentSubmission> {
        let row = sqlx::query_as!(
            ContentSubmission,
            r#"
            INSERT INTO games.content_submissions (
                id, creator_user_id, creator_profile_id, title, description, content_type,
                template_id, ai_assisted, ai_generation_percentage, original_prompt,
                age_range_min, age_range_max, difficulty_level, educational_goals, 
                vocabulary_words, learning_objectives, educational_alignment,
                content_data, asset_urls, estimated_duration_minutes, status,
                submission_date, automated_safety_check, safety_check_results,
                safety_check_score, safety_issues, quality_score, readability_score,
                educational_value_score, proposed_price, licensing_model,
                marketing_description, search_keywords, version, parent_submission_id,
                created_at, updated_at, last_saved_at
            ) VALUES (
                $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17,
                $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32,
                $33, $34, $35, $36, $37, $38
            ) RETURNING *
            "#,
            submission.id,
            submission.creator_user_id,
            submission.creator_profile_id,
            submission.title,
            submission.description,
            submission.content_type,
            submission.template_id,
            submission.ai_assisted,
            submission.ai_generation_percentage,
            submission.original_prompt,
            submission.age_range_min,
            submission.age_range_max,
            submission.difficulty_level,
            submission.educational_goals.as_ref().map(|v| v.as_slice()),
            submission.vocabulary_words.as_ref().map(|v| v.as_slice()),
            submission.learning_objectives.as_ref().map(|v| v.as_slice()),
            submission.educational_alignment,
            submission.content_data,
            submission.asset_urls,
            submission.estimated_duration_minutes,
            submission.status,
            submission.submission_date,
            submission.automated_safety_check,
            submission.safety_check_results,
            submission.safety_check_score,
            submission.safety_issues.as_ref().map(|v| v.as_slice()),
            submission.quality_score,
            submission.readability_score,
            submission.educational_value_score,
            submission.proposed_price,
            submission.licensing_model,
            submission.marketing_description,
            submission.search_keywords.as_ref().map(|v| v.as_slice()),
            submission.version,
            submission.parent_submission_id,
            submission.created_at,
            submission.updated_at,
            submission.last_saved_at
        )
        .fetch_one(&self.db)
        .await
        .map_err(|e| {
            tracing::error!("Failed to create content submission: {}", e);
            AppError::DatabaseError(e)
        })?;

        Ok(row)
    }

    pub async fn update_submission(&self, submission: ContentSubmission) -> AppResult<ContentSubmission> {
        let row = sqlx::query_as!(
            ContentSubmission,
            r#"
            UPDATE games.content_submissions SET
                title = $2,
                description = $3,
                content_data = $4,
                educational_goals = $5,
                vocabulary_words = $6,
                learning_objectives = $7,
                educational_alignment = $8,
                asset_urls = $9,
                estimated_duration_minutes = $10,
                status = $11,
                submission_date = $12,
                automated_safety_check = $13,
                safety_check_results = $14,
                safety_check_score = $15,
                safety_issues = $16,
                quality_score = $17,
                readability_score = $18,
                educational_value_score = $19,
                proposed_price = $20,
                marketing_description = $21,
                search_keywords = $22,
                updated_at = $23,
                last_saved_at = $24
            WHERE id = $1
            RETURNING *
            "#,
            submission.id,
            submission.title,
            submission.description,
            submission.content_data,
            submission.educational_goals.as_ref().map(|v| v.as_slice()),
            submission.vocabulary_words.as_ref().map(|v| v.as_slice()),
            submission.learning_objectives.as_ref().map(|v| v.as_slice()),
            submission.educational_alignment,
            submission.asset_urls,
            submission.estimated_duration_minutes,
            submission.status,
            submission.submission_date,
            submission.automated_safety_check,
            submission.safety_check_results,
            submission.safety_check_score,
            submission.safety_issues.as_ref().map(|v| v.as_slice()),
            submission.quality_score,
            submission.readability_score,
            submission.educational_value_score,
            submission.proposed_price,
            submission.marketing_description,
            submission.search_keywords.as_ref().map(|v| v.as_slice()),
            submission.updated_at,
            submission.last_saved_at
        )
        .fetch_one(&self.db)
        .await
        .map_err(|e| {
            tracing::error!("Failed to update content submission: {}", e);
            AppError::DatabaseError(e)
        })?;

        Ok(row)
    }

    pub async fn get_submission_by_id(&self, submission_id: Uuid) -> AppResult<Option<ContentSubmission>> {
        let row = sqlx::query_as!(
            ContentSubmission,
            "SELECT * FROM games.content_submissions WHERE id = $1",
            submission_id
        )
        .fetch_optional(&self.db)
        .await
        .map_err(|e| {
            tracing::error!("Failed to get content submission: {}", e);
            AppError::DatabaseError(e)
        })?;

        Ok(row)
    }

    pub async fn get_submissions_by_creator(
        &self,
        creator_user_id: Uuid,
        offset: i32,
        limit: i32,
        status_filter: Option<String>,
    ) -> AppResult<(Vec<ContentSubmission>, i64)> {
        let submissions = if let Some(ref status) = status_filter {
            sqlx::query_as!(
                ContentSubmission,
                r#"
                SELECT * FROM games.content_submissions 
                WHERE creator_user_id = $1 AND status = $2
                ORDER BY updated_at DESC 
                LIMIT $3 OFFSET $4
                "#,
                creator_user_id,
                status,
                limit as i64,
                offset as i64
            )
            .fetch_all(&self.db)
            .await
        } else {
            sqlx::query_as!(
                ContentSubmission,
                r#"
                SELECT * FROM games.content_submissions 
                WHERE creator_user_id = $1
                ORDER BY updated_at DESC 
                LIMIT $2 OFFSET $3
                "#,
                creator_user_id,
                limit as i64,
                offset as i64
            )
            .fetch_all(&self.db)
            .await
        }
        .map_err(|e| {
            tracing::error!("Failed to get creator submissions: {}", e);
            AppError::DatabaseError(e)
        })?;

        let total_count = if let Some(ref status) = status_filter {
            sqlx::query_scalar!(
                "SELECT COUNT(*) FROM games.content_submissions WHERE creator_user_id = $1 AND status = $2",
                creator_user_id,
                status
            )
            .fetch_one(&self.db)
            .await
        } else {
            sqlx::query_scalar!(
                "SELECT COUNT(*) FROM games.content_submissions WHERE creator_user_id = $1",
                creator_user_id
            )
            .fetch_one(&self.db)
            .await
        }
        .map_err(|e| {
            tracing::error!("Failed to count creator submissions: {}", e);
            AppError::DatabaseError(e)
        })?
        .unwrap_or(0);

        Ok((submissions, total_count))
    }

    pub async fn delete_submission(&self, submission_id: Uuid) -> AppResult<()> {
        sqlx::query!(
            "DELETE FROM games.content_submissions WHERE id = $1",
            submission_id
        )
        .execute(&self.db)
        .await
        .map_err(|e| {
            tracing::error!("Failed to delete content submission: {}", e);
            AppError::DatabaseError(e)
        })?;

        Ok(())
    }

    pub async fn get_creator_profile_id_by_user(&self, user_id: Uuid) -> AppResult<Option<Uuid>> {
        let row = sqlx::query!(
            "SELECT id FROM games.creator_profiles WHERE user_id = $1",
            user_id
        )
        .fetch_optional(&self.db)
        .await
        .map_err(|e| {
            tracing::error!("Failed to get creator profile: {}", e);
            AppError::DatabaseError(e)
        })?;

        Ok(row.map(|r| r.id))
    }

    pub async fn get_creator_status_counts(&self, creator_user_id: Uuid) -> AppResult<HashMap<String, i64>> {
        let rows = sqlx::query!(
            r#"
            SELECT status, COUNT(*) as count 
            FROM games.content_submissions 
            WHERE creator_user_id = $1 
            GROUP BY status
            "#,
            creator_user_id
        )
        .fetch_all(&self.db)
        .await
        .map_err(|e| {
            tracing::error!("Failed to get creator status counts: {}", e);
            AppError::DatabaseError(e)
        })?;

        let mut counts = HashMap::new();
        for row in rows {
            let status = row.status.unwrap_or_else(|| "draft".to_string());
            counts.insert(status, row.count.unwrap_or(0));
        }

        Ok(counts)
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
        let mut query = "SELECT * FROM games.content_templates WHERE active = true".to_string();
        let mut params = Vec::new();
        let mut param_count = 1;

        if let Some(cat) = category {
            query.push_str(&format!(" AND category = ${}", param_count));
            params.push(cat);
            param_count += 1;
        }

        if let Some(min_age) = age_range_min {
            query.push_str(&format!(" AND age_range_max >= ${}", param_count));
            params.push(min_age.to_string());
            param_count += 1;
        }

        if let Some(max_age) = age_range_max {
            query.push_str(&format!(" AND age_range_min <= ${}", param_count));
            params.push(max_age.to_string());
        }

        query.push_str(" ORDER BY featured DESC, usage_count DESC, name ASC");

        let templates = sqlx::query_as::<_, ContentTemplate>(&query)
            .fetch_all(&self.db)
            .await
            .map_err(|e| {
                tracing::error!("Failed to get content templates: {}", e);
                AppError::DatabaseError(e)
            })?;

        Ok(templates)
    }

    pub async fn get_template_by_id(&self, template_id: Uuid) -> AppResult<Option<ContentTemplate>> {
        let template = sqlx::query_as!(
            ContentTemplate,
            "SELECT * FROM games.content_templates WHERE id = $1 AND active = true",
            template_id
        )
        .fetch_optional(&self.db)
        .await
        .map_err(|e| {
            tracing::error!("Failed to get content template: {}", e);
            AppError::DatabaseError(e)
        })?;

        Ok(template)
    }

    // =============================================================================
    // CONTENT GUIDELINES
    // =============================================================================

    pub async fn get_content_guidelines(
        &self,
        category: Option<String>,
        mandatory_only: Option<bool>,
    ) -> AppResult<Vec<ContentGuideline>> {
        let guidelines = if let Some(category) = category {
            if let Some(mandatory) = mandatory_only {
                sqlx::query_as!(
                    ContentGuideline,
                    r#"
                    SELECT * FROM games.content_guidelines 
                    WHERE active = true AND category = $1 AND mandatory = $2
                    ORDER BY mandatory DESC, title ASC
                    "#,
                    category,
                    mandatory
                )
                .fetch_all(&self.db)
                .await
            } else {
                sqlx::query_as!(
                    ContentGuideline,
                    r#"
                    SELECT * FROM games.content_guidelines 
                    WHERE active = true AND category = $1
                    ORDER BY mandatory DESC, title ASC
                    "#,
                    category
                )
                .fetch_all(&self.db)
                .await
            }
        } else if let Some(mandatory) = mandatory_only {
            sqlx::query_as!(
                ContentGuideline,
                r#"
                SELECT * FROM games.content_guidelines 
                WHERE active = true AND mandatory = $1
                ORDER BY mandatory DESC, title ASC
                "#,
                mandatory
            )
            .fetch_all(&self.db)
            .await
        } else {
            sqlx::query_as!(
                ContentGuideline,
                r#"
                SELECT * FROM games.content_guidelines 
                WHERE active = true
                ORDER BY mandatory DESC, title ASC
                "#
            )
            .fetch_all(&self.db)
            .await
        }
        .map_err(|e| {
            tracing::error!("Failed to get content guidelines: {}", e);
            AppError::DatabaseError(e)
        })?;

        Ok(guidelines)
    }

    // =============================================================================
    // CONTENT VALIDATION
    // =============================================================================

    pub async fn save_validation_result(&self, result: ContentValidationResult) -> AppResult<()> {
        sqlx::query!(
            r#"
            INSERT INTO games.content_validation_results (
                id, submission_id, validation_version, validation_timestamp,
                language_appropriateness_score, content_safety_score, age_appropriateness_score,
                readability_score, grammar_score, educational_value_score,
                flagged_words, safety_issues, quality_issues, suggestions,
                overall_score, passed_automated_checks, requires_human_review,
                processing_time_ms, validation_errors
            ) VALUES (
                $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19
            )
            "#,
            result.id,
            result.submission_id,
            result.validation_version,
            result.validation_timestamp,
            result.language_appropriateness_score,
            result.content_safety_score,
            result.age_appropriateness_score,
            result.readability_score,
            result.grammar_score,
            result.educational_value_score,
            &result.flagged_words,
            result.safety_issues,
            result.quality_issues,
            result.suggestions,
            result.overall_score,
            result.passed_automated_checks,
            result.requires_human_review,
            result.processing_time_ms,
            &result.validation_errors
        )
        .execute(&self.db)
        .await
        .map_err(|e| {
            tracing::error!("Failed to save validation result: {}", e);
            AppError::DatabaseError(e)
        })?;

        Ok(())
    }

    // =============================================================================
    // CREATOR ANALYTICS
    // =============================================================================

    pub async fn get_creator_stats(&self, creator_user_id: Uuid) -> AppResult<CreatorStats> {
        let stats = sqlx::query!(
            r#"
            SELECT 
                COUNT(*) FILTER (WHERE status != 'draft') as total_submissions,
                COUNT(*) FILTER (WHERE status = 'approved') as approved_submissions,
                COUNT(*) FILTER (WHERE status IN ('submitted_for_review', 'under_review')) as pending_submissions,
                COUNT(*) FILTER (WHERE status = 'rejected') as rejected_submissions,
                COUNT(*) FILTER (WHERE status = 'draft') as total_drafts,
                AVG(quality_score) as average_quality_score,
                CASE 
                    WHEN COUNT(*) FILTER (WHERE status != 'draft') > 0 
                    THEN COUNT(*) FILTER (WHERE status = 'approved')::DECIMAL / COUNT(*) FILTER (WHERE status != 'draft') * 100
                    ELSE 0
                END as approval_rate
            FROM games.content_submissions 
            WHERE creator_user_id = $1
            "#,
            creator_user_id
        )
        .fetch_one(&self.db)
        .await
        .map_err(|e| {
            tracing::error!("Failed to get creator stats: {}", e);
            AppError::DatabaseError(e)
        })?;

        Ok(CreatorStats {
            total_submissions: stats.total_submissions.unwrap_or(0) as i32,
            approved_submissions: stats.approved_submissions.unwrap_or(0) as i32,
            pending_submissions: stats.pending_submissions.unwrap_or(0) as i32,
            rejected_submissions: stats.rejected_submissions.unwrap_or(0) as i32,
            total_drafts: stats.total_drafts.unwrap_or(0) as i32,
            approval_rate: BigDecimal::try_from(stats.approval_rate.unwrap_or(BigDecimal::from(0))).unwrap_or_default(),
            average_quality_score: BigDecimal::try_from(stats.average_quality_score.unwrap_or(BigDecimal::from(0))).unwrap_or_default(),
            average_creation_time_hours: BigDecimal::from(0), // TODO: Calculate from timestamps
        })
    }

    pub async fn get_creator_recent_activities(&self, creator_user_id: Uuid) -> AppResult<Vec<CreatorRecentActivity>> {
        let activities = sqlx::query!(
            r#"
            SELECT 
                title as submission_title,
                status as activity_type,
                updated_at as timestamp,
                CASE 
                    WHEN status = 'approved' THEN 'Content approved for publication'
                    WHEN status = 'rejected' THEN 'Content needs revision'
                    WHEN status = 'submitted_for_review' THEN 'Submitted for review'
                    ELSE NULL
                END as details
            FROM games.content_submissions
            WHERE creator_user_id = $1 AND status != 'draft'
            ORDER BY updated_at DESC
            LIMIT 10
            "#,
            creator_user_id
        )
        .fetch_all(&self.db)
        .await
        .map_err(|e| {
            tracing::error!("Failed to get creator activities: {}", e);
            AppError::DatabaseError(e)
        })?;

        let recent_activities = activities
            .into_iter()
            .map(|row| CreatorRecentActivity {
                submission_title: row.submission_title,
                activity_type: row.activity_type.unwrap_or_default(),
                timestamp: row.timestamp.unwrap_or_else(|| chrono::Utc::now()),
                details: row.details,
            })
            .collect();

        Ok(recent_activities)
    }
}

// =============================================================================
// HELPER TYPES
// =============================================================================

#[derive(Debug, Clone)]
pub struct CreatorStats {
    pub total_submissions: i32,
    pub approved_submissions: i32,
    pub pending_submissions: i32,
    pub rejected_submissions: i32,
    pub total_drafts: i32,
    pub approval_rate: BigDecimal,
    pub average_quality_score: BigDecimal,
    pub average_creation_time_hours: BigDecimal,
}

#[derive(Debug, Clone)]
pub struct CreatorRecentActivity {
    pub submission_title: String,
    pub activity_type: String,
    pub timestamp: DateTime<Utc>,
    pub details: Option<String>,
}