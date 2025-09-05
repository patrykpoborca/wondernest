use axum::{
    extract::{Query, State},
    http::StatusCode,
    middleware,
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::{
    error::{AppError, AppResult},
    extractors::AuthClaims,
    middleware::auth::auth_middleware,
    services::AppState,
};

#[derive(Debug, Serialize, Deserialize)]
pub struct GenerateStoryRequest {
    pub prompt: String,
    pub title: Option<String>,
    pub age_range: String,
    pub educational_goals: Vec<String>,
    pub max_pages: Option<u8>,
    pub vocabulary_level: Option<String>,
    pub include_images: Option<bool>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct EnhanceTextRequest {
    pub text: String,
    pub mode: EnhancementMode,
    pub context: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum EnhancementMode {
    Simplify,
    Elaborate,
    AddVocabulary,
    MakeExciting,
    AddEducational,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct SuggestionRequest {
    pub context: StoryContext,
    pub suggestion_type: SuggestionType,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct StoryContext {
    pub current_text: String,
    pub previous_page: Option<String>,
    pub next_page: Option<String>,
    pub story_title: String,
    pub target_age: String,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum SuggestionType {
    NextSentence,
    PlotTwist,
    Character,
    Setting,
    Dialogue,
    Ending,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GenerateStoryResponse {
    pub id: String,
    pub title: String,
    pub pages: Vec<StoryPage>,
    pub metadata: StoryMetadata,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct StoryPage {
    pub id: String,
    pub page_number: u32,
    pub content: String,
    pub image_prompt: Option<String>,
    pub vocabulary_words: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct StoryMetadata {
    pub age_range: String,
    pub educational_goals: Vec<String>,
    pub estimated_reading_time: u32,
    pub vocabulary_level: String,
    pub ai_generated_percentage: f32,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct EnhanceTextResponse {
    pub enhanced_text: String,
    pub changes_made: Vec<String>,
    pub vocabulary_added: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct SuggestionResponse {
    pub suggestions: Vec<Suggestion>,
    pub confidence_score: f32,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Suggestion {
    pub text: String,
    pub reasoning: String,
    pub educational_value: Option<String>,
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/generate", post(generate_story))
        .route("/enhance", post(enhance_text))
        .route("/suggest", post(get_suggestions))
        .route("/templates", get(get_templates))
        .layer(middleware::from_fn(auth_middleware))
}

async fn generate_story(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Json(request): Json<GenerateStoryRequest>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Story generation request from user: {}", claims.user_id);
    
    // Validate request
    if request.prompt.is_empty() {
        return Err(AppError::BadRequest("Prompt cannot be empty".to_string()));
    }
    
    if request.prompt.len() > 1000 {
        return Err(AppError::BadRequest("Prompt too long (max 1000 characters)".to_string()));
    }
    
    // TODO: Integrate with actual AI service (OpenAI, Anthropic, etc.)
    // For now, return mock response for development
    
    let story_id = Uuid::new_v4().to_string();
    let title = request.title.clone().unwrap_or_else(|| generate_title_from_prompt(&request.prompt));
    
    let pages = generate_mock_pages(&request);
    let metadata = StoryMetadata {
        age_range: request.age_range.clone(),
        educational_goals: request.educational_goals.clone(),
        estimated_reading_time: calculate_reading_time(&pages),
        vocabulary_level: request.vocabulary_level.unwrap_or_else(|| "grade_2".to_string()),
        ai_generated_percentage: 100.0,
    };
    
    let response = GenerateStoryResponse {
        id: story_id,
        title,
        pages,
        metadata,
    };
    
    Ok((StatusCode::OK, Json(response)))
}

async fn enhance_text(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Json(request): Json<EnhanceTextRequest>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Text enhancement request from user: {}", claims.user_id);
    
    if request.text.is_empty() {
        return Err(AppError::BadRequest("Text cannot be empty".to_string()));
    }
    
    // TODO: Implement actual AI enhancement
    let enhanced = match request.mode {
        EnhancementMode::Simplify => simplify_text(&request.text),
        EnhancementMode::Elaborate => elaborate_text(&request.text),
        EnhancementMode::AddVocabulary => add_vocabulary(&request.text),
        EnhancementMode::MakeExciting => make_exciting(&request.text),
        EnhancementMode::AddEducational => add_educational_content(&request.text),
    };
    
    let response = EnhanceTextResponse {
        enhanced_text: enhanced,
        changes_made: vec!["Enhanced readability".to_string()],
        vocabulary_added: vec!["adventure".to_string(), "discover".to_string()],
    };
    
    Ok((StatusCode::OK, Json(response)))
}

async fn get_suggestions(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Json(request): Json<SuggestionRequest>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Suggestion request from user: {}", claims.user_id);
    
    // TODO: Implement actual AI suggestions
    let suggestions = generate_mock_suggestions(&request);
    
    let response = SuggestionResponse {
        suggestions,
        confidence_score: 0.85,
    };
    
    Ok((StatusCode::OK, Json(response)))
}

async fn get_templates(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Template request from user: {}", claims.user_id);
    
    // TODO: Fetch from database
    let templates = vec![
        StoryTemplate {
            id: "adventure_template".to_string(),
            name: "Adventure Story".to_string(),
            description: "A brave hero goes on an exciting journey".to_string(),
            age_range: "5-8".to_string(),
            prompt_template: "Create a story about {character_name} who goes on an adventure to {destination}".to_string(),
        },
        StoryTemplate {
            id: "friendship_template".to_string(),
            name: "Friendship Story".to_string(),
            description: "A heartwarming tale about making new friends".to_string(),
            age_range: "4-7".to_string(),
            prompt_template: "Tell a story about {character_name} who learns about friendship".to_string(),
        },
    ];
    
    Ok((StatusCode::OK, Json(templates)))
}

#[derive(Debug, Serialize, Deserialize)]
struct StoryTemplate {
    id: String,
    name: String,
    description: String,
    age_range: String,
    prompt_template: String,
}

// Helper functions (mock implementations)
fn generate_title_from_prompt(prompt: &str) -> String {
    let words: Vec<&str> = prompt.split_whitespace().take(5).collect();
    format!("The {} Adventure", words.join(" "))
}

fn generate_mock_pages(request: &GenerateStoryRequest) -> Vec<StoryPage> {
    let num_pages = request.max_pages.unwrap_or(5);
    (1..=num_pages).map(|i| {
        StoryPage {
            id: Uuid::new_v4().to_string(),
            page_number: i as u32,
            content: format!("Once upon a time, there was a wonderful story about {}. This is page {}.", request.prompt, i),
            image_prompt: Some(format!("Illustration for {}", request.prompt)),
            vocabulary_words: vec!["adventure".to_string(), "discover".to_string()],
        }
    }).collect()
}

fn calculate_reading_time(pages: &[StoryPage]) -> u32 {
    let total_words: usize = pages.iter()
        .map(|p| p.content.split_whitespace().count())
        .sum();
    ((total_words as f32 / 200.0) * 60.0) as u32 // 200 words per minute average
}

fn simplify_text(text: &str) -> String {
    format!("{} (simplified)", text)
}

fn elaborate_text(text: &str) -> String {
    format!("{} The scene was filled with wonder and excitement.", text)
}

fn add_vocabulary(text: &str) -> String {
    format!("{} The protagonist embarked on an extraordinary adventure.", text)
}

fn make_exciting(text: &str) -> String {
    format!("Suddenly, {}!", text)
}

fn add_educational_content(text: &str) -> String {
    format!("{} This teaches us about perseverance and courage.", text)
}

fn generate_mock_suggestions(request: &SuggestionRequest) -> Vec<Suggestion> {
    match request.suggestion_type {
        SuggestionType::NextSentence => vec![
            Suggestion {
                text: "The brave explorer continued down the winding path.".to_string(),
                reasoning: "Continues the narrative flow".to_string(),
                educational_value: Some("Teaches about perseverance".to_string()),
            },
        ],
        SuggestionType::PlotTwist => vec![
            Suggestion {
                text: "But then, they discovered the map was upside down all along!".to_string(),
                reasoning: "Adds surprise element".to_string(),
                educational_value: Some("Teaches problem-solving".to_string()),
            },
        ],
        _ => vec![
            Suggestion {
                text: "The story continues...".to_string(),
                reasoning: "Generic continuation".to_string(),
                educational_value: None,
            },
        ],
    }
}