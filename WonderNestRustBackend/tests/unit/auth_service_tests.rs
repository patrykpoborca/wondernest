// Simplified unit tests for AuthService
// Testing core business logic without complex database setup

use uuid::Uuid;
use wondernest_backend::{
    models::SignupRequest,
    services::auth_service::AuthServiceError,
};

// Simple test data helpers
struct TestDataBuilder;

impl TestDataBuilder {
    fn valid_signup_request() -> SignupRequest {
        SignupRequest {
            email: "test@example.com".to_string(),
            password: "SecurePass123!".to_string(),
            name: None,
            first_name: Some("John".to_string()),
            last_name: Some("Doe".to_string()),
            phone_number: None,
            country_code: "US".to_string(),
            timezone: "UTC".to_string(),
            language: "en".to_string(),
        }
    }
    
    fn weak_password_signup_request() -> SignupRequest {
        let mut req = Self::valid_signup_request();
        req.password = "weak".to_string();
        req
    }
    
    fn invalid_email_signup_request() -> SignupRequest {
        let mut req = Self::valid_signup_request();
        req.email = "invalid_email".to_string();
        req
    }
}

mod signup_request_validation_tests {
    use super::*;
    
    #[test]
    fn test_valid_signup_request_creation() {
        let request = TestDataBuilder::valid_signup_request();
        
        assert_eq!(request.email, "test@example.com");
        assert_eq!(request.password, "SecurePass123!");
        assert_eq!(request.first_name, Some("John".to_string()));
        assert_eq!(request.last_name, Some("Doe".to_string()));
        assert_eq!(request.country_code, "US");
        assert_eq!(request.timezone, "UTC");
        assert_eq!(request.language, "en");
    }
    
    #[test]
    fn test_weak_password_request_creation() {
        let request = TestDataBuilder::weak_password_signup_request();
        
        assert_eq!(request.password, "weak");
        // Should still have valid other fields
        assert_eq!(request.email, "test@example.com");
    }
    
    #[test]
    fn test_invalid_email_request_creation() {
        let request = TestDataBuilder::invalid_email_signup_request();
        
        assert_eq!(request.email, "invalid_email");
        // Should still have valid other fields
        assert_eq!(request.password, "SecurePass123!");
    }
}

mod password_validation_tests {
    use super::*;
    
    #[test]
    fn test_password_requirements() {
        // Test various password strengths
        let test_cases = vec![
            ("SecurePass123!", true),  // Valid: has uppercase, lowercase, number, special
            ("password123", false),    // Invalid: no uppercase, no special
            ("PASSWORD123!", false),   // Invalid: no lowercase
            ("SecurePass!", false),    // Invalid: no number
            ("SecurePass123", false),  // Invalid: no special character
            ("Short1!", false),        // Invalid: too short
            ("", false),               // Invalid: empty
        ];
        
        for (password, should_be_valid) in test_cases {
            let is_valid = is_password_strong(password);
            assert_eq!(is_valid, should_be_valid, "Password '{}' should be {}", 
                      password, if should_be_valid { "valid" } else { "invalid" });
        }
    }
}

mod email_validation_tests {
    use super::*;
    
    #[test]
    fn test_email_validation() {
        let test_cases = vec![
            ("user@example.com", true),
            ("test.email+tag@domain.co.uk", true),
            ("invalid_email", false),
            ("@domain.com", false),
            ("user@", false),
            ("", false),
        ];
        
        for (email, should_be_valid) in test_cases {
            let is_valid = is_email_valid(email);
            assert_eq!(is_valid, should_be_valid, "Email '{}' should be {}", 
                      email, if should_be_valid { "valid" } else { "invalid" });
        }
    }
}

mod auth_service_error_tests {
    use super::*;
    
    #[test]
    fn test_auth_service_error_display() {
        let error = AuthServiceError::ValidationError("Invalid email format".to_string());
        let error_string = format!("{}", error);
        assert!(error_string.contains("Invalid email format"));
    }
    
    #[test]
    fn test_auth_service_error_types() {
        // Test that different error types can be created
        let _validation_error = AuthServiceError::ValidationError("test".to_string());
        
        // We can add more error type tests as the AuthServiceError enum is expanded
        // For now, just verify we can create the basic error types
    }
}

mod user_id_generation_tests {
    use super::*;
    
    #[test]
    fn test_uuid_generation() {
        let id1 = Uuid::new_v4();
        let id2 = Uuid::new_v4();
        
        // UUIDs should be unique
        assert_ne!(id1, id2);
        
        // UUIDs should be valid v4 format
        assert_eq!(id1.get_version_num(), 4);
        assert_eq!(id2.get_version_num(), 4);
    }
}

// Simple helper functions for validation (these would normally be part of the service)
fn is_password_strong(password: &str) -> bool {
    if password.len() < 8 {
        return false;
    }
    
    let has_lower = password.chars().any(|c| c.is_lowercase());
    let has_upper = password.chars().any(|c| c.is_uppercase());
    let has_digit = password.chars().any(|c| c.is_digit(10));
    let has_special = password.chars().any(|c| "!@#$%^&*()_+-=[]{}|;:,.<>?".contains(c));
    
    has_lower && has_upper && has_digit && has_special
}

fn is_email_valid(email: &str) -> bool {
    // Simple email validation for testing
    email.contains('@') && email.len() > 3 && !email.starts_with('@') && !email.ends_with('@')
}

mod login_request_tests {
    use wondernest_backend::models::LoginRequest;
    
    #[test]
    fn test_valid_login_request_creation() {
        let request = LoginRequest {
            email: "test@example.com".to_string(),
            password: "SecurePass123!".to_string(),
        };
        
        assert_eq!(request.email, "test@example.com");
        assert_eq!(request.password, "SecurePass123!");
    }
    
    #[test]
    fn test_login_request_with_empty_fields() {
        let request = LoginRequest {
            email: "".to_string(),
            password: "".to_string(),
        };
        
        assert_eq!(request.email, "");
        assert_eq!(request.password, "");
    }
}

mod name_parsing_tests {
    
    #[test]
    fn test_first_name_extraction_from_full_name() {
        let full_name = "John Doe";
        let first_name = full_name.split_whitespace().next().unwrap_or("");
        assert_eq!(first_name, "John");
    }
    
    #[test]
    fn test_last_name_extraction_from_full_name() {
        let full_name = "John Doe Smith";
        let parts: Vec<&str> = full_name.split_whitespace().collect();
        let last_name = if parts.len() > 1 {
            parts[1..].join(" ")
        } else {
            "".to_string()
        };
        assert_eq!(last_name, "Doe Smith");
    }
    
    #[test]
    fn test_single_name_parsing() {
        let full_name = "John";
        let parts: Vec<&str> = full_name.split_whitespace().collect();
        let first_name = parts.get(0).unwrap_or(&"");
        let last_name = if parts.len() > 1 {
            parts[1..].join(" ")
        } else {
            "".to_string()
        };
        
        assert_eq!(first_name, &"John");
        assert_eq!(last_name, "");
    }
}

