#[cfg(test)]
mod tests {
    use super::super::*;
    use crate::models::*;
    use crate::db::*;
    
    #[test]
    fn test_email_validation() {
        let auth_service = AuthService::new(
            UserRepository::new(sqlx::PgPool::new()),
            FamilyRepository::new(sqlx::PgPool::new()),
        );
        
        // Valid emails
        assert!(auth_service.is_valid_email("test@example.com"));
        assert!(auth_service.is_valid_email("user.name@example.co.uk"));
        
        // Invalid emails
        assert!(!auth_service.is_valid_email("notanemail"));
        assert!(!auth_service.is_valid_email("@example.com"));
        assert!(!auth_service.is_valid_email("test@"));
        assert!(!auth_service.is_valid_email(""));
    }
    
    #[test]
    fn test_password_validation() {
        let auth_service = AuthService::new(
            UserRepository::new(sqlx::PgPool::new()),
            FamilyRepository::new(sqlx::PgPool::new()),
        );
        
        // Valid passwords
        assert!(auth_service.validate_password("ValidPass123").is_ok());
        assert!(auth_service.validate_password("Another1Good!").is_ok());
        
        // Invalid passwords
        assert!(auth_service.validate_password("short").is_err()); // Too short
        assert!(auth_service.validate_password("nouppercase123").is_err()); // No uppercase
        assert!(auth_service.validate_password("NOLOWERCASE123").is_err()); // No lowercase
        assert!(auth_service.validate_password("NoNumbers!").is_err()); // No digits
    }
}