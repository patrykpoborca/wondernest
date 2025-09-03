use axum::Router;

use crate::services::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        // Game data routes will go here
}