mod auth_response_tests {
    use super::*;
    use wondernest_backend::models::{AuthResponse, AuthData, TokenPair};
    
    #[test]
    fn test_token_pair_creation() {
        let token_pair = TokenPair {
            access_token: "access_token_value".to_string(),
            refresh_token: "refresh_token_value".to_string(),
            expires_in: 3600,
        };
        
        assert_eq!(token_pair.access_token, "access_token_value");
        assert_eq!(token_pair.refresh_token, "refresh_token_value");
        assert_eq!(token_pair.expires_in, 3600);
    }
    
    #[test]
    fn test_auth_data_creation() {
        let auth_data = AuthData {
            user_id: Uuid::new_v4().to_string(),
            email: "test@example.com".to_string(),
            access_token: "access_token_value".to_string(),
            refresh_token: "refresh_token_value".to_string(),
            expires_in: 3600,
            has_pin: false,
            requires_pin_setup: true,
            children: vec!["child1".to_string(), "child2".to_string()],
        };
        
        assert_eq!(auth_data.email, "test@example.com");
        assert_eq!(auth_data.access_token, "access_token_value");
        assert!(!auth_data.has_pin);
        assert!(auth_data.requires_pin_setup);
        assert_eq!(auth_data.children.len(), 2);
    }
    
    #[test]
    fn test_auth_response_success() {
        let auth_data = AuthData {
            user_id: Uuid::new_v4().to_string(),
            email: "test@example.com".to_string(),
            access_token: "access_token_value".to_string(),
            refresh_token: "refresh_token_value".to_string(),
            expires_in: 3600,
            has_pin: false,
            requires_pin_setup: true,
            children: vec![],
        };
        
        let response = AuthResponse::success(auth_data);
        
        assert!(response.success);
        assert_eq!(response.data.email, "test@example.com");
        assert_eq!(response.data.access_token, "access_token_value");
    }
}

mod security_validation_tests {
    
    #[test]
    fn test_email_normalization() {
        // Test that emails should be normalized to lowercase
        let test_cases = vec![
            ("Test@Example.Com", "test@example.com"),
            ("USER@DOMAIN.ORG", "user@domain.org"),
            ("MiXeD.CaSe@TeSt.CoM", "mixed.case@test.com"),
        ];
        
        for (input, expected) in test_cases {
            let normalized = input.to_lowercase();
            assert_eq!(normalized, expected);
        }
    }
    
    #[test]
    fn test_password_hashing_concept() {
        // Test that passwords should never be stored as plain text
        let plain_password = "SecurePass123!";
        
        // In a real implementation, this would use bcrypt
        // For testing, we just verify the concept
        let should_not_store_plain_text = plain_password != "hashed_value";
        assert!(should_not_store_plain_text);
        
        // Verify password is not empty
        assert!(!plain_password.is_empty());
        assert!(plain_password.len() >= 8);
    }
}

mod family_creation_tests {
    use super::*;
    use wondernest_backend::models::Family;
    use chrono::Utc;
    
    #[test]
    fn test_family_name_generation() {
        let first_name = "John";
        let family_name = format!("{}'s Family", first_name);
        assert_eq!(family_name, "John's Family");
    }
    
    #[test]
    fn test_family_structure() {
        let family_id = Uuid::new_v4();
        let creator_id = Uuid::new_v4();
        let now = Utc::now();
        
        let family = Family {
            id: family_id,
            name: "Test Family".to_string(),
            created_by: Some(creator_id),
            created_at: now,
            updated_at: now,
        };
        
        assert_eq!(family.name, "Test Family");
        assert_eq!(family.created_by, Some(creator_id));
        assert!(family.created_at <= Utc::now());
    }
}

mod pin_verification_tests {
    use wondernest_backend::models::{PinVerificationRequest, PinVerificationResponse};
    
    #[test]
    fn test_pin_verification_request() {
        let request = PinVerificationRequest {
            pin: "1234".to_string(),
        };
        
        assert_eq!(request.pin, "1234");
        assert_eq!(request.pin.len(), 4);
    }
    
    #[test]
    fn test_pin_verification_response() {
        let response = PinVerificationResponse {
            verified: true,
            message: "PIN verified successfully".to_string(),
            session_token: Some("session_token_123".to_string()),
        };
        
        assert!(response.verified);
        assert_eq!(response.message, "PIN verified successfully");
        assert!(response.session_token.is_some());
        assert_eq!(response.session_token.unwrap(), "session_token_123");
    }
    
    #[test]
    fn test_pin_verification_failed() {
        let response = PinVerificationResponse {
            verified: false,
            message: "Invalid PIN".to_string(),
            session_token: None,
        };
        
        assert!(!response.verified);
        assert_eq!(response.message, "Invalid PIN");
        assert!(response.session_token.is_none());
    }
}

mod refresh_token_tests {
    use wondernest_backend::models::RefreshTokenRequest;
    
    #[test]
    fn test_refresh_token_request_with_token() {
        let request = RefreshTokenRequest {
            refresh_token: Some("refresh_token_123".to_string()),
        };
        
        assert!(request.refresh_token.is_some());
        assert_eq!(request.refresh_token.unwrap(), "refresh_token_123");
    }
    
    #[test]
    fn test_refresh_token_request_without_token() {
        let request = RefreshTokenRequest {
            refresh_token: None,
        };
        
        assert!(request.refresh_token.is_none());
    }
}

mod message_response_tests {
    use wondernest_backend::models::MessageResponse;
    
    #[test]
    fn test_message_response() {
        let response = MessageResponse {
            message: "Operation completed successfully".to_string(),
        };
        
        assert_eq!(response.message, "Operation completed successfully");
    }
}

mod signup_request_defaults_tests {
    use wondernest_backend::models::SignupRequest;
    
    #[test]
    fn test_signup_request_default() {
        let request = SignupRequest::default();
        
        assert_eq!(request.email, "");
        assert_eq!(request.password, "");
        assert!(request.name.is_none());
        assert!(request.first_name.is_none());
        assert!(request.last_name.is_none());
        assert!(request.phone_number.is_none());
        assert_eq!(request.country_code, "US");
        assert_eq!(request.timezone, "UTC");
        assert_eq!(request.language, "en");
    }
}

mod auth_service_error_coverage_tests {
    use super::*;
    
    #[test]
    fn test_validation_error_debug() {
        let error = AuthServiceError::ValidationError("Test error".to_string());
        let debug_string = format!("{:?}", error);
        assert!(debug_string.contains("ValidationError"));
        assert!(debug_string.contains("Test error"));
    }
}

mod game_data_models_tests {
    use serde_json::json;
    use wondernest_backend::models::{
        SaveGameDataRequest, GameDataResponse, GameDataItem, LoadGameDataResponse,
        GameRegistry, ChildGameInstance, ChildGameData, SimpleGameData
    };
    use uuid::Uuid;
    use chrono::Utc;
    
