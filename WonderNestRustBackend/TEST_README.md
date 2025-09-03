# WonderNest Authentication Test Suite

A comprehensive test guardian for the COPPA-compliant child development platform, ensuring every authentication feature is thoroughly tested, secure, and protects children's privacy.

## 🎯 Overview

This test suite provides comprehensive coverage of the WonderNest authentication system with a focus on:

- **Security**: Protection against SQL injection, XSS, JWT tampering, and other attacks
- **COPPA Compliance**: Ensuring child data protection and privacy requirements
- **Reliability**: Concurrent operations, race conditions, and edge cases
- **Performance**: Load testing and response time validation

## 📊 Test Coverage

### Current Metrics
- **Minimum Coverage**: 80%
- **Target Coverage**: 90%
- **Security Tests**: 100% of auth endpoints
- **COPPA Tests**: 100% of child data operations

### Test Categories

| Category | Description | Test Count | Coverage |
|----------|-------------|------------|----------|
| Unit Tests | Core auth service logic | 25+ | Auth Service |
| Integration Tests | API endpoint testing | 20+ | All endpoints |
| Security Tests | SQL injection, XSS, JWT | 15+ | Security boundaries |
| COPPA Compliance | Child data protection | 10+ | All child operations |
| Concurrency Tests | Race conditions, deadlocks | 8+ | Concurrent scenarios |

## 🏗️ Test Architecture

```
tests/
├── common/                 # Shared test utilities
│   └── mod.rs             # Database helpers, test server setup
├── fixtures/              # Test data generators
│   └── mod.rs             # Mock data, fixtures, payloads
├── unit/                  # Unit tests
│   └── auth_service_tests.rs
├── integration/           # API integration tests
│   ├── auth_endpoints_tests.rs
│   └── concurrency_tests.rs
└── security/              # Security-focused tests
    ├── security_tests.rs
    └── coppa_compliance_tests.rs
```

## 🚀 Quick Start

### Prerequisites

1. **Rust Toolchain** (latest stable)
2. **Docker** and **Docker Compose**
3. **PostgreSQL Client** (`psql`)
4. **Just** (optional, for simplified commands)

### Installation

```bash
# Install test dependencies
cargo install cargo-tarpaulin cargo-llvm-cov cargo-watch cargo-audit

# Or use the helper script
just install-tools
```

### Running Tests

#### Full Test Suite
```bash
# Run all tests with coverage
./scripts/run_tests.sh

# Or with just
just test
```

#### Quick Tests (No Coverage)
```bash
# Faster execution, skip coverage
./scripts/run_tests.sh --quick
just test-quick
```

#### Specific Test Categories
```bash
# Unit tests only
just test-unit
cargo test --lib unit

# Integration tests
just test-integration
cargo test --test '*' integration

# Security tests
just test-security
cargo test --test '*' security

# COPPA compliance tests
just test-coppa
cargo test coppa

# Concurrency tests
just test-concurrency
cargo test concurrency
```

#### Coverage Analysis
```bash
# Generate coverage report
just coverage
./scripts/run_tests.sh --coverage-only
```

#### Mutation Testing
```bash
# Advanced testing (slow)
./scripts/run_tests.sh --mutation
```

## 📋 Test Categories Detail

### Unit Tests (`tests/unit/auth_service_tests.rs`)

Tests core authentication service logic in isolation:

- **Parent Signup**: Valid requests, validation errors, duplicate emails
- **Parent Login**: Authentication, family context, invalid credentials
- **Token Refresh**: Valid/invalid tokens, expiration handling
- **Password Validation**: Strength requirements, edge cases
- **Email Validation**: Format checking, special characters
- **Session Management**: Creation, logout, cleanup

### Integration Tests (`tests/integration/`)

Tests complete API workflows:

- **Auth Endpoints**: Full request/response cycles
- **Concurrency**: Race conditions, deadlock prevention
- **Database Transactions**: ACID compliance, isolation
- **Error Handling**: Proper HTTP status codes and messages

### Security Tests (`tests/security/security_tests.rs`)

Comprehensive security validation:

- **SQL Injection**: Parameterized queries, input sanitization
- **XSS Protection**: Input validation, output encoding
- **JWT Security**: Token validation, signature verification
- **Session Security**: Token hashing, secure storage
- **Input Validation**: Size limits, null bytes, type safety
- **Timing Attacks**: Consistent response times

### COPPA Compliance Tests (`tests/security/coppa_compliance_tests.rs`)

