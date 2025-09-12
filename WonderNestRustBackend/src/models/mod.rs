pub mod admin;
pub mod admin_content;
pub mod analytics;
pub mod audio;
pub mod auth;
pub mod content;
pub mod content_ecosystem;
pub mod content_pack;
pub mod content_publishing;
pub mod coppa;
pub mod creator;
pub mod family;
pub mod file_operations;
pub mod file_upload;
pub mod game;
pub mod marketplace;
pub mod user;

pub use admin::*;
pub use analytics::*;
pub use audio::*;
pub use auth::*;
pub use content::*;
pub use content_ecosystem::*;
pub use content_pack::*;
pub use coppa::*;
pub use family::*;
pub use file_operations::*;
pub use file_upload::*;
pub use game::*;
pub use marketplace::*;
pub use user::*;

// Import admin_content without conflicting ContentListResponse
pub use admin_content::{
    AdminCreator, UpdateAdminCreatorRequest, CreateAdminCreatorRequest,
    CreateContentRequest, UpdateContentRequest, PublishContentRequest, BulkPublishRequest,
    CsvContentRow, ContentListRequest,
    ContentListResponse as AdminContentListResponse, // Renamed to avoid conflict
};

// Import content_publishing without conflicting structs
pub use content_publishing::{
    ContentSubmission, ContentTemplate, ContentGuideline, ContentValidationResult,
    CreateContentSubmissionRequest, UpdateContentSubmissionRequest, ContentPreviewRequest,
    AIAssistedCreationRequest, AIAssistedCreationResponse, ContentSubmissionListResponse,
    ContentTemplateListResponse, ContentGuidelinesResponse, BigDecimal, ContentTemplateResponse, ContentGuidelineResponse,
    ContentModerationQueue, ContentModerationDecision, CreatorOnboardingProgress,
    ModerationQueueRequest, ModerationDecisionRequest, ModerationQueueResponse,
    ModerationQueueItem, ModerationQueueSummary, CreatorAnalyticsResponse, CreatorActivity,
    ContentPreviewResponse as PublishingContentPreviewResponse, // Renamed to avoid conflict
    ContentSubmissionSummary as PublishingContentSubmissionSummary, // Renamed to avoid conflict
};

// Import creator module with minimal conflicts
pub use creator::{
    ContentListResponse as CreatorContentListResponse, // Renamed to avoid conflict
    ContentPreviewResponse as CreatorContentPreviewResponse, // Renamed to avoid conflict
    ContentSubmissionSummary as CreatorContentSubmissionSummary, // Renamed to avoid conflict
};