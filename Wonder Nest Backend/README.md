# WonderNest Backend API

A comprehensive, production-ready Ktor backend implementation for the WonderNest child development and content platform. Built with Kotlin, KTOR, PostgreSQL, and Redis, following clean architecture principles.

## Overview

WonderNest is a COPPA-compliant platform that helps parents track their child's development through audio analysis and curated content engagement. The backend implements privacy-first architecture with on-device audio processing and secure cloud analytics.

## Features

### Core Features
- **User Management** - Parent registration, authentication, and profile management
- **JWT Authentication** - Secure token-based authentication with refresh tokens
- **Family Management** - Family groups and child profiles with privacy controls
- **Content Library** - Curated, age-appropriate content with safety ratings
- **Audio Analytics** - Privacy-safe speech analysis and development tracking
- **Development Insights** - Child progress tracking and milestone detection
- **Subscription Management** - Stripe-integrated billing and feature gating

### Technical Features
- **Clean Architecture** - Domain, Data, and Presentation layers
- **COPPA Compliance** - Privacy-first design with minimal data collection
- **Rate Limiting** - Configurable rate limiting for API endpoints
- **Caching** - Redis-based caching for performance optimization
- **Monitoring** - Prometheus metrics and health checks
- **Docker Support** - Containerized deployment with Docker Compose
- **Database Migrations** - Flyway database migration support
- **Security** - Input validation, SQL injection protection, and audit logging

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Mobile Apps   │────│   API Gateway   │────│     Backend     │
│  (Flutter/iOS)  │    │   (Load Bal.)   │    │     Services    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                      │
                       ┌─────────────────┬────────────┼────────────┐
                       │                 │            │            │
                ┌──────▼──────┐  ┌──────▼──────┐  ┌──▼──┐  ┌─────▼─────┐
                │ PostgreSQL  │  │    Redis    │  │ S3  │  │   Email   │
                │ (Primary)   │  │   (Cache)   │  │     │  │ (SendGrid)│
                └─────────────┘  └─────────────┘  └─────┘  └───────────┘
```

## Quick Start

### Prerequisites
- Java 17+
- Docker and Docker Compose
- PostgreSQL 16+ (if running locally)
- Redis 7+ (if running locally)

### Using Docker Compose (Recommended)

1. Clone the repository
2. Copy environment configuration:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. Start all services:
   ```bash
   docker-compose up -d
   ```

4. The API will be available at `http://localhost:8080`

### Local Development

1. **Database Setup**:
   ```bash
   # Start PostgreSQL and Redis
   docker-compose up -d postgres redis
   
   # Run database migrations
   ./gradlew flywayMigrate
   ```

2. **Environment Configuration**:
   ```bash
   cp .env.example .env
   # Update database and Redis connection details
   ```

3. **Run the Application**:
   ```bash
   ./gradlew run
   ```

## API Documentation

### Health Checks
- `GET /health` - Application health status
- `GET /ready` - Readiness probe
- `GET /metrics` - Prometheus metrics

### Authentication
- `POST /api/v1/auth/signup` - User registration
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/oauth` - OAuth login (Google, Apple)
- `POST /api/v1/auth/refresh` - Refresh access token
- `POST /api/v1/auth/logout` - User logout
- `POST /api/v1/auth/password-reset` - Request password reset
- `POST /api/v1/auth/verify-email` - Verify email address

### Family Management
- `GET /api/v1/families` - Get family information
- `POST /api/v1/families` - Create family
- `GET /api/v1/children` - Get child profiles
- `POST /api/v1/children` - Create child profile

### Content
- `GET /api/v1/content/library` - Get content library
- `GET /api/v1/content/recommendations/{childId}` - Get content recommendations
- `POST /api/v1/content/engagement` - Track content engagement

### Audio Analytics
- `POST /api/v1/audio/sessions` - Create audio session
- `POST /api/v1/audio/metrics` - Upload speech metrics
- `GET /api/v1/audio/sessions/{id}/status` - Get session status

### Analytics
- `GET /api/v1/analytics/children/{childId}/daily` - Daily child metrics
- `GET /api/v1/analytics/children/{childId}/insights` - Development insights
- `POST /api/v1/analytics/events` - Track analytics events

## Configuration

### Environment Variables

Key configuration options:

```env
# Database
DB_HOST=localhost
DB_NAME=wondernest_dev
DB_USERNAME=wondernest_user
DB_PASSWORD=wondernest_password

# JWT
JWT_SECRET=your-secure-jwt-secret
JWT_EXPIRES_IN=3600000

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# AWS (for production)
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_S3_BUCKET=your-content-bucket

