use chrono::{DateTime, Duration, Utc};
use sqlx::PgPool;
use uuid::Uuid;

use crate::models::{
    User, UserSession, PasswordResetToken, Family, FamilyMember, ChildProfile, NewUser
};

pub struct UserRepository {
    pool: PgPool,
}

impl UserRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    // Get user by email (matching Kotlin getUserByEmail exactly)
    pub async fn get_user_by_email(&self, email: &str) -> anyhow::Result<Option<User>> {
        let user = sqlx::query_as::<_, User>(
            r#"
            SELECT * FROM core.users 
            WHERE email = $1 AND is_active = true
            "#
        )
        .bind(email.to_lowercase())
        .fetch_optional(&self.pool)
        .await?;
        
        Ok(user)
    }

    // Get user by ID (matching Kotlin getUserById exactly)
    pub async fn get_user_by_id(&self, user_id: Uuid) -> anyhow::Result<Option<User>> {
        let user = sqlx::query_as::<_, User>(
            r#"
            SELECT * FROM core.users 
            WHERE id = $1 AND is_active = true
            "#
        )
        .bind(user_id)
        .fetch_optional(&self.pool)
        .await?;
        
        Ok(user)
    }

    // Create user (matching Kotlin createUser exactly)
    pub async fn create_user(&self, new_user: &NewUser) -> anyhow::Result<User> {
        let now = Utc::now();
        
        let user = sqlx::query_as::<_, User>(
            r#"
            INSERT INTO core.users (
                id, email, password_hash, first_name, last_name, phone,
                email_verified, is_active, role, created_at, updated_at
            ) VALUES (
                $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11
            )
            RETURNING *
            "#
        )
        .bind(new_user.id)
        .bind(&new_user.email)
        .bind("") // password_hash - will be updated separately
        .bind(&new_user.first_name)
        .bind(&new_user.last_name)
        .bind(None::<String>) // phone
        .bind(false) // email_verified
        .bind(true) // is_active
        .bind("parent") // role
        .bind(now)
        .bind(now)
        .fetch_one(&self.pool)
        .await?;

        Ok(user)
    }

    // Update user password hash (matching Kotlin updateUserPassword exactly)
    pub async fn update_user_password(&self, user_id: Uuid, password_hash: &str) -> anyhow::Result<bool> {
        let result = sqlx::query(
            r#"
            UPDATE core.users 
            SET password_hash = $1, updated_at = CURRENT_TIMESTAMP
            WHERE id = $2            "#
        )
        .bind(password_hash)
        .bind(user_id)
        .execute(&self.pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    // Get user password hash (matching Kotlin getUserPasswordHash exactly)
    pub async fn get_user_password_hash(&self, user_id: Uuid) -> anyhow::Result<Option<String>> {
        let result = sqlx::query_scalar::<_, Option<String>>(
            r#"
            SELECT password_hash 
            FROM core.users 
            WHERE id = $1            "#
        )
        .bind(user_id)
        .fetch_one(&self.pool)
        .await?;

        Ok(result)
    }

    // Update last login (matching Kotlin updateLastLogin exactly)
    pub async fn update_last_login(&self, user_id: Uuid) -> anyhow::Result<bool> {
        let result = sqlx::query(
            r#"
            UPDATE core.users 
            SET updated_at = CURRENT_TIMESTAMP
            WHERE id = $1            "#
        )
        .bind(user_id)
        .execute(&self.pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    // Create user session (matching Kotlin createSession exactly)
    pub async fn create_session(&self, session: &UserSession) -> anyhow::Result<UserSession> {
        let result = sqlx::query_as::<_, UserSession>(
            r#"
            INSERT INTO core.user_sessions (
                id, user_id, token_hash, expires_at, created_at, last_accessed, device_info
            ) VALUES (
                $1, $2, $3, $4, $5, $6, $7
            )
            RETURNING id, user_id, token_hash, expires_at, created_at, last_accessed, device_info
            "#
        )
        .bind(session.id)
        .bind(session.user_id)
        .bind(&session.token_hash)
        .bind(session.expires_at)
        .bind(session.created_at)
        .bind(session.last_accessed)
        .bind(&session.device_info)
        .fetch_one(&self.pool)
        .await?;

        Ok(result)
    }

    // Get session by token (matching Kotlin getSessionByToken exactly)
    pub async fn get_session_by_token(&self, token_hash: &str) -> anyhow::Result<Option<UserSession>> {
        let session = sqlx::query_as::<_, UserSession>(
            r#"
            SELECT id, user_id, token_hash, expires_at, created_at, last_accessed, device_info
            FROM core.user_sessions 
            WHERE token_hash = $1 AND expires_at > CURRENT_TIMESTAMP
            "#
        )
        .bind(token_hash)
        .fetch_optional(&self.pool)
        .await?;
        
        Ok(session)
    }

    // Invalidate session (matching Kotlin invalidateSession exactly)
    pub async fn invalidate_session(&self, session_id: Uuid) -> anyhow::Result<bool> {
        let result = sqlx::query(
            r#"
            DELETE FROM core.user_sessions 
            WHERE id = $1
            "#
        )
        .bind(session_id)
        .execute(&self.pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    // Verify user email (matching Kotlin verifyUserEmail exactly)
    pub async fn verify_user_email(&self, user_id: Uuid) -> anyhow::Result<bool> {
        let result = sqlx::query(
            r#"
            UPDATE core.users 
            SET email_verified = true, 
                email_verified_at = CURRENT_TIMESTAMP,
                status = CASE WHEN status = 'pending_verification' THEN 'active' ELSE status END,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = $1            "#
        )
        .bind(user_id)
        .execute(&self.pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    // Create password reset token (matching Kotlin createPasswordResetToken exactly)
    pub async fn create_password_reset_token(&self, token: &PasswordResetToken) -> anyhow::Result<PasswordResetToken> {
        let result = sqlx::query_as::<_, PasswordResetToken>(
            r#"
            INSERT INTO core.password_reset_tokens (
                id, user_id, token, used, expires_at, created_at
            ) VALUES (
                $1, $2, $3, $4, $5, $6
            )
            RETURNING id, user_id, token, used, expires_at, created_at
            "#
        )
        .bind(token.id)
        .bind(token.user_id)
        .bind(&token.token)
        .bind(token.used)
        .bind(token.expires_at)
        .bind(token.created_at)
        .fetch_one(&self.pool)
        .await?;

        Ok(result)
    }

    // Get password reset token (matching Kotlin getPasswordResetToken exactly)
    pub async fn get_password_reset_token(&self, token: &str) -> anyhow::Result<Option<PasswordResetToken>> {
        let reset_token = sqlx::query_as::<_, PasswordResetToken>(
            r#"
            SELECT id, user_id, token, used, expires_at, created_at
            FROM core.password_reset_tokens 
            WHERE token = $1 AND used = false AND expires_at > CURRENT_TIMESTAMP
            "#
        )
        .bind(token)
        .fetch_optional(&self.pool)
        .await?;
        
        Ok(reset_token)
    }

    // Mark password reset token as used (matching Kotlin markPasswordResetTokenUsed exactly)
    pub async fn mark_password_reset_token_used(&self, token_id: Uuid) -> anyhow::Result<bool> {
        let result = sqlx::query(
            r#"
            UPDATE core.password_reset_tokens 
            SET used = true 
            WHERE id = $1
            "#
        )
        .bind(token_id)
        .execute(&self.pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }

    // Invalidate all user sessions (matching Kotlin invalidateAllUserSessions exactly)
    pub async fn invalidate_all_user_sessions(&self, user_id: Uuid) -> anyhow::Result<bool> {
        let result = sqlx::query(
            r#"
            DELETE FROM core.user_sessions 
            WHERE user_id = $1
            "#
        )
        .bind(user_id)
        .execute(&self.pool)
        .await?;

        Ok(result.rows_affected() > 0)
    }
}

// Family repository operations (needed for parent login with family context)
pub struct FamilyRepository {
    pool: PgPool,
}

impl FamilyRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    // Create family (matching Kotlin createFamily exactly)
    pub async fn create_family(&self, family: &Family) -> anyhow::Result<Family> {
        let result = sqlx::query_as::<_, Family>(
            r#"
            INSERT INTO family.families (
                id, name, created_by, created_at, updated_at
            ) VALUES (
                $1, $2, $3, $4, $5
            )
            RETURNING id, name, created_by, created_at, updated_at
            "#
        )
        .bind(family.id)
        .bind(&family.name)
        .bind(family.created_by)
        .bind(family.created_at)
        .bind(family.updated_at)
        .fetch_one(&self.pool)
        .await?;

        Ok(result)
    }

    // Add family member (matching Kotlin addFamilyMember exactly)
    pub async fn add_family_member(&self, member: &FamilyMember) -> anyhow::Result<FamilyMember> {
        let result = sqlx::query_as::<_, FamilyMember>(
            r#"
            INSERT INTO family.family_members (
                id, family_id, user_id, role, joined_at
            ) VALUES (
                $1, $2, $3, $4, $5
            )
            RETURNING id, family_id, user_id, role, joined_at
            "#
        )
        .bind(member.id)
        .bind(member.family_id)
        .bind(member.user_id)
        .bind(&member.role)
        .bind(member.joined_at)
        .fetch_one(&self.pool)
        .await?;

        Ok(result)
    }

    // Get family by user ID (matching Kotlin getFamilyByUserId exactly)
    pub async fn get_family_by_user_id(&self, user_id: Uuid) -> anyhow::Result<Option<Family>> {
        let family = sqlx::query_as::<_, Family>(
            r#"
            SELECT f.id, f.name, f.created_by, f.created_at, f.updated_at
            FROM family.families f
            INNER JOIN family.family_members fm ON f.id = fm.family_id
            WHERE fm.user_id = $1
            ORDER BY fm.joined_at ASC
            LIMIT 1
            "#
        )
        .bind(user_id)
        .fetch_optional(&self.pool)
        .await?;
        
        Ok(family)
    }

    // Get children by family (matching Kotlin getChildrenByFamily exactly)
    pub async fn get_children_by_family(&self, family_id: Uuid) -> anyhow::Result<Vec<ChildProfile>> {
        let children = sqlx::query_as::<_, ChildProfile>(
            r#"
            SELECT id, family_id, name, nickname, birth_date, gender, avatar_url,
                   interests, favorite_colors, is_active, created_at, updated_at, archived_at
            FROM family.child_profiles 
            WHERE family_id = $1 AND is_active = true AND archived_at IS NULL
            ORDER BY created_at ASC
            "#
        )
        .bind(family_id)
        .fetch_all(&self.pool)
        .await?;

        Ok(children)
    }
}