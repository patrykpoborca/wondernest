use bcrypt::{hash, verify};

#[derive(Clone)]
pub struct PasswordService;

impl PasswordService {
    pub fn new() -> Self {
        Self
    }

    // Hash password with cost factor 12 (matching Kotlin BCryptPasswordEncoder(12))
    pub fn hash_password(&self, password: &str) -> anyhow::Result<String> {
        // Use cost factor 12 to match Kotlin's BCryptPasswordEncoder(12)
        let cost = 12;
        hash(password, cost).map_err(|e| anyhow::anyhow!("Password hashing failed: {}", e))
    }

    // Verify password against hash (matching Kotlin's passwordEncoder.matches())
    pub fn verify_password(&self, password: &str, hash: &str) -> anyhow::Result<bool> {
        verify(password, hash).map_err(|e| anyhow::anyhow!("Password verification failed: {}", e))
    }
}