# Email
SENDGRID_API_KEY=your-sendgrid-key
```

### Feature Flags
```env
FEATURE_EMAIL_VERIFICATION=true
FEATURE_MFA_ENABLED=true
FEATURE_AUDIT_LOGGING=true
FEATURE_RATE_LIMITING=true
```

## Development

### Project Structure
```
src/main/kotlin/com/wondernest/
├── api/                    # API routes and controllers
│   ├── auth/              # Authentication endpoints
│   ├── family/            # Family management endpoints
│   ├── content/           # Content management endpoints
│   ├── audio/             # Audio processing endpoints
│   └── analytics/         # Analytics endpoints
├── config/                # Application configuration
├── domain/                # Domain models and business logic
│   ├── model/             # Domain entities
│   ├── repository/        # Repository interfaces
│   └── usecase/           # Business use cases
├── data/                  # Data layer implementation
│   ├── database/          # Database entities and repositories
│   │   ├── table/         # Exposed table definitions
│   │   └── repository/    # Repository implementations
│   ├── cache/             # Redis cache implementation
│   └── external/          # External API integrations
├── services/              # Application services
│   ├── auth/              # Authentication service
│   ├── email/             # Email service
│   ├── storage/           # File storage service
│   └── notification/      # Push notification service
└── utils/                 # Utility classes
```

### Database Schema

The application uses a comprehensive PostgreSQL schema with these main entities:

- **Users** - Parent accounts and authentication
- **Families** - Family groups and relationships
- **ChildProfiles** - Child information (COPPA compliant)
- **ContentItems** - Curated content library
- **AudioSessions** - Audio recording metadata
- **SpeechMetrics** - Privacy-safe analysis results
- **Analytics** - Development tracking and insights

### Testing

```bash
# Run unit tests
./gradlew test

# Run integration tests
./gradlew integrationTest

# Run with test containers
./gradlew testWithContainers
```

### Code Quality

The project follows strict coding standards:

- **Kotlin Coding Conventions**
- **Clean Architecture** principles
- **SOLID** design patterns
- **Comprehensive error handling**
- **Input validation** on all endpoints
- **Security best practices**

## Deployment

### Docker Production

```bash
# Build production image
docker build -t wondernest-api:latest .

# Run with production compose
docker-compose -f docker-compose.prod.yml up -d
```

### Kubernetes

```bash
# Apply Kubernetes manifests
kubectl apply -f k8s/
```

### Environment-Specific Configs

- **Development**: `application.yaml`
- **Staging**: `application-staging.yaml`  
- **Production**: `application-production.yaml`

## Security

### Privacy & COPPA Compliance

- **Minimal Data Collection** - Only collect necessary data
- **On-Device Processing** - Audio analysis on client side
- **Data Encryption** - AES-256 encryption at rest
- **Secure Transmission** - TLS 1.3 for all communications
- **Parental Consent** - Verified consent for child data
- **Data Retention** - Automated cleanup of expired data

### Authentication & Authorization

- **JWT Tokens** - Short-lived access tokens
- **Refresh Tokens** - Secure token renewal
- **Rate Limiting** - Prevent abuse and DoS attacks
- **Input Validation** - Comprehensive request validation
- **SQL Injection Protection** - Parameterized queries
- **XSS Prevention** - Input sanitization

## Monitoring & Observability

### Metrics
- **Prometheus** metrics collection
- **Grafana** dashboards
- **Application metrics** - Request rates, latency, errors
- **Business metrics** - User activity, content engagement

### Logging
- **Structured logging** with Logback
- **Request/response logging**
- **Error tracking** and alerting
- **Audit logging** for compliance

### Health Checks
- **Readiness probes** - Database and Redis connectivity
- **Liveness probes** - Application health
- **Dependency health** - External service status

## Contributing

1. Fork the repository
2. Create a feature branch
3. Follow coding standards
4. Add tests for new features
5. Submit a pull request

## Performance

### Optimization Features
- **Connection Pooling** - HikariCP for database connections
- **Redis Caching** - Aggressive caching strategy
- **Database Indexing** - Optimized query performance
- **Async Processing** - Kotlin coroutines for concurrency
- **Response Compression** - Gzip compression
- **CDN Integration** - CloudFront for static content

### Expected Performance
- **Response Time**: < 200ms (95th percentile)
- **Throughput**: > 1000 RPS per instance
- **Database**: Optimized for read-heavy workloads
- **Cache Hit Rate**: > 90% for frequently accessed data

## License

This project is proprietary software for WonderNest. All rights reserved.

## Support

For technical questions or support:
- Create an issue in the repository
- Contact the development team
- Review the API documentation

---

**Version**: 0.0.1  
**Last Updated**: January 2025  
**Built with**: Kotlin, KTOR, PostgreSQL, Redis

