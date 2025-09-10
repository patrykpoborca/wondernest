use axum::Router;
use crate::services::AppState;

pub mod auth;
pub mod dashboard;
pub mod content_seeding;

/// Creates the admin router with all admin endpoints
pub fn router() -> Router<AppState> {
    Router::new()
        .nest("/auth", auth::router())
        .nest("/dashboard", dashboard::router())
        .nest("/content-seeding", content_seeding::routes())
}