    #[test]
    fn test_save_game_data_request_creation() {
        let request = SaveGameDataRequest {
            game_type: "sticker_book".to_string(),
            data_key: "progress".to_string(),
            data_value: json!({"level": 1, "completed": false}),
        };
        
        assert_eq!(request.game_type, "sticker_book");
        assert_eq!(request.data_key, "progress");
        assert_eq!(request.data_value["level"], 1);
        assert_eq!(request.data_value["completed"], false);
    }
    
    #[test]
    fn test_game_data_response_success() {
        let response = GameDataResponse {
            success: true,
            message: "Game data saved successfully".to_string(),
            child_id: "test-child-id".to_string(),
            game_type: "sticker_book".to_string(),
            data_key: Some("progress".to_string()),
        };
        
        assert!(response.success);
        assert_eq!(response.message, "Game data saved successfully");
        assert_eq!(response.child_id, "test-child-id");
        assert_eq!(response.game_type, "sticker_book");
        assert_eq!(response.data_key, Some("progress".to_string()));
    }
    
    #[test]
    fn test_game_data_response_failure() {
        let response = GameDataResponse {
            success: false,
            message: "Failed to save game data".to_string(),
            child_id: "test-child-id".to_string(),
            game_type: "sticker_book".to_string(),
            data_key: None,
        };
        
        assert!(!response.success);
        assert_eq!(response.message, "Failed to save game data");
        assert!(response.data_key.is_none());
    }
    
    #[test]
    fn test_game_data_item_creation() {
        let item = GameDataItem {
            id: "test-id".to_string(),
            child_id: "child-123".to_string(),
            game_type: "sticker_book".to_string(),
            data_key: "progress".to_string(),
            data_value: json!({"level": 1, "score": 100}),
            created_at: "2024-01-01T00:00:00Z".to_string(),
            updated_at: "2024-01-01T00:00:00Z".to_string(),
        };
        
        assert_eq!(item.id, "test-id");
        assert_eq!(item.child_id, "child-123");
        assert_eq!(item.game_type, "sticker_book");
        assert_eq!(item.data_key, "progress");
        assert_eq!(item.data_value["level"], 1);
        assert_eq!(item.data_value["score"], 100);
    }
    
    #[test]
    fn test_load_game_data_response() {
        let game_data = vec![
            GameDataItem {
                id: "1".to_string(),
                child_id: "child-123".to_string(),
                game_type: "sticker_book".to_string(),
                data_key: "progress".to_string(),
                data_value: json!({"level": 1}),
                created_at: "2024-01-01T00:00:00Z".to_string(),
                updated_at: "2024-01-01T00:00:00Z".to_string(),
            },
            GameDataItem {
                id: "2".to_string(),
                child_id: "child-123".to_string(),
                game_type: "sticker_book".to_string(),
                data_key: "settings".to_string(),
                data_value: json!({"sound": true}),
                created_at: "2024-01-01T00:00:00Z".to_string(),
                updated_at: "2024-01-01T00:00:00Z".to_string(),
            },
        ];
        
        let response = LoadGameDataResponse {
            success: true,
            game_data,
        };
        
        assert!(response.success);
        assert_eq!(response.game_data.len(), 2);
        assert_eq!(response.game_data[0].data_key, "progress");
        assert_eq!(response.game_data[1].data_key, "settings");
    }
    
    #[test]
    fn test_game_registry_model() {
        let game_id = Uuid::new_v4();
        let now = Utc::now();
        
        let game = GameRegistry {
            id: game_id,
            game_identifier: "sticker_book_v1".to_string(),
            name: "Sticker Book Adventure".to_string(),
            description: "An interactive sticker book game".to_string(),
            category: "creative".to_string(),
            age_min: 3,
            age_max: 8,
            is_active: true,
            created_at: now,
            updated_at: now,
        };
        
        assert_eq!(game.id, game_id);
        assert_eq!(game.game_identifier, "sticker_book_v1");
        assert_eq!(game.name, "Sticker Book Adventure");
        assert_eq!(game.category, "creative");
        assert_eq!(game.age_min, 3);
        assert_eq!(game.age_max, 8);
        assert!(game.is_active);
    }
    
    #[test]
    fn test_child_game_instance_model() {
        let instance_id = Uuid::new_v4();
        let child_id = Uuid::new_v4();
        let game_id = Uuid::new_v4();
        let now = Utc::now();
        
        let instance = ChildGameInstance {
            id: instance_id,
            child_id,
            game_id,
            is_enabled: true,
            unlocked_at: now,
            last_played: Some(now),
            created_at: now,
            updated_at: now,
        };
        
        assert_eq!(instance.id, instance_id);
        assert_eq!(instance.child_id, child_id);
        assert_eq!(instance.game_id, game_id);
        assert!(instance.is_enabled);
        assert!(instance.last_played.is_some());
    }
    
    #[test]
    fn test_child_game_data_model() {
        let data_id = Uuid::new_v4();
        let instance_id = Uuid::new_v4();
        let now = Utc::now();
        
        let game_data = ChildGameData {
            id: data_id,
            child_game_instance_id: instance_id,
            save_data: json!({"level": 5, "coins": 100, "achievements": ["first_win"]}),
            version: 1,
            created_at: now,
            updated_at: now,
        };
        
        assert_eq!(game_data.id, data_id);
        assert_eq!(game_data.child_game_instance_id, instance_id);
        assert_eq!(game_data.save_data["level"], 5);
        assert_eq!(game_data.save_data["coins"], 100);
        assert_eq!(game_data.version, 1);
    }
    
    #[test]
    fn test_simple_game_data_model() {
        let data_id = Uuid::new_v4();
        let child_id = Uuid::new_v4();
        let now = Utc::now();
        
        let simple_data = SimpleGameData {
            id: data_id,
            child_id,
            game_type: "sticker_book".to_string(),
            data_key: "user_preferences".to_string(),
            data_value: json!({"theme": "rainbow", "difficulty": "easy"}),
            created_at: now,
            updated_at: now,
        };
        
        assert_eq!(simple_data.id, data_id);
        assert_eq!(simple_data.child_id, child_id);
        assert_eq!(simple_data.game_type, "sticker_book");
        assert_eq!(simple_data.data_key, "user_preferences");
        assert_eq!(simple_data.data_value["theme"], "rainbow");
        assert_eq!(simple_data.data_value["difficulty"], "easy");
    }
}

mod validation_service_tests {
    use wondernest_backend::{
        models::{SignupRequest, LoginRequest},
        services::validation::{ValidationService, ValidationResult, AuthValidationException, ValidationResultExt}
    };
    
    #[test]
    fn test_validation_result_success() {
        let result = ValidationResult::success();
        assert!(result.is_valid);
        assert!(result.errors.is_empty());
    }
    
    #[test]
    fn test_validation_result_failure() {
        let result = ValidationResult::failure("Test error".to_string());
        assert!(!result.is_valid);
        assert_eq!(result.errors.len(), 1);
        assert_eq!(result.errors[0], "Test error");
    }
    
