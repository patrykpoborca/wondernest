use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::IntoResponse,
    routing::{delete, get, put},
    Json, Router,
};
use serde::Deserialize;
use uuid::Uuid;

use crate::{
    extractors::AuthClaims,
    error::AppResult,
    models::{SaveGameDataRequest},
    services::{AppState, game_data_service::GameDataService},
};

#[derive(Debug, Deserialize)]
pub struct GameDataQuery {
    #[serde(rename = "gameType")]
    pub game_type: Option<String>,
    #[serde(rename = "dataKey")]
    pub data_key: Option<String>,
}

pub fn router() -> Router<AppState> {
    Router::new()
        // Save or update game data for a child (matching Kotlin PUT /children/{childId}/data)
        .route("/children/:child_id/data", put(save_game_data))
        
        // Get all game data for a child with optional filters (matching Kotlin GET /children/{childId}/data)
        .route("/children/:child_id/data", get(load_game_data))
        
        // Get specific game data item (matching Kotlin GET /children/{childId}/data/{gameType}/{dataKey})
        .route("/children/:child_id/data/:game_type/:data_key", get(get_game_data_item))
        
        // Delete specific game data (matching Kotlin DELETE /children/{childId}/data/{gameType}/{dataKey})
        .route("/children/:child_id/data/:game_type/:data_key", delete(delete_game_data_item))
        
        // Delete all game data for a child and game type (matching Kotlin DELETE /children/{childId}/data/{gameType})
        .route("/children/:child_id/data/:game_type", delete(delete_game_data_for_type))
}

// Save or update game data for a child (matching Kotlin exactly)
async fn save_game_data(
    State(state): State<AppState>,
    Path(child_id_str): Path<String>,
    Json(request): Json<SaveGameDataRequest>,
) -> AppResult<axum::response::Response> {
    // Parse child ID
    let child_id = match Uuid::parse_str(&child_id_str) {
        Ok(id) => id,
        Err(_) => {
            return Ok((StatusCode::BAD_REQUEST, "Invalid child ID format").into_response());
        }
    };

    // Validate request
    if request.game_type.is_empty() || request.data_key.is_empty() {
        return Ok((StatusCode::BAD_REQUEST, "Game type and data key are required").into_response());
    }

    let game_service = GameDataService::new(state.db.clone());

    match game_service.save_game_data(child_id, request).await {
        Ok(response) => {
            if response.success {
                Ok((StatusCode::OK, Json(response)).into_response())
            } else {
                // Child not found case
                Ok((StatusCode::NOT_FOUND, response.message).into_response())
            }
        }
        Err(err) => {
            tracing::error!("Failed to save game data: {:?}", err);
            Ok((StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to save game data: {}", err)).into_response())
        }
    }
}

// Get all game data for a child with optional filters (matching Kotlin exactly)
async fn load_game_data(
    State(state): State<AppState>,
    Path(child_id_str): Path<String>,
    Query(query): Query<GameDataQuery>,
) -> AppResult<axum::response::Response> {
    // Parse child ID
    let child_id = match Uuid::parse_str(&child_id_str) {
        Ok(id) => id,
        Err(_) => {
            return Ok((StatusCode::BAD_REQUEST, "Invalid child ID format").into_response());
        }
    };

    let game_service = GameDataService::new(state.db.clone());

    match game_service.load_game_data(
        child_id,
        query.game_type.as_deref(),
        query.data_key.as_deref(),
    ).await {
        Ok(response) => {
            Ok((StatusCode::OK, Json(response)).into_response())
        }
        Err(err) => {
            tracing::error!("Failed to load game data: {:?}", err);
            Ok((StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to load game data: {}", err)).into_response())
        }
    }
}

// Get specific game data item (matching Kotlin exactly)
async fn get_game_data_item(
    State(state): State<AppState>,
    Path((child_id_str, game_type, data_key)): Path<(String, String, String)>,
) -> AppResult<axum::response::Response> {
    // Parse child ID
    let child_id = match Uuid::parse_str(&child_id_str) {
        Ok(id) => id,
        Err(_) => {
            return Ok((StatusCode::BAD_REQUEST, "Invalid child ID format").into_response());
        }
    };

    if game_type.is_empty() {
        return Ok((StatusCode::BAD_REQUEST, "Game type required").into_response());
    }

    if data_key.is_empty() {
        return Ok((StatusCode::BAD_REQUEST, "Data key required").into_response());
    }

    let game_service = GameDataService::new(state.db.clone());

    match game_service.get_game_data_item(child_id, &game_type, &data_key).await {
        Ok(Some(game_data)) => {
            Ok((StatusCode::OK, Json(game_data)).into_response())
        }
        Ok(None) => {
            Ok((StatusCode::NOT_FOUND, "Game data not found").into_response())
        }
        Err(err) => {
            tracing::error!("Failed to load game data: {:?}", err);
            Ok((StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to load game data: {}", err)).into_response())
        }
    }
}

// Delete specific game data (matching Kotlin exactly)
async fn delete_game_data_item(
    State(state): State<AppState>,
    Path((child_id_str, game_type, data_key)): Path<(String, String, String)>,
) -> AppResult<axum::response::Response> {
    // Parse child ID
    let child_id = match Uuid::parse_str(&child_id_str) {
        Ok(id) => id,
        Err(_) => {
            return Ok((StatusCode::BAD_REQUEST, "Invalid child ID format").into_response());
        }
    };

    if game_type.is_empty() {
        return Ok((StatusCode::BAD_REQUEST, "Game type required").into_response());
    }

    if data_key.is_empty() {
        return Ok((StatusCode::BAD_REQUEST, "Data key required").into_response());
    }

    let game_service = GameDataService::new(state.db.clone());

    match game_service.delete_game_data_item(child_id, &game_type, &data_key).await {
        Ok(response) => {
            if response.success {
                Ok((StatusCode::OK, Json(response)).into_response())
            } else {
                // Not found case
                Ok((StatusCode::NOT_FOUND, response.message).into_response())
            }
        }
        Err(err) => {
            tracing::error!("Failed to delete game data: {:?}", err);
            Ok((StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to delete game data: {}", err)).into_response())
        }
    }
}

// Delete all game data for a child and game type (matching Kotlin exactly)
async fn delete_game_data_for_type(
    State(state): State<AppState>,
    Path((child_id_str, game_type)): Path<(String, String)>,
) -> AppResult<axum::response::Response> {
    // Parse child ID
    let child_id = match Uuid::parse_str(&child_id_str) {
        Ok(id) => id,
        Err(_) => {
            return Ok((StatusCode::BAD_REQUEST, "Invalid child ID format").into_response());
        }
    };

    if game_type.is_empty() {
        return Ok((StatusCode::BAD_REQUEST, "Game type required").into_response());
    }

    let game_service = GameDataService::new(state.db.clone());

    match game_service.delete_game_data_for_type(child_id, &game_type).await {
        Ok(response) => {
            Ok((StatusCode::OK, Json(response)).into_response())
        }
        Err(err) => {
            tracing::error!("Failed to delete game data: {:?}", err);
            Ok((StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to delete game data: {}", err)).into_response())
        }
    }
}