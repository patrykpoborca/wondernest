use axum::Router;
use crate::services::AppState;

pub mod auth;
pub mod dashboard;
// pub mod content_seeding; // Temporarily disabled - needs API compatibility fixes

/// Creates the admin router with all admin endpoints
pub fn router() -> Router<AppState> {
    Router::new()
        .nest("/auth", auth::router())
        .nest("/dashboard", dashboard::router())
        // .nest("/seed", content_seeding::routes()) // Temporarily disabled - needs API compatibility fixes
}