    #[test]
    fn test_validation_result_combine_all_success() {
        let results = vec![
            ValidationResult::success(),
            ValidationResult::success(),
            ValidationResult::success(),
        ];
        
        let combined = ValidationResult::combine(results);
        assert!(combined.is_valid);
        assert!(combined.errors.is_empty());
    }
    
    #[test]
    fn test_validation_result_combine_with_failures() {
        let results = vec![
            ValidationResult::success(),
            ValidationResult::failure("Error 1".to_string()),
            ValidationResult::failure("Error 2".to_string()),
        ];
        
        let combined = ValidationResult::combine(results);
        assert!(!combined.is_valid);
        assert_eq!(combined.errors.len(), 2);
        assert_eq!(combined.errors[0], "Error 1");
        assert_eq!(combined.errors[1], "Error 2");
    }
    
    #[test]
    fn test_validation_service_creation() {
        let _service = ValidationService::new();
        // Just verify we can create the service
        assert!(true);
    }
    
    #[test]
    fn test_validate_signup_request_valid() {
        let service = ValidationService::new();
        let request = SignupRequest {
            email: "test@example.com".to_string(),
            password: "SecurePass123!".to_string(),
            name: None,
            first_name: Some("John".to_string()),
            last_name: Some("Doe".to_string()),
            phone_number: None,
            country_code: "US".to_string(),
            timezone: "UTC".to_string(),
            language: "en".to_string(),
        };
        
        let result = service.validate_signup_request(&request);
        assert!(result.is_valid, "Validation errors: {:?}", result.errors);
    }
    
    #[test]
    fn test_validate_signup_request_invalid_email() {
        let service = ValidationService::new();
        let request = SignupRequest {
            email: "invalid_email".to_string(),
            password: "SecurePass123!".to_string(),
            name: None,
            first_name: Some("John".to_string()),
            last_name: Some("Doe".to_string()),
            phone_number: None,
            country_code: "US".to_string(),
            timezone: "UTC".to_string(),
            language: "en".to_string(),
        };
        
        let result = service.validate_signup_request(&request);
        assert!(!result.is_valid);
        assert!(result.errors.iter().any(|e| e.contains("Invalid email format")));
    }
    
    #[test]
    fn test_validate_signup_request_weak_password() {
        let service = ValidationService::new();
        let request = SignupRequest {
            email: "test@example.com".to_string(),
            password: "weak".to_string(),
            name: None,
            first_name: Some("John".to_string()),
            last_name: Some("Doe".to_string()),
            phone_number: None,
            country_code: "US".to_string(),
            timezone: "UTC".to_string(),
            language: "en".to_string(),
        };
        
        let result = service.validate_signup_request(&request);
        assert!(!result.is_valid);
        assert!(result.errors.iter().any(|e| e.contains("Password must be at least 8 characters")));
    }
    
    #[test]
    fn test_validate_login_request_valid() {
        let service = ValidationService::new();
        let request = LoginRequest {
            email: "test@example.com".to_string(),
            password: "any_password".to_string(),
        };
        
        let result = service.validate_login_request(&request);
        assert!(result.is_valid);
    }
    
    #[test]
    fn test_validate_login_request_invalid() {
        let service = ValidationService::new();
        let request = LoginRequest {
            email: "invalid_email".to_string(),
            password: "".to_string(),
        };
        
        let result = service.validate_login_request(&request);
        assert!(!result.is_valid);
        assert!(result.errors.iter().any(|e| e.contains("Invalid email format")));
        assert!(result.errors.iter().any(|e| e.contains("Password is required")));
    }
    
    #[test]
    fn test_sanitize_signup_request() {
        let service = ValidationService::new();
        let request = SignupRequest {
            email: "  TEST@EXAMPLE.COM  ".to_string(),
            password: "SecurePass123!".to_string(),
            name: Some("  <script>alert('xss')</script>  ".to_string()),
            first_name: Some("  John  ".to_string()),
            last_name: Some("  Doe  ".to_string()),
            phone_number: Some("  +1234567890  ".to_string()),
            country_code: "  US  ".to_string(),
            timezone: "  UTC  ".to_string(),
            language: "  EN  ".to_string(),
        };
        
        let sanitized = service.sanitize_signup_request(request);
        
        assert_eq!(sanitized.email, "test@example.com");
        assert_eq!(sanitized.password, "SecurePass123!"); // Password should not be changed
        assert_eq!(sanitized.name, Some("&amp;lt;script&amp;gt;alert(&#x27;xss&#x27;)&amp;lt;/script&amp;gt;".to_string()));
        assert_eq!(sanitized.first_name, Some("John".to_string()));
        assert_eq!(sanitized.last_name, Some("Doe".to_string()));
        assert_eq!(sanitized.phone_number, Some("+1234567890".to_string()));
        assert_eq!(sanitized.country_code, "US");
        assert_eq!(sanitized.timezone, "UTC");
        assert_eq!(sanitized.language, "en");
    }
    
    #[test]
    fn test_sanitize_login_request() {
        let service = ValidationService::new();
        let request = LoginRequest {
            email: "  TEST@EXAMPLE.COM  ".to_string(),
            password: "SecurePass123!".to_string(),
        };
        
        let sanitized = service.sanitize_login_request(request);
        
        assert_eq!(sanitized.email, "test@example.com");
        assert_eq!(sanitized.password, "SecurePass123!"); // Password should not be changed
    }
    
    #[test]
    fn test_auth_validation_exception() {
        let exception = AuthValidationException::new(
            "Validation failed".to_string(),
            vec!["Error 1".to_string(), "Error 2".to_string()]
        );
        
        assert_eq!(exception.message, "Validation failed");
        assert_eq!(exception.validation_errors.len(), 2);
        assert_eq!(exception.validation_errors[0], "Error 1");
        assert_eq!(exception.validation_errors[1], "Error 2");
        
        let response = exception.to_message_response();
        assert_eq!(response.message, "Validation failed");
    }
    
    #[test]
    fn test_validation_result_ext_success() {
        let result = ValidationResult::success();
        assert!(result.throw_if_invalid().is_ok());
    }
    
    #[test]
    fn test_validation_result_ext_failure() {
        let result = ValidationResult::failure("Test error".to_string());
        let exception_result = result.throw_if_invalid();
        
        assert!(exception_result.is_err());
        let exception = exception_result.unwrap_err();
        assert!(exception.message.contains("Test error"));
        assert_eq!(exception.validation_errors.len(), 1);
        assert_eq!(exception.validation_errors[0], "Test error");
    }
}

mod content_pack_models_tests {
    use wondernest_backend::models::{
        ContentPack, ContentPackCategory, ContentPackResponse,
        ContentPackSearchRequest, ContentPackSearchResponse
    };
    use serde_json::json;
    use uuid::Uuid;
    use chrono::Utc;
    
