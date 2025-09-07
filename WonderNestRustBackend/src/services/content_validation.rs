use serde_json::Value;
use regex::Regex;
use std::collections::HashSet;

use crate::error::{AppError, AppResult};

pub struct ContentValidator {
    inappropriate_words: HashSet<String>,
    title_regex: Regex,
    content_length_limits: ContentLengthLimits,
}

pub struct ContentLengthLimits {
    pub title_min: usize,
    pub title_max: usize,
    pub story_min_words: usize,
    pub story_max_words: usize,
    pub description_max: usize,
}

impl Default for ContentLengthLimits {
    fn default() -> Self {
        Self {
            title_min: 5,
            title_max: 200,
            story_min_words: 50,
            story_max_words: 5000,
            description_max: 1000,
        }
    }
}

impl ContentValidator {
    pub fn new() -> Self {
        let inappropriate_words = Self::load_inappropriate_words();
        let title_regex = Regex::new(r"^[a-zA-Z0-9\s\-'.,!?]+$").unwrap();
        
        Self {
            inappropriate_words,
            title_regex,
            content_length_limits: ContentLengthLimits::default(),
        }
    }

    // =============================================================================
    // BASIC VALIDATION
    // =============================================================================

    pub fn validate_title(&self, title: &str) -> AppResult<()> {
        let title = title.trim();
        
        if title.len() < self.content_length_limits.title_min {
            return Err(AppError::BadRequest(
                format!("Title too short (minimum {} characters)", self.content_length_limits.title_min)
            ));
        }

        if title.len() > self.content_length_limits.title_max {
            return Err(AppError::BadRequest(
                format!("Title too long (maximum {} characters)", self.content_length_limits.title_max)
            ));
        }

        if !self.title_regex.is_match(title) {
            return Err(AppError::BadRequest(
                "Title contains invalid characters".to_string()
            ));
        }

        // Check for inappropriate content
        self.check_inappropriate_language(title)?;

        Ok(())
    }

    pub fn validate_description(&self, description: &str) -> AppResult<()> {
        if description.len() > self.content_length_limits.description_max {
            return Err(AppError::BadRequest(
                format!("Description too long (maximum {} characters)", self.content_length_limits.description_max)
            ));
        }

        self.check_inappropriate_language(description)?;

        Ok(())
    }

    // =============================================================================
    // CONTENT TYPE VALIDATION
    // =============================================================================

    pub fn validate_content_data(&self, content_data: &Value, content_type: &str) -> AppResult<()> {
        match content_type {
            "story" => self.validate_story_content(content_data),
            "interactive_story" => self.validate_interactive_story_content(content_data),
            "educational_activity" => self.validate_educational_activity_content(content_data),
            "learning_game" => self.validate_learning_game_content(content_data),
            _ => Err(AppError::BadRequest("Invalid content type".to_string())),
        }
    }

    pub fn validate_story_content(&self, content_data: &Value) -> AppResult<()> {
        // Expect structure: { "pages": [{"page_number": 1, "content": "...", "image_prompt": "..."}] }
        let pages = content_data.get("pages")
            .and_then(|p| p.as_array())
            .ok_or_else(|| AppError::BadRequest("Story content must have 'pages' array".to_string()))?;

        if pages.is_empty() {
            return Err(AppError::BadRequest("Story must have at least one page".to_string()));
        }

        if pages.len() > 50 {
            return Err(AppError::BadRequest("Story cannot have more than 50 pages".to_string()));
        }

        let mut total_word_count = 0;

        for (idx, page) in pages.iter().enumerate() {
            let page_number = page.get("page_number")
                .and_then(|p| p.as_u64())
                .ok_or_else(|| AppError::BadRequest(
                    format!("Page {} missing page_number", idx + 1)
                ))?;

            if page_number as usize != idx + 1 {
                return Err(AppError::BadRequest("Page numbers must be sequential starting from 1".to_string()));
            }

            let content = page.get("content")
                .and_then(|c| c.as_str())
                .ok_or_else(|| AppError::BadRequest(
                    format!("Page {} missing content", page_number)
                ))?;

            if content.trim().is_empty() {
                return Err(AppError::BadRequest(
                    format!("Page {} has empty content", page_number)
                ));
            }

            let word_count = content.split_whitespace().count();
            if word_count > 500 {
                return Err(AppError::BadRequest(
                    format!("Page {} exceeds maximum word count (500 words)", page_number)
                ));
            }

            total_word_count += word_count;

            // Validate page content for appropriateness
            self.check_inappropriate_language(content)?;

            // Validate vocabulary words if present
            if let Some(vocab) = page.get("vocabulary_words").and_then(|v| v.as_array()) {
                for word in vocab {
                    if let Some(word_str) = word.as_str() {
                        self.validate_vocabulary_word(word_str)?;
                    }
                }
            }
        }

        // Check total story length
        if total_word_count < self.content_length_limits.story_min_words {
            return Err(AppError::BadRequest(
                format!("Story too short (minimum {} words)", self.content_length_limits.story_min_words)
            ));
        }

        if total_word_count > self.content_length_limits.story_max_words {
            return Err(AppError::BadRequest(
                format!("Story too long (maximum {} words)", self.content_length_limits.story_max_words)
            ));
        }

        Ok(())
    }