Child privacy and data protection:

- **Minimal Data Collection**: Only required fields
- **Age Verification**: Birth date validation, boundary testing
- **Parental Consent**: Authentication requirements
- **Data Retention**: Archival capabilities, cleanup
- **Audit Trails**: Access logging, compliance reporting

## 🛡️ Security Testing Focus

### SQL Injection Protection
```rust
// Example test
#[rstest]
#[tokio::test]
async fn test_sql_injection_in_registration_fields() {
    for payload in SecurityTestHelper::sql_injection_payloads() {
        // Test various injection attempts
        let response = server.post("/api/v1/auth/parent/register")
            .json(&malicious_request)
            .await;
        
        // Should be safely handled
        assert!(response.status_code().is_client_error());
    }
}
```

### JWT Security Validation
```rust
#[rstest]
#[tokio::test]
async fn test_invalid_jwt_tokens_rejected() {
    for invalid_token in SecurityTestHelper::invalid_jwt_tokens() {
        let response = server.post("/api/v1/auth/session/refresh")
            .json(&json!({"refreshToken": invalid_token}))
            .await;
        
        response.assert_status_unauthorized();
    }
}
```

## 👶 COPPA Compliance Testing

### Age Verification Testing
```rust
#[rstest]
#[tokio::test]
async fn test_coppa_protected_age_detection() {
    // Test children under/over 13 boundary
    let under_13_birth_date = COPPATestHelper::child_under_13_birth_date();
    let over_13_birth_date = COPPATestHelper::child_over_13_birth_date();
    
    // Verify proper COPPA classification
    assert!(is_coppa_protected(under_13_birth_date));
    assert!(!is_coppa_protected(over_13_birth_date));
}
```

### Minimal Data Collection
```rust
#[rstest]
#[tokio::test]
async fn test_minimal_child_data_collection() {
    // Verify only required fields are collected
    let child = TestDataBuilder::create_test_child(&test_db.pool, family.id).await.unwrap();
    
    assert!(!child.name.is_empty(), "Name is required");
    assert!(child.birth_date.is_some(), "Birth date required for age verification");
    
    // Optional fields should be limited
    if let Some(interests) = child.interests {
        assert!(interests.len() <= 10, "Should limit tracked interests");
    }
}
```

## ⚡ Performance and Concurrency Testing

### Race Condition Prevention
```rust
#[rstest]
#[tokio::test]
async fn test_concurrent_registration_same_email() {
    // Launch concurrent registration attempts
    let barrier = Arc::new(Barrier::new(5));
    let mut handles = Vec::new();
    
    for req in signup_requests {
        let barrier = barrier.clone();
        let server = server.clone();
        
        let handle = tokio::spawn(async move {
            barrier.wait().await;
            server.post("/api/v1/auth/parent/register").json(&req).await
        });
        
        handles.push(handle);
    }
    
    // Only one should succeed, others should get duplicate error
    assert_eq!(success_count, 1);
    assert_eq!(duplicate_error_count, 4);
}
```

## 📊 Coverage and Reporting

### Coverage Reports
- **HTML Report**: `coverage/tarpaulin-report.html`
- **XML Report**: `cobertura.xml` (for CI/CD)
- **Console Output**: Real-time coverage metrics

### Test Reports
- **Comprehensive Report**: `test-report-YYYYMMDD-HHMMSS.md`
- **CI Summary**: GitHub Actions summary
- **Coverage Badge**: Codecov integration

## 🔧 Configuration

### Environment Variables
```bash
# Required for tests
TEST_DATABASE_URL=postgresql://wondernest_app:wondernest_secure_password_dev@localhost:5433/postgres
RUST_LOG=debug           # Logging level
TEST_MODE=true           # Test environment flag

# Optional
MIN_COVERAGE=80          # Minimum coverage threshold
TARGET_COVERAGE=90       # Target coverage goal
```

### Database Setup
```bash
# Start test database
docker-compose up -d wondernest-db

# Wait for readiness
just db-setup

# Reset if needed
just db-reset
```

## 🚨 CI/CD Integration

### GitHub Actions
The test suite runs automatically on:
- **Push** to `main` or `develop`
- **Pull Requests** to `main` or `develop`
- **Schedule** (daily mutation testing)