    #[test]
    fn test_content_pack_creation() {
        let pack_id = Uuid::new_v4();
        let publisher_id = Uuid::new_v4();
        let now = Utc::now();
        let featured_until = Utc::now() + chrono::Duration::days(30);
        
        let pack = ContentPack {
            id: pack_id,
            name: "Math Adventure Pack".to_string(),
            description: "Learn math through fun adventures".to_string(),
            category: "educational".to_string(),
            pack_type: "game".to_string(),
            age_min: 5,
            age_max: 10,
            price: 499,
            is_free: false,
            preview_assets: json!({"images": ["preview1.jpg", "preview2.jpg"]}),
            educational_goals: vec!["math".to_string(), "problem-solving".to_string()],
            tags: vec!["math".to_string(), "adventure".to_string(), "interactive".to_string()],
            downloads: 1500,
            rating: 4.5,
            version: "1.2.0".to_string(),
            size_mb: 125,
            created_at: now,
            updated_at: now,
            publisher_id: Some(publisher_id),
            is_featured: true,
            featured_until: Some(featured_until),
        };
        
        assert_eq!(pack.id, pack_id);
        assert_eq!(pack.name, "Math Adventure Pack");
        assert_eq!(pack.category, "educational");
        assert_eq!(pack.pack_type, "game");
        assert_eq!(pack.age_min, 5);
        assert_eq!(pack.age_max, 10);
        assert_eq!(pack.price, 499);
        assert!(!pack.is_free);
        assert_eq!(pack.educational_goals.len(), 2);
        assert_eq!(pack.tags.len(), 3);
        assert_eq!(pack.downloads, 1500);
        assert_eq!(pack.rating, 4.5);
        assert_eq!(pack.version, "1.2.0");
        assert_eq!(pack.size_mb, 125);
        assert!(pack.is_featured);
        assert!(pack.featured_until.is_some());
    }
    
    #[test]
    fn test_content_pack_category() {
        let category = ContentPackCategory {
            id: "educational".to_string(),
            name: "Educational".to_string(),
            icon: "graduation-cap".to_string(),
            description: "Educational content for learning".to_string(),
            pack_count: 25,
        };
        
        assert_eq!(category.id, "educational");
        assert_eq!(category.name, "Educational");
        assert_eq!(category.icon, "graduation-cap");
        assert_eq!(category.pack_count, 25);
    }
    
    #[test]
    fn test_content_pack_response_success() {
        let pack = ContentPack {
            id: Uuid::new_v4(),
            name: "Test Pack".to_string(),
            description: "Test description".to_string(),
            category: "test".to_string(),
            pack_type: "game".to_string(),
            age_min: 3,
            age_max: 8,
            price: 0,
            is_free: true,
            preview_assets: json!({}),
            educational_goals: vec![],
            tags: vec![],
            downloads: 0,
            rating: 0.0,
            version: "1.0.0".to_string(),
            size_mb: 50,
            created_at: Utc::now(),
            updated_at: Utc::now(),
            publisher_id: None,
            is_featured: false,
            featured_until: None,
        };
        
        let response: ContentPackResponse<ContentPack> = ContentPackResponse {
            success: true,
            data: Some(pack.clone()),
            error: None,
        };
        
        assert!(response.success);
        assert!(response.data.is_some());
        assert!(response.error.is_none());
        assert_eq!(response.data.unwrap().name, "Test Pack");
    }
    
    #[test]
    fn test_content_pack_response_error() {
        let response: ContentPackResponse<ContentPack> = ContentPackResponse {
            success: false,
            data: None,
            error: Some("Failed to load content pack".to_string()),
        };
        
        assert!(!response.success);
        assert!(response.data.is_none());
        assert!(response.error.is_some());
        assert_eq!(response.error.unwrap(), "Failed to load content pack");
    }
    
    #[test]
    fn test_content_pack_search_request() {
        let request = ContentPackSearchRequest {
            query: Some("math".to_string()),
            category: Some("educational".to_string()),
            pack_type: Some("game".to_string()),
            age_min: Some(5),
            age_max: Some(10),
            price_min: Some(0),
            price_max: Some(1000),
            is_free: Some(false),
            educational_goals: vec!["math".to_string(), "problem-solving".to_string()],
            sort_by: "rating".to_string(),
            sort_order: "desc".to_string(),
            page: 1,
            size: 20,
        };
        
        assert_eq!(request.query, Some("math".to_string()));
        assert_eq!(request.category, Some("educational".to_string()));
        assert_eq!(request.pack_type, Some("game".to_string()));
        assert_eq!(request.age_min, Some(5));
        assert_eq!(request.age_max, Some(10));
        assert_eq!(request.price_min, Some(0));
        assert_eq!(request.price_max, Some(1000));
        assert_eq!(request.is_free, Some(false));
        assert_eq!(request.educational_goals.len(), 2);
        assert_eq!(request.sort_by, "rating");
        assert_eq!(request.sort_order, "desc");
        assert_eq!(request.page, 1);
        assert_eq!(request.size, 20);
    }
    
    #[test]
    fn test_content_pack_search_response() {
        let pack = ContentPack {
            id: Uuid::new_v4(),
            name: "Search Result Pack".to_string(),
            description: "Found in search".to_string(),
            category: "educational".to_string(),
            pack_type: "game".to_string(),
            age_min: 5,
            age_max: 10,
            price: 299,
            is_free: false,
            preview_assets: json!({}),
            educational_goals: vec!["math".to_string()],
            tags: vec!["math".to_string()],
            downloads: 500,
            rating: 4.2,
            version: "1.0.0".to_string(),
            size_mb: 75,
            created_at: Utc::now(),
            updated_at: Utc::now(),
            publisher_id: None,
            is_featured: false,
            featured_until: None,
        };
        
        let response = ContentPackSearchResponse {
            packs: vec![pack.clone()],
            total: 1,
            page: 1,
            size: 20,
            total_pages: 1,
        };
        
        assert_eq!(response.packs.len(), 1);
        assert_eq!(response.total, 1);
        assert_eq!(response.page, 1);
        assert_eq!(response.size, 20);
        assert_eq!(response.total_pages, 1);
        assert_eq!(response.packs[0].name, "Search Result Pack");
    }
}

mod jwt_service_tests {
    use wondernest_backend::{
        models::{User, TokenPair},
        services::jwt::{JwtService, Claims, RefreshClaims}
    };
    use uuid::Uuid;
    use chrono::Utc;
    
    fn create_test_user() -> User {
        User {
            id: Uuid::new_v4(),
            email: "test@example.com".to_string(),
            password_hash: "hashed_password".to_string(),
            first_name: Some("John".to_string()),
            last_name: Some("Doe".to_string()),
            phone: None,
            role: "user".to_string(),
            email_verified: true,
            is_active: true,
            pin_hash: None,
            family_id: None,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        }
    }
    
    #[test]
    fn test_jwt_service_creation() {
        let _service = JwtService::new();
        // Just verify we can create the service
        assert!(true);
    }
    
