use chrono::{Duration, Utc};
use uuid::Uuid;

use crate::{
    db::{UserRepository, FamilyRepository},
    models::{
        SignupRequest, LoginRequest, AuthResponse, AuthData, TokenPair, MessageResponse,
        User, UserSession, Family, FamilyMember, NewUser,
    },
    services::{
        jwt::JwtService,
        password::PasswordService,
        validation::ValidationService,
    },
};

pub struct AuthService {
    user_repo: UserRepository,
    family_repo: FamilyRepository,
    jwt_service: JwtService,
    password_service: PasswordService,
    validation_service: ValidationService,
}

impl AuthService {
    pub fn new(
        user_repo: UserRepository,
        family_repo: FamilyRepository,
    ) -> Self {
        Self {
            user_repo,
            family_repo,
            jwt_service: JwtService::new(),
            password_service: PasswordService::new(),
            validation_service: ValidationService::new(),
        }
    }

    // Parent signup with family creation (matching Kotlin signupParent exactly)
    pub async fn signup_parent(&self, request: SignupRequest) -> Result<AuthResponse, AuthServiceError> {
        // Validate email format
        if !self.is_valid_email(&request.email) {
            return Err(AuthServiceError::ValidationError("Invalid email format".to_string()));
        }

        // Check if user already exists
        if let Some(_) = self.user_repo.get_user_by_email(&request.email).await? {
            return Err(AuthServiceError::ValidationError("User with this email already exists".to_string()));
        }

        // Validate password strength
        self.validate_password(&request.password)?;

        // Create parent user
        let now = Utc::now();
        let hashed_password = self.password_service.hash_password(&request.password)?;
        
        // Parse name fields (matching Kotlin logic exactly)
        let first_name = if let Some(ref fname) = request.first_name {
            Some(fname.trim().to_string())
        } else if let Some(ref name) = request.name {
            name.split_whitespace().next().map(|s| s.trim().to_string())
        } else {
            None
        };
        
        let last_name = if let Some(ref lname) = request.last_name {
            Some(lname.trim().to_string())
        } else if let Some(ref name) = request.name {
            let parts: Vec<&str> = name.split_whitespace().collect();
            if parts.len() > 1 {
                Some(parts[1..].join(" "))
            } else {
                None
            }
        } else {
            None
        }.filter(|s| !s.trim().is_empty())
            .map(|s| s.trim().to_string());

        let mut new_user = NewUser::default();
        new_user.id = Uuid::new_v4();
        new_user.email = request.email.to_lowercase();
        new_user.first_name = first_name.clone();
        new_user.last_name = last_name;
        // Timezone and language stored elsewhere
        // Language stored elsewhere
        // User starts as active (email verification handled separately)
        // Role is set to "parent" in the database insert // Matching Kotlin UserRole.PARENT

        let created_user = self.user_repo.create_user(&new_user).await?;
        
        // Store password hash separately (matching Kotlin pattern)
        self.user_repo.update_user_password(created_user.id, &hashed_password).await?;

        // Create family for the parent using the user's first name (matching Kotlin logic)
        let family_name = format!("{}'s Family", 
            first_name.as_ref().unwrap_or(&"Unknown".to_string()));
        
        let family = Family {
            id: Uuid::new_v4(),
            name: family_name,
            created_by: Some(created_user.id),
            created_at: now,
            updated_at: now,
        };

        let created_family = self.family_repo.create_family(&family).await?;

        // Add user as family member
        let family_member = FamilyMember {
            id: Uuid::new_v4(),
            family_id: created_family.id,
            user_id: created_user.id,
            role: "parent".to_string(),
            joined_at: now,
        };

        self.family_repo.add_family_member(&family_member).await?;

        // Generate tokens with family context (matching Kotlin generateTokenWithFamilyContext)
        let token_pair = self.jwt_service.generate_token_with_family_context(&created_user, created_family.id)?;
        
        // Create session
        let session = self.create_user_session(&created_user, &token_pair)?;
        self.user_repo.create_session(&session).await?;

        tracing::info!(
            "Parent signed up with family: {} ({}) - Family: {} ({})",
            created_user.email,
            created_user.id,
            created_family.name,
            created_family.id
        );

        Ok(AuthResponse::success(AuthData {
            user_id: created_user.id.to_string(),
            email: created_user.email,
            access_token: token_pair.access_token,
            refresh_token: token_pair.refresh_token,
            expires_in: token_pair.expires_in,
            has_pin: false,
            requires_pin_setup: true,
            children: vec![], // Empty for new parents
        }))
    }

