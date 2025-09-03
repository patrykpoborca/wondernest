use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    routing::get,
    Json, Router,
};
use chrono::Utc;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

use crate::services::AppState;

#[derive(Serialize, Deserialize)]
struct HealthResponse {
    status: String,
}

#[derive(Serialize, Deserialize)]
struct DetailedHealthResponse {
    status: String,
    timestamp: String,
    version: String,
    environment: String,
    services: HashMap<String, ServiceHealth>,
}

#[derive(Serialize, Deserialize)]
struct ServiceHealth {
    status: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    message: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none", rename = "responseTime")]
    response_time: Option<u64>,
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/", get(health_check).head(health_check_head))
        .route("/detailed", get(health_detailed))
        .route("/ready", get(health_ready))
        .route("/live", get(health_live))
        .route("/startup", get(health_startup))
}

// Basic health check - minimal response for load balancers
async fn health_check() -> impl IntoResponse {
    Json(HealthResponse {
        status: "UP".to_string(),
    })
}

// HEAD support for health check (used by load balancers)
async fn health_check_head() -> impl IntoResponse {
    StatusCode::OK
}

// Detailed health check with service status
async fn health_detailed(State(state): State<AppState>) -> impl IntoResponse {
    let _start = std::time::Instant::now();
    let mut services = HashMap::new();

    // Check database health
    let db_start = std::time::Instant::now();
    let db_healthy = sqlx::query("SELECT 1")
        .fetch_one(&state.db)
        .await
        .is_ok();
    let db_response_time = db_start.elapsed().as_millis() as u64;

    services.insert(
        "database".to_string(),
        ServiceHealth {
            status: if db_healthy { "UP" } else { "DOWN" }.to_string(),
            message: Some(if db_healthy {
                "Connected".to_string()
            } else {
                "Connection failed".to_string()
            }),
            response_time: Some(db_response_time),
        },
    );

    // Check Redis health
    let redis_start = std::time::Instant::now();
    let mut redis_conn = state.redis.clone();
    let redis_healthy = redis::cmd("PING")
        .query_async::<_, String>(&mut redis_conn)
        .await
        .is_ok();
    let redis_response_time = redis_start.elapsed().as_millis() as u64;

    services.insert(
        "redis".to_string(),
        ServiceHealth {
            status: if redis_healthy { "UP" } else { "DOWN" }.to_string(),
            message: Some(if redis_healthy {
                "Connected".to_string()
            } else {
                "Connection failed".to_string()
            }),
            response_time: Some(redis_response_time),
        },
    );

    let overall_healthy = db_healthy && redis_healthy;
    let status = if overall_healthy { "UP" } else { "DOWN" };

    let response = DetailedHealthResponse {
        status: status.to_string(),
        timestamp: Utc::now().to_rfc3339(),
        version: "0.0.1".to_string(),
        environment: std::env::var("RUST_ENV").unwrap_or_else(|_| "unknown".to_string()),
        services,
    };

    if overall_healthy {
        (StatusCode::OK, Json(response))
    } else {
        (StatusCode::SERVICE_UNAVAILABLE, Json(response))
    }
}

// Readiness check - indicates the app is ready to receive traffic
async fn health_ready(State(state): State<AppState>) -> impl IntoResponse {
    let db_healthy = sqlx::query("SELECT 1")
        .fetch_one(&state.db)
        .await
        .is_ok();

    let mut redis_conn = state.redis.clone();
    let redis_healthy = redis::cmd("PING")
        .query_async::<_, String>(&mut redis_conn)
        .await
        .is_ok();

    if db_healthy && redis_healthy {
        (
            StatusCode::OK,
            Json(serde_json::json!({
                "status": "READY"
            })),
        ).into_response()
    } else {
        (
            StatusCode::SERVICE_UNAVAILABLE,
            Json(serde_json::json!({
                "status": "NOT_READY",
                "database": if db_healthy { "UP" } else { "DOWN" },
                "redis": if redis_healthy { "UP" } else { "DOWN" }
            })),
        ).into_response()
    }
}

// Liveness check - indicates the app is alive (basic check)
async fn health_live() -> impl IntoResponse {
    Json(serde_json::json!({
        "status": "ALIVE"
    }))
}

// Startup check - indicates the app has finished starting up
async fn health_startup(State(state): State<AppState>) -> impl IntoResponse {
    let db_initialized = sqlx::query("SELECT 1")
        .fetch_one(&state.db)
        .await
        .is_ok();

    if db_initialized {
        (
            StatusCode::OK,
            Json(serde_json::json!({
                "status": "STARTED"
            })),
        ).into_response()
    } else {
        (
            StatusCode::SERVICE_UNAVAILABLE,
            Json(serde_json::json!({
                "status": "STARTING"
            })),
        ).into_response()
    }
}