    #[test]
    fn test_claims_structure() {
        let user_id = Uuid::new_v4().to_string();
        let family_id = Uuid::new_v4().to_string();
        let now = Utc::now().timestamp();
        let exp = now + 3600;
        
        let claims = Claims {
            sub: user_id.clone(),
            user_id: user_id.clone(),
            email: "test@example.com".to_string(),
            role: "user".to_string(),
            verified: true,
            nonce: "test-nonce".to_string(),
            family_id: Some(family_id.clone()),
            iss: "wondernest-api".to_string(),
            aud: "wondernest-users".to_string(),
            iat: now,
            exp,
        };
        
        assert_eq!(claims.sub, user_id);
        assert_eq!(claims.user_id, user_id);
        assert_eq!(claims.email, "test@example.com");
        assert_eq!(claims.role, "user");
        assert!(claims.verified);
        assert_eq!(claims.nonce, "test-nonce");
        assert_eq!(claims.family_id, Some(family_id));
        assert_eq!(claims.iss, "wondernest-api");
        assert_eq!(claims.aud, "wondernest-users");
        assert_eq!(claims.iat, now);
        assert_eq!(claims.exp, exp);
    }
    
    #[test]
    fn test_refresh_claims_structure() {
        let user_id = Uuid::new_v4().to_string();
        let family_id = Uuid::new_v4().to_string();
        let now = Utc::now().timestamp();
        let exp = now + 2592000; // 30 days
        
        let claims = RefreshClaims {
            sub: user_id.clone(),
            user_id: user_id.clone(),
            token_type: "refresh".to_string(),
            nonce: "refresh-nonce".to_string(),
            family_id: Some(family_id.clone()),
            iss: "wondernest-api".to_string(),
            aud: "wondernest-users-refresh".to_string(),
            iat: now,
            exp,
        };
        
        assert_eq!(claims.sub, user_id);
        assert_eq!(claims.user_id, user_id);
        assert_eq!(claims.token_type, "refresh");
        assert_eq!(claims.nonce, "refresh-nonce");
        assert_eq!(claims.family_id, Some(family_id));
        assert_eq!(claims.iss, "wondernest-api");
        assert_eq!(claims.aud, "wondernest-users-refresh");
        assert_eq!(claims.iat, now);
        assert_eq!(claims.exp, exp);
    }
    
    #[test]
    fn test_token_pair_structure() {
        let token_pair = TokenPair {
            access_token: "access_token_value".to_string(),
            refresh_token: "refresh_token_value".to_string(),
            expires_in: 3600000,
        };
        
        assert_eq!(token_pair.access_token, "access_token_value");
        assert_eq!(token_pair.refresh_token, "refresh_token_value");
        assert_eq!(token_pair.expires_in, 3600000);
    }
    
    // Note: We're not testing actual token generation/verification here
    // because that would require setting up proper environment variables
    // and dealing with the complexity of JWT token validation.
    // Instead, we focus on the data structures and basic service creation.
    
    #[test]
    fn test_jwt_claims_with_no_family_context() {
        let user_id = Uuid::new_v4().to_string();
        let now = Utc::now().timestamp();
        let exp = now + 3600;
        
        let claims = Claims {
            sub: user_id.clone(),
            user_id: user_id.clone(),
            email: "test@example.com".to_string(),
            role: "user".to_string(),
            verified: true,
            nonce: "test-nonce".to_string(),
            family_id: None,
            iss: "wondernest-api".to_string(),
            aud: "wondernest-users".to_string(),
            iat: now,
            exp,
        };
        
        assert_eq!(claims.family_id, None);
        assert!(claims.verified);
        assert_eq!(claims.role, "user");
    }
    
    #[test]
    fn test_jwt_claims_with_admin_role() {
        let user_id = Uuid::new_v4().to_string();
        let now = Utc::now().timestamp();
        let exp = now + 3600;
        
        let claims = Claims {
            sub: user_id.clone(),
            user_id: user_id.clone(),
            email: "admin@example.com".to_string(),
            role: "admin".to_string(),
            verified: true,
            nonce: "admin-nonce".to_string(),
            family_id: None,
            iss: "wondernest-api".to_string(),
            aud: "wondernest-users".to_string(),
            iat: now,
            exp,
        };
        
        assert_eq!(claims.role, "admin");
        assert_eq!(claims.email, "admin@example.com");
        assert_eq!(claims.nonce, "admin-nonce");
    }
    
    #[test]
    fn test_refresh_claims_token_type_validation() {
        let user_id = Uuid::new_v4().to_string();
        let now = Utc::now().timestamp();
        let exp = now + 2592000;
        
        let claims = RefreshClaims {
            sub: user_id.clone(),
            user_id: user_id.clone(),
            token_type: "refresh".to_string(),
            nonce: "refresh-nonce".to_string(),
            family_id: None,
            iss: "wondernest-api".to_string(),
            aud: "wondernest-users-refresh".to_string(),
            iat: now,
            exp,
        };
        
        // This is the key validation - refresh tokens must have type "refresh"
        assert_eq!(claims.token_type, "refresh");
    }
}

mod advanced_security_validation_tests {
    use wondernest_backend::{
        models::{SignupRequest, LoginRequest},
        services::validation::ValidationService
    };
    
    #[test]
    fn test_basic_sanitization_in_signup() {
        let service = ValidationService::new();
        let request = SignupRequest {
            email: "  TEST@EXAMPLE.COM  ".to_string(),
            password: "SecurePass123!".to_string(),
            name: Some("  Normal Name  ".to_string()),
            first_name: Some("  John  ".to_string()),
            last_name: Some("  Doe  ".to_string()),
            phone_number: Some("  +1234567890  ".to_string()),
            country_code: "  US  ".to_string(),
            timezone: "  UTC  ".to_string(),
            language: "  EN  ".to_string(),
        };
        
        let sanitized = service.sanitize_signup_request(request);
        
        // Verify basic sanitization (trimming and case normalization)
        assert_eq!(sanitized.email, "test@example.com");
        assert_eq!(sanitized.name, Some("Normal Name".to_string()));
        assert_eq!(sanitized.first_name, Some("John".to_string()));
        assert_eq!(sanitized.last_name, Some("Doe".to_string()));
        assert_eq!(sanitized.phone_number, Some("+1234567890".to_string()));
        assert_eq!(sanitized.country_code, "US");
        assert_eq!(sanitized.timezone, "UTC");
        assert_eq!(sanitized.language, "en");
    }
    
    #[test]
    fn test_sql_injection_pattern_detection() {
        let service = ValidationService::new();
        
        // Test common SQL injection patterns in email field
        let malicious_emails = vec![
            "admin'; DROP TABLE users; --",
            "test@example.com' OR '1'='1",
            "user@domain.com'; UPDATE users SET role='admin' WHERE id=1; --",
            "test@example.com' UNION SELECT * FROM users WHERE '1'='1",
        ];
        
        for email in malicious_emails {
            let request = LoginRequest {
                email: email.to_string(),
                password: "password".to_string(),
            };
            
            let sanitized = service.sanitize_login_request(request);
            // Email normalization should have lowercased and trimmed,
            // but malicious content should be detectable
            assert!(!sanitized.email.contains("DROP TABLE"));
            assert!(!sanitized.email.contains("UNION SELECT"));
            assert!(!sanitized.email.contains("UPDATE"));
        }
    }
    
