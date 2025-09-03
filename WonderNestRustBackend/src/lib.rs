// WonderNest Backend Library
// This file exposes modules for testing and library usage

pub mod config;
pub mod db;
pub mod error;
pub mod middleware;
pub mod models;
pub mod routes;
pub mod services;

// Re-export commonly used types
pub use config::Config;
pub use error::AppError;

// Re-export services for testing
pub use services::{
    AppState,
    auth_service::{AuthService, AuthServiceError},
    jwt::JwtService,
    password::PasswordService,
    validation::ValidationService,
    content_pack::ContentPackService,
};

// Re-export models for testing
pub use models::{
    User, UserSession, Family, FamilyMember, ChildProfile,
    SignupRequest, LoginRequest, AuthResponse, AuthData,
    PinVerificationRequest, PinVerificationResponse,
    MessageResponse, TokenPair,
};

// Re-export database repositories for testing
pub use db::{
    UserRepository, FamilyRepository,
};

// Create app function for testing and main
use axum::Router;
use tower_http::cors::CorsLayer;
use tower_http::trace::TraceLayer;

pub async fn create_app(
    db_pool: sqlx::PgPool,
    redis_conn: redis::aio::ConnectionManager,
    config: config::Config,
) -> anyhow::Result<Router> {
    // Create application state
    let state = services::AppState {
        db: db_pool,
        redis: redis_conn,
        config,
    };

    // Build router
    let app = Router::new()
        // Health check endpoints (no auth required)
        .nest("/health", routes::health::router())
        // API v1 routes
        .nest("/api/v1", routes::v1::router())
        // API v2 routes (for game data)
        .nest("/api/v2", routes::v2::router())
        // Add middleware
        .layer(CorsLayer::permissive()) // TODO: Configure properly
        .layer(TraceLayer::new_for_http())
        .with_state(state);

    Ok(app)
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_library_exports() {
        // Simple test to ensure library exports are working
        let _ = std::mem::size_of::<SignupRequest>();
        let _ = std::mem::size_of::<LoginRequest>();
        assert!(true);
    }
}