### Test Jobs
1. **Code Quality**: Formatting, linting, documentation
2. **Unit Tests**: Fast feedback on core logic
3. **Integration Tests**: API endpoint validation
4. **Security Tests**: SQL injection, XSS, JWT security
5. **COPPA Compliance**: Child data protection
6. **Concurrency Tests**: Race conditions, deadlocks
7. **Coverage**: Minimum 80% threshold
8. **Mutation Testing**: Test quality validation (main branch only)

## 🔍 Debugging Failed Tests

### Common Issues

1. **Database Connection Failed**
   ```bash
   # Check database is running
   docker-compose ps
   
   # Check connectivity
   PGPASSWORD=wondernest_secure_password_dev psql -h localhost -p 5433 -U wondernest_app -d wondernest_prod -c "SELECT 1;"
   ```

2. **Port Conflicts**
   ```bash
   # Find processes using port 5433
   lsof -ti:5433
   
   # Kill conflicting processes
   lsof -ti:5433 | xargs kill -9
   ```

3. **Test Database Cleanup**
   ```bash
   # Clean test databases
   just db-reset
   
   # Manual cleanup
   docker-compose down
   docker-compose up -d wondernest-db
   ```

### Debugging Commands
```bash
# Verbose test output
RUST_LOG=debug cargo test -- --nocapture

# Run specific test
cargo test test_parent_register_success -- --nocapture

# Run tests without parallel execution
cargo test -- --test-threads=1

# Show test execution time
cargo test -- --report-time
```

## 📈 Metrics and Monitoring

### Key Metrics
- **Test Execution Time**: < 2 minutes for full suite
- **Code Coverage**: ≥ 80% (target 90%)
- **Security Test Coverage**: 100% of auth endpoints
- **COPPA Test Coverage**: 100% of child data operations
- **Flakiness Rate**: < 1% over 100 runs
- **Mutation Score**: > 70%

### Performance Benchmarks
- **Unit Tests**: < 30 seconds
- **Integration Tests**: < 2 minutes
- **Security Tests**: < 1 minute
- **COPPA Tests**: < 30 seconds
- **Concurrency Tests**: < 45 seconds

## 🤝 Contributing

### Adding New Tests

1. **Create Test File**: Follow naming convention `*_tests.rs`
2. **Use Fixtures**: Leverage existing test data generators
3. **Add Documentation**: Document test purpose and expectations
4. **Update Metrics**: Ensure coverage goals are maintained

### Test Guidelines

- **Descriptive Names**: `test_parent_register_duplicate_email_returns_400`
- **Arrange-Act-Assert**: Clear test structure
- **Independent Tests**: No shared state between tests
- **Error Testing**: Test both success and failure paths
- **Security Focus**: Always consider security implications

### Code Review Checklist

- [ ] Tests cover both happy path and error cases
- [ ] Security boundaries are tested
- [ ] COPPA compliance is verified for child data
- [ ] Tests are deterministic and not flaky
- [ ] Test data is properly cleaned up
- [ ] Documentation is updated

## 📚 Resources

### Documentation
- [Rust Testing Guide](https://doc.rust-lang.org/book/ch11-00-testing.html)
- [rstest Documentation](https://docs.rs/rstest/)
- [axum-test Documentation](https://docs.rs/axum-test/)
- [COPPA Compliance Guidelines](https://www.ftc.gov/enforcement/rules/rulemaking-regulatory-reform-proceedings/childrens-online-privacy-protection-rule)

### Tools
- [cargo-tarpaulin](https://github.com/xd009642/tarpaulin) - Coverage
- [cargo-mutants](https://github.com/sourcefrog/cargo-mutants) - Mutation testing
- [cargo-audit](https://github.com/RustSec/rustsec/tree/main/cargo-audit) - Security audit

---

## 🎉 Success Criteria

A successful test suite run should demonstrate:

- ✅ **100% Security Coverage**: All authentication endpoints tested for SQL injection, XSS, JWT security
- ✅ **100% COPPA Coverage**: All child data operations comply with privacy requirements  
- ✅ **≥80% Code Coverage**: Minimum threshold met with target of 90%
- ✅ **Zero Security Vulnerabilities**: No SQL injection, authentication bypass, or data exposure
- ✅ **Child Data Protection**: Minimal collection, parental consent, age verification
- ✅ **Concurrent Safety**: No race conditions, deadlocks, or data corruption
- ✅ **Performance Standards**: All tests complete within time limits

Remember: **Every test protects real children's data. Be thorough, creative in finding edge cases, and never compromise on security or privacy testing.**