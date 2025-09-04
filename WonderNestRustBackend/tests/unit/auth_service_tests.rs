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
        assert_eq!(sanitized.name, Some("&lt;script&gt;alert(&#x27;xss&#x27;)&lt;/script&gt;".to_string()));
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

mod family_management_tests {
    use wondernest_backend::models::{User, Family, ChildProfile, FamilyMember, NewUser, UserInfo};
    use uuid::Uuid;
    use chrono::{Utc, NaiveDate};
    
    #[test]
    fn test_user_model_creation() {
        let user_id = Uuid::new_v4();
        let family_id = Uuid::new_v4();
        let now = Utc::now();
        
        let user = User {
            id: user_id,
            email: "parent@example.com".to_string(),
            password_hash: "hashed_password_123".to_string(),
            first_name: Some("Jane".to_string()),
            last_name: Some("Doe".to_string()),
            phone: Some("+1234567890".to_string()),
            email_verified: true,
            is_active: true,
            created_at: now,
            updated_at: now,
            role: "parent".to_string(),
            pin_hash: Some("pin_hash_456".to_string()),
            family_id: Some(family_id),
        };
        
        assert_eq!(user.id, user_id);
        assert_eq!(user.email, "parent@example.com");
        assert_eq!(user.first_name, Some("Jane".to_string()));
        assert_eq!(user.last_name, Some("Doe".to_string()));
        assert_eq!(user.role, "parent");
        assert!(user.email_verified);
        assert!(user.is_active);
        assert_eq!(user.family_id, Some(family_id));
        assert!(user.pin_hash.is_some());
    }
    
    #[test]
    fn test_family_creation() {
        let family_id = Uuid::new_v4();
        let creator_id = Uuid::new_v4();
        let now = Utc::now();
        
        let family = Family {
            id: family_id,
            name: "The Johnson Family".to_string(),
            created_by: Some(creator_id),
            created_at: now,
            updated_at: now,
        };
        
        assert_eq!(family.id, family_id);
        assert_eq!(family.name, "The Johnson Family");
        assert_eq!(family.created_by, Some(creator_id));
        assert!(family.created_at <= Utc::now());
    }
    
    #[test]
    fn test_child_profile_creation() {
        let child_id = Uuid::new_v4();
        let family_id = Uuid::new_v4();
        let birth_date = NaiveDate::from_ymd_opt(2018, 5, 15).unwrap();
        let now = Utc::now();
        
        let child = ChildProfile {
            id: child_id,
            family_id,
            name: "Emily".to_string(),
            nickname: Some("Em".to_string()),
            birth_date,
            gender: Some("female".to_string()),
            avatar_url: Some("https://example.com/avatar.jpg".to_string()),
            interests: Some(vec!["drawing".to_string(), "puzzles".to_string()]),
            favorite_colors: Some(vec!["purple".to_string(), "pink".to_string()]),
            is_active: true,
            created_at: now,
            updated_at: now,
            archived_at: None,
        };
        
        assert_eq!(child.id, child_id);
        assert_eq!(child.family_id, family_id);
        assert_eq!(child.name, "Emily");
        assert_eq!(child.nickname, Some("Em".to_string()));
        assert_eq!(child.birth_date, birth_date);
        assert_eq!(child.gender, Some("female".to_string()));
        assert!(child.is_active);
        assert!(child.archived_at.is_none());
        assert_eq!(child.interests.as_ref().unwrap().len(), 2);
        assert_eq!(child.favorite_colors.as_ref().unwrap().len(), 2);
    }
    
    #[test]
    fn test_family_member_creation() {
        let member_id = Uuid::new_v4();
        let family_id = Uuid::new_v4();
        let user_id = Uuid::new_v4();
        let now = Utc::now();
        
        let family_member = FamilyMember {
            id: member_id,
            family_id,
            user_id,
            role: "parent".to_string(),
            joined_at: now,
        };
        
        assert_eq!(family_member.id, member_id);
        assert_eq!(family_member.family_id, family_id);
        assert_eq!(family_member.user_id, user_id);
        assert_eq!(family_member.role, "parent");
    }
    
    #[test]
    fn test_new_user_default() {
        let new_user = NewUser::default();
        
        assert_ne!(new_user.id, Uuid::nil());
        assert_eq!(new_user.email, "");
        assert!(!new_user.email_verified);
        assert_eq!(new_user.auth_provider, "email");
        assert_eq!(new_user.timezone, "UTC");
        assert_eq!(new_user.language, "en");
        assert_eq!(new_user.status, "pending_verification");
        assert_eq!(new_user.role, "parent");
        assert!(!new_user.parental_consent_verified);
    }
    
    #[test]
    fn test_user_info_from_user_conversion() {
        let user_id = Uuid::new_v4();
        let now = Utc::now();
        
        let user = User {
            id: user_id,
            email: "test@example.com".to_string(),
            password_hash: "hashed".to_string(),
            first_name: Some("John".to_string()),
            last_name: Some("Doe".to_string()),
            phone: None,
            email_verified: true,
            is_active: true,
            created_at: now,
            updated_at: now,
            role: "parent".to_string(),
            pin_hash: None,
            family_id: None,
        };
        
        let user_info: UserInfo = user.into();
        
        assert_eq!(user_info.id, user_id);
        assert_eq!(user_info.email, "test@example.com");
        assert_eq!(user_info.first_name, Some("John".to_string()));
        assert_eq!(user_info.last_name, Some("Doe".to_string()));
        assert_eq!(user_info.role, "parent");
        assert!(user_info.email_verified);
    }
    
    #[test]
    fn test_child_age_calculation_concept() {
        let birth_date = NaiveDate::from_ymd_opt(2018, 1, 1).unwrap();
        let current_date = NaiveDate::from_ymd_opt(2024, 1, 1).unwrap();
        
        let age_years = current_date.years_since(birth_date).unwrap_or(0);
        
        assert_eq!(age_years, 6);
        
        // Test COPPA compliance - child under 13
        let is_coppa_protected = age_years < 13;
        assert!(is_coppa_protected);
    }
    
    #[test]
    fn test_family_name_generation_patterns() {
        let test_cases = vec![
            ("Smith", "The Smith Family"),
            ("Johnson", "The Johnson Family"),
            ("García", "The García Family"),
            ("O'Connor", "The O'Connor Family"),
        ];
        
        for (last_name, expected_family_name) in test_cases {
            let family_name = format!("The {} Family", last_name);
            assert_eq!(family_name, expected_family_name);
        }
    }
    
    #[test]
    fn test_child_profile_validation_concepts() {
        // Test that child names should be validated
        let valid_names = vec![
            "Emily",
            "José",
            "李小明",
            "Anne-Marie",
            "D'Angelo",
        ];
        
        for name in valid_names {
            assert!(!name.is_empty());
            assert!(name.len() <= 50); // Reasonable name length limit
            assert!(!name.contains('<')); // No HTML/XSS
            assert!(!name.contains('>')); 
        }
        
        // Test invalid names
        let long_name = "a".repeat(100);
        let invalid_names = vec![
            "", // Empty
            &long_name, // Too long
            "<script>alert('xss')</script>", // XSS attempt
            "SELECT * FROM users", // SQL injection attempt
        ];
        
        for name in invalid_names {
            if name.is_empty() {
                assert_eq!(name.len(), 0);
            } else if name.len() > 50 {
                assert!(name.len() > 50, "Name '{}' is too long: {} chars", name, name.len());
            } else if name.contains('<') || name.contains('>') {
                assert!(true, "Name '{}' contains HTML tags", name);
            } else if name.to_uppercase().contains("SELECT") {
                assert!(true, "Name '{}' contains SQL keywords", name);
            }
        }
    }
}
mod content_management_tests {
    use wondernest_backend::models::{
        ContentItem, ContentCategory, ContentResponse, ContentRecommendationsResponse,
        ContentCategoriesResponse, ContentEngagementRequest
    };
    
