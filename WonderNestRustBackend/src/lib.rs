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
    UserRepository, FamilyRepository, MarketplaceRepository,
    AdminRepository,
};

// Create app function for testing and main
use axum::{
    Router, 
    http::{HeaderValue, Method},
    extract::DefaultBodyLimit,
};
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
    // Initialize storage provider
    let storage_config = services::storage::StorageConfigBuilder::from_environment()
        .map_err(|e| anyhow::anyhow!("Failed to load storage configuration: {}", e))?;
    let storage_provider = storage_config.create_provider().await
        .map_err(|e| anyhow::anyhow!("Failed to create storage provider: {}", e))?;

    // Create application state
    let file_access_controller = services::file_access_controller::FileAccessController::new(db_pool.clone());
    
    // Create signed URL service with secret from config
    let signed_url_secret = std::env::var("SIGNED_URL_SECRET")
        .unwrap_or_else(|_| config.jwt.secret.clone());
    let signed_url_service = services::signed_url_service::SignedUrlService::new(signed_url_secret, Some(24)); // 24 hour expiry
    
    // Create content pack service
    let file_reference_service = services::file_reference_service::FileReferenceService::new(db_pool.clone());
    let marketplace_repository = db::MarketplaceRepository::new(db_pool.clone());
    let content_pack_service = services::content_pack_service::ContentPackService::new(
        file_reference_service,
        signed_url_service.clone(),
        marketplace_repository,
    );
    
    // Create admin services
    let admin_repository = db::AdminRepository::new(db_pool.clone());
    let admin_auth_service = services::admin_auth_service::AdminAuthService::new(admin_repository);
    let admin_content_service = services::admin_content_service::AdminContentService::new(db_pool.clone());
    
    let state = services::AppState {
        db: db_pool,
        redis: redis_conn,
        config,
        storage: storage_provider,
        file_access: file_access_controller,
        signed_url: signed_url_service,
        content_pack: content_pack_service,
        admin_auth: admin_auth_service,
        admin_content: admin_content_service,
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
        // Admin routes (separate authentication system)
        .nest("/api/admin", routes::admin::router())
        // Add production middleware stack
        .layer(
            ServiceBuilder::new()
                .layer(DefaultBodyLimit::max(10 * 1024 * 1024)) // 10MB limit for file uploads
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