    // Parent login with family context (matching Kotlin loginParent exactly)
    pub async fn login_parent(&self, request: LoginRequest) -> Result<AuthResponse, AuthServiceError> {
        let user = self.user_repo.get_user_by_email(&request.email.to_lowercase()).await?
            .ok_or_else(|| AuthServiceError::SecurityError("Invalid credentials".to_string()))?;

        if !user.is_active {
            return Err(AuthServiceError::SecurityError("Account suspended".to_string()));
        }

        if user.role != "parent" {
            return Err(AuthServiceError::SecurityError("This endpoint is for parents only".to_string()));
        }

        // Check password
        let password_hash = self.user_repo.get_user_password_hash(user.id).await?
            .ok_or_else(|| AuthServiceError::SecurityError("Invalid credentials".to_string()))?;

        if !self.password_service.verify_password(&request.password, &password_hash)? {
            return Err(AuthServiceError::SecurityError("Invalid credentials".to_string()));
        }

        // Get family context
        let family = self.family_repo.get_family_by_user_id(user.id).await?
            .ok_or_else(|| AuthServiceError::SecurityError("No family found for this parent".to_string()))?;

        // Update last login
        self.user_repo.update_last_login(user.id).await?;

        // Generate tokens with family context
        let token_pair = self.jwt_service.generate_token_with_family_context(&user, family.id)?;
        
        // Create session
        let session = self.create_user_session(&user, &token_pair)?;
        self.user_repo.create_session(&session).await?;

        tracing::info!(
            "Parent logged in with family context: {} ({}) - Family: {} ({})",
            user.email,
            user.id,
            family.name,
            family.id
        );

        // Get children for the family to include in response
        let children = self.family_repo.get_children_by_family(family.id).await?;
        let children_ids: Vec<String> = children.iter().map(|c| c.id.to_string()).collect();

        Ok(AuthResponse::success(AuthData {
            user_id: user.id.to_string(),
            email: user.email,
            access_token: token_pair.access_token,
            refresh_token: token_pair.refresh_token,
            expires_in: token_pair.expires_in,
            has_pin: true, // TODO: Check if user has PIN set up
            requires_pin_setup: false,
            children: children_ids,
        }))
    }

    // Regular signup (matching Kotlin signup exactly)
    pub async fn signup(&self, request: SignupRequest) -> Result<AuthResponse, AuthServiceError> {
        // Validate email format
        if !self.is_valid_email(&request.email) {
            return Err(AuthServiceError::ValidationError("Invalid email format".to_string()));
        }

        // Check if user already exists
        if let Some(_) = self.user_repo.get_user_by_email(&request.email).await? {
            return Err(AuthServiceError::ValidationError("User with this email already exists".to_string()));
        }

        // Validate password strength
        self.validate_password(&request.password)?;

        // Create user
        let hashed_password = self.password_service.hash_password(&request.password)?;
        
        let mut new_user = NewUser::default();
        new_user.id = Uuid::new_v4();
        new_user.email = request.email.to_lowercase();
        new_user.first_name = request.first_name.map(|s| s.trim().to_string());
        new_user.last_name = request.last_name.map(|s| s.trim().to_string());
        // Timezone and language stored elsewhere
        // Language stored elsewhere
        // User starts as active (email verification handled separately)
        // Role is set to "parent" in the database insert

        let created_user = self.user_repo.create_user(&new_user).await?;
        
        // Store password hash separately
        self.user_repo.update_user_password(created_user.id, &hashed_password).await?;

        // Generate tokens
        let token_pair = self.jwt_service.generate_token(&created_user)?;
        
        // Create session
        let session = self.create_user_session(&created_user, &token_pair)?;
        self.user_repo.create_session(&session).await?;

        tracing::info!("User signed up: {} ({})", created_user.email, created_user.id);

        Ok(AuthResponse::success(AuthData {
            user_id: created_user.id.to_string(),
            email: created_user.email,
            access_token: token_pair.access_token,
            refresh_token: token_pair.refresh_token,
            expires_in: token_pair.expires_in,
            has_pin: false,
            requires_pin_setup: true,
            children: vec![], // Empty for new users
        }))
    }

    // Regular login (matching Kotlin login exactly)
    pub async fn login(&self, request: LoginRequest) -> Result<AuthResponse, AuthServiceError> {
        let user = self.user_repo.get_user_by_email(&request.email.to_lowercase()).await?
            .ok_or_else(|| AuthServiceError::SecurityError("Invalid credentials".to_string()))?;

        if !user.is_active {
            return Err(AuthServiceError::SecurityError("Account suspended".to_string()));
        }

        // Check password
        let password_hash = self.user_repo.get_user_password_hash(user.id).await?
            .ok_or_else(|| AuthServiceError::SecurityError("Invalid credentials".to_string()))?;

        if !self.password_service.verify_password(&request.password, &password_hash)? {
            return Err(AuthServiceError::SecurityError("Invalid credentials".to_string()));
        }

        // Update last login
        self.user_repo.update_last_login(user.id).await?;

        // Generate tokens
        let token_pair = self.jwt_service.generate_token(&user)?;
        
        // Create session
        let session = self.create_user_session(&user, &token_pair)?;
        self.user_repo.create_session(&session).await?;

        tracing::info!("User logged in: {} ({})", user.email, user.id);

        Ok(AuthResponse::success(AuthData {
            user_id: user.id.to_string(),
            email: user.email,
            access_token: token_pair.access_token,
            refresh_token: token_pair.refresh_token,
            expires_in: token_pair.expires_in,
            has_pin: false, // TODO: Check if user has PIN set up
            requires_pin_setup: true,
            children: vec![], // Empty for regular login
        }))
    }

