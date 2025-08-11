# WonderNest API - Swagger Documentation

## Overview

The WonderNest API now includes comprehensive Swagger/OpenAPI documentation for easy API exploration and testing. This documentation provides detailed information about all available endpoints, request/response schemas, authentication requirements, and interactive testing capabilities.

## Accessing Swagger UI

### Development Environment

When running the application locally, you can access the Swagger UI at:

- **Swagger UI**: http://localhost:8080/swagger
- **OpenAPI Specification**: http://localhost:8080/openapi.yaml

### Production Environment

- **Swagger UI**: https://api.wondernest.com/swagger
- **OpenAPI Specification**: https://api.wondernest.com/openapi.yaml

## Features

### 1. Interactive API Explorer
- Browse all available API endpoints organized by functional areas
- View detailed parameter descriptions and examples
- Test endpoints directly from the browser interface
- See real-time request/response examples

### 2. Authentication Testing
- JWT Bearer token authentication is fully documented
- Use the "Authorize" button in Swagger UI to set your bearer token
- All protected endpoints are clearly marked with lock icons
- Token can be obtained from `/api/v1/auth/login` or `/api/v1/auth/signup` endpoints

### 3. Comprehensive Documentation
- **Authentication**: Complete auth flow including signup, login, OAuth, password reset
- **Family Management**: Family creation, member management, child profiles
- **Content Management**: Content library, personalized recommendations, engagement tracking
- **Audio Management**: Audio session management, metrics collection, quality monitoring
- **Analytics**: Daily analytics, development insights, milestone tracking
- **Health Monitoring**: Service health checks and monitoring endpoints

## Using the API with Swagger UI

### Step 1: Get Authentication Token

1. Navigate to the "Authentication" section
2. Use the `POST /api/v1/auth/signup` endpoint to create a new account, or
3. Use the `POST /api/v1/auth/login` endpoint to authenticate with existing credentials
4. Copy the `accessToken` from the response

### Step 2: Authorize Requests

1. Click the "Authorize" button at the top of the Swagger UI
2. Enter your access token in the format: `Bearer your_access_token_here`
3. Click "Authorize" to apply the token to all subsequent requests

### Step 3: Explore and Test Endpoints

1. Browse the available endpoint categories
2. Click on any endpoint to see detailed documentation
3. Click "Try it out" to enable interactive testing
4. Fill in required parameters and request body
5. Click "Execute" to send the request and see the response

## API Endpoint Categories

### Authentication (`/api/v1/auth`)
- User registration and login
- OAuth authentication (Google, Apple, Facebook)
- Token refresh and session management
- Password reset functionality
- Email verification
- User profile access

### Family Management (`/api/v1/families`, `/api/v1/children`)
- Create and manage family groups
- Add and manage child profiles
- Family member permissions
- Child interest and preference tracking

### Content Management (`/api/v1/content`, `/api/v1/categories`)
- Browse content library
- Get personalized recommendations
- Track content engagement
- Manage content categories

### Audio Management (`/api/v1/audio`)
- Audio playback session management
- Audio quality metrics collection
- Session status tracking
- Performance monitoring

### Analytics (`/api/v1/analytics`)
- Daily activity analytics
- AI-powered development insights
- Milestone tracking and progress
- Custom event tracking

### Health Monitoring (`/health`)
- Basic health checks
- Detailed service status
- Kubernetes-compatible probes (readiness, liveness, startup)

## Request/Response Examples

All endpoints include comprehensive examples for:
- Request payloads with realistic sample data
- Success response formats
- Error response formats with appropriate HTTP status codes
- Parameter validation examples

## Error Handling

The API uses standard HTTP status codes:
- `200 OK` - Successful requests
- `201 Created` - Successful resource creation
- `400 Bad Request` - Invalid request data
- `401 Unauthorized` - Authentication required or invalid
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `429 Too Many Requests` - Rate limit exceeded
- `500 Internal Server Error` - Server error

All error responses include a descriptive message to help with debugging.

## Rate Limiting

Some endpoints (particularly authentication) are rate-limited for security:
- Authentication endpoints: Limited requests per IP per time window
- Other endpoints: Standard rate limits apply

Rate limit information is included in the response headers when applicable.

## Data Formats

- **Dates**: ISO 8601 format (e.g., "2024-01-15T10:45:00Z")
- **UUIDs**: Standard UUID v4 format
- **Timestamps**: UTC timezone
- **File URLs**: Absolute HTTPS URLs

## Security Considerations

- All authentication endpoints use HTTPS in production
- JWT tokens have expiration times
- Refresh tokens should be stored securely
- Personal data is protected and only accessible by authorized users
- All endpoints validate input data and sanitize outputs

## Development Notes

When adding new endpoints to the codebase:

1. Add OpenAPI documentation using the `openAPI` DSL
2. Include comprehensive examples for requests and responses
3. Document all parameters with descriptions and examples
4. Specify security requirements using `securitySchemeName = "JWT"`
5. Include appropriate HTTP status codes and error responses

Example:
```kotlin
get("/example", {
    tags = listOf("Example")
    summary = "Example endpoint"
    description = "Detailed description of what this endpoint does"
    
    securitySchemeName = "JWT" // For protected endpoints
    
    request {
        pathParameter<String>("id") {
            description = "Resource identifier"
            example = "123e4567-e89b-12d3-a456-426614174000"
        }
    }
    
    response {
        HttpStatusCode.OK to {
            description = "Success response"
            body<ExampleResponse> {
                example("example", ExampleResponse(...))
            }
        }
    }
}) {
    // Implementation
}
```

## Support

For questions about the API or issues with the documentation:
- Email: support@wondernest.com
- Check the health endpoints for service status
- Review error responses for detailed debugging information