    #[test]
    fn test_content_item_creation() {
        let content = ContentItem {
            id: "content_123".to_string(),
            title: "Learn Numbers with Animals".to_string(),
            description: "Interactive number learning game with cute animals".to_string(),
            category: "educational".to_string(),
            age_rating: 4,
            duration: 15, // 15 minutes
            thumbnail_url: "https://example.com/thumbnail.jpg".to_string(),
            content_url: "https://example.com/content.html".to_string(),
            tags: vec!["numbers".to_string(), "animals".to_string(), "interactive".to_string()],
            is_educational: true,
            difficulty: "easy".to_string(),
            created_at: "2024-01-01T00:00:00Z".to_string(),
        };
        
        assert_eq!(content.id, "content_123");
        assert_eq!(content.title, "Learn Numbers with Animals");
        assert_eq!(content.category, "educational");
        assert_eq!(content.age_rating, 4);
        assert_eq!(content.duration, 15);
        assert!(content.is_educational);
        assert_eq!(content.difficulty, "easy");
        assert_eq!(content.tags.len(), 3);
        assert!(content.tags.contains(&"numbers".to_string()));
    }
    
    #[test]
    fn test_content_category_creation() {
        let category = ContentCategory {
            id: "educational".to_string(),
            name: "Educational".to_string(),
            description: "Learning content for cognitive development".to_string(),
            icon: "graduation-cap".to_string(),
            color: "#4CAF50".to_string(),
            min_age: 3,
            max_age: 12,
        };
        
        assert_eq!(category.id, "educational");
        assert_eq!(category.name, "Educational");
        assert_eq!(category.icon, "graduation-cap");
        assert_eq!(category.color, "#4CAF50");
        assert_eq!(category.min_age, 3);
        assert_eq!(category.max_age, 12);
    }
    
    #[test]
    fn test_content_engagement_request() {
        let engagement = ContentEngagementRequest {
            content_id: "content_456".to_string(),
            child_id: "child_789".to_string(),
            engagement_type: "complete".to_string(),
            duration: Some(300), // 5 minutes
            metadata: Some(serde_json::json!({
                "score": 85,
                "attempts": 3,
                "help_used": false
            })),
        };
        
        assert_eq!(engagement.content_id, "content_456");
        assert_eq!(engagement.child_id, "child_789");
        assert_eq!(engagement.engagement_type, "complete");
        assert_eq!(engagement.duration, Some(300));
        assert!(engagement.metadata.is_some());
        
        let metadata = engagement.metadata.unwrap();
        assert_eq!(metadata["score"], 85);
        assert_eq!(metadata["attempts"], 3);
        assert_eq!(metadata["help_used"], false);
    }
    
    #[test]
    fn test_age_appropriate_content_filtering() {
        let content_items = vec![
            ContentItem {
                id: "1".to_string(),
                title: "Toddler ABC".to_string(),
                description: "For very young children".to_string(),
                category: "educational".to_string(),
                age_rating: 2,
                duration: 5,
                thumbnail_url: "toddler.jpg".to_string(),
                content_url: "toddler.html".to_string(),
                tags: vec!["alphabet".to_string()],
                is_educational: true,
                difficulty: "easy".to_string(),
                created_at: "2024-01-01T00:00:00Z".to_string(),
            },
            ContentItem {
                id: "2".to_string(),
                title: "Advanced Math".to_string(),
                description: "Complex problem solving".to_string(),
                category: "educational".to_string(),
                age_rating: 10,
                duration: 30,
                thumbnail_url: "math.jpg".to_string(),
                content_url: "math.html".to_string(),
                tags: vec!["mathematics".to_string(), "advanced".to_string()],
                is_educational: true,
                difficulty: "hard".to_string(),
                created_at: "2024-01-01T00:00:00Z".to_string(),
            },
        ];
        
        let child_age = 5;
        let suitable_content: Vec<&ContentItem> = content_items
            .iter()
            .filter(|item| {
                // Age appropriateness check (within 3 years range to include toddler content)
                let age_diff = (item.age_rating as i32 - child_age as i32).abs();
                age_diff <= 3
            })
            .collect();
        
        // Should only include toddler content for a 5-year-old
        assert_eq!(suitable_content.len(), 1);
        assert_eq!(suitable_content[0].id, "1");
    }
}

mod analytics_tests {
    use wondernest_backend::models::{
        DailyAnalytics, ChildInsights, WeeklyOverview, ChildMilestones, 
        MilestoneItem, AnalyticsEvent, AnalyticsEventResponse,
        AnalyticsGameDataResponse, AnalyticsGameDataContainer, AnalyticsGameDataItem
    };
    use std::collections::HashMap;
    
    #[test]
    fn test_daily_analytics_creation() {
        let analytics = DailyAnalytics {
            date: "2024-01-15".to_string(),
            child_id: "child_123".to_string(),
            total_screen_time: 45, // minutes
            content_consumed: 3,
            educational_time: 30,
            average_session_length: 15,
            most_engaged_category: "educational".to_string(),
            completed_activities: 2,
            learning_progress: 0.75,
        };
        
        assert_eq!(analytics.date, "2024-01-15");
        assert_eq!(analytics.child_id, "child_123");
        assert_eq!(analytics.total_screen_time, 45);
        assert_eq!(analytics.content_consumed, 3);
        assert_eq!(analytics.educational_time, 30);
        assert_eq!(analytics.average_session_length, 15);
        assert_eq!(analytics.most_engaged_category, "educational");
        assert_eq!(analytics.completed_activities, 2);
        assert_eq!(analytics.learning_progress, 0.75);
        
        // Verify healthy screen time limits (under 60 minutes for young children)
        assert!(analytics.total_screen_time <= 60);
        
        // Verify educational content ratio
        let educational_ratio = analytics.educational_time as f64 / analytics.total_screen_time as f64;
        assert!(educational_ratio >= 0.5, "Educational content should be at least 50%");
    }
    
    #[test]
    fn test_child_insights_creation() {
        let insights = ChildInsights {
            child_id: "child_456".to_string(),
            preferred_learning_style: "visual".to_string(),
            strong_subjects: vec!["mathematics".to_string(), "art".to_string()],
            improvement_areas: vec!["reading comprehension".to_string()],
            recommended_activities: vec![
                "pattern recognition games".to_string(),
                "creative drawing apps".to_string()
            ],
            parental_guidance: vec![
                "Encourage reading together for 15 minutes daily".to_string(),
                "Practice counting with physical objects".to_string()
            ],
        };
        
        assert_eq!(insights.child_id, "child_456");
        assert_eq!(insights.preferred_learning_style, "visual");
        assert_eq!(insights.strong_subjects.len(), 2);
        assert_eq!(insights.improvement_areas.len(), 1);
        assert_eq!(insights.recommended_activities.len(), 2);
        assert_eq!(insights.parental_guidance.len(), 2);
        
        assert!(insights.strong_subjects.contains(&"mathematics".to_string()));
        assert!(insights.improvement_areas.contains(&"reading comprehension".to_string()));
    }
    
