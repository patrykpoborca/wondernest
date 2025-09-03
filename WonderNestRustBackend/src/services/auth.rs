// Basic auth service placeholder - minimal implementation for compilation
use crate::services::AppState;

pub struct AuthService {}

impl AuthService {
    pub fn new(_state: &AppState) -> Self {
        Self {}
    }
}