    pub fn validate_interactive_story_content(&self, content_data: &Value) -> AppResult<()> {
        // First validate as regular story
        self.validate_story_content(content_data)?;

        // Additional validation for interactive elements
        let pages = content_data.get("pages").unwrap().as_array().unwrap();

        for page in pages {
            if let Some(choices) = page.get("choices").and_then(|c| c.as_array()) {
                if choices.len() > 5 {
                    return Err(AppError::BadRequest("Too many choices per page (maximum 5)".to_string()));
                }

                for choice in choices {
                    let choice_text = choice.get("text")
                        .and_then(|t| t.as_str())
                        .ok_or_else(|| AppError::BadRequest("Choice missing text".to_string()))?;

                    self.check_inappropriate_language(choice_text)?;

                    // Validate next_page reference
                    if let Some(next_page) = choice.get("next_page").and_then(|p| p.as_u64()) {
                        if next_page as usize > pages.len() {
                            return Err(AppError::BadRequest("Choice references invalid page".to_string()));
                        }
                    }
                }
            }
        }

        Ok(())
    }

    pub fn validate_educational_activity_content(&self, content_data: &Value) -> AppResult<()> {
        // Expect structure: { "type": "matching|counting|sorting", "instructions": "...", "activities": [...] }
        let activity_type = content_data.get("type")
            .and_then(|t| t.as_str())
            .ok_or_else(|| AppError::BadRequest("Educational activity must have 'type' field".to_string()))?;

        let valid_types = ["matching", "counting", "sorting", "fill_in_blank", "multiple_choice"];
        if !valid_types.contains(&activity_type) {
            return Err(AppError::BadRequest("Invalid educational activity type".to_string()));
        }

        let instructions = content_data.get("instructions")
            .and_then(|i| i.as_str())
            .ok_or_else(|| AppError::BadRequest("Educational activity must have instructions".to_string()))?;

        self.check_inappropriate_language(instructions)?;

        let activities = content_data.get("activities")
            .and_then(|a| a.as_array())
            .ok_or_else(|| AppError::BadRequest("Educational activity must have 'activities' array".to_string()))?;

        if activities.is_empty() {
            return Err(AppError::BadRequest("Educational activity must have at least one activity".to_string()));
        }

        if activities.len() > 20 {
            return Err(AppError::BadRequest("Too many activities (maximum 20)".to_string()));
        }

        // Validate individual activities based on type
        match activity_type {
            "matching" => self.validate_matching_activities(activities)?,
            "counting" => self.validate_counting_activities(activities)?,
            "sorting" => self.validate_sorting_activities(activities)?,
            _ => {} // Other types can be added as needed
        }

        Ok(())
    }

    pub fn validate_learning_game_content(&self, content_data: &Value) -> AppResult<()> {
        // Basic validation for learning games
        let game_type = content_data.get("game_type")
            .and_then(|t| t.as_str())
            .ok_or_else(|| AppError::BadRequest("Learning game must have 'game_type' field".to_string()))?;

        let valid_game_types = ["memory", "puzzle", "quiz", "word_game", "math_game"];
        if !valid_game_types.contains(&game_type) {
            return Err(AppError::BadRequest("Invalid learning game type".to_string()));
        }

        // Validate game rules/instructions
        if let Some(instructions) = content_data.get("instructions").and_then(|i| i.as_str()) {
            self.check_inappropriate_language(instructions)?;
        }

        Ok(())
    }

    // =============================================================================
    // SAFETY AND APPROPRIATENESS CHECKS
    // =============================================================================

    pub fn check_inappropriate_language(&self, text: &str) -> AppResult<()> {
        let text_lower = text.to_lowercase();
        
        for word in &self.inappropriate_words {
            if text_lower.contains(word) {
                return Err(AppError::BadRequest("Content contains inappropriate language".to_string()));
            }
        }

        Ok(())
    }

    pub fn validate_vocabulary_word(&self, word: &str) -> AppResult<()> {
        if word.trim().is_empty() {
            return Err(AppError::BadRequest("Vocabulary word cannot be empty".to_string()));
        }

        if word.len() > 50 {
            return Err(AppError::BadRequest("Vocabulary word too long".to_string()));
        }

        if !word.chars().all(|c| c.is_alphabetic() || c.is_whitespace() || c == '-' || c == '\'') {
            return Err(AppError::BadRequest("Vocabulary word contains invalid characters".to_string()));
        }

        self.check_inappropriate_language(word)?;

        Ok(())
    }