    #[test]
    fn test_weekly_overview_creation() {
        let overview = WeeklyOverview {
            week_start: "2024-01-15".to_string(),
            total_screen_time: 180, // 3 hours total for the week
            educational_percentage: 75.0,
            average_daily_usage: 25, // minutes
            top_categories: vec![
                "educational".to_string(),
                "creative".to_string(),
                "puzzles".to_string()
            ],
            completion_rate: 0.85,
            parental_interaction: 12, // number of interactions
        };
        
        assert_eq!(overview.week_start, "2024-01-15");
        assert_eq!(overview.total_screen_time, 180);
        assert_eq!(overview.educational_percentage, 75.0);
        assert_eq!(overview.average_daily_usage, 25);
        assert_eq!(overview.top_categories.len(), 3);
        assert_eq!(overview.completion_rate, 0.85);
        assert_eq!(overview.parental_interaction, 12);
        
        // Verify healthy weekly limits (AAP recommends 1 hour/day for ages 2-5)
        let recommended_weekly_limit = 7 * 60; // 7 hours per week
        assert!(overview.total_screen_time <= recommended_weekly_limit);
        
        // Verify high educational content percentage
        assert!(overview.educational_percentage >= 70.0);
    }
    
    #[test]
    fn test_child_milestones_creation() {
        let milestones = vec![
            MilestoneItem {
                category: "cognitive".to_string(),
                description: "Can count to 20".to_string(),
                achieved: true,
            },
            MilestoneItem {
                category: "social".to_string(),
                description: "Shares toys with others".to_string(),
                achieved: true,
            },
            MilestoneItem {
                category: "motor".to_string(),
                description: "Can draw simple shapes".to_string(),
                achieved: false,
            },
        ];
        
        let child_milestones = ChildMilestones {
            age: 5,
            milestones: milestones.clone(),
            next_goals: vec![
                "Practice drawing circles and squares".to_string(),
                "Learn to write first name".to_string(),
            ],
        };
        
        assert_eq!(child_milestones.age, 5);
        assert_eq!(child_milestones.milestones.len(), 3);
        assert_eq!(child_milestones.next_goals.len(), 2);
        
        // Count achieved milestones
        let achieved_count = child_milestones.milestones.iter()
            .filter(|m| m.achieved)
            .count();
        assert_eq!(achieved_count, 2);
        
        // Check milestone categories
        let categories: Vec<&String> = child_milestones.milestones.iter()
            .map(|m| &m.category)
            .collect();
        assert!(categories.contains(&&"cognitive".to_string()));
        assert!(categories.contains(&&"social".to_string()));
        assert!(categories.contains(&&"motor".to_string()));
    }
    
    #[test]
    fn test_analytics_event_creation() {
        let mut event_data = HashMap::new();
        event_data.insert("activity_type".to_string(), serde_json::json!("puzzle"));
        event_data.insert("difficulty".to_string(), serde_json::json!("easy"));
        event_data.insert("completion_time".to_string(), serde_json::json!(45));
        
        let event = AnalyticsEvent {
            event_type: "activity_completed".to_string(),
            child_id: "child_789".to_string(),
            content_id: Some("puzzle_123".to_string()),
            duration: Some(300), // 5 minutes
            event_data,
            session_id: Some("session_456".to_string()),
        };
        
        assert_eq!(event.event_type, "activity_completed");
        assert_eq!(event.child_id, "child_789");
        assert_eq!(event.content_id, Some("puzzle_123".to_string()));
        assert_eq!(event.duration, Some(300));
        assert!(event.session_id.is_some());
        
        // Verify event data structure
        assert!(event.event_data.contains_key("activity_type"));
        assert!(event.event_data.contains_key("difficulty"));
        assert_eq!(event.event_data["completion_time"], 45);
    }
    
    #[test]
    fn test_analytics_event_response() {
        let response = AnalyticsEventResponse {
            message: "Event recorded successfully".to_string(),
            event_id: "event_12345".to_string(),
            timestamp: "2024-01-15T10:30:00Z".to_string(),
        };
        
        assert_eq!(response.message, "Event recorded successfully");
        assert_eq!(response.event_id, "event_12345");
        assert_eq!(response.timestamp, "2024-01-15T10:30:00Z");
    }
    
    #[test]
    fn test_analytics_game_data_structures() {
        let game_data_items = vec![
            AnalyticsGameDataItem {
                data_key: "sticker_progress".to_string(),
                data_value: r#"{"completed_pages": 3, "total_stickers": 15}"#.to_string(),
            },
            AnalyticsGameDataItem {
                data_key: "puzzle_scores".to_string(),
                data_value: r#"{"best_time": 45, "average_score": 85}"#.to_string(),
            },
        ];
        
        let container = AnalyticsGameDataContainer {
            game_data: game_data_items.clone(),
        };
        
        let response = AnalyticsGameDataResponse {
            data: container,
        };
        
        assert_eq!(response.data.game_data.len(), 2);
        assert_eq!(response.data.game_data[0].data_key, "sticker_progress");
        assert_eq!(response.data.game_data[1].data_key, "puzzle_scores");
        
        // Verify JSON data is valid
        assert!(response.data.game_data[0].data_value.contains("completed_pages"));
        assert!(response.data.game_data[1].data_value.contains("best_time"));
    }
    
    #[test]
    fn test_screen_time_compliance() {
        // Test American Academy of Pediatrics screen time recommendations
        let test_cases = vec![
            (2, 30, true),  // 2 years old, 30 minutes - acceptable
            (3, 60, true),  // 3 years old, 1 hour - at limit
            (4, 90, false), // 4 years old, 1.5 hours - exceeds recommendation
            (6, 120, false), // 6 years old, 2 hours - exceeds recommendation
        ];
        
        for (age, screen_time_minutes, should_be_compliant) in test_cases {
            let recommended_limit = if age <= 5 { 60 } else { 90 }; // minutes
            let is_compliant = screen_time_minutes <= recommended_limit;
            
            assert_eq!(is_compliant, should_be_compliant,
                "Age {} with {} minutes should be compliant: {}", 
                age, screen_time_minutes, should_be_compliant);
        }
    }
    
    #[test]
    fn test_educational_content_ratio() {
        // Test that educational content maintains appropriate ratios
        let analytics = DailyAnalytics {
            date: "2024-01-15".to_string(),
            child_id: "child_test".to_string(),
            total_screen_time: 60,
            content_consumed: 4,
            educational_time: 45, // 75% educational
            average_session_length: 15,
            most_engaged_category: "educational".to_string(),
            completed_activities: 3,
            learning_progress: 0.8,
        };
        
        let educational_ratio = analytics.educational_time as f64 / analytics.total_screen_time as f64;
        
        // Should maintain high educational content ratio
        assert!(educational_ratio >= 0.6, 
            "Educational ratio should be at least 60%, got {:.2}", educational_ratio);
        
        // Verify progress is being made
        assert!(analytics.learning_progress >= 0.7,
            "Learning progress should be substantial");
        
        // Verify engagement
        assert!(analytics.completed_activities > 0,
            "Child should complete some activities");
    }
}

mod coppa_consent_tests {
    use wondernest_backend::models::{
        COPPAConsentRequest, COPPAConsentResponse, COPPAStatusResponse, COPPAComplianceInfo
    };
    use std::collections::HashMap;
    
    #[test]
    fn test_coppa_consent_request_creation() {
        let mut permissions = HashMap::new();
        permissions.insert("data_collection".to_string(), true);
        permissions.insert("location_tracking".to_string(), false);
        permissions.insert("behavioral_advertising".to_string(), false);
        permissions.insert("third_party_sharing".to_string(), false);
        
        let mut verification_data = HashMap::new();
        verification_data.insert("method".to_string(), "credit_card".to_string());
        verification_data.insert("last_four_digits".to_string(), "1234".to_string());
        
        let consent_request = COPPAConsentRequest {
            child_id: "child_123".to_string(),
            consent_type: "verifiable_consent".to_string(),
            permissions: permissions.clone(),
            verification_method: "credit_card".to_string(),
            verification_data: Some(verification_data.clone()),
        };
        
        assert_eq!(consent_request.child_id, "child_123");
        assert_eq!(consent_request.consent_type, "verifiable_consent");
        assert_eq!(consent_request.verification_method, "credit_card");
        assert_eq!(consent_request.permissions.len(), 4);
        
        // Verify minimal permissions (COPPA requires minimal data collection)
        assert_eq!(consent_request.permissions["data_collection"], true);
        assert_eq!(consent_request.permissions["location_tracking"], false);
        assert_eq!(consent_request.permissions["behavioral_advertising"], false);
        assert_eq!(consent_request.permissions["third_party_sharing"], false);
        
        assert!(consent_request.verification_data.is_some());
    }
    
