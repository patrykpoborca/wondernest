# WonderNest Backend Test Suite

## Overview

This comprehensive test suite validates all critical backend endpoints and ensures seamless integration with the Flutter frontend. The tests focus on API contracts, serialization/deserialization, JWT token handling, and error scenarios that are critical for mobile app functionality.

## Test Structure

### Core Test Files

1. **`TestUtils.kt`** - Centralized utilities and test data factories
2. **`TestApplicationConfiguration.kt`** - Reusable test application setup
3. **`ComprehensiveIntegrationTest.kt`** - End-to-end integration tests

### Endpoint-Specific Tests

#### Authentication Tests (`AuthRoutesTest.kt`)
- **Parent Registration Flow**: Validates `POST /api/v1/auth/parent/register`
  - JWT token generation with familyId claim
  - Password validation and hashing
  - Family creation for new parents
  - Duplicate email handling
  - Input validation and sanitization

- **Parent Login Flow**: Validates `POST /api/v1/auth/parent/login`
  - Credential validation
  - JWT token with family context
  - Account status checking (suspended, etc.)
  - Role-based access (parent-only endpoint)

- **PIN Verification**: Validates `POST /api/v1/auth/parent/verify-pin`
  - PIN format validation (4 digits)
  - Session token generation
  - Error handling for incorrect PINs

#### Family Management Tests (`FamilyRoutesTest.kt`)
- **Family Profile**: Validates `GET /api/v1/family/profile`
  - Family data retrieval with members and children
  - JWT authorization with family context
  - Response structure for Flutter consumption

- **Children CRUD Operations**:
  - `GET /api/v1/family/children` - List all children
  - `POST /api/v1/family/children` - Create new child profile
  - `PUT /api/v1/family/children/{id}` - Update child profile
  - `DELETE /api/v1/family/children/{id}` - Archive child profile
  - `GET /api/v1/family/children/{id}` - Get specific child
  - `POST /api/v1/family/children/{id}/select` - Select active child

- **Age-Appropriate Settings**: Validates automatic content settings based on child age
- **COPPA Compliance**: Tests age restrictions and validation
- **Data Validation**: UUID format, required fields, and nested object validation

#### Content System Tests (`ContentRoutesTest.kt`)
- **Content Library**: Validates `GET /api/v1/content`
  - Age-based filtering
  - Category filtering
  - Pagination (page, limit parameters)
  - Empty result handling
  - Content item structure validation

- **Content Recommendations**: Validates `GET /api/v1/content/recommendations/{childId}`
  - Child-specific recommendations
  - Response structure for Flutter
  - Recommendation algorithm placeholders

- **Content Categories**: Validates `GET /api/v1/categories`
  - Category structure with age ranges
  - Color and icon data for Flutter UI

- **Individual Content**: Validates `GET /api/v1/content/{contentId}`
  - Specific content item retrieval
  - 404 handling for non-existent content

#### Analytics Tests (`AnalyticsRoutesTest.kt`)
- **Daily Analytics**: Validates `GET /api/v1/analytics/daily?childId={id}`
  - Screen time tracking
  - Educational content percentage
  - Learning progress metrics
  - Data consistency validation

- **Weekly Overview**: Validates `GET /api/v1/analytics/weekly?childId={id}`
  - Aggregated weekly metrics
  - Top categories analysis
  - Parental interaction tracking

- **Child Insights**: Validates `GET /api/v1/analytics/children/{id}/insights`
  - Learning style analysis
  - Strength and improvement areas
  - Personalized recommendations
  - Parental guidance suggestions

- **Milestone Tracking**: Validates `GET /api/v1/analytics/children/{id}/milestones`
  - Developmental milestone tracking
  - Achievement status
  - Next goal recommendations

- **Event Tracking**: Validates `POST /api/v1/analytics/events`
  - Analytics event ingestion
  - Event validation and storage
  - Response confirmation

### JWT Service Tests (`JwtServiceTest.kt`)
- **Token Generation**: 
  - Standard JWT tokens
  - JWT tokens with family context
  - Token expiration validation
  - Claim validation (userId, email, role, familyId)

- **Token Verification**:
  - Valid token verification
  - Invalid token rejection
  - Expired token handling
  - Token type validation (access vs refresh)

- **Claim Extraction**:
  - User ID extraction without verification
  - Role extraction for authorization
  - Family ID extraction for context
  - Error handling for malformed tokens

- **Flutter Integration**:
  - Token structure compatibility
  - Required claims for Flutter auth state
  - Refresh token functionality

