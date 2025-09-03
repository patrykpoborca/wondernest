use axum::{
    extract::{State, Request},
    response::IntoResponse,
    routing::get,
    Json, Router,
};

use crate::{
    error::AppResult,
    services::AppState,
};

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/profile", get(get_family_profile))
}

async fn get_family_profile(
    State(state): State<AppState>,
    req: Request,
) -> AppResult<impl IntoResponse> {
    // TODO: Implement actual family profile retrieval
    Ok(Json(serde_json::json!({
        "success": false,
        "error": "Not implemented yet"
    })))
}