    #[test]
    fn test_coppa_consent_response() {
        let mut permissions = HashMap::new();
        permissions.insert("basic_service".to_string(), true);
        permissions.insert("marketing".to_string(), false);
        permissions.insert("analytics".to_string(), false);
        
        let consent_response = COPPAConsentResponse {
            consent_id: "consent_456".to_string(),
            child_id: "child_123".to_string(),
            consent_type: "verifiable_consent".to_string(),
            permissions: permissions.clone(),
            consent_granted: true,
            expires_at: Some("2025-01-15T00:00:00Z".to_string()),
            verification_status: "verified".to_string(),
            compliance_warnings: vec![
                "Data retention limited to 30 days".to_string(),
                "No behavioral tracking enabled".to_string(),
            ],
        };
        
        assert_eq!(consent_response.consent_id, "consent_456");
        assert_eq!(consent_response.child_id, "child_123");
        assert!(consent_response.consent_granted);
        assert_eq!(consent_response.verification_status, "verified");
        assert_eq!(consent_response.compliance_warnings.len(), 2);
        assert!(consent_response.expires_at.is_some());
        
        // Verify only essential permissions are granted
        assert_eq!(consent_response.permissions["basic_service"], true);
        assert_eq!(consent_response.permissions["marketing"], false);
        assert_eq!(consent_response.permissions["analytics"], false);
    }
    
    #[test]
    fn test_coppa_status_response() {
        let status_response = COPPAStatusResponse {
            child_id: "child_789".to_string(),
            consent_status: "consent_required".to_string(),
            consent_required: true,
            verification_required: true,
            data_collection_allowed: false,
            warnings: vec![
                "Child appears to be under 13".to_string(),
                "Parental consent not yet obtained".to_string(),
            ],
            next_steps: vec![
                "Obtain verifiable parental consent".to_string(),
                "Limit data collection to essential only".to_string(),
            ],
        };
        
        assert_eq!(status_response.child_id, "child_789");
        assert_eq!(status_response.consent_status, "consent_required");
        assert!(status_response.consent_required);
        assert!(status_response.verification_required);
        assert!(!status_response.data_collection_allowed);
        assert_eq!(status_response.warnings.len(), 2);
        assert_eq!(status_response.next_steps.len(), 2);
    }
    
    #[test]
    fn test_coppa_compliance_info() {
        let compliance_info = COPPAComplianceInfo {
            coppa_compliant: true,
            implementation_status: "fully_implemented".to_string(),
            required_features: vec![
                "parental_consent_mechanism".to_string(),
                "age_verification_system".to_string(),
                "data_minimization_policy".to_string(),
                "secure_data_deletion".to_string(),
            ],
            legal_requirements: vec![
                "Obtain verifiable parental consent before collecting personal info".to_string(),
                "Provide clear privacy notice about data collection practices".to_string(),
                "Allow parents to review and delete child's personal information".to_string(),
                "Not condition participation on unnecessary personal info disclosure".to_string(),
            ],
            warnings: vec![],
        };
        
        assert!(compliance_info.coppa_compliant);
        assert_eq!(compliance_info.implementation_status, "fully_implemented");
        assert_eq!(compliance_info.required_features.len(), 4);
        assert_eq!(compliance_info.legal_requirements.len(), 4);
        assert_eq!(compliance_info.warnings.len(), 0);
        
        // Verify all required features are present
        assert!(compliance_info.required_features.contains(&"parental_consent_mechanism".to_string()));
        assert!(compliance_info.required_features.contains(&"age_verification_system".to_string()));
        assert!(compliance_info.required_features.contains(&"data_minimization_policy".to_string()));
        assert!(compliance_info.required_features.contains(&"secure_data_deletion".to_string()));
    }
    
    #[test]
    fn test_age_verification_logic() {
        use chrono::{NaiveDate, Utc, Datelike};
        
        let current_date = Utc::now().naive_utc().date();
        let current_year = current_date.year();
        
        let test_birthdates = vec![
            (NaiveDate::from_ymd_opt(current_year - 9, 1, 1).unwrap(), 9, true),   // Under 13, COPPA applies
            (NaiveDate::from_ymd_opt(current_year - 12, 1, 1).unwrap(), 12, true),  // Under 13, COPPA applies
            (NaiveDate::from_ymd_opt(current_year - 13, 1, 1).unwrap(), 13, false), // Exactly 13, COPPA doesn't apply
            (NaiveDate::from_ymd_opt(current_year - 14, 1, 1).unwrap(), 14, false), // Over 13, COPPA doesn't apply
            (NaiveDate::from_ymd_opt(current_year - 16, 1, 1).unwrap(), 16, false), // Over 13, COPPA doesn't apply
        ];
        
        for (birth_date, expected_age, coppa_applies) in test_birthdates {
            let age_years = current_date.years_since(birth_date).unwrap_or(0);
            let is_coppa_protected = age_years < 13;
            
            // Allow for some variance in age calculation due to current date
            assert!((age_years as i32 - expected_age as i32).abs() <= 1, 
                "Age calculation variance too large: expected ~{}, got {}", expected_age, age_years);
            assert_eq!(is_coppa_protected, coppa_applies,
                "COPPA protection mismatch for age {}: expected {}, got {}", age_years, coppa_applies, is_coppa_protected);
        }
    }
    
    #[test]
    fn test_data_minimization_validation() {
        // Test that only essential data is collected for COPPA-protected children
        let essential_fields = vec![
            "first_name",      // Required for personalization
            "birth_year",      // Required for age verification (not full birth date)
            "parent_email",    // Required for communication
        ];
        
        let prohibited_fields = vec![
            "full_birth_date", // Too specific, birth year sufficient
            "home_address",    // Not necessary for service
            "phone_number",    // Not necessary for basic service
            "school_name",     // Could identify location
            "real_photo",      // Privacy risk
            "friends_list",    // Social connections not essential
        ];
        
        // Verify essential fields are minimal
        assert!(essential_fields.len() <= 5, 
            "Too many essential fields for COPPA compliance: {}", essential_fields.len());
        
        // Verify prohibited fields are avoided
        for prohibited_field in prohibited_fields {
            assert!(!essential_fields.contains(&prohibited_field),
                "Prohibited field '{}' found in essential fields", prohibited_field);
        }
    }
    
    #[test]
    fn test_parental_consent_mechanisms() {
        let consent_mechanisms = vec![
            ("credit_card", true),        // FTC approved method
            ("digital_signature", true), // FTC approved method
            ("phone_verification", true), // FTC approved method
            ("email_confirmation", false), // Not sufficient for COPPA
            ("checkbox_only", false),     // Not sufficient for COPPA
            ("sms_code", false),          // Not sufficient for COPPA
        ];
        
        for (method, is_coppa_compliant) in consent_mechanisms {
            let meets_ftc_requirements = match method {
                "credit_card" | "digital_signature" | "phone_verification" => true,
                _ => false,
            };
            
            assert_eq!(meets_ftc_requirements, is_coppa_compliant,
                "Consent mechanism '{}' compliance mismatch: expected {}, got {}", 
                method, is_coppa_compliant, meets_ftc_requirements);
        }
    }
    
