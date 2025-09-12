use axum::{middleware, Router};

use crate::{
    extractors::AuthClaims,
    middleware::auth_middleware, 
    services::AppState
};

mod ai_story;
mod analytics;
mod audio;
mod auth;
mod content;
mod content_packs;
mod content_publishing;
mod content_moderation;
mod coppa;
mod creator_auth;
mod family;
mod file_upload;
mod marketplace;

pub fn router() -> Router<AppState> {
    let protected_routes = Router::new()
        .nest("/ai/story", ai_story::router())
        .nest("/family", family::router())
        .nest("/content-packs", content_packs::router())
        .nest("/content/publishing", content_publishing::router())
        .nest("/content/moderation", content_moderation::router())
        .nest("/coppa", coppa::router())
        .nest("/audio", audio::router())
        .nest("/analytics", analytics::router())
        .nest("/marketplace", marketplace::router())
        .merge(content::router()) // content routes are at the root level
        .layer(middleware::from_fn(auth_middleware));

    Router::new()
        // Auth routes (no middleware)
        .nest("/auth", auth::router())
        // Creator auth routes (separate auth system)
        .nest("/creators/auth", creator_auth::router())
        // File routes (mixed public/protected, handles its own auth)
        .nest("/files", file_upload::router())
        // Protected routes with middleware
        .merge(protected_routes)
}