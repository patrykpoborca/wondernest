// WonderNest Backend Test Suite
// Simplified unit tests focusing on core functionality

// Simple unit tests only
#[cfg(test)]
mod unit {
    pub mod auth_service_tests;
}

// Test configuration
use std::sync::Once;

static INIT: Once = Once::new();

/// Initialize test environment
pub fn init_test_env() {
    INIT.call_once(|| {
        // Set up environment variables for testing
        std::env::set_var("RUST_LOG", "debug");
        std::env::set_var("TEST_MODE", "true");
        
        // Initialize tracing for tests
        tracing_subscriber::fmt()
            .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
            .with_test_writer()
            .try_init()
            .ok(); // Ignore error if already initialized
    });
}

#[cfg(test)]
mod test_setup {
    use super::*;
    
    #[test]
    fn test_environment_setup() {
        init_test_env();
        assert_eq!(std::env::var("TEST_MODE").unwrap(), "true");
    }
}