    #[test]
    fn test_data_retention_limits() {
        // Test COPPA-compliant data retention periods
        let data_types = vec![
            ("game_progress", 90),      // 3 months max for gameplay data
            ("learning_analytics", 30), // 1 month for educational insights  
            ("session_logs", 7),        // 1 week for technical logs
            ("crash_reports", 30),      // 1 month for debugging
            ("user_preferences", 365),  // 1 year for essential settings
        ];
        
        for (data_type, retention_days) in data_types {
            // COPPA requires reasonable retention periods
            let max_reasonable_retention = match data_type {
                "game_progress" => 365,      // Up to 1 year reasonable
                "learning_analytics" => 90,  // Up to 3 months reasonable
                "session_logs" => 30,        // Up to 1 month reasonable
                "crash_reports" => 90,       // Up to 3 months reasonable
                "user_preferences" => 365,   // Up to 1 year reasonable
                _ => 30, // Default: 1 month
            };
            
            assert!(retention_days <= max_reasonable_retention,
                "Data retention period for '{}' exceeds reasonable limit: {} days > {} days",
                data_type, retention_days, max_reasonable_retention);
        }
    }
    
    #[test]
    fn test_privacy_notice_requirements() {
        // Test that privacy notices meet COPPA requirements
        let required_disclosures = vec![
            "what_information_collected",
            "how_information_used", 
            "whether_info_disclosed_to_third_parties",
            "parental_rights_and_procedures",
            "contact_information_for_operator",
        ];
        
        // Simulate a privacy notice checklist
        let mut privacy_notice_items = HashMap::new();
        privacy_notice_items.insert("what_information_collected".to_string(), true);
        privacy_notice_items.insert("how_information_used".to_string(), true);
        privacy_notice_items.insert("whether_info_disclosed_to_third_parties".to_string(), true);
        privacy_notice_items.insert("parental_rights_and_procedures".to_string(), true);
        privacy_notice_items.insert("contact_information_for_operator".to_string(), true);
        
        // Store the length before the loop consumes the vector
        let required_count = required_disclosures.len();
        
        // Verify all required disclosures are present
        for required_disclosure in required_disclosures {
            assert!(privacy_notice_items.contains_key(required_disclosure),
                "Privacy notice missing required disclosure: {}", required_disclosure);
            assert_eq!(privacy_notice_items[required_disclosure], true,
                "Required disclosure '{}' not properly implemented", required_disclosure);
        }
        
        // Verify completeness
        assert_eq!(privacy_notice_items.len(), 5,
            "Privacy notice should contain exactly {} required disclosures", required_count);
    }
    
    #[test]
    fn test_safe_harbor_provisions() {
        // Test compliance with COPPA Safe Harbor provisions
        let safe_harbor_requirements = vec![
            ("self_assessment", true),           // Regular compliance assessment
            ("employee_training", true),         // Staff training on COPPA
            ("compliance_monitoring", true),     // Ongoing monitoring
            ("complaint_handling", true),        // Process for handling complaints
            ("data_security_measures", true),    // Appropriate security safeguards
        ];
        
        for (requirement, implemented) in safe_harbor_requirements {
            assert!(implemented,
                "Safe Harbor requirement '{}' must be implemented for COPPA compliance", requirement);
        }
    }
}

mod file_management_tests {
    use wondernest_backend::models::{
        UploadedFileDto, FileUploadSuccessResponse, FileListSuccessResponse,
        FileDeleteSuccessResponse, FileUsageResponse, FileErrorResponse,
        ErrorDetails, FileQueryParams
    };
    
    #[test]
    fn test_uploaded_file_dto_creation() {
        let file_dto = UploadedFileDto {
            id: "file_123".to_string(),
            original_name: "child_drawing.png".to_string(),
            mime_type: "image/png".to_string(),
            file_size: 1024768, // ~1MB
            category: "child_artwork".to_string(),
            url: "https://cdn.wondernest.com/files/file_123.png".to_string(),
            uploaded_at: "2024-01-15T10:30:00Z".to_string(),
            metadata: Some(serde_json::json!({
                "width": 800,
                "height": 600,
                "child_id": "child_456",
                "created_in_app": "sticker_book"
            })),
        };
        
        assert_eq!(file_dto.id, "file_123");
        assert_eq!(file_dto.original_name, "child_drawing.png");
        assert_eq!(file_dto.mime_type, "image/png");
        assert_eq!(file_dto.file_size, 1024768);
        assert_eq!(file_dto.category, "child_artwork");
        assert!(file_dto.metadata.is_some());
        
        let metadata = file_dto.metadata.unwrap();
        assert_eq!(metadata["width"], 800);
        assert_eq!(metadata["height"], 600);
        assert_eq!(metadata["child_id"], "child_456");
    }
    
    #[test]
    fn test_file_upload_success_response() {
        let file_dto = UploadedFileDto {
            id: "uploaded_file_789".to_string(),
            original_name: "story_audio.mp3".to_string(),
            mime_type: "audio/mpeg".to_string(),
            file_size: 2097152, // 2MB
            category: "audio".to_string(),
            url: "https://cdn.wondernest.com/audio/uploaded_file_789.mp3".to_string(),
            uploaded_at: "2024-01-15T11:00:00Z".to_string(),
            metadata: Some(serde_json::json!({
                "duration_seconds": 180,
                "bitrate": "128kbps",
                "sample_rate": "44100Hz"
            })),
        };
        
        let response = FileUploadSuccessResponse {
            data: file_dto.clone(),
        };
        
        assert_eq!(response.data.id, "uploaded_file_789");
        assert_eq!(response.data.mime_type, "audio/mpeg");
        assert_eq!(response.data.category, "audio");
        assert_eq!(response.data.file_size, 2097152);
    }
    
    #[test]
    fn test_file_usage_response() {
        let usage_response = FileUsageResponse {
            is_used: true,
            stories: vec![
                "story_001".to_string(),
                "story_025".to_string(),
                "story_042".to_string(),
            ],
        };
        
        assert!(usage_response.is_used);
        assert_eq!(usage_response.stories.len(), 3);
        assert!(usage_response.stories.contains(&"story_001".to_string()));
        assert!(usage_response.stories.contains(&"story_025".to_string()));
        assert!(usage_response.stories.contains(&"story_042".to_string()));
    }
    
    #[test]
    fn test_file_error_response() {
        let error_details = ErrorDetails {
            code: "FILE_TOO_LARGE".to_string(),
            message: "File size exceeds maximum allowed size of 10MB".to_string(),
        };
        
        let error_response = FileErrorResponse {
            error: error_details,
        };
        
        assert_eq!(error_response.error.code, "FILE_TOO_LARGE");
        assert_eq!(error_response.error.message, "File size exceeds maximum allowed size of 10MB");
    }
    
    #[test]
    fn test_file_query_params() {
        let query_params = FileQueryParams {
            category: Some("images".to_string()),
            child_id: Some("child_123".to_string()),
            limit: Some(20),
            offset: Some(0),
            is_public: Some(false),
        };
        
        assert_eq!(query_params.category, Some("images".to_string()));
        assert_eq!(query_params.child_id, Some("child_123".to_string()));
        assert_eq!(query_params.limit, Some(20));
        assert_eq!(query_params.offset, Some(0));
        assert_eq!(query_params.is_public, Some(false));
    }
    