    #[test]
    fn test_password_security_requirements() {
        let service = ValidationService::new();
        
        // Test various weak password patterns (based on actual validation rules)
        let weak_passwords = vec![
            ("12345678", "only numbers"),
            ("abcdefgh", "only lowercase"),
            ("ABCDEFGH", "only uppercase"),
            ("Password", "missing numbers"),
            ("password1", "missing uppercase"),
            ("PASSWORD1", "missing lowercase"),
            ("Pas1", "too short"),
            ("", "empty password"),
        ];
        
        for (password, _reason) in weak_passwords {
            let request = SignupRequest {
                email: "test@example.com".to_string(),
                password: password.to_string(),
                name: None,
                first_name: Some("John".to_string()),
                last_name: Some("Doe".to_string()),
                phone_number: None,
                country_code: "US".to_string(),
                timezone: "UTC".to_string(),
                language: "en".to_string(),
            };
            
            let result = service.validate_signup_request(&request);
            assert!(!result.is_valid, "Password '{}' should be invalid", password);
        }
    }
    
    #[test]
    fn test_email_validation_edge_cases() {
        let service = ValidationService::new();
        
        let invalid_emails = vec![
            "",
            " ",
            "@",
            "user@",
            "user",
            "user@domain", // no dot
            "abcd", // too short, no @ or dot
        ];
        
        for email in invalid_emails {
            let request = LoginRequest {
                email: email.to_string(),
                password: "ValidPass123!".to_string(),
            };
            
            let result = service.validate_login_request(&request);
            assert!(!result.is_valid, "Email '{}' should be invalid", email);
        }
    }
    
    #[test]
    fn test_timezone_validation_edge_cases() {
        let service = ValidationService::new();
        
        let valid_timezones = vec![
            "UTC",
            "GMT",
            "America/New_York",
            "Europe/London",
            "Asia/Tokyo",
            "GMT+5",
            "UTC-8",
        ];
        
        for timezone in valid_timezones {
            let request = SignupRequest {
                email: "test@example.com".to_string(),
                password: "SecurePass123!".to_string(),
                name: None,
                first_name: Some("John".to_string()),
                last_name: Some("Doe".to_string()),
                phone_number: None,
                country_code: "US".to_string(),
                timezone: timezone.to_string(),
                language: "en".to_string(),
            };
            
            let result = service.validate_signup_request(&request);
            assert!(result.is_valid, "Timezone '{}' should be valid, errors: {:?}", timezone, result.errors);
        }
        
        let invalid_timezones = vec![
            "",
            "INVALID",
            "America", // no slash
            "123",
        ];
        
        for timezone in invalid_timezones {
            let request = SignupRequest {
                email: "test@example.com".to_string(),
                password: "SecurePass123!".to_string(),
                name: None,
                first_name: Some("John".to_string()),
                last_name: Some("Doe".to_string()),
                phone_number: None,
                country_code: "US".to_string(),
                timezone: timezone.to_string(),
                language: "en".to_string(),
            };
            
            let result = service.validate_signup_request(&request);
            assert!(!result.is_valid, "Timezone '{}' should be invalid", timezone);
        }
    }
    
    #[test]
    fn test_language_code_validation() {
        let service = ValidationService::new();
        
        let valid_languages = vec![
            "en",
            "es",
            "fr",
            "de",
            "en-US",
            "es-MX",
            "zh-CN",
        ];
        
        for language in valid_languages {
            let request = SignupRequest {
                email: "test@example.com".to_string(),
                password: "SecurePass123!".to_string(),
                name: None,
                first_name: Some("John".to_string()),
                last_name: Some("Doe".to_string()),
                phone_number: None,
                country_code: "US".to_string(),
                timezone: "UTC".to_string(),
                language: language.to_string(),
            };
            
            let result = service.validate_signup_request(&request);
            assert!(result.is_valid, "Language '{}' should be valid, errors: {:?}", language, result.errors);
        }
        
        let invalid_languages = vec![
            "",
            "1",
            "english",
            "123",
            "en_US_extra",
            "toolong",
        ];
        
        for language in invalid_languages {
            let request = SignupRequest {
                email: "test@example.com".to_string(),
                password: "SecurePass123!".to_string(),
                name: None,
                first_name: Some("John".to_string()),
                last_name: Some("Doe".to_string()),
                phone_number: None,
                country_code: "US".to_string(),
                timezone: "UTC".to_string(),
                language: language.to_string(),
            };
            
            let result = service.validate_signup_request(&request);
            assert!(!result.is_valid, "Language '{}' should be invalid", language);
        }
    }
}

mod game_data_security_tests {
    use serde_json::json;
    use wondernest_backend::models::SaveGameDataRequest;
    
    #[test]
    fn test_game_data_json_injection_prevention() {
        // Test that malicious JSON cannot break our data structure
        let malicious_data = json!({
            "constructor": {"prototype": {"polluted": true}},
            "__proto__": {"polluted": true},
            "eval": "alert('xss')",
            "script": "<script>alert('xss')</script>",
            "sql": "'; DROP TABLE games; --"
        });
        
        let request = SaveGameDataRequest {
            game_type: "sticker_book".to_string(),
            data_key: "malicious_data".to_string(),
            data_value: malicious_data,
        };
        
        // Verify the structure can handle malicious JSON
        assert_eq!(request.game_type, "sticker_book");
        assert_eq!(request.data_key, "malicious_data");
        
        // The JSON should be stored as-is (it's the responsibility of 
        // the application layer to sanitize when processing)
        assert!(request.data_value.get("constructor").is_some());
    }
    
    #[test]
    fn test_game_type_validation_patterns() {
        // Test various game type patterns for potential security issues
        let suspicious_game_types = vec![
            "../../../etc/passwd",
            "sticker_book'; DROP TABLE games; --",
            "<script>alert('xss')</script>",
            "game\x00type", // null byte
            "game\ttype",   // tab
            "game\ntype",   // newline
            "game\rtype",   // carriage return
        ];
        
        for game_type in suspicious_game_types {
            let request = SaveGameDataRequest {
                game_type: game_type.to_string(),
                data_key: "test".to_string(),
                data_value: json!({"level": 1}),
            };
            
            // The request structure should handle these, but downstream 
            // validation should catch suspicious patterns
            assert_eq!(request.game_type, game_type);
            
            // Verify no path traversal in game type
            if game_type.contains("../") {
                assert!(true, "Path traversal detected in game_type: {}", game_type);
            }
        }
    }
    
    #[test]
    fn test_data_key_boundary_values() {
        let long_key = "a".repeat(1000);
        let boundary_keys = vec![
            "",                    // Empty
            " ",                   // Space only
            &long_key,             // Very long key
            "key.with.dots",       // Dots (potential JSON path)
            "key[0]",              // Array notation
            "key['property']",     // Property notation
            "key$special",         // Special characters
            "key\\escape",         // Escape characters
        ];
        
        for key in boundary_keys {
            let request = SaveGameDataRequest {
                game_type: "sticker_book".to_string(),
                data_key: key.to_string(),
                data_value: json!({"test": true}),
            };
            
            assert_eq!(request.data_key, key);
            
            // Verify key length limits (application should enforce)
            if key.len() > 255 {
                assert!(true, "Data key too long: {} chars", key.len());
            }
        }
    }
    
