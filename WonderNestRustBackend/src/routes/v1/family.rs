use axum::{
    extract::{State},
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use chrono::Utc;
use uuid::Uuid;

use crate::{
    extractors::AuthClaims,
    error::AppResult,
    models::{CreateChildRequest, ChildProfile, Family},
    services::AppState,
};

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/profile", get(get_family_profile))
        .route("/children", post(create_child))
}

async fn get_family_profile(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Getting family profile for user: {}", claims.user_id);
    
    // Validate the user has a family_id
    let family_id = match claims.family_id {
        Some(id) => Uuid::parse_str(&id).map_err(|_| crate::error::AppError::BadRequest("Invalid family ID".to_string()))?,
        None => return Err(crate::error::AppError::BadRequest("No family associated with user".to_string())),
    };
    
    // Get family information
    let family = sqlx::query_as::<_, crate::models::Family>(
        r#"
        SELECT id, name, created_by, created_at, updated_at, NULL::timestamptz as archived_at
        FROM family.families 
        WHERE id = $1
        "#
    )
    .bind(family_id)
    .fetch_optional(&state.db)
    .await
    .map_err(|e| {
        tracing::error!("Failed to fetch family: {}", e);
        crate::error::AppError::InternalError("Failed to fetch family".to_string())
    })?;
    
    if family.is_none() {
        return Err(crate::error::AppError::NotFound("Family not found".to_string()));
    }
    
    let family = family.unwrap();
    
    // Get all children in the family
    let children = sqlx::query_as::<_, ChildProfile>(
        r#"
        SELECT id, family_id, name, nickname, birth_date, gender, avatar_url, 
               interests, favorite_colors, is_active, created_at, updated_at, archived_at
        FROM family.child_profiles
        WHERE family_id = $1 AND is_active = true
        ORDER BY birth_date DESC
        "#
    )
    .bind(family_id)
    .fetch_all(&state.db)
    .await
    .map_err(|e| {
        tracing::error!("Failed to fetch children: {}", e);
        crate::error::AppError::InternalError("Failed to fetch children".to_string())
    })?;
    
    // Get family members (parents/guardians)
    let members = sqlx::query!(
        r#"
        SELECT fm.id, fm.user_id, fm.role, fm.joined_at, 
               u.email, 
               COALESCE(NULLIF(CONCAT(u.first_name, ' ', u.last_name), ' '), u.email) as name
        FROM family.family_members fm
        JOIN core.users u ON fm.user_id = u.id
        WHERE fm.family_id = $1
        ORDER BY fm.joined_at ASC
        "#,
        family_id
    )
    .fetch_all(&state.db)
    .await
    .map_err(|e| {
        tracing::error!("Failed to fetch family members: {}", e);
        crate::error::AppError::InternalError("Failed to fetch family members".to_string())
    })?;
    
    // Format children for response
    let children_json: Vec<serde_json::Value> = children.iter().map(|child| {
        serde_json::json!({
            "id": child.id,
            "familyId": child.family_id,
            "name": child.name,
            "nickname": child.nickname,
            "birthDate": child.birth_date,
            "gender": child.gender,
            "avatarUrl": child.avatar_url,
            "interests": child.interests,
            "favoriteColors": child.favorite_colors,
            "isActive": child.is_active,
            "createdAt": child.created_at,
            "updatedAt": child.updated_at
        })
    }).collect();
    
    // Format members for response
    let members_json: Vec<serde_json::Value> = members.iter().map(|member| {
        serde_json::json!({
            "id": member.id,
            "userId": member.user_id,
            "email": member.email,
            "name": member.name,
            "role": member.role,
            "joinedAt": member.joined_at
        })
    }).collect();
    
    tracing::info!("Found {} children and {} members for family {}", children.len(), members.len(), family.name);
    
    Ok(Json(serde_json::json!({
        "success": true,
        "data": {
            "family": {
                "id": family.id,
                "name": family.name,
                "createdAt": family.created_at,
                "updatedAt": family.updated_at
            },
            "members": members_json,
            "children": children_json
        }
    })))
}

async fn create_child(
    State(state): State<AppState>,
    AuthClaims(claims): AuthClaims,
    Json(request): Json<CreateChildRequest>,
) -> AppResult<impl IntoResponse> {
    tracing::info!("Creating child profile: name={}, family_id={}", request.name, claims.family_id.as_ref().unwrap_or(&"None".to_string()));
    
    // Validate the user has a family_id
    let family_id = match claims.family_id {
        Some(id) => Uuid::parse_str(&id).map_err(|_| crate::error::AppError::BadRequest("Invalid family ID".to_string()))?,
        None => return Err(crate::error::AppError::BadRequest("No family associated with user".to_string())),
    };
    
    // Parse birth date
    let birth_date = chrono::NaiveDate::parse_from_str(&request.birth_date, "%Y-%m-%d")
        .map_err(|_| crate::error::AppError::BadRequest("Invalid birth date format, use YYYY-MM-DD".to_string()))?;
    
    // Generate new child ID
    let child_id = Uuid::new_v4();
    let now = Utc::now();
    
    // Insert into database
    let child = sqlx::query_as::<_, ChildProfile>(
        r#"
        INSERT INTO family.child_profiles 
        (id, family_id, name, nickname, birth_date, gender, avatar_url, interests, favorite_colors, is_active, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, ARRAY[]::text[], true, $9, $10)
        RETURNING id, family_id, name, nickname, birth_date, gender, avatar_url, interests, favorite_colors, is_active, created_at, updated_at, archived_at
        "#
    )
    .bind(child_id)
    .bind(family_id)
    .bind(&request.name)
    .bind(None::<String>) // nickname
    .bind(birth_date)
    .bind(&request.gender)
    .bind(&request.avatar)
    .bind(&request.interests)
    .bind(now)
    .bind(now)
    .fetch_one(&state.db)
    .await
    .map_err(|e| {
        tracing::error!("Failed to create child profile: {}", e);
        crate::error::AppError::InternalError("Failed to create child profile".to_string())
    })?;
    
    tracing::info!("Child profile created successfully: id={}, name={}", child.id, child.name);
    
    Ok(Json(serde_json::json!({
        "success": true,
        "data": {
            "id": child.id,
            "familyId": child.family_id,
            "name": child.name,
            "nickname": child.nickname,
            "birthDate": child.birth_date,
            "gender": child.gender,
            "avatarUrl": child.avatar_url,
            "interests": child.interests,
            "favoriteColors": child.favorite_colors,
            "isActive": child.is_active,
            "createdAt": child.created_at,
            "updatedAt": child.updated_at
        }
    })))
}