pub mod admin_auth_service;
// pub mod admin_content_service_simple; // Temporarily disabled - needs model fixes
pub mod admin_jwt;
pub mod auth;
pub mod auth_service;
pub mod content_pack;
pub mod content_pack_service;
pub mod content_publishing_service;
pub mod content_moderation_service;
pub mod content_validation;
pub mod family;
pub mod file_access_controller;
pub mod file_reference_service;
pub mod game_data;
pub mod game_data_service;
pub mod jwt;
pub mod password;
pub mod signed_url_service;
pub mod storage;
pub mod validation;

use crate::config::Config;
use std::sync::Arc;
use storage::StorageProvider;

#[derive(Clone)]
pub struct AppState {
    pub db: sqlx::PgPool,
    pub redis: redis::aio::ConnectionManager,
    pub config: Config,
    pub storage: Arc<dyn StorageProvider>,
    pub file_access: file_access_controller::FileAccessController,
    pub signed_url: signed_url_service::SignedUrlService,
    pub content_pack: content_pack_service::ContentPackService,
    pub admin_auth: admin_auth_service::AdminAuthService,
    // pub admin_content: admin_content_service_simple::AdminContentService, // Temporarily disabled
}