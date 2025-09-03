# Rust Backend Rewrite

## Overview
Complete rewrite of the WonderNest backend from Kotlin/KTOR to Rust while maintaining 100% API compatibility and database schema compatibility. The frontend applications should require zero changes.

## User Stories
- As a developer, I want a more performant backend with better memory safety
- As a system administrator, I want reduced resource consumption and faster response times
- As a maintainer, I want type-safe database queries and compile-time guarantees

## Acceptance Criteria
- [ ] All existing API endpoints work identically to Kotlin version
- [ ] JWT authentication maintains same token format and claims
- [ ] Database queries use existing schema without modifications
- [ ] Docker deployment works with same docker-compose setup
- [ ] All health check endpoints respond correctly
- [ ] Response JSON structure matches exactly
- [ ] Error codes and messages remain consistent

## Technical Constraints
- Must use existing PostgreSQL database schema
- Must maintain same JWT secret and signing algorithm
- Must support same Redis caching patterns
- Must work with existing Flyway migrations
- Must maintain COPPA compliance
- API paths must remain identical (/api/v1/*)

## Security Considerations
- JWT validation must be identical
- Password hashing must use same bcrypt configuration
- PIN protection must work the same way
- Audit logging must continue