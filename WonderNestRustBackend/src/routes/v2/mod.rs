use axum::{middleware, Router};

use crate::{
    extractors::AuthClaims,
    middleware::auth_middleware, 
    services::AppState
};

mod games;
mod content;

pub fn router() -> Router<AppState> {
    Router::new()
        // Game data routes with JWT authentication required
        .nest("/games", games::router())
        // Content ecosystem routes with JWT authentication required
        .nest("/content", content::router())
        .layer(middleware::from_fn(auth_middleware))
}