    pub fn assess_age_appropriateness(&self, content: &str, target_age_min: i32, target_age_max: i32) -> AppResult<f64> {
        // Simple readability assessment based on sentence length and word complexity
        let sentences: Vec<&str> = content.split(&['.', '!', '?'][..]).collect();
        let words: Vec<&str> = content.split_whitespace().collect();
        
        if sentences.is_empty() || words.is_empty() {
            return Ok(0.0);
        }

        let avg_sentence_length = words.len() as f64 / sentences.len() as f64;
        let avg_word_length: f64 = words.iter()
            .map(|w| w.len() as f64)
            .sum::<f64>() / words.len() as f64;

        // Age-based thresholds
        let (max_sentence_length, max_word_length) = match target_age_min {
            24..=48 => (8.0, 5.0),   // 2-4 years: simple sentences, short words
            49..=72 => (12.0, 6.0),  // 4-6 years: moderate sentences
            73..=96 => (15.0, 7.0),  // 6-8 years: longer sentences
            _ => (20.0, 8.0),        // 8+ years: complex content
        };

        // Calculate appropriateness score (0-100)
        let sentence_score = if avg_sentence_length <= max_sentence_length { 1.0 } 
                           else { max_sentence_length / avg_sentence_length };
        
        let word_score = if avg_word_length <= max_word_length { 1.0 }
                        else { max_word_length / avg_word_length };

        let score = ((sentence_score + word_score) / 2.0 * 100.0).min(100.0);

        Ok(score)
    }

    // =============================================================================
    // ACTIVITY-SPECIFIC VALIDATION
    // =============================================================================

    fn validate_matching_activities(&self, activities: &[Value]) -> AppResult<()> {
        for (idx, activity) in activities.iter().enumerate() {
            let left_items = activity.get("left_items")
                .and_then(|l| l.as_array())
                .ok_or_else(|| AppError::BadRequest(
                    format!("Matching activity {} missing left_items", idx + 1)
                ))?;

            let right_items = activity.get("right_items")
                .and_then(|r| r.as_array())
                .ok_or_else(|| AppError::BadRequest(
                    format!("Matching activity {} missing right_items", idx + 1)
                ))?;

            if left_items.len() != right_items.len() {
                return Err(AppError::BadRequest(
                    format!("Matching activity {} has mismatched item counts", idx + 1)
                ));
            }

            if left_items.len() > 10 {
                return Err(AppError::BadRequest(
                    format!("Matching activity {} has too many items (max 10)", idx + 1)
                ));
            }

            // Validate item content
            for item in left_items.iter().chain(right_items.iter()) {
                if let Some(text) = item.get("text").and_then(|t| t.as_str()) {
                    self.check_inappropriate_language(text)?;
                }
            }
        }

        Ok(())
    }

    fn validate_counting_activities(&self, activities: &[Value]) -> AppResult<()> {
        for (idx, activity) in activities.iter().enumerate() {
            let count = activity.get("target_count")
                .and_then(|c| c.as_u64())
                .ok_or_else(|| AppError::BadRequest(
                    format!("Counting activity {} missing target_count", idx + 1)
                ))?;

            if count == 0 || count > 100 {
                return Err(AppError::BadRequest(
                    format!("Counting activity {} has invalid count (1-100)", idx + 1)
                ));
            }

            if let Some(instruction) = activity.get("instruction").and_then(|i| i.as_str()) {
                self.check_inappropriate_language(instruction)?;
            }
        }

        Ok(())
    }

    fn validate_sorting_activities(&self, activities: &[Value]) -> AppResult<()> {
        for (idx, activity) in activities.iter().enumerate() {
            let items = activity.get("items")
                .and_then(|i| i.as_array())
                .ok_or_else(|| AppError::BadRequest(
                    format!("Sorting activity {} missing items", idx + 1)
                ))?;

            if items.len() < 3 || items.len() > 15 {
                return Err(AppError::BadRequest(
                    format!("Sorting activity {} must have 3-15 items", idx + 1)
                ));
            }

            let categories = activity.get("categories")
                .and_then(|c| c.as_array())
                .ok_or_else(|| AppError::BadRequest(
                    format!("Sorting activity {} missing categories", idx + 1)
                ))?;

            if categories.len() < 2 || categories.len() > 5 {
                return Err(AppError::BadRequest(
                    format!("Sorting activity {} must have 2-5 categories", idx + 1)
                ));
            }

            // Validate item and category content
            for item in items {
                if let Some(text) = item.get("text").and_then(|t| t.as_str()) {
                    self.check_inappropriate_language(text)?;
                }
            }

            for category in categories {
                if let Some(text) = category.get("name").and_then(|t| t.as_str()) {
                    self.check_inappropriate_language(text)?;
                }
            }
        }

        Ok(())
    }

    // =============================================================================
    // HELPER METHODS
    // =============================================================================

    fn load_inappropriate_words() -> HashSet<String> {
        // This would typically be loaded from a configuration file or database
        // For now, we'll use a basic set for demonstration
        let mut words = HashSet::new();
        
        // Add basic inappropriate words (this is a very minimal list for demo purposes)
        let basic_inappropriate = vec![
            "hate", "stupid", "dumb", "kill", "die", "death", "blood", "violence", 
            "scary", "nightmare", "monster", "ghost", "demon", "devil"
        ];
        
        for word in basic_inappropriate {
            words.insert(word.to_string());
        }
        
        words
    }
}

impl Default for ContentValidator {
    fn default() -> Self {
        Self::new()
    }
}