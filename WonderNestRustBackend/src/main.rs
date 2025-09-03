mod config;
mod error;
mod middleware;
mod models;
mod routes;
mod services;
mod db;

use axum::Router;
use sqlx::postgres::PgPoolOptions;
use std::net::SocketAddr;
use tower_http::cors::CorsLayer;
use tower_http::trace::TraceLayer;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Load environment variables
    dotenv::dotenv().ok();

    // Initialize tracing
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "wondernest_backend=debug,tower_http=debug,axum=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Load configuration
    let config = config::Config::from_env()?;

    // Create database pool
    let db_pool = PgPoolOptions::new()
        .max_connections(config.database.max_connections)
        .connect(&config.database.url)
        .await?;

    tracing::info!("Database connected successfully");

    // Run migrations if needed (compatibility with existing Flyway migrations)
    // Note: We'll use existing migrations, not create new ones
    
    // Create Redis connection
    let redis_client = redis::Client::open(config.redis.url.clone())?;
    let redis_conn = redis::aio::ConnectionManager::new(redis_client).await?;
    
    tracing::info!("Redis connected successfully");

    // Build application
    let app = create_app(db_pool, redis_conn, config.clone()).await?;

    // Start server
    let addr = SocketAddr::from(([0, 0, 0, 0], config.server.port));
    tracing::info!("Starting server on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}

async fn create_app(
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