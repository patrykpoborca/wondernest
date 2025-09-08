use bcrypt::{hash, DEFAULT_COST};

fn main() {
    let password = "admin123";
    let cost = 12; // Match the admin service
    let hashed = hash(password, cost).expect("Failed to hash password");
    println!("{}", hashed);
}