### Serialization Tests (`SerializationTest.kt`)
- **DTO Validation**: Ensures all DTOs serialize exactly as Flutter expects
- **Round-trip Testing**: Validates serialization → deserialization integrity
- **Field Validation**: Confirms all required fields are present
- **Data Type Validation**: Ensures proper JSON types for Flutter parsing
- **Nested Object Handling**: Validates complex object serialization
- **Date/Time Formatting**: Ensures ISO format for Flutter DateTime parsing
- **Optional Field Handling**: Tests nullable and default value behavior

## Critical Flutter Integration Points

### JWT Token Requirements
- **Access Token Claims**: `userId`, `email`, `role`, `verified`, `familyId` (for parents)
- **Refresh Token Claims**: `userId`, `familyId`, `type: "refresh"`
- **Token Format**: Standard JWT with HMAC256 signature
- **Expiration**: Access tokens (1 hour), Refresh tokens (30 days)

### API Response Formats
- **Authentication Responses**: Include `user`, `accessToken`, `refreshToken`, `expiresIn`
- **Paginated Responses**: Include `items`, `totalItems`, `currentPage`, `totalPages`
- **Error Responses**: Consistent `message` or `error` field structure
- **Success Responses**: HTTP status codes aligned with REST conventions

### Data Transfer Objects
- **Child Profile**: Matches Flutter `ChildProfile` model exactly
- **Content Item**: All fields required for Flutter content display
- **Analytics Data**: Formatted for Flutter chart widgets and dashboard
- **Family Data**: Structured for Flutter family management screens

## Test Configuration

### Environment Variables
- `JWT_SECRET`: Test JWT signing key
- `JWT_EXPIRES_IN`: Token expiration time (1 hour)
- `JWT_REFRESH_EXPIRES_IN`: Refresh token expiration (30 days)

### Test Data Factories
- `TestUtils.createTestUser()`: Standard user creation
- `TestUtils.createTestFamily()`: Family with default settings
- `TestUtils.createTestChild()`: Child with age-appropriate settings
- `TestUtils.createSignupRequest()`: Valid registration request
- `TestUtils.createLoginRequest()`: Valid login request

### Mock Configuration
- **UserRepository**: Mocked for user CRUD operations
- **FamilyRepository**: Mocked for family and child operations
- **EmailService**: Mocked to avoid external dependencies
- **Database**: No real database required - all mocked

## Running Tests

### Prerequisites
- JUnit 5
- Mockito for mocking
- Ktor Test framework
- kotlinx.serialization for JSON handling

### Test Execution Order
1. **Unit Tests**: Individual service and utility tests
2. **Route Tests**: Endpoint-specific functionality
3. **Integration Tests**: End-to-end flow validation
4. **Serialization Tests**: DTO validation
5. **Comprehensive Integration**: Full API flow testing

### Test Coverage Areas
- ✅ **Authentication Flow**: Registration, login, JWT handling
- ✅ **Authorization**: Role-based access, family context
- ✅ **Family Management**: CRUD operations for families and children
- ✅ **Content Discovery**: Filtering, pagination, recommendations
- ✅ **Analytics**: Tracking, insights, milestone management
- ✅ **Error Handling**: Consistent error responses
- ✅ **Data Validation**: Input sanitization and validation
- ✅ **Serialization**: Flutter-compatible JSON formats
- ✅ **JWT Security**: Token generation, validation, expiration

## Key Testing Principles

1. **Flutter-First Design**: All tests validate Flutter frontend requirements
2. **API Contract Validation**: Ensures consistent request/response formats
3. **Error Scenario Coverage**: Tests all expected error conditions
4. **Data Integrity**: Validates serialization round-trips
5. **Security Validation**: JWT tokens, authentication, and authorization
6. **Performance Considerations**: Pagination, filtering, and data limits
7. **COPPA Compliance**: Age restrictions and parental consent flows

## Production Considerations

These tests validate the current mock implementation but are designed to work with the real production implementation when:

1. **Database Integration**: Replace mocked repositories with real database operations
2. **External Services**: Integrate with real email service, analytics platform
3. **Content Management**: Replace mock content with real CMS integration
4. **ML/AI Features**: Implement actual recommendation algorithms
5. **Security Hardening**: Add rate limiting, advanced validation, audit logging

The test suite provides confidence that all API endpoints work correctly with the Flutter frontend and can be extended as the backend implementation evolves from mock to production-ready services.