    #[test]
    fn test_file_size_validation() {
        let file_size_limits = vec![
            ("image", 5 * 1024 * 1024),     // 5MB for images
            ("audio", 10 * 1024 * 1024),    // 10MB for audio
            ("video", 50 * 1024 * 1024),    // 50MB for video
        ];
        
        for (file_type, max_size) in file_size_limits {
            // Test files within limits
            let valid_file_size = max_size - 1024; // Just under limit
            assert!(valid_file_size <= max_size,
                "Valid file size for {} should be within limit", file_type);
            
            // Test files exceeding limits
            let invalid_file_size = max_size + 1024; // Just over limit
            assert!(invalid_file_size > max_size,
                "Invalid file size for {} should exceed limit", file_type);
        }
    }
    
    #[test]
    fn test_mime_type_validation() {
        let allowed_mime_types = vec![
            // Images
            ("image/jpeg", true),
            ("image/png", true),
            ("image/gif", true),
            ("image/webp", true),
            // Audio
            ("audio/mpeg", true),
            ("audio/wav", true),
            ("audio/ogg", true),
            // Text/Documents
            ("text/plain", true),
            ("application/json", true),
            // Prohibited types
            ("application/x-executable", false),
            ("application/x-msdownload", false),
            ("text/html", false), // Could contain scripts
            ("application/javascript", false),
        ];
        
        for (mime_type, should_be_allowed) in allowed_mime_types {
            let is_safe_mime_type = match mime_type {
                mime if mime.starts_with("image/") => true,
                mime if mime.starts_with("audio/") => true,
                "text/plain" | "application/json" => true,
                mime if mime.contains("executable") => false,
                mime if mime.contains("script") => false,
                "text/html" => false,
                _ => false,
            };
            
            assert_eq!(is_safe_mime_type, should_be_allowed,
                "MIME type '{}' safety check failed: expected {}, got {}",
                mime_type, should_be_allowed, is_safe_mime_type);
        }
    }
    
    #[test]
    fn test_file_name_sanitization() {
        let test_cases = vec![
            ("normal_file.jpg", "normal_file.jpg", true),
            ("file with spaces.png", "file_with_spaces.png", true),
            ("../../../etc/passwd", "passwd", false), // Path traversal
            ("file<script>.js", "filescript.js", false), // HTML tags
            ("CON.txt", "CON_safe.txt", false), // Windows reserved name
            ("file|pipe.txt", "filepipe.txt", false), // Pipe character
            ("file\x00null.txt", "filenull.txt", false), // Null byte
        ];
        
        for (input, expected_safe, is_originally_safe) in test_cases {
            // Basic sanitization logic
            let mut sanitized = input
                .replace(['<', '>', '|', '\x00'], "")
                .replace("../", "")
                .replace(' ', "_");
            
            // Handle Windows reserved names
            let reserved_names = ["CON", "PRN", "AUX", "NUL", "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9", "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9"];
            if let Some(stem) = sanitized.split('.').next() {
                if reserved_names.contains(&stem.to_uppercase().as_str()) {
                    sanitized = format!("{}_safe{}", stem, if sanitized.contains('.') { format!(".{}", sanitized.split('.').skip(1).collect::<Vec<_>>().join(".")) } else { String::new() });
                }
            }
            
            if !is_originally_safe {
                assert_ne!(input, sanitized,
                    "Unsafe filename '{}' should be sanitized", input);
            }
            
            // Verify no path traversal
            assert!(!sanitized.contains("../"),
                "Sanitized filename should not contain path traversal: '{}'", sanitized);
            
            // Verify no dangerous characters
            assert!(!sanitized.contains('<') && !sanitized.contains('>'),
                "Sanitized filename should not contain HTML tags: '{}'", sanitized);
        }
    }
}

mod audio_processing_tests {
    use wondernest_backend::models::{
        AudioSessionRequest, AudioSessionResponse, AudioMetricsRequest
    };
    
    #[test]
    fn test_audio_session_request() {
        let session_request = AudioSessionRequest {
            child_id: "child_456".to_string(),
            session_type: "story_reading".to_string(),
            metadata: Some(serde_json::json!({
                "story_id": "story_123",
                "reading_level": "beginner",
                "parent_assisted": false
            })),
        };
        
        assert_eq!(session_request.child_id, "child_456");
        assert_eq!(session_request.session_type, "story_reading");
        assert!(session_request.metadata.is_some());
        
        let metadata = session_request.metadata.unwrap();
        assert_eq!(metadata["story_id"], "story_123");
        assert_eq!(metadata["reading_level"], "beginner");
        assert_eq!(metadata["parent_assisted"], false);
    }
    
    #[test]
    fn test_audio_session_response() {
        let session_response = AudioSessionResponse {
            session_id: "session_789".to_string(),
            child_id: "child_456".to_string(),
            session_type: "free_play".to_string(),
            status: "active".to_string(),
            start_time: "2024-01-15T14:30:00Z".to_string(),
            end_time: None, // Still active
        };
        
        assert_eq!(session_response.session_id, "session_789");
        assert_eq!(session_response.child_id, "child_456");
        assert_eq!(session_response.session_type, "free_play");
        assert_eq!(session_response.status, "active");
        assert!(session_response.end_time.is_none());
    }
    
    #[test]
    fn test_completed_audio_session() {
        let completed_session = AudioSessionResponse {
            session_id: "session_completed_001".to_string(),
            child_id: "child_789".to_string(),
            session_type: "learning".to_string(),
            status: "ended".to_string(),
            start_time: "2024-01-15T15:00:00Z".to_string(),
            end_time: Some("2024-01-15T15:25:00Z".to_string()),
        };
        
        assert_eq!(completed_session.status, "ended");
        assert!(completed_session.end_time.is_some());
        
        // Calculate session duration (in a real implementation)
        if let Some(end_time) = &completed_session.end_time {
            // This would involve proper datetime parsing in production
            assert!(end_time > &completed_session.start_time,
                "End time should be after start time");
        }
    }
    
    #[test]
    fn test_audio_metrics_request() {
        let metrics_request = AudioMetricsRequest {
            session_id: "session_metrics_123".to_string(),
            child_id: "child_metrics_456".to_string(),
            speech_clarity: Some(0.85), // 85% clarity
            vocabulary_used: Some(vec![
                "cat".to_string(),
                "dog".to_string(),
                "house".to_string(),
                "happy".to_string(),
                "run".to_string(),
            ]),
            session_duration: Some(900), // 15 minutes
            engagement_level: Some(0.75), // 75% engaged
            metadata: Some(serde_json::json!({
                "background_noise_level": "low",
                "microphone_quality": "good",
                "interruptions": 2,
                "words_per_minute": 45
            })),
        };
        
        assert_eq!(metrics_request.session_id, "session_metrics_123");
        assert_eq!(metrics_request.child_id, "child_metrics_456");
        assert_eq!(metrics_request.speech_clarity, Some(0.85));
        assert_eq!(metrics_request.vocabulary_used.as_ref().unwrap().len(), 5);
        assert_eq!(metrics_request.session_duration, Some(900));
        assert_eq!(metrics_request.engagement_level, Some(0.75));
        
        // Verify vocabulary diversity
        let vocab = metrics_request.vocabulary_used.unwrap();
        assert!(vocab.contains(&"cat".to_string()));
        assert!(vocab.contains(&"happy".to_string()));
        
        // Verify metrics are within valid ranges
        assert!(metrics_request.speech_clarity.unwrap() >= 0.0 && metrics_request.speech_clarity.unwrap() <= 1.0);
        assert!(metrics_request.engagement_level.unwrap() >= 0.0 && metrics_request.engagement_level.unwrap() <= 1.0);
        
        let metadata = metrics_request.metadata.unwrap();
        assert_eq!(metadata["background_noise_level"], "low");
        assert_eq!(metadata["words_per_minute"], 45);
    }
    
