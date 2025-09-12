use serde::{Deserialize, Serialize};
use uuid::Uuid;
use chrono::{DateTime, Utc, NaiveDate};
use std::collections::HashMap;

// =============================================================================
// CREATOR AUTHENTICATION MODELS
// =============================================================================

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct CreatorRegisterRequest {
    pub email: String,
    pub password: String,
    #[serde(rename = "firstName")]
    pub first_name: String,
    #[serde(rename = "lastName")]
    pub last_name: String,
    #[serde(rename = "displayName")]
    pub display_name: String,
    pub country: String, // ISO 3166-1 alpha-3
    #[serde(rename = "acceptTerms")]
    pub accept_terms: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreatorLoginRequest {
    pub email: String,
    pub password: String,
    #[serde(rename = "otpCode")]
    pub otp_code: Option<String>, // For 2FA
    #[serde(skip_deserializing)]
    pub ip_address: Option<String>, // Added by middleware
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreatorRefreshTokenRequest {
    #[serde(rename = "refreshToken")]
    pub refresh_token: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreatorLoginResponse {
    #[serde(rename = "accessToken")]
    pub access_token: String,
    #[serde(rename = "refreshToken")]
    pub refresh_token: String,
    #[serde(rename = "creatorId")]
    pub creator_id: Uuid,
    pub tier: String,
    #[serde(rename = "requires2FA")]
    pub requires_2fa: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreatorRefreshResponse {
    #[serde(rename = "accessToken")]
    pub access_token: String,
    #[serde(rename = "refreshToken")]
    pub refresh_token: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Enable2FARequest {
    pub password: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Enable2FAResponse {
    pub secret: String,
    #[serde(rename = "qrCode")]
    pub qr_code: String,
    #[serde(rename = "backupCodes")]
    pub backup_codes: Vec<String>,
}

// =============================================================================
// CREATOR ACCOUNT MODELS
// =============================================================================

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, sqlx::Type)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "creator_status", rename_all = "snake_case")]
pub enum CreatorStatus {
    PendingVerification,
    PendingApproval,
    Active,
    Suspended,
    Banned,
    SelfDisabled,
}

#[derive(Debug, Serialize, Deserialize, Clone, sqlx::Type)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "creator_type", rename_all = "snake_case")]
pub enum CreatorType {
    Community,
    Educator,
    Professional,
    Partner,
}

#[derive(Debug, Serialize, Deserialize, Clone, sqlx::Type)]
#[serde(rename_all = "snake_case")]
#[sqlx(type_name = "creator_tier", rename_all = "snake_case")]
pub enum CreatorTier {
    Tier1, // Community Creator (50% revenue share)
    Tier2, // Verified Educator (60% revenue share)
    Tier3, // Professional Creator (70% revenue share)
    Tier4, // Partner Creator (custom revenue share)
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct CreatorAccount {
    pub id: Uuid,
    pub email: String,
    #[serde(rename = "emailVerified")]
    pub email_verified: bool,
    #[serde(rename = "firstName")]
    pub first_name: String,
    #[serde(rename = "lastName")]
    pub last_name: String,
    #[serde(rename = "displayName")]
    pub display_name: String,
    pub bio: Option<String>,
    pub country: String,
    pub status: CreatorStatus,
    #[serde(rename = "creatorType")]
    pub creator_type: CreatorType,
    #[serde(rename = "creatorTier")]
    pub creator_tier: CreatorTier,
    #[serde(rename = "twoFactorEnabled")]
    pub two_factor_enabled: bool,
    #[serde(rename = "avatarUrl")]
    pub avatar_url: Option<String>,
    #[serde(rename = "coverImageUrl")]
    pub cover_image_url: Option<String>,
    #[serde(rename = "websiteUrl")]
    pub website_url: Option<String>,
    #[serde(rename = "socialLinks")]
    pub social_links: HashMap<String, String>,
    #[serde(rename = "contentSpecialties")]
    pub content_specialties: Vec<String>,
    #[serde(rename = "languagesSupported")]
    pub languages_supported: Vec<String>,
    #[serde(rename = "targetAgeGroups")]
    pub target_age_groups: Vec<String>,
    #[serde(rename = "termsAccepted")]
    pub terms_accepted: bool,
    #[serde(rename = "createdAt")]
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreatorProfileUpdateRequest {
    #[serde(rename = "displayName")]
    pub display_name: Option<String>,
    pub bio: Option<String>,
    #[serde(rename = "contentSpecialties")]
    pub content_specialties: Option<Vec<String>>,
    #[serde(rename = "languagesSupported")]
    pub languages_supported: Option<Vec<String>>,
    #[serde(rename = "socialLinks")]
    pub social_links: Option<HashMap<String, String>>,
}

// =============================================================================
// CREATOR APPLICATION MODELS
// =============================================================================

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "snake_case")]
pub enum ApplicationStatus {
    Submitted,
    UnderReview,
    PendingIdentityVerification,
    PendingCredentialVerification,
    PendingBackgroundCheck,
    Approved,
    Rejected,
    AdditionalInfoRequired,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreatorApplicationRequest {
    #[serde(rename = "creatorType")]
    pub creator_type: CreatorType,
    #[serde(rename = "professionalBackground")]
    pub professional_background: String,
    #[serde(rename = "teachingExperienceYears")]
    pub teaching_experience_years: Option<i32>,
    #[serde(rename = "contentCreationExperience")]
    pub content_creation_experience: String,
    #[serde(rename = "portfolioUrls")]
    pub portfolio_urls: Vec<String>,
    #[serde(rename = "sampleContentUrls")]
    pub sample_content_urls: Vec<String>,
    #[serde(rename = "educationDegree")]
    pub education_degree: Option<String>,
    #[serde(rename = "educationInstitution")]
    pub education_institution: Option<String>,
    #[serde(rename = "teachingCertifications")]
    pub teaching_certifications: Vec<String>,
    #[serde(rename = "professionalCertifications")]
    pub professional_certifications: Vec<String>,
    #[serde(rename = "targetAgeGroups")]
    pub target_age_groups: Vec<String>,
    #[serde(rename = "contentTypesInterested")]
    pub content_types_interested: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreatorApplicationResponse {
    #[serde(rename = "applicationId")]
    pub application_id: Uuid,
    pub status: ApplicationStatus,
    #[serde(rename = "estimatedReviewTime")]
    pub estimated_review_time: String,
    #[serde(rename = "nextSteps")]
    pub next_steps: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct OnboardingStatusResponse {
    #[serde(rename = "overallStatus")]
    pub overall_status: String,
    #[serde(rename = "completionPercentage")]
    pub completion_percentage: i32,
    pub steps: Vec<OnboardingStep>,
    #[serde(rename = "blockedReasons")]
    pub blocked_reasons: Vec<String>,
    #[serde(rename = "nextActionRequired")]
    pub next_action_required: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct OnboardingStep {
    pub step: String,
    pub status: String,
    #[serde(rename = "completedAt")]
    pub completed_at: Option<DateTime<Utc>>,
    #[serde(rename = "startedAt")]
    pub started_at: Option<DateTime<Utc>>,
}

// =============================================================================
// CREATOR VERIFICATION MODELS
// =============================================================================

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "snake_case")]
pub enum VerificationType {
    Identity,
    Credentials,
    BackgroundCheck,
    BankAccount,
    TaxDocument,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "snake_case")]
pub enum VerificationStatus {
    Pending,
    InProgress,
    Verified,
    Failed,
    Expired,
    ManualReview,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct IdentityVerificationRequest {
    #[serde(rename = "verificationMethod")]
    pub verification_method: String,
    #[serde(rename = "documentType")]
    pub document_type: String,
    #[serde(rename = "documentFront")]
    pub document_front: String, // Base64 encoded
    #[serde(rename = "documentBack")]
    pub document_back: Option<String>, // Base64 encoded
    pub selfie: String, // Base64 encoded
}

#[derive(Debug, Serialize, Deserialize)]
pub struct VerificationResponse {
    #[serde(rename = "verificationId")]
    pub verification_id: Uuid,
    pub status: VerificationStatus,
    #[serde(rename = "estimatedCompletion")]
    pub estimated_completion: Option<DateTime<Utc>>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CredentialVerificationRequest {
    #[serde(rename = "credentialType")]
    pub credential_type: String,
    pub document: String, // Base64 encoded PDF
    #[serde(rename = "issuingAuthority")]
    pub issuing_authority: String,
    #[serde(rename = "licenseNumber")]
    pub license_number: String,
    #[serde(rename = "expiryDate")]
    pub expiry_date: NaiveDate,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TaxDocumentRequest {
    #[serde(rename = "documentType")]
    pub document_type: String, // W9, W8_BEN, etc.
    #[serde(rename = "taxId")]
    pub tax_id: String, // Encrypted
    pub document: String, // Base64 encoded PDF
    pub signature: String, // Base64 encoded signature
    #[serde(rename = "signedDate")]
    pub signed_date: NaiveDate,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TaxDocumentResponse {
    #[serde(rename = "documentId")]
    pub document_id: Uuid,
    pub status: String,
    #[serde(rename = "validUntil")]
    pub valid_until: NaiveDate,
}

// =============================================================================
// CREATOR CONTENT MODELS
// =============================================================================

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "snake_case")]
pub enum ContentType {
    Story,
    InteractiveStory,
    StickerPack,
    EducationalActivity,
    LearningGame,
    CharacterPack,
    Applet,
    Template,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "snake_case")]
pub enum CreationMethod {
    Manual,
    Template,
    AiAssisted,
    Imported,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "snake_case")]
pub enum DifficultyLevel {
    Beginner,
    Intermediate,
    Advanced,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "snake_case")]
pub enum SubmissionStatus {
    Draft,
    SubmittedForReview,
    UnderAutomatedReview,
    UnderHumanReview,
    PendingChanges,
    Approved,
    Rejected,
    Withdrawn,
    Published,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ContentSubmissionRequest {
    pub title: String,
    pub description: Option<String>,
    #[serde(rename = "contentType")]
    pub content_type: ContentType,
    #[serde(rename = "templateId")]
    pub template_id: Option<Uuid>,
    #[serde(rename = "ageRangeMin")]
    pub age_range_min: i32,
    #[serde(rename = "ageRangeMax")]
    pub age_range_max: i32,
    #[serde(rename = "difficultyLevel")]
    pub difficulty_level: DifficultyLevel,
    #[serde(rename = "educationalGoals")]
    pub educational_goals: Vec<String>,
    #[serde(rename = "vocabularyWords")]
    pub vocabulary_words: Vec<String>,
    #[serde(rename = "learningObjectives")]
    pub learning_objectives: Vec<String>,
    #[serde(rename = "contentData")]
    pub content_data: serde_json::Value,
    #[serde(rename = "estimatedDurationMinutes")]
    pub estimated_duration_minutes: Option<i32>,
    #[serde(rename = "proposedPrice")]
    pub proposed_price: Option<f64>,
    #[serde(rename = "marketingDescription")]
    pub marketing_description: Option<String>,
    #[serde(rename = "searchKeywords")]
    pub search_keywords: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ContentSubmissionResponse {
    #[serde(rename = "submissionId")]
    pub submission_id: Uuid,
    pub status: SubmissionStatus,
    #[serde(rename = "createdAt")]
    pub created_at: DateTime<Utc>,
    #[serde(rename = "autoSaveEnabled")]
    pub auto_save_enabled: bool,
    #[serde(rename = "validationStatus")]
    pub validation_status: ValidationStatus,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ValidationStatus {
    #[serde(rename = "isValid")]
    pub is_valid: bool,
    #[serde(rename = "missingFields")]
    pub missing_fields: Vec<String>,
    #[serde(rename = "readyForSubmission")]
    pub ready_for_submission: Option<bool>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ContentSubmissionUpdateRequest {
    pub title: Option<String>,
    #[serde(rename = "contentData")]
    pub content_data: Option<serde_json::Value>,
    #[serde(rename = "marketingDescription")]
    pub marketing_description: Option<String>,
    #[serde(rename = "proposedPrice")]
    pub proposed_price: Option<f64>,
    #[serde(rename = "searchKeywords")]
    pub search_keywords: Option<Vec<String>>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct SubmitForReviewRequest {
    #[serde(rename = "finalCheckCompleted")]
    pub final_check_completed: bool,
    #[serde(rename = "creatorNotes")]
    pub creator_notes: String,
    #[serde(rename = "licensingModel")]
    pub licensing_model: String,
    #[serde(rename = "proposedPrice")]
    pub proposed_price: f64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct SubmitForReviewResponse {
    #[serde(rename = "submissionId")]
    pub submission_id: Uuid,
    pub status: SubmissionStatus,
    #[serde(rename = "estimatedReviewTime")]
    pub estimated_review_time: String,
    #[serde(rename = "moderationQueuePosition")]
    pub moderation_queue_position: i32,
    #[serde(rename = "automaticChecks")]
    pub automatic_checks: AutomaticChecks,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AutomaticChecks {
    #[serde(rename = "safetyScan")]
    pub safety_scan: String,
    #[serde(rename = "plagiarismCheck")]
    pub plagiarism_check: String,
    #[serde(rename = "qualityScore")]
    pub quality_score: i32,
    pub flags: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreatorContentPreviewRequest {
    pub mode: String, // child_view, parent_view, full_content
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ContentPreviewResponse {
    #[serde(rename = "submissionId")]
    pub submission_id: Uuid,
    #[serde(rename = "previewUrl")]
    pub preview_url: String,
    #[serde(rename = "previewExpires")]
    pub preview_expires: DateTime<Utc>,
    #[serde(rename = "previewData")]
    pub preview_data: serde_json::Value,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ContentListResponse {
    pub content: Vec<ContentSubmissionSummary>,
    pub pagination: PaginationInfo,
    pub summary: ContentSummary,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ContentSubmissionSummary {
    pub id: Uuid,
    pub title: String,
    #[serde(rename = "contentType")]
    pub content_type: ContentType,
    pub status: SubmissionStatus,
    #[serde(rename = "createdAt")]
    pub created_at: DateTime<Utc>,
    #[serde(rename = "lastUpdated")]
    pub last_updated: DateTime<Utc>,
    #[serde(rename = "marketplaceStatus")]
    pub marketplace_status: Option<String>,
    pub stats: ContentStats,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ContentStats {
    pub views: i32,
    pub purchases: i32,
    pub rating: f64,
    pub revenue: f64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ContentSummary {
    #[serde(rename = "totalDrafts")]
    pub total_drafts: i32,
    #[serde(rename = "pendingReview")]
    pub pending_review: i32,
    pub approved: i32,
    pub rejected: i32,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PaginationInfo {
    pub page: i32,
    pub limit: i32,
    pub total: i32,
    #[serde(rename = "hasMore")]
    pub has_more: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AssetUploadRequest {
    #[serde(rename = "assetType")]
    pub asset_type: String, // image, audio, video
    #[serde(rename = "submissionId")]
    pub submission_id: Uuid,
    pub description: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AssetUploadResponse {
    #[serde(rename = "assetId")]
    pub asset_id: Uuid,
    pub url: String,
    #[serde(rename = "thumbnailUrl")]
    pub thumbnail_url: Option<String>,
    #[serde(rename = "fileSize")]
    pub file_size: i64,
    #[serde(rename = "mimeType")]
    pub mime_type: String,
    pub dimensions: Option<ImageDimensions>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ImageDimensions {
    pub width: i32,
    pub height: i32,
}

// =============================================================================
// CREATOR ANALYTICS MODELS
// =============================================================================

#[derive(Debug, Serialize, Deserialize)]
pub struct CreatorDashboardResponse {
    pub overview: DashboardOverview,
    #[serde(rename = "recentSales")]
    pub recent_sales: Vec<RecentSale>,
    #[serde(rename = "trendingContent")]
    pub trending_content: Vec<TrendingContent>,
    pub notifications: Vec<CreatorNotification>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct DashboardOverview {
    #[serde(rename = "totalRevenue")]
    pub total_revenue: f64,
    #[serde(rename = "monthlyRevenue")]
    pub monthly_revenue: f64,
    #[serde(rename = "totalSales")]
    pub total_sales: i32,
    #[serde(rename = "monthlySales")]
    pub monthly_sales: i32,
    #[serde(rename = "averageRating")]
    pub average_rating: f64,
    #[serde(rename = "contentCount")]
    pub content_count: i32,
    #[serde(rename = "followerCount")]
    pub follower_count: i32,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct RecentSale {
    pub date: DateTime<Utc>,
    #[serde(rename = "contentTitle")]
    pub content_title: String,
    #[serde(rename = "buyerRegion")]
    pub buyer_region: String,
    pub amount: f64,
    #[serde(rename = "creatorEarnings")]
    pub creator_earnings: f64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TrendingContent {
    #[serde(rename = "contentId")]
    pub content_id: Uuid,
    pub title: String,
    pub trend: String, // up, down, stable
    #[serde(rename = "changePercentage")]
    pub change_percentage: f64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreatorNotification {
    #[serde(rename = "type")]
    pub notification_type: String,
    pub message: String,
    pub timestamp: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AnalyticsRequest {
    pub period: String, // 7d, 30d, 90d, 1y, all
    pub metrics: String, // revenue,sales,views,engagement
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AnalyticsResponse {
    pub period: AnalyticsPeriod,
    pub revenue: RevenueAnalytics,
    pub sales: SalesAnalytics,
    pub engagement: EngagementAnalytics,
    pub demographics: DemographicsAnalytics,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AnalyticsPeriod {
    pub start: NaiveDate,
    pub end: NaiveDate,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct RevenueAnalytics {
    pub total: f64,
    #[serde(rename = "byDay")]
    pub by_day: Vec<DailyRevenue>,
    #[serde(rename = "byContent")]
    pub by_content: Vec<ContentRevenue>,
    #[serde(rename = "growthRate")]
    pub growth_rate: f64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct DailyRevenue {
    pub date: NaiveDate,
    pub amount: f64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ContentRevenue {
    #[serde(rename = "contentId")]
    pub content_id: Uuid,
    pub title: String,
    pub amount: f64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct SalesAnalytics {
    pub total: i32,
    #[serde(rename = "conversionRate")]
    pub conversion_rate: f64,
    #[serde(rename = "averageOrderValue")]
    pub average_order_value: f64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct EngagementAnalytics {
    #[serde(rename = "totalViews")]
    pub total_views: i32,
    #[serde(rename = "uniqueViewers")]
    pub unique_viewers: i32,
    #[serde(rename = "averageRating")]
    pub average_rating: f64,
    #[serde(rename = "reviewCount")]
    pub review_count: i32,
    #[serde(rename = "completionRate")]
    pub completion_rate: f64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct DemographicsAnalytics {
    #[serde(rename = "ageDistribution")]
    pub age_distribution: HashMap<String, i32>,
    #[serde(rename = "geographicDistribution")]
    pub geographic_distribution: HashMap<String, i32>,
}

// =============================================================================
// CREATOR FINANCIAL MODELS
// =============================================================================

#[derive(Debug, Serialize, Deserialize)]
pub struct PayoutHistoryResponse {
    #[serde(rename = "pendingPayout")]
    pub pending_payout: PendingPayout,
    #[serde(rename = "payoutHistory")]
    pub payout_history: Vec<PayoutRecord>,
    #[serde(rename = "lifetimeEarnings")]
    pub lifetime_earnings: f64,
    #[serde(rename = "availableBalance")]
    pub available_balance: f64,
    #[serde(rename = "minimumPayout")]
    pub minimum_payout: f64,
    #[serde(rename = "nextPayoutEligible")]
    pub next_payout_eligible: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PendingPayout {
    pub amount: f64,
    pub currency: String,
    #[serde(rename = "estimatedDate")]
    pub estimated_date: NaiveDate,
    #[serde(rename = "transactionsIncluded")]
    pub transactions_included: i32,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PayoutRecord {
    #[serde(rename = "payoutId")]
    pub payout_id: Uuid,
    pub amount: f64,
    pub currency: String,
    pub status: String,
    pub method: String,
    #[serde(rename = "paidDate")]
    pub paid_date: NaiveDate,
    #[serde(rename = "transactionCount")]
    pub transaction_count: i32,
    #[serde(rename = "receiptUrl")]
    pub receipt_url: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PayoutRequest {
    pub amount: f64,
    pub method: String, // ACH, PayPal, Wire
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PayoutResponse {
    #[serde(rename = "payoutId")]
    pub payout_id: Uuid,
    pub status: String,
    pub amount: f64,
    #[serde(rename = "estimatedArrival")]
    pub estimated_arrival: NaiveDate,
    #[serde(rename = "transactionFee")]
    pub transaction_fee: f64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct BankingUpdateRequest {
    pub method: String,
    #[serde(rename = "accountHolderName")]
    pub account_holder_name: String,
    #[serde(rename = "accountType")]
    pub account_type: String,
    #[serde(rename = "routingNumber")]
    pub routing_number: String, // Encrypted
    #[serde(rename = "accountNumber")]
    pub account_number: String, // Encrypted
    #[serde(rename = "bankName")]
    pub bank_name: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct BankingUpdateResponse {
    pub status: String,
    #[serde(rename = "lastFour")]
    pub last_four: String,
    #[serde(rename = "bankName")]
    pub bank_name: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TaxDocumentsResponse {
    pub year: i32,
    pub documents: Vec<TaxDocument>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TaxDocument {
    #[serde(rename = "type")]
    pub document_type: String,
    #[serde(rename = "generatedDate")]
    pub generated_date: NaiveDate,
    #[serde(rename = "amountReported")]
    pub amount_reported: f64,
    #[serde(rename = "downloadUrl")]
    pub download_url: String,
}

// =============================================================================
// CREATOR SUPPORT MODELS
// =============================================================================

#[derive(Debug, Serialize, Deserialize)]
pub struct SupportTicketsResponse {
    pub tickets: Vec<SupportTicket>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct SupportTicket {
    #[serde(rename = "ticketId")]
    pub ticket_id: Uuid,
    pub subject: String,
    pub status: String,
    pub priority: String,
    #[serde(rename = "createdAt")]
    pub created_at: DateTime<Utc>,
    #[serde(rename = "lastUpdated")]
    pub last_updated: DateTime<Utc>,
    #[serde(rename = "lastResponseFrom")]
    pub last_response_from: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreateSupportTicketRequest {
    pub subject: String,
    pub category: String,
    pub priority: String,
    pub message: String,
    pub attachments: Vec<Uuid>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreateSupportTicketResponse {
    #[serde(rename = "ticketId")]
    pub ticket_id: Uuid,
    #[serde(rename = "ticketNumber")]
    pub ticket_number: String,
    pub status: String,
    #[serde(rename = "estimatedResponseTime")]
    pub estimated_response_time: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreatorNotificationsResponse {
    pub notifications: Vec<CreatorNotificationDetailed>,
    #[serde(rename = "unreadCount")]
    pub unread_count: i32,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreatorNotificationDetailed {
    pub id: Uuid,
    #[serde(rename = "type")]
    pub notification_type: String,
    pub title: String,
    pub message: String,
    pub timestamp: DateTime<Utc>,
    pub read: bool,
    #[serde(rename = "actionUrl")]
    pub action_url: Option<String>,
}

// =============================================================================
// MODERATION FEEDBACK MODELS
// =============================================================================

#[derive(Debug, Serialize, Deserialize)]
pub struct ModerationFeedbackResponse {
    #[serde(rename = "submissionId")]
    pub submission_id: Uuid,
    #[serde(rename = "moderationStatus")]
    pub moderation_status: String,
    pub feedback: ModerationScores,
    #[serde(rename = "publicFeedback")]
    pub public_feedback: String,
    #[serde(rename = "suggestedChanges")]
    pub suggested_changes: Vec<String>,
    #[serde(rename = "flaggedIssues")]
    pub flagged_issues: Vec<String>,
    #[serde(rename = "canResubmit")]
    pub can_resubmit: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ModerationScores {
    #[serde(rename = "overallRating")]
    pub overall_rating: f64,
    #[serde(rename = "contentQuality")]
    pub content_quality: f64,
    #[serde(rename = "educationalValue")]
    pub educational_value: f64,
    #[serde(rename = "safetyRating")]
    pub safety_rating: f64,
    #[serde(rename = "ageAppropriateness")]
    pub age_appropriateness: f64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AppealRequest {
    pub reason: String,
    pub explanation: String,
    #[serde(rename = "supportingDocuments")]
    pub supporting_documents: Vec<Uuid>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AppealResponse {
    #[serde(rename = "appealId")]
    pub appeal_id: Uuid,
    pub status: String,
    #[serde(rename = "estimatedReviewTime")]
    pub estimated_review_time: String,
}

// =============================================================================
// TEMPLATE MODELS
// =============================================================================

#[derive(Debug, Serialize, Deserialize)]
pub struct TemplatesResponse {
    pub templates: Vec<CreatorContentTemplate>,
    #[serde(rename = "featuredTemplates")]
    pub featured_templates: Vec<CreatorContentTemplate>,
    pub categories: Vec<TemplateCategory>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreatorContentTemplate {
    pub id: Uuid,
    pub name: String,
    pub category: String,
    pub description: String,
    #[serde(rename = "ageRange")]
    pub age_range: String,
    #[serde(rename = "difficultyLevel")]
    pub difficulty_level: String,
    #[serde(rename = "estimatedCreationTime")]
    pub estimated_creation_time: i32,
    #[serde(rename = "usageCount")]
    pub usage_count: i32,
    #[serde(rename = "averageRating")]
    pub average_rating: f64,
    #[serde(rename = "previewUrl")]
    pub preview_url: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TemplateCategory {
    pub category: String,
    #[serde(rename = "displayName")]
    pub display_name: String,
    #[serde(rename = "templateCount")]
    pub template_count: i32,
}

// =============================================================================
// ERROR MODELS
// =============================================================================

#[derive(Debug, Serialize, Deserialize)]
pub struct CreatorErrorResponse {
    pub error: String,
    pub message: String,
    pub details: Option<serde_json::Value>,
}