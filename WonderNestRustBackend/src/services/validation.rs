use regex::Regex;
use crate::models::{SignupRequest, LoginRequest, MessageResponse};

#[derive(Debug, Clone)]
pub struct ValidationResult {
    pub is_valid: bool,
    pub errors: Vec<String>,
}

impl ValidationResult {
    pub fn success() -> Self {
        Self {
            is_valid: true,
            errors: vec![],
        }
    }

    pub fn failure(error: String) -> Self {
        Self {
            is_valid: false,
            errors: vec![error],
        }
    }

    pub fn combine(results: Vec<ValidationResult>) -> Self {
        let mut all_errors = Vec::new();
        let mut is_valid = true;

        for result in results {
            if !result.is_valid {
                is_valid = false;
                all_errors.extend(result.errors);
            }
        }

        Self {
            is_valid,
            errors: all_errors,
        }
    }
}

pub struct ValidationService;

impl ValidationService {
    pub fn new() -> Self {
        Self
    }

    // Validate signup request (matching Kotlin AuthValidation exactly)
    pub fn validate_signup_request(&self, request: &SignupRequest) -> ValidationResult {
        let mut validations = Vec::new();

        // Email validation
        if !self.is_valid_email(&request.email) {
            validations.push(ValidationResult::failure("Invalid email format".to_string()));
        }

        // Password validation
        validations.push(self.validate_password(&request.password));

        // First name validation (optional)
        if let Some(first_name) = &request.first_name {
            validations.push(self.validate_string_length(
                first_name,
                "First name",
                1,
                50,
                false,
            ));
        }

        // Last name validation (optional)
        if let Some(last_name) = &request.last_name {
            validations.push(self.validate_string_length(
                last_name,
                "Last name",
                1,
                50,
                false,
            ));
        }

        // Timezone validation
        if !self.is_valid_timezone(&request.timezone) {
            validations.push(ValidationResult::failure("Invalid timezone".to_string()));
        }

        // Language validation
        if !self.is_valid_language_code(&request.language) {
            validations.push(ValidationResult::failure("Invalid language code".to_string()));
        }

        ValidationResult::combine(validations)
    }

    // Validate login request (matching Kotlin AuthValidation exactly)
    pub fn validate_login_request(&self, request: &LoginRequest) -> ValidationResult {
        let mut validations = Vec::new();

        // Email validation
        if !self.is_valid_email(&request.email) {
            validations.push(ValidationResult::failure("Invalid email format".to_string()));
        }

        // Password presence check (don't validate strength for login)
        if request.password.is_empty() {
            validations.push(ValidationResult::failure("Password is required".to_string()));
        }

        ValidationResult::combine(validations)
    }

    // Sanitize signup request (matching Kotlin AuthValidation exactly)
    pub fn sanitize_signup_request(&self, request: SignupRequest) -> SignupRequest {
        SignupRequest {
            email: request.email.trim().to_lowercase(),
            password: request.password, // Don't sanitize password
            name: request.name.map(|s| self.sanitize_string(&s)),
            first_name: request.first_name.map(|s| self.sanitize_string(&s)),
            last_name: request.last_name.map(|s| self.sanitize_string(&s)),
            phone_number: request.phone_number.map(|s| s.trim().to_string()),
            country_code: request.country_code.trim().to_string(),
            timezone: request.timezone.trim().to_string(),
            language: request.language.trim().to_lowercase(),
        }
    }

    // Sanitize login request (matching Kotlin AuthValidation exactly)
    pub fn sanitize_login_request(&self, request: LoginRequest) -> LoginRequest {
        LoginRequest {
            email: request.email.trim().to_lowercase(),
            password: request.password, // Don't sanitize password
        }
    }

    // Email validation (matching Kotlin isValidEmail exactly)
    fn is_valid_email(&self, email: &str) -> bool {
        email.contains("@") && email.contains(".") && email.len() >= 5
    }

    // Password validation (matching Kotlin validatePassword exactly)
    fn validate_password(&self, password: &str) -> ValidationResult {
        if password.len() < 8 {
            return ValidationResult::failure("Password must be at least 8 characters long".to_string());
        }
        
        if !password.chars().any(|c| c.is_ascii_digit()) {
            return ValidationResult::failure("Password must contain at least one digit".to_string());
        }
        
        if !password.chars().any(|c| c.is_ascii_uppercase()) {
            return ValidationResult::failure("Password must contain at least one uppercase letter".to_string());
        }
        
        if !password.chars().any(|c| c.is_ascii_lowercase()) {
            return ValidationResult::failure("Password must contain at least one lowercase letter".to_string());
        }

        ValidationResult::success()
    }

    // String length validation
    fn validate_string_length(
        &self,
        value: &str,
        field_name: &str,
        min_length: usize,
        max_length: usize,
        required: bool,
    ) -> ValidationResult {
        let trimmed = value.trim();
        
        if trimmed.is_empty() && required {
            return ValidationResult::failure(format!("{} is required", field_name));
        }
        
        if !trimmed.is_empty() {
            if trimmed.len() < min_length {
                return ValidationResult::failure(format!("{} must be at least {} characters", field_name, min_length));
            }
            
            if trimmed.len() > max_length {
                return ValidationResult::failure(format!("{} must be at most {} characters", field_name, max_length));
            }
        }

        ValidationResult::success()
    }

    // Timezone validation (basic check - matching Kotlin pattern)
    fn is_valid_timezone(&self, timezone: &str) -> bool {
        // Basic timezone validation - accept UTC, standard formats
        matches!(timezone, "UTC" | "GMT") || 
        timezone.contains("/") || // Like "America/New_York"
        timezone.starts_with("GMT") || // Like "GMT+5"
        timezone.starts_with("UTC") // Like "UTC-8"
    }

    // Language code validation (basic check - matching Kotlin pattern)
    fn is_valid_language_code(&self, language: &str) -> bool {
        // Accept common language codes
        language.len() >= 2 && language.len() <= 5 && language.chars().all(|c| c.is_ascii_alphabetic() || c == '-')
    }

    // String sanitization (basic HTML/XSS prevention)
    fn sanitize_string(&self, input: &str) -> String {
        input
            .trim()
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("&", "&amp;")
            .replace("\"", "&quot;")
            .replace("'", "&#x27;")
    }
}

// Custom exception for validation errors (matching Kotlin AuthValidationException)
#[derive(Debug, thiserror::Error)]
#[error("Validation failed: {message}")]
pub struct AuthValidationException {
    pub message: String,
    pub validation_errors: Vec<String>,
}

impl AuthValidationException {
    pub fn new(message: String, errors: Vec<String>) -> Self {
        Self {
            message,
            validation_errors: errors,
        }
    }

    pub fn to_message_response(&self) -> MessageResponse {
        MessageResponse {
            message: self.message.clone(),
        }
    }
}

// Extension trait to throw validation exception if validation fails
pub trait ValidationResultExt {
    fn throw_if_invalid(self) -> Result<(), AuthValidationException>;
}

impl ValidationResultExt for ValidationResult {
    fn throw_if_invalid(self) -> Result<(), AuthValidationException> {
        if !self.is_valid {
            let message = format!("Validation failed: {}", self.errors.join(", "));
            Err(AuthValidationException::new(message, self.errors))
        } else {
            Ok(())
        }
    }
}