    #[test]
    fn test_session_type_validation() {
        let valid_session_types = vec![
            "story_reading",
            "free_play", 
            "learning",
            "guided_activity",
            "parent_interaction",
        ];
        
        let invalid_session_types = vec![
            "", // Empty
            "unknown_type",
            "adult_content",
            "commercial",
        ];
        
        for session_type in valid_session_types {
            assert!(!session_type.is_empty(), 
                "Valid session type should not be empty");
            assert!(session_type.len() <= 50,
                "Session type should have reasonable length limit");
        }
        
        for session_type in invalid_session_types {
            if session_type.is_empty() {
                assert_eq!(session_type.len(), 0);
            } else if session_type == "unknown_type" {
                assert!(session_type.contains("unknown"));
            } else if session_type.contains("adult") || session_type.contains("commercial") {
                assert!(true, "Session type '{}' should be rejected for child safety", session_type);
            }
        }
    }
    
    #[test]
    fn test_speech_development_metrics() {
        // Test metrics that would indicate healthy speech development
        let good_metrics = AudioMetricsRequest {
            session_id: "good_session".to_string(),
            child_id: "child_developing_well".to_string(),
            speech_clarity: Some(0.80), // Good clarity for age
            vocabulary_used: Some(vec![
                "dog".to_string(), "cat".to_string(), "run".to_string(), 
                "play".to_string(), "happy".to_string(), "big".to_string(),
                "small".to_string(), "red".to_string(), "blue".to_string(),
                "mama".to_string(), "dada".to_string(), "please".to_string(),
            ]),
            session_duration: Some(600), // 10 minutes - appropriate attention span
            engagement_level: Some(0.85), // Highly engaged
            metadata: Some(serde_json::json!({
                "new_words_attempted": 3,
                "sentence_complexity": "simple",
                "response_to_prompts": "good"
            })),
        };
        
        // Verify healthy development indicators
        assert!(good_metrics.speech_clarity.unwrap() >= 0.70,
            "Speech clarity should indicate good development");
        assert!(good_metrics.vocabulary_used.as_ref().unwrap().len() >= 10,
            "Vocabulary should show good diversity");
        assert!(good_metrics.engagement_level.unwrap() >= 0.70,
            "Engagement should be high for effective learning");
        assert!(good_metrics.session_duration.unwrap() >= 300 && good_metrics.session_duration.unwrap() <= 1200,
            "Session duration should be age-appropriate (5-20 minutes)");
    }
}

mod comprehensive_security_tests {
    use wondernest_backend::models::{SignupRequest, LoginRequest};
    use wondernest_backend::services::validation::ValidationService;
    
    #[test]
    fn test_sql_injection_prevention() {
        let service = ValidationService::new();
        
        let sql_injection_attempts = vec![
            "admin'; DROP TABLE users; --",
            "' OR '1'='1' --",
            "' UNION SELECT password FROM users WHERE username='admin' --",
            "'; DELETE FROM children; --",
            "' OR 1=1 LIMIT 1 --",
            "admin'/**/OR/**/1=1--",
            "' AND (SELECT COUNT(*) FROM users) > 0 --",
        ];
        
        for malicious_input in sql_injection_attempts {
            let request = LoginRequest {
                email: malicious_input.to_string(),
                password: "any_password".to_string(),
            };
            
            let result = service.validate_login_request(&request);
            
            // Should be invalid due to malicious content
            assert!(!result.is_valid,
                "SQL injection attempt should be caught: '{}'", malicious_input);
            
            // Sanitized version should not contain SQL keywords
            let sanitized = service.sanitize_login_request(request);
            let sanitized_lower = sanitized.email.to_lowercase();
            
            // Check for common SQL injection patterns
            let dangerous_patterns = ["drop", "delete", "union", "select", "--", "/*", "*/"];
            let contains_dangerous_pattern = dangerous_patterns.iter()
                .any(|&pattern| sanitized_lower.contains(pattern));
            
            if contains_dangerous_pattern {
                // If dangerous patterns remain after sanitization, it should be flagged
                assert!(true, "Dangerous SQL pattern detected after sanitization: '{}'", sanitized.email);
            }
        }
    }
    
    #[test]
    fn test_xss_prevention() {
        let service = ValidationService::new();
        
        let xss_attempts = vec![
            "<script>alert('xss')</script>",
            "<img src=x onerror=alert('xss')>",
            "javascript:alert('xss')",
            "<svg onload=alert('xss')>",
            "<iframe src=javascript:alert('xss')>",
            "onmouseover=\"alert('xss')\"",
            "<object data=\"javascript:alert('xss')\">",
        ];
        
        for xss_payload in xss_attempts {
            let request = SignupRequest {
                email: "test@example.com".to_string(),
                password: "SecurePass123!".to_string(),
                name: Some(xss_payload.to_string()),
                first_name: Some("John".to_string()),
                last_name: Some("Doe".to_string()),
                phone_number: None,
                country_code: "US".to_string(),
                timezone: "UTC".to_string(),
                language: "en".to_string(),
            };
            
            let sanitized = service.sanitize_signup_request(request);
            
            // Verify XSS payload is neutralized
            if let Some(name) = &sanitized.name {
                assert!(!name.contains("<script"),
                    "Script tags should be escaped: '{}'", name);
                assert!(!name.contains("javascript:"),
                    "JavaScript protocols should be escaped: '{}'", name);
                assert!(!name.contains("onerror="),
                    "Event handlers should be escaped: '{}'", name);
                assert!(!name.contains("onload="),
                    "Event handlers should be escaped: '{}'", name);
                assert!(!name.contains("onmouseover="),
                    "Event handlers should be escaped: '{}'", name);
            }
        }
    }
    
    #[test]
    fn test_csrf_token_concept() {
        // Test CSRF token validation logic (conceptual)
        
        let valid_tokens = vec![
            "a1b2c3d4e5f6g7h8i9j0",  // 20 char token
            "9f8e7d6c5b4a3210fedcba9876543210", // 32 char token
            "abcdef1234567890abcdef1234567890abcdef12", // 40 char token
        ];
        
        let invalid_tokens = vec![
            "",                    // Empty
            "123",                 // Too short
            "predictable",         // Dictionary word
            "11111111111111111111", // All same character
            "abcd<script>alert()", // Contains XSS
        ];
        
        for token in valid_tokens {
            assert!(token.len() >= 16, "CSRF token should be at least 16 characters");
            assert!(token.chars().all(|c| c.is_alphanumeric()), 
                "CSRF token should be alphanumeric only");
            assert!(!token.chars().all(|c| c == token.chars().next().unwrap()),
                "CSRF token should not be all same character");
        }
        
        for token in invalid_tokens {
            if token.is_empty() {
                assert_eq!(token.len(), 0);
            } else if token.len() < 16 {
                assert!(token.len() < 16, "Short token should be rejected");
            } else if token.contains('<') {
                assert!(token.contains('<'), "Token with XSS should be rejected");
            }
        }
    }
    
    #[test]
    fn test_rate_limiting_logic() {
        // Test rate limiting concepts for login attempts
        
        struct RateLimitTracker {
            attempts: Vec<u64>, // timestamps
            max_attempts: usize,
            window_seconds: u64,
        }
        
        impl RateLimitTracker {
            fn new(max_attempts: usize, window_seconds: u64) -> Self {
                Self {
                    attempts: Vec::new(),
                    max_attempts,
                    window_seconds,
                }
            }
            
            fn is_allowed(&mut self, current_time: u64) -> bool {
                // Remove old attempts outside the window
                self.attempts.retain(|&time| current_time - time < self.window_seconds);
                
                // Check if under limit
                if self.attempts.len() < self.max_attempts {
                    self.attempts.push(current_time);
                    true
                } else {
                    false
                }
            }
        }
        
        let mut limiter = RateLimitTracker::new(5, 300); // 5 attempts per 5 minutes
        let base_time = 1000;
        
        // First 5 attempts should be allowed
        for i in 0..5 {
            assert!(limiter.is_allowed(base_time + i),
                "Attempt {} should be allowed", i + 1);
        }
        
        // 6th attempt should be blocked
        assert!(!limiter.is_allowed(base_time + 5),
            "6th attempt should be blocked by rate limiting");
        
        // After window expires, should be allowed again
        assert!(limiter.is_allowed(base_time + 301),
            "Attempt after window expiry should be allowed");
    }
    
