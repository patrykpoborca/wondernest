use axum::{middleware, Router};

use crate::{middleware::auth_middleware, services::AppState};

mod auth;
mod content_packs;
mod family;

pub fn router() -> Router<AppState> {
    let protected_routes = Router::new()
        .nest("/family", family::router())
        .nest("/content-packs", content_packs::router())
        .layer(middleware::from_fn(auth_middleware));

    Router::new()
        // Auth routes (no middleware)
        .nest("/auth", auth::router())
        // Protected routes with middleware
        .merge(protected_routes)
}