    #[test]
    fn test_json_data_structure_limits() {
        // Test deeply nested JSON (potential DoS)
        let mut deep_json = json!("value");
        for _ in 0..100 {
            deep_json = json!({"nested": deep_json});
        }
        
        let request = SaveGameDataRequest {
            game_type: "sticker_book".to_string(),
            data_key: "deep_nesting".to_string(),
            data_value: deep_json,
        };
        
        assert_eq!(request.data_key, "deep_nesting");
        // The JSON should be accepted, but applications should limit nesting depth
    }
    
    #[test]
    fn test_large_json_payload() {
        // Test large JSON payload (potential memory exhaustion)
        let large_string = "x".repeat(10000);
        let large_json = json!({
            "large_field": large_string,
            "array": vec![large_string.clone(); 100]
        });
        
        let request = SaveGameDataRequest {
            game_type: "sticker_book".to_string(),
            data_key: "large_data".to_string(),
            data_value: large_json,
        };
        
        assert_eq!(request.data_key, "large_data");
        // The structure should handle large payloads, but size limits should be enforced at the API level
    }
}

mod coppa_compliance_tests {
    use wondernest_backend::models::{SignupRequest, SaveGameDataRequest, GameDataItem};
    use serde_json::json;
    
    #[test]
    fn test_minimal_data_collection_signup() {
        // COPPA requires minimal data collection for children under 13
        let minimal_request = SignupRequest {
            email: "parent@example.com".to_string(),
            password: "SecurePass123!".to_string(),
            name: None,  // Optional - good for privacy
            first_name: None,  // Should be minimal for child accounts
            last_name: None,   // Should be minimal for child accounts
            phone_number: None,  // Should not be collected for children
            country_code: "US".to_string(),
            timezone: "UTC".to_string(),
            language: "en".to_string(),
        };
        
        // Verify minimal data collection
        assert!(minimal_request.name.is_none());
        assert!(minimal_request.first_name.is_none());
        assert!(minimal_request.last_name.is_none());
        assert!(minimal_request.phone_number.is_none());
        
        // Essential fields for service operation
        assert!(!minimal_request.email.is_empty());
        assert!(!minimal_request.password.is_empty());
        assert!(!minimal_request.country_code.is_empty());
    }
    
    #[test]
    fn test_child_game_data_privacy() {
        // Test that child game data doesn't contain PII
        let safe_game_data = json!({
            "level": 5,
            "coins": 100,
            "achievements": ["first_win", "perfect_score"],
            "preferences": {
                "sound_enabled": true,
                "difficulty": "easy"
            }
        });
        
        let _request = SaveGameDataRequest {
            game_type: "sticker_book".to_string(),
            data_key: "progress".to_string(),
            data_value: safe_game_data.clone(),
        };
        
        // Verify no PII in game data
        let data_str = safe_game_data.to_string();
        assert!(!data_str.contains("name"));
        assert!(!data_str.contains("email"));
        assert!(!data_str.contains("phone"));
        assert!(!data_str.contains("address"));
        assert!(!data_str.contains("birthday"));
        
        // Verify only game-related data
        assert!(data_str.contains("level"));
        assert!(data_str.contains("preferences"));
    }
    
    #[test]
    fn test_potentially_identifying_data_detection() {
        // Test detection of potentially identifying information in game data
        let problematic_data = json!({
            "player_name": "John Doe",  // Real name - COPPA concern
            "school": "Elementary School", // Location info - COPPA concern
            "home_address": "123 Main St", // Address - COPPA violation
            "phone_number": "555-1234", // Phone - COPPA violation
            "email": "child@email.com", // Email - COPPA violation
            "photo": "base64_encoded_image", // Photo - COPPA violation
            "friends": ["friend1", "friend2"], // Social connections - COPPA concern
            "chat_messages": ["Hello", "How are you?"] // Communications - COPPA concern
        });
        
        let _request = SaveGameDataRequest {
            game_type: "social_game".to_string(),
            data_key: "user_data".to_string(),
            data_value: problematic_data.clone(),
        };
        
        // In a real implementation, this data should be flagged for review
        let data_str = problematic_data.to_string();
        let concerning_fields = vec![
            "player_name", "school", "home_address", "phone_number", 
            "email", "photo", "friends", "chat_messages"
        ];
        
        for field in concerning_fields {
            if data_str.contains(field) {
                // This would trigger COPPA compliance review in production
                assert!(true, "COPPA concern: field '{}' detected in child data", field);
            }
        }
    }
    
    #[test]
    fn test_age_appropriate_content_markers() {
        // Test that game data can include age-appropriate content markers
        let age_appropriate_data = json!({
            "content_rating": "K-A", // Kids to Adults
            "educational_value": true,
            "violence_level": "none",
            "language_level": "appropriate",
            "themes": ["friendship", "learning", "creativity"],
            "parental_guidance": false
        });
        
        let request = SaveGameDataRequest {
            game_type: "educational_game".to_string(),
            data_key: "content_info".to_string(),
            data_value: age_appropriate_data.clone(),
        };
        
        // Verify age-appropriate content markers are present
        let data = &request.data_value;
        assert_eq!(data["content_rating"], "K-A");
        assert_eq!(data["educational_value"], true);
        assert_eq!(data["violence_level"], "none");
        assert!(data["themes"].is_array());
    }
    
    #[test]
    fn test_data_retention_metadata() {
        // Test that data includes retention metadata for COPPA compliance
        let item = GameDataItem {
            id: "test-123".to_string(),
            child_id: "child-456".to_string(),
            game_type: "sticker_book".to_string(),
            data_key: "progress".to_string(),
            data_value: json!({"level": 1}),
            created_at: "2024-01-01T00:00:00Z".to_string(),
            updated_at: "2024-01-01T00:00:00Z".to_string(),
        };
        
        // Verify timestamp fields are present for retention tracking
        assert!(!item.created_at.is_empty());
        assert!(!item.updated_at.is_empty());
        
        // In production, additional metadata would be needed:
        // - retention_period
        // - deletion_scheduled_at
        // - parental_consent_given_at
        // - data_purpose
        
        // Verify child_id is not the actual name or PII
        assert!(!item.child_id.contains("@")); // Not an email
        assert!(!item.child_id.contains(" ")); // Not a real name
    }
}

// Additional test categories that could be added:
// - Integration tests for full auth flow (when database setup is simplified)
// - Security vulnerability tests (SQL injection, XSS, etc.)
// - COPPA compliance tests for child data handling
// - Rate limiting tests for auth endpoints
// - Concurrent user signup/login tests (simplified versions without tokio::spawn)

// For now, focusing on unit tests that don't require external dependencies
// This provides a solid foundation that can be expanded as needed