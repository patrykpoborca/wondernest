use axum::{middleware, Router};

use crate::{
    extractors::AuthClaims,
    middleware::auth_middleware, 
    services::AppState
};

mod games;

pub fn router() -> Router<AppState> {
    Router::new()
        // Game data routes with JWT authentication required
        .nest("/games", games::router())
        .layer(middleware::from_fn(auth_middleware))
}