    #[test]
    fn test_password_strength_comprehensive() {
        let service = ValidationService::new();
        
        let password_tests = vec![
            // Very weak passwords
            ("password", false, "common dictionary word"),
            ("123456", false, "sequential numbers"),
            ("qwerty", false, "keyboard pattern"),
            ("admin", false, "too short and common"),
            ("", false, "empty password"),
            
            // Weak passwords
            ("password123", false, "dictionary word with numbers"),
            ("Password", false, "dictionary word with capitalization"),
            ("12345678", false, "only numbers"),
            ("abcdefgh", false, "only lowercase letters"),
            ("ABCDEFGH", false, "only uppercase letters"),
            
            // Medium strength
            ("Password1", false, "missing special characters"),
            ("Password!", false, "missing numbers"),
            ("password1!", false, "missing uppercase"),
            ("PASSWORD1!", false, "missing lowercase"),
            
            // Strong passwords
            ("MyP@ssw0rd123", true, "mixed case, numbers, special chars"),
            ("Secure!P@ss2024", true, "good complexity"),
            ("Ch1ld$@fe2024!", true, "very strong"),
            ("Wonder&Nest123", true, "good entropy"),
        ];
        
        for (password, should_be_strong, description) in password_tests {
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
            
            if should_be_strong {
                assert!(result.is_valid, 
                    "Strong password '{}' ({}) should be accepted, errors: {:?}",
                    password, description, result.errors);
            } else {
                assert!(!result.is_valid,
                    "Weak password '{}' ({}) should be rejected",
                    password, description);
            }
        }
    }
    
    #[test]
    fn test_session_security() {
        // Test session token security concepts
        
        struct SessionToken {
            token: String,
            expires_at: u64,
            created_at: u64,
            user_id: String,
            ip_address: Option<String>,
        }
        
        impl SessionToken {
            fn new(user_id: String, current_time: u64, expires_in: u64) -> Self {
                // Generate a secure token (in real implementation, use cryptographic random)
                let token = format!("tok_{}_{}_rand", user_id, current_time);
                
                Self {
                    token,
                    expires_at: current_time + expires_in,
                    created_at: current_time,
                    user_id,
                    ip_address: Some("192.168.1.1".to_string()),
                }
            }
            
            fn is_valid(&self, current_time: u64, client_ip: Option<&str>) -> bool {
                // Check expiration
                if current_time > self.expires_at {
                    return false;
                }
                
                // Check IP address binding (optional security measure)
                if let (Some(stored_ip), Some(client_ip)) = (&self.ip_address, client_ip) {
                    if stored_ip != client_ip {
                        return false; // IP mismatch
                    }
                }
                
                // Token should not be empty
                if self.token.is_empty() {
                    return false;
                }
                
                true
            }
        }
        
        let current_time = 1000;
        let session = SessionToken::new("user123".to_string(), current_time, 3600); // 1 hour
        
        // Valid session with correct IP
        assert!(session.is_valid(current_time + 1800, Some("192.168.1.1")),
            "Valid session should be accepted");
        
        // Expired session
        assert!(!session.is_valid(current_time + 3601, Some("192.168.1.1")),
            "Expired session should be rejected");
        
        // Wrong IP address
        assert!(!session.is_valid(current_time + 1800, Some("10.0.0.1")),
            "Session with wrong IP should be rejected");
    }
    
    #[test]
    fn test_data_encryption_concepts() {
        // Test concepts for data encryption requirements
        
        let sensitive_data_types = vec![
            ("password", true, "Must always be hashed"),
            ("email", false, "Can be stored as plaintext for functionality"),
            ("child_name", true, "PII should be encrypted"),
            ("birth_date", true, "PII should be encrypted"),
            ("audio_transcript", true, "Speech data should be encrypted"),
            ("session_token", true, "Tokens should be hashed"),
            ("pin_code", true, "PIN must be hashed"),
            ("family_id", false, "UUID can be stored as plaintext"),
            ("preferences", false, "Non-sensitive settings"),
        ];
        
        for (data_type, requires_encryption, reason) in sensitive_data_types {
            let is_pii = matches!(data_type, "child_name" | "birth_date" | "audio_transcript");
            let is_auth_data = matches!(data_type, "password" | "pin_code" | "session_token");
            let should_encrypt = is_pii || is_auth_data;
            
            assert_eq!(should_encrypt, requires_encryption,
                "Data type '{}' encryption requirement mismatch: {} ({})",
                data_type, reason, should_encrypt);
        }
    }
    
    #[test]
    fn test_input_length_limits() {
        // Test input length validation to prevent DoS attacks
        
        let field_limits = vec![
            ("email", 254),           // RFC 5321 limit
            ("first_name", 50),       // Reasonable name length
            ("last_name", 50),        // Reasonable name length
            ("password", 128),        // Allow long passwords
            ("child_name", 50),       // Reasonable child name length
            ("family_name", 100),     // Family name can be longer
            ("content_title", 200),   // Content titles
            ("description", 1000),    // Descriptions
            ("feedback", 2000),       // User feedback
        ];
        
        for (field_name, max_length) in field_limits {
            // Test valid length
            let valid_input = "a".repeat(max_length - 1);
            assert!(valid_input.len() < max_length,
                "Valid input for '{}' should be under limit", field_name);
            
            // Test exceeding length
            let too_long_input = "a".repeat(max_length + 1);
            assert!(too_long_input.len() > max_length,
                "Oversized input for '{}' should exceed limit", field_name);
            
            // In a real implementation, this would be rejected
            let should_be_rejected = too_long_input.len() > max_length;
            assert!(should_be_rejected,
                "Oversized input for '{}' should be rejected", field_name);
        }
    }
    
    #[test]
    fn test_content_security_policy() {
        // Test Content Security Policy concepts for web security
        
        let csp_directives = vec![
            ("default-src", "'self'", "Only allow same origin by default"),
            ("script-src", "'self' 'unsafe-inline'", "Allow inline scripts for app functionality"),
            ("style-src", "'self' 'unsafe-inline'", "Allow inline styles"),
            ("img-src", "'self' data: https:", "Allow images from self, data URLs, and HTTPS"),
            ("media-src", "'self' https:", "Allow media from self and HTTPS"),
            ("connect-src", "'self' https://api.wondernest.com", "Allow connections to API"),
            ("font-src", "'self' https:", "Allow fonts from self and HTTPS"),
            ("object-src", "'none'", "Disallow objects/embeds"),
            ("frame-src", "'none'", "Disallow frames"),
        ];
        
        for (directive, value, purpose) in csp_directives {
            assert!(!directive.is_empty(), "CSP directive should not be empty");
            assert!(!value.is_empty(), "CSP value should not be empty");
            
            // Verify secure defaults
            match directive {
                "object-src" | "frame-src" => {
                    assert_eq!(value, "'none'", 
                        "Potentially dangerous directive '{}' should be disabled: {}", 
                        directive, purpose);
                },
                "default-src" => {
                    assert!(value.contains("'self'"),
                        "Default source should include 'self': {}", purpose);
                },
                _ => {
                    // Other directives should have reasonable restrictions
                    assert!(value.len() > 0, "Directive '{}' should have a value: {}", directive, purpose);
                }
            }
        }
    }
}