    // Refresh token (matching Kotlin refreshToken exactly)
    pub async fn refresh_token(&self, refresh_token: &str) -> Result<AuthResponse, AuthServiceError> {
        let user_id_str = self.jwt_service.verify_refresh_token(refresh_token)
            .map_err(|_| AuthServiceError::SecurityError("Invalid refresh token".to_string()))?;

        let user_id = Uuid::parse_str(&user_id_str)
            .map_err(|_| AuthServiceError::SecurityError("Invalid user ID in token".to_string()))?;

        let user = self.user_repo.get_user_by_id(user_id).await?
            .ok_or_else(|| AuthServiceError::SecurityError("User not found".to_string()))?;

        if !user.is_active {
            return Err(AuthServiceError::SecurityError("Account not active".to_string()));
        }

        // Generate new tokens
        let token_pair = self.jwt_service.generate_token(&user)?;
        
        // Create new session
        let session = self.create_user_session(&user, &token_pair)?;
        self.user_repo.create_session(&session).await?;

        Ok(AuthResponse::success(AuthData {
            user_id: user.id.to_string(),
            email: user.email,
            access_token: token_pair.access_token,
            refresh_token: token_pair.refresh_token,
            expires_in: token_pair.expires_in,
            has_pin: false, // TODO: Check if user has PIN set up
            requires_pin_setup: false,
            children: vec![], // TODO: Get children if family context
        }))
    }

    // Logout (matching Kotlin logout exactly)
    pub async fn logout(&self, session_token: &str) -> Result<bool, AuthServiceError> {
        use sha2::{Sha256, Digest};
        
        // Create hash of the token to look up in database
        let mut hasher = Sha256::new();
        hasher.update(session_token.as_bytes());
        let token_hash = format!("{:x}", hasher.finalize());
        
        if let Some(session) = self.user_repo.get_session_by_token(&token_hash).await? {
            Ok(self.user_repo.invalidate_session(session.id).await?)
        } else {
            Ok(false)
        }
    }

    // Private helper methods (matching Kotlin private methods)

    fn create_user_session(&self, user: &User, token_pair: &TokenPair) -> anyhow::Result<UserSession> {
        use sha2::{Sha256, Digest};
        
        let now = Utc::now();
        
        // Create a hash of the token for storage
        let mut hasher = Sha256::new();
        hasher.update(token_pair.access_token.as_bytes());
        let token_hash = format!("{:x}", hasher.finalize());
        
        Ok(UserSession {
            id: Uuid::new_v4(),
            user_id: user.id,
            token_hash,
            expires_at: now + Duration::milliseconds(token_pair.expires_in),
            created_at: now,
            last_accessed: now,
            device_info: None,
        })
    }

    fn validate_password(&self, password: &str) -> Result<(), AuthServiceError> {
        if password.len() < 8 {
            return Err(AuthServiceError::ValidationError("Password must be at least 8 characters long".to_string()));
        }
        if !password.chars().any(|c| c.is_ascii_digit()) {
            return Err(AuthServiceError::ValidationError("Password must contain at least one digit".to_string()));
        }
        if !password.chars().any(|c| c.is_ascii_uppercase()) {
            return Err(AuthServiceError::ValidationError("Password must contain at least one uppercase letter".to_string()));
        }
        if !password.chars().any(|c| c.is_ascii_lowercase()) {
            return Err(AuthServiceError::ValidationError("Password must contain at least one lowercase letter".to_string()));
        }
        Ok(())
    }

    fn is_valid_email(&self, email: &str) -> bool {
        email.contains("@") && email.contains(".") && email.len() >= 5
    }
}

// Error handling (matching Kotlin exception types)
#[derive(Debug, thiserror::Error)]
pub enum AuthServiceError {
    #[error("Validation error: {0}")]
    ValidationError(String),
    
    #[error("Security error: {0}")]
    SecurityError(String),
    
    #[error("Database error: {0}")]
    DatabaseError(#[from] sqlx::Error),
    
    #[error("Internal error: {0}")]
    InternalError(#[from] anyhow::Error),
}

impl AuthServiceError {
    pub fn to_message_response(&self) -> MessageResponse {
        MessageResponse {
            message: match self {
                Self::ValidationError(msg) => msg.clone(),
                Self::SecurityError(msg) => msg.clone(),
                Self::DatabaseError(_) => "Database operation failed".to_string(),
                Self::InternalError(_) => "Internal server error".to_string(),
            }
        }
    }
}
