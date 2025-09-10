use axum::{
    async_trait,
    extract::{FromRequestParts, rejection::JsonRejection},
    http::{request::Parts, StatusCode},
    response::{IntoResponse, Response},
    Json,
};
use serde_json::json;

use crate::middleware::auth::Claims;
use crate::services::admin_jwt::AdminClaims;

// Custom extractor for Claims that were added by auth middleware
pub struct AuthClaims(pub Claims);

#[async_trait]
impl<S> FromRequestParts<S> for AuthClaims
where
    S: Send + Sync,
{
    type Rejection = AuthClaimsRejection;

    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
        let claims = parts
            .extensions
            .get::<Claims>()
            .cloned()
            .ok_or(AuthClaimsRejection)?;

        Ok(AuthClaims(claims))
    }
}

// Custom rejection type for when claims are not found
pub struct AuthClaimsRejection;

impl IntoResponse for AuthClaimsRejection {
    fn into_response(self) -> Response {
        let body = Json(json!({
            "error": "Unauthorized",
            "message": "No valid authentication token found"
        }));

        (StatusCode::UNAUTHORIZED, body).into_response()
    }
}

// Optional claims extractor - doesn't fail if no claims
pub struct OptionalAuthClaims(pub Option<Claims>);

#[async_trait]
impl<S> FromRequestParts<S> for OptionalAuthClaims
where
    S: Send + Sync,
{
    type Rejection = std::convert::Infallible;

    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
        let claims = parts.extensions.get::<Claims>().cloned();
        Ok(OptionalAuthClaims(claims))
    }
}

// Custom extractor for AdminClaims that were added by admin auth middleware
pub struct AdminClaimsExtractor(pub AdminClaims);

#[async_trait]
impl<S> FromRequestParts<S> for AdminClaimsExtractor
where
    S: Send + Sync,
{
    type Rejection = AdminClaimsRejection;

    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
        let claims = parts
            .extensions
            .get::<AdminClaims>()
            .cloned()
            .ok_or(AdminClaimsRejection)?;

        Ok(AdminClaimsExtractor(claims))
    }
}

// Custom rejection type for when admin claims are not found
pub struct AdminClaimsRejection;

impl IntoResponse for AdminClaimsRejection {
    fn into_response(self) -> Response {
        let body = Json(json!({
            "error": "Unauthorized",
            "message": "No valid admin authentication token found"
        }));

        (StatusCode::UNAUTHORIZED, body).into_response()
    }
}