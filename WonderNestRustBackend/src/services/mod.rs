pub mod auth;
pub mod auth_service;
pub mod content_pack;
pub mod family;
pub mod game_data;
pub mod jwt;
pub mod password;
pub mod validation;

use crate::config::Config;

#[derive(Clone)]
pub struct AppState {
    pub db: sqlx::PgPool,
    pub redis: redis::aio::ConnectionManager,
    pub config: Config,
}