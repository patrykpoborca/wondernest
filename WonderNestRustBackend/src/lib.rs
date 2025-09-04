// WonderNest Backend Library
// This file exposes modules for testing and library usage

pub mod config;
pub mod db;
pub mod error;
pub mod extractors;
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
use axum::{Router, http::{HeaderValue, Method}};
use tower_http::cors::{CorsLayer, Any};
use tower_http::trace::TraceLayer;
use tower_http::compression::CompressionLayer;
use tower::ServiceBuilder;
use std::time::Duration;

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

    // Configure CORS for production
    let cors = CorsLayer::new()
        .allow_origin([
            "http://localhost:3000".parse::<HeaderValue>().unwrap(), // Flutter web dev
            "http://localhost:3001".parse::<HeaderValue>().unwrap(), // Website dev port
            "http://localhost:8080".parse::<HeaderValue>().unwrap(), // Alternative dev port
            "https://wondernest.app".parse::<HeaderValue>().unwrap(), // Production domain
        ])
        .allow_methods([
            Method::GET,
            Method::POST, 
            Method::PUT,
            Method::DELETE,
            Method::OPTIONS,
            Method::PATCH,
        ])
        .allow_headers([
            "authorization".parse().unwrap(),
            "content-type".parse().unwrap(),
            "accept".parse().unwrap(),
            "origin".parse().unwrap(),
            "user-agent".parse().unwrap(),
            "x-requested-with".parse().unwrap(),
        ])
        .allow_credentials(true)
        .max_age(Duration::from_secs(3600)); // Cache preflight for 1 hour

    // Build router with comprehensive middleware stack
    let app = Router::new()
        // Health check endpoints (no auth required)
        .nest("/health", routes::health::router())
        // API v1 routes
        .nest("/api/v1", routes::v1::router())
        // API v2 routes (for game data)
        .nest("/api/v2", routes::v2::router())
        // Add production middleware stack
        .layer(
            ServiceBuilder::new()
                .layer(TraceLayer::new_for_http()) // Request tracing first
                .layer(CompressionLayer::new()) // Compress responses
                .layer(cors) // CORS last
        )
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