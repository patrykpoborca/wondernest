# Manual Testing Scripts

This directory contains manual testing scripts for the WonderNest Backend API using curl commands.

## Setup

1. Ensure the WonderNest Backend is running locally on port 8080
2. Set environment variables for testing:
   ```bash
   export BASE_URL="http://localhost:8080"
   export ACCESS_TOKEN=""  # Will be set after login
   ```

## Usage

1. **Run health checks first** to ensure the service is running:
   ```bash
   ./health-checks.sh
   ```

2. **Test authentication flow**:
   ```bash
   ./auth-flow.sh
   ```

3. **Test individual endpoints**:
   ```bash
   ./test-families.sh
   ./test-content.sh
   ./test-audio.sh
   ./test-analytics.sh
   ```

4. **Run all tests**:
   ```bash
   ./run-all-tests.sh
   ```

## Environment Variables

- `BASE_URL`: Base URL of the API (default: http://localhost:8080)
- `ACCESS_TOKEN`: JWT access token (set automatically by auth scripts)
- `TEST_EMAIL`: Email for test user (default: test@example.com)
- `TEST_PASSWORD`: Password for test user (default: TestPassword123!)

## Scripts

- `health-checks.sh` - Test all health monitoring endpoints
- `auth-flow.sh` - Complete authentication flow (signup, login, profile, logout)
- `test-families.sh` - Test family and children management endpoints
- `test-content.sh` - Test content management endpoints
- `test-audio.sh` - Test audio session endpoints
- `test-analytics.sh` - Test analytics endpoints
- `security-tests.sh` - Security and validation tests
- `performance-tests.sh` - Basic performance testing
- `run-all-tests.sh` - Execute all test scripts

## Notes

- Scripts use `jq` for JSON processing. Install with: `brew install jq` (macOS) or `apt-get install jq` (Ubuntu)
- All scripts include error handling and colored output for better readability
- Failed requests will display detailed error information
- Successful requests will show response summaries