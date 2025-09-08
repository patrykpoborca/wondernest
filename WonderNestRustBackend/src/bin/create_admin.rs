use wondernest_backend::services::password::PasswordService;

fn main() {
    let password_service = PasswordService::new();
    let hash = password_service.hash_password("admin123").expect("Failed to hash password");
    println!("Password hash for 'admin123': {}", hash);
}