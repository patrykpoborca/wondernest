# WonderNest Scripts Directory

This directory contains all automation scripts for the WonderNest Rust backend.

## 📁 Script Categories

### 🐳 Docker Management
- `rebuild-docker.sh` - Complete Docker image rebuild with health checks
- `quick-rebuild.sh` - Fast Docker rebuild using cache
- `restart-docker.sh` - Restart containers without rebuild
- `docker-status.sh` - Check status of all containers
- `docker-logs.sh` - View container logs with formatting

### 🧪 Testing Scripts
- `run_all_tests.sh` - **Main test suite runner** (comprehensive)
- `test_quick.sh` - Quick unit tests for development
- `run_tests.sh` - Original test runner with coverage
- `test-auth-rust.sh` - Live authentication endpoint tests
- `test-auth.sh` - Legacy Kotlin backend auth tests

## 🚀 Quick Start

### Run All Tests
```bash
./scripts/run_all_tests.sh
```

### Quick Development Tests
```bash
./scripts/test_quick.sh
```

### Docker Operations
```bash
# Full rebuild
./scripts/rebuild-docker.sh

# Quick rebuild (cached)
./scripts/quick-rebuild.sh

# Check status
./scripts/docker-status.sh

# View logs
./scripts/docker-logs.sh
```

### Test Authentication Endpoints
```bash
# Test Rust backend (port 8082)
./scripts/test-auth-rust.sh

# Test Kotlin backend (port 8080)
./scripts/test-auth.sh
```

## 📊 Test Coverage

The main test runner (`run_all_tests.sh`) provides:

1. **Unit Tests** - Business logic and services
2. **Integration Tests** - API endpoint validation
3. **Security Tests** - SQL injection, XSS, JWT security
4. **COPPA Compliance** - Child data protection
5. **Concurrency Tests** - Race conditions and deadlocks
6. **Live Endpoint Tests** - Actual HTTP requests
7. **Coverage Report** - Code coverage metrics

## 🎯 Test Requirements

- **Minimum Coverage**: 80%
- **Security Coverage**: 100% of auth endpoints
- **COPPA Coverage**: 100% of child data operations

## 🔧 Prerequisites

Required:
- Rust and Cargo
- Docker and Docker Compose
- PostgreSQL client (psql)

Optional:
- cargo-tarpaulin (for coverage)
- cargo-watch (for watch mode)
- cargo-mutants (for mutation testing)

## 📝 Script Conventions

All scripts follow these conventions:
- Use `set -e` to exit on error
- Provide colored output for readability
- Include help text when appropriate
- Check prerequisites before running
- Clean up resources on exit
- Return appropriate exit codes

## 🔄 Continuous Integration

These scripts are integrated with CI/CD:
- GitHub Actions runs `run_all_tests.sh` on every push
- Coverage reports are sent to Codecov
- Failed tests block PR merges
- Performance benchmarks are tracked

## 🐛 Debugging

If tests fail:
1. Check Docker containers: `./scripts/docker-status.sh`
2. View logs: `./scripts/docker-logs.sh`
3. Run quick tests: `./scripts/test_quick.sh`
4. Run specific test: `cargo test test_name -- --nocapture`
5. Check test output: `/tmp/auth_test.log`

## 📈 Performance

Typical execution times:
- Quick tests: < 10 seconds
- Unit tests: < 30 seconds
- Full test suite: < 5 minutes
- With coverage: < 10 minutes

## 🔒 Security Note

All test scripts ensure:
- No production data is used
- Test databases are isolated
- Sensitive data is not logged
- COPPA compliance is verified
- Security vulnerabilities are checked