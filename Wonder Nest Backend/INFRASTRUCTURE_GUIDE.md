# WonderNest Backend Infrastructure Guide

A comprehensive guide to understanding, setting up, and migrating the WonderNest backend architecture to other projects.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Technology Stack](#technology-stack)
3. [Docker Setup](#docker-setup)
4. [Database Configuration](#database-configuration)
5. [Application Configuration](#application-configuration)
6. [Development Workflow](#development-workflow)
7. [Migration Guide](#migration-guide)
8. [Scripts and Automation](#scripts-and-automation)
9. [Monitoring and Observability](#monitoring-and-observability)
10. [Security Considerations](#security-considerations)
11. [Troubleshooting](#troubleshooting)
12. [Production Considerations](#production-considerations)

## Architecture Overview

### System Components

The WonderNest backend follows a containerized microservices architecture with the following components:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   KTOR API      │    │  PostgreSQL     │    │     Redis       │
│   (Port 8080)   │◄──►│  (Port 5433)    │    │   (Port 6379)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
    ┌─────────────────┐    ┌─────▼─────────┐    ┌─────────────────┐
    │    pgAdmin      │    │  LocalStack   │    │   Prometheus    │
    │   (Port 5050)   │    │  (Port 4566)  │    │   (Port 9090)   │
    └─────────────────┘    └───────────────┘    └─────────────────┘
                                 │
                        ┌─────────▼─────────┐
                        │     Grafana       │
                        │   (Port 3000)     │
                        └───────────────────┘
```

### Key Design Principles

1. **Containerization**: All services run in Docker containers for consistency
2. **Service Isolation**: Each service has dedicated configuration and data volumes
3. **Environment Parity**: Development environment mirrors production architecture
4. **Security by Design**: Proper user permissions, password hashing, network isolation
5. **Observability**: Built-in monitoring, logging, and health checks
6. **Developer Experience**: Automated setup scripts and comprehensive tooling

## Technology Stack

### Core Framework
- **KTOR 3.2.3**: Kotlin-native async web framework
- **Kotlin 2.1.10**: Primary programming language
- **Gradle 8.5**: Build system and dependency management

### Database Layer
- **PostgreSQL 15.5**: Primary database with Alpine Linux base
- **Exposed ORM**: Kotlin SQL framework for database operations
- **Flyway**: Database migration management
- **HikariCP**: Connection pooling

### Caching & Session Management
- **Redis 7.2**: In-memory data structure store
- **Lettuce**: Async Redis client for Kotlin/JVM

### Security & Authentication
- **JWT**: JSON Web Tokens for stateless authentication
- **BCrypt**: Password hashing (Spring Security implementation)
- **CORS**: Cross-Origin Resource Sharing configuration

### Dependency Injection
- **Koin 3.5.3**: Lightweight dependency injection framework

### Monitoring & Observability
- **Prometheus**: Metrics collection and monitoring
- **Grafana**: Visualization and dashboards
- **Micrometer**: Application metrics facade

### Development Tools
- **pgAdmin**: PostgreSQL administration interface
- **LocalStack**: AWS services emulation for development

### External Integrations
- **AWS SDK**: S3, SES, SNS, SQS services
- **SendGrid**: Email delivery service
- **Jackson**: Advanced JSON processing

## Docker Setup

### Container Architecture

The system uses Docker Compose to orchestrate multiple containers:

#### 1. API Service (`api`)
```yaml
# Multi-stage build for optimal image size
FROM gradle:8.5-jdk17 AS builder  # Build stage
FROM eclipse-temurin:17-jre       # Runtime stage

# Security: Non-root user
USER wondernest (UID: 1001)

# Health checks and proper signal handling
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
```

#### 2. PostgreSQL Service (`postgres`)
```yaml
# Features:
- Custom initialization script
- Persistent volume storage  
- Performance-optimized configuration
- Multiple user roles (app, analytics)
- Proper authentication (SCRAM-SHA-256)
```

#### 3. Redis Service (`redis`)
```yaml
# Features:
- AOF + RDB persistence
- Password authentication
- Memory optimization (LRU eviction)
- Performance monitoring
```

### Networking

All services communicate through a custom Docker network (`wondernest`) with:
- Bridge driver for container-to-container communication
- Isolated network segment from host system
- DNS-based service discovery

### Volume Management

#### Bind Mounts (Development)
```yaml
postgres_data: ./docker/volumes/postgres
redis_data:    ./docker/volumes/redis  
pgadmin_data:  ./docker/volumes/pgadmin
```

#### Named Volumes (Monitoring)
```yaml
prometheus_data: Docker-managed
grafana_data:    Docker-managed
localstack_data: Docker-managed
```

### Health Checks

Each service implements comprehensive health checks:

```yaml
postgres:
  test: ["CMD-SHELL", "pg_isready -U postgres -d wondernest_prod"]
  interval: 10s, timeout: 5s, retries: 10

redis:
  test: ["CMD", "redis-cli", "--no-auth-warning", "-a", "password", "ping"]
  interval: 10s, timeout: 5s, retries: 5

api:
  test: ["CMD", "wget", "--spider", "-q", "http://localhost:8080/health"]
  interval: 30s, timeout: 10s, retries: 3, start_period: 60s
```

## Database Configuration

### Schema Architecture

The database uses a multi-schema approach for logical separation:

```sql
-- Core schemas
CREATE SCHEMA core;          -- Users, auth, system config
CREATE SCHEMA family;        -- Family management
CREATE SCHEMA subscription;  -- Billing and subscriptions
CREATE SCHEMA content;       -- Content management
CREATE SCHEMA audio;         -- Audio processing
CREATE SCHEMA analytics;     -- Analytics and reporting
CREATE SCHEMA ml;            -- Machine learning data
CREATE SCHEMA safety;        -- Safety monitoring
CREATE SCHEMA audit;         -- Audit logging
```

### User Management

Three distinct database users with role-based permissions:

#### 1. PostgreSQL Superuser (`postgres`)
- Database administration
- Schema management
- User creation

#### 2. Application User (`wondernest_app`)
- Full CRUD operations on application schemas
- Database migration execution
- Connection limit: 50

#### 3. Analytics User (`wondernest_analytics`)
- Read-only access to all schemas
- Reporting and business intelligence
- Connection limit: 10

### Performance Optimization

#### PostgreSQL Configuration (`postgresql.conf`)
```ini
# Memory Settings
shared_buffers = 256MB        # 25% of available RAM
work_mem = 8MB                # Per-operation memory
effective_cache_size = 1GB    # OS cache estimate

# Storage Optimization
random_page_cost = 1.1        # SSD optimization
effective_io_concurrency = 100

# Connection Management  
max_connections = 100
```

#### Indexing Strategy
```sql
-- Performance indexes automatically created
CREATE INDEX idx_users_email ON core.users(email);
CREATE INDEX idx_users_active ON core.users(is_active);
CREATE INDEX idx_user_sessions_token ON core.user_sessions(token_hash);
CREATE INDEX idx_activity_logs_user_id ON audit.activity_logs(user_id);
```

### Migration Strategy

The system uses Flyway for database migrations:

```kotlin
// Migration configuration
FLYWAY_ENABLED = true
FLYWAY_BASELINE_ON_MIGRATE = true
```

Migration files location: `src/main/resources/db/migration/`

### Backup and Restore

Automated backup scripts provide data protection:

```bash
# Backup script features:
- Timestamped backups
- Compression (gzip)
- Retention policy
- Verification checks
- Incremental backups option
```

## Application Configuration

### KTOR Configuration Structure

#### Module Organization
```kotlin
fun Application.module() {
    configureDependencyInjection()  // Koin setup
    configureDatabase()            // Database connection
    configureSerialization()       // JSON serialization
    configureHTTP()               // HTTP features
    configureSecurity()           // Security headers
    configureAuthentication()     // JWT authentication  
    configureMonitoring()         // Metrics and health
    configureRouting()            // API routes
}
```

#### Configuration Files

**Primary Configuration** (`application.yaml`)
```yaml
# Environment-based configuration
database:
  host: ${DB_HOST:localhost}
  port: ${DB_PORT:5433}
  name: ${DB_NAME:wondernest_prod}

redis:
  host: ${REDIS_HOST:localhost}
  password: ${REDIS_PASSWORD:}

jwt:
  secret: ${JWT_SECRET:fallback-secret}
  expiresIn: 3600000  # 1 hour
```

**Build Configuration** (`build.gradle.kts`)
```kotlin
// Key dependencies and versions
dependencies {
    implementation("io.ktor:ktor-server-core-jvm:$ktor_version")
    implementation("org.jetbrains.exposed:exposed-core:$exposed_version")
    implementation("org.postgresql:postgresql:$postgresql_version")
    implementation("io.insert-koin:koin-ktor:$koin_version")
    // ... additional dependencies
}
```

### Environment Variable Management

The application supports multiple configuration sources:

1. **Environment Variables** (Highest Priority)
2. **application.yaml** (Default Values)
3. **Gradle Properties** (Build-time Configuration)

#### Required Environment Variables

**Database Configuration**
```bash
DB_HOST=localhost
DB_PORT=5433
DB_NAME=wondernest_prod
DB_USERNAME=wondernest_app
DB_PASSWORD=secure_password
```

**Security Configuration**
```bash
JWT_SECRET=your-super-secure-jwt-secret
REDIS_PASSWORD=redis_password
```

**External Services**
```bash
SENDGRID_API_KEY=your-sendgrid-api-key
AWS_ACCESS_KEY_ID=your-aws-key
AWS_SECRET_ACCESS_KEY=your-aws-secret
```

### Dependency Injection

Koin modules organize dependencies by domain:

```kotlin
// Example module structure
val databaseModule = module {
    single<DatabaseFactory> { DatabaseFactory(get()) }
    single<UserRepository> { UserRepositoryImpl(get()) }
}

val serviceModule = module {
    single<AuthService> { AuthService(get(), get()) }
    single<EmailService> { EmailService(get()) }
}
```

## Development Workflow

### Initial Setup

#### Prerequisites
- Docker Desktop 4.0+
- Docker Compose 2.0+
- JDK 17+ (for local development)
- Git

#### Quick Start
```bash
# 1. Clone and navigate to project
git clone <repository>
cd "Wonder Nest Backend"

# 2. Run setup script
./scripts/setup.sh

# 3. Start development environment  
./scripts/start-dev.sh

# 4. Run application
./run-app.sh
```

### Daily Development Commands

#### Database Operations
```bash
# Reset database to clean state
./scripts/reset-db.sh

# Backup current database
./scripts/backup.sh

# Restore from backup
./scripts/restore.sh backup-20240109-143022.sql.gz
```

#### Service Management
```bash
# Start all services
docker compose up -d

# View service logs
docker compose logs -f api
docker compose logs -f postgres

# Stop specific service
docker compose stop redis

# Rebuild and restart API
docker compose up --build -d api
```

#### Application Development
```bash
# Run with hot reload (local development)
./gradlew run --continuous

# Run tests
./gradlew test

# Build production JAR
./gradlew shadowJar
```

### Testing Procedures

#### Unit Testing
```kotlin
// Example test structure
@ExtendWith(KoinTestExtension::class)
class UserServiceTest {
    @Test
    fun `should create user successfully`() {
        // Test implementation
    }
}
```

#### Integration Testing
- TestContainers for database testing
- In-memory Redis for caching tests
- MockK for service mocking

#### API Testing
```bash
# Health check
curl http://localhost:8080/health

# Authentication endpoint
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'
```

### Debugging Tips

#### Database Debugging
```bash
# Connect to PostgreSQL
docker compose exec postgres psql -U wondernest_app -d wondernest_prod

# View active connections
SELECT * FROM pg_stat_activity WHERE datname = 'wondernest_prod';

# Monitor slow queries
SELECT * FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;
```

#### Redis Debugging
```bash
# Connect to Redis
docker compose exec redis redis-cli -a wondernest_redis_password_dev

# Monitor commands
MONITOR

# Check memory usage
INFO memory
```

#### Application Debugging
```bash
# View application logs with correlation IDs
docker compose logs -f api | grep "request-id"

# Check JVM metrics
curl http://localhost:8080/metrics | grep jvm
```

## Migration Guide

### Overview

This section provides step-by-step instructions for migrating another project to use the WonderNest architecture.

### Step 1: Project Structure Analysis

Before migrating, analyze your current project:

**Current Project Assessment**
```bash
# Document current architecture
├── What web framework? (Spring Boot, Node.js, etc.)
├── Database type and version?
├── Caching solution?
├── Authentication method?
├── Deployment strategy?
└── External dependencies?
```

### Step 2: Infrastructure Migration

#### Copy Infrastructure Files
```bash
# Copy Docker configuration
cp docker-compose.yml /path/to/your/project/
cp Dockerfile /path/to/your/project/
cp -r docker/ /path/to/your/project/

# Copy scripts
cp -r scripts/ /path/to/your/project/

# Copy monitoring configuration
cp -r monitoring/ /path/to/your/project/
```

#### Customize Docker Compose
```yaml
# Update service names and passwords
services:
  api:
    # Change to your application name
    container_name: yourapp_api
    
  postgres:
    container_name: yourapp_postgres
    environment:
      POSTGRES_DB: yourapp_prod
      YOURAPP_DB_NAME: yourapp_prod
      YOURAPP_APP_USER: yourapp_app
      YOURAPP_APP_PASSWORD: your_secure_password
```

#### Update Configuration Files
```bash
# Update PostgreSQL configuration
sed -i 's/wondernest/yourapp/g' docker/postgres/pg_hba.conf

# Update initialization script
sed -i 's/WONDERNEST/YOURAPP/g' scripts/01-init-wondernest-complete.sh
sed -i 's/wondernest/yourapp/g' scripts/01-init-wondernest-complete.sh
```

### Step 3: Application Migration

#### If Migrating FROM Spring Boot TO KTOR

**Dependencies Migration**
```kotlin
// Replace Spring Boot dependencies
// FROM:
implementation("org.springframework.boot:spring-boot-starter-web")
implementation("org.springframework.boot:spring-boot-starter-data-jpa")

// TO:
implementation("io.ktor:ktor-server-core-jvm:$ktor_version")
implementation("org.jetbrains.exposed:exposed-core:$exposed_version")
```

**Configuration Migration**
```yaml
# FROM: application.properties
spring.datasource.url=jdbc:postgresql://localhost:5433/myapp
spring.datasource.username=user

# TO: application.yaml
database:
  host: ${DB_HOST:localhost}
  port: ${DB_PORT:5433}
  name: ${DB_NAME:yourapp_prod}
  username: ${DB_USERNAME:yourapp_app}
```

**Code Structure Migration**
```kotlin
// FROM: Spring Boot Controller
@RestController
@RequestMapping("/api/users")
class UserController {
    @PostMapping
    fun createUser(@RequestBody user: User): User {
        return userService.create(user)
    }
}

// TO: KTOR Route
fun Route.userRoutes() {
    route("/api/users") {
        post {
            val user = call.receive<User>()
            val created = userService.create(user)
            call.respond(HttpStatusCode.Created, created)
        }
    }
}
```

#### If Migrating FROM Node.js/Express TO KTOR

**Package.json to build.gradle.kts**
```javascript
// FROM: package.json
{
  "dependencies": {
    "express": "^4.18.2",
    "pg": "^8.8.0",
    "redis": "^4.5.0",
    "jsonwebtoken": "^9.0.0"
  }
}
```

```kotlin
// TO: build.gradle.kts
dependencies {
    implementation("io.ktor:ktor-server-core-jvm:$ktor_version")
    implementation("org.postgresql:postgresql:$postgresql_version")  
    implementation("io.lettuce:lettuce-core:6.3.0.RELEASE")
    implementation("com.auth0:java-jwt:4.4.0")
}
```

**Route Migration**
```javascript
// FROM: Express route
app.post('/api/users', async (req, res) => {
    try {
        const user = await User.create(req.body);
        res.status(201).json(user);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});
```

```kotlin
// TO: KTOR route
post("/api/users") {
    try {
        val userRequest = call.receive<CreateUserRequest>()
        val user = userService.create(userRequest)
        call.respond(HttpStatusCode.Created, user)
    } catch (e: Exception) {
        call.respond(HttpStatusCode.InternalServerError, ErrorResponse(e.message))
    }
}
```

### Step 4: Database Schema Migration

#### Schema Adaptation
```sql
-- Update initialization script with your schema
-- Replace WonderNest schemas with your application schemas

-- FROM:
CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS family;
CREATE SCHEMA IF NOT EXISTS content;

-- TO:
CREATE SCHEMA IF NOT EXISTS users;
CREATE SCHEMA IF NOT EXISTS products;
CREATE SCHEMA IF NOT EXISTS orders;
```

#### Data Migration
```bash
# If migrating existing data:

# 1. Export from existing database
pg_dump -h oldhost -U olduser -d olddb --data-only > data_export.sql

# 2. Transform schema references
sed -i 's/old_schema/new_schema/g' data_export.sql

# 3. Import to new database
docker compose exec postgres psql -U yourapp_app -d yourapp_prod < data_export.sql
```

### Step 5: Configuration Updates

#### Environment Variables
```bash
# Create .env file for your project
cp .env.example .env

# Update with your values:
DB_NAME=yourapp_prod
DB_USERNAME=yourapp_app
DB_PASSWORD=your_secure_password
JWT_SECRET=your-jwt-secret
REDIS_PASSWORD=your_redis_password
```

#### Application Configuration
```yaml
# Update application.yaml
app:
  name: YourApp API
  version: 1.0.0
  baseUrl: http://localhost:8080
  frontendUrl: http://localhost:3000

# Update CORS origins
cors:
  allowed_origins: "http://localhost:3000,https://yourapp.com"
```

### Step 6: Scripts Customization

#### Update Setup Scripts
```bash
# Update scripts/setup.sh
sed -i 's/WonderNest/YourApp/g' scripts/setup.sh
sed -i 's/wondernest/yourapp/g' scripts/setup.sh

# Update validation references
sed -i 's/wondernest_prod/yourapp_prod/g' scripts/validate-setup.sh
```

#### Test Script Updates
```bash
# Update run-app.sh
export DB_NAME=${DB_NAME:-yourapp_prod}
export DB_USERNAME=${DB_USERNAME:-yourapp_app}
```

### Step 7: Testing Migration

#### Validation Checklist
```bash
# 1. Validate configuration
docker compose config --quiet

# 2. Test database setup
./scripts/setup.sh

# 3. Verify services are running
docker compose ps

# 4. Test API endpoints
curl http://localhost:8080/health

# 5. Check database connectivity
docker compose exec postgres psql -U yourapp_app -d yourapp_prod -c "SELECT 1;"
```

### Step 8: Common Migration Pitfalls

#### Database Connection Issues
```bash
# Problem: Connection refused
# Solution: Check network settings and user permissions
docker compose logs postgres | grep "authentication"
```

#### Port Conflicts
```bash
# Problem: Port already in use
# Solution: Update docker-compose.yml ports
postgres:
  ports:
    - "5433:5432"  # Use different external port
```

#### Permission Issues
```bash
# Problem: Volume permission denied
# Solution: Fix ownership
sudo chown -R $USER:$USER docker/volumes/
```

### Step 9: Production Migration Considerations

#### Security Updates
```yaml
# Update production passwords
environment:
  DB_PASSWORD: ${DB_PASSWORD}  # Load from secrets
  JWT_SECRET: ${JWT_SECRET}    # Load from secrets
  REDIS_PASSWORD: ${REDIS_PASSWORD}
```

#### Performance Tuning
```ini
# Update postgresql.conf for production
shared_buffers = 1GB           # 25% of server RAM
effective_cache_size = 4GB     # 75% of server RAM
max_connections = 200          # Based on expected load
```

#### Monitoring Setup
```yaml
# Update monitoring/prometheus.yml
scrape_configs:
  - job_name: 'yourapp-api'
    static_configs:
      - targets: ['api:8080']
```

## Scripts and Automation

### Available Scripts

The project includes comprehensive automation scripts for common tasks:

#### Core Setup Scripts

**1. setup.sh** - Complete Environment Setup
```bash
# Features:
- Docker and Docker Compose validation
- Directory creation with proper permissions
- Service startup and health verification
- Database schema initialization
- Connection information display

# Usage:
./scripts/setup.sh            # Full setup
./scripts/setup.sh --reset    # Reset environment
./scripts/setup.sh --help     # Show options
```

**2. start-dev.sh** - Development Environment Startup
```bash
# Features:
- Service dependency management
- Health check validation
- Development-specific configuration
- Hot-reload support preparation

# Usage:
./scripts/start-dev.sh        # Start development environment
```

**3. validate-setup.sh** - Setup Validation
```bash
# Features:
- Configuration file validation
- Script permissions verification
- Docker daemon status check
- Database file accessibility

# Usage:
./scripts/validate-setup.sh   # Validate entire setup
```

#### Database Management Scripts

**4. reset-db.sh** - Database Reset
```bash
# Features:
- Safe data destruction with confirmation
- Complete schema recreation
- User permission restoration
- Volume cleanup

# Usage:
./scripts/reset-db.sh         # Interactive reset
./scripts/reset-db.sh --force # Skip confirmation
```

**5. backup.sh** - Database Backup
```bash
# Features:
- Timestamped backup files
- Automatic compression (gzip)
- Verification of backup integrity
- Retention policy management

# Usage:
./scripts/backup.sh                    # Standard backup
./scripts/backup.sh --compress-level=9 # Maximum compression
```

**6. restore.sh** - Database Restore
```bash
# Features:
- Backup file validation
- Pre-restore database verification
- Progress tracking
- Rollback capability

# Usage:
./scripts/restore.sh backup-file.sql.gz
```

#### Application Scripts

**7. run-app.sh** - Application Runner
```bash
# Features:
- Environment variable validation
- Service dependency checks
- Connection testing
- Graceful shutdown handling

# Usage:
./run-app.sh                  # Start application
./run-app.sh --check-only     # Validation only
```

### Script Customization for Migration

#### Template Replacement Script
```bash
#!/bin/bash
# migrate-project.sh - Customizes scripts for new project

PROJECT_NAME="$1"
OLD_NAME="wondernest"

if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: $0 <new-project-name>"
    exit 1
fi

# Convert to various naming conventions
PROJECT_LOWER=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]')
PROJECT_UPPER=$(echo "$PROJECT_NAME" | tr '[:lower:]' '[:upper:]')

# Update all scripts
find scripts/ -name "*.sh" -exec sed -i "s/$OLD_NAME/$PROJECT_LOWER/g" {} \;
find scripts/ -name "*.sh" -exec sed -i "s/${OLD_NAME^^}/${PROJECT_UPPER}/g" {} \;

# Update configuration files
sed -i "s/$OLD_NAME/$PROJECT_LOWER/g" docker-compose.yml
sed -i "s/$OLD_NAME/$PROJECT_LOWER/g" docker/postgres/pg_hba.conf

echo "Project migration completed for: $PROJECT_NAME"
```

### Automation Features

#### Error Handling
All scripts implement comprehensive error handling:
```bash
set -e  # Exit on any error

# Custom error handler
error_exit() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

# Usage
check_docker || error_exit "Docker is not running"
```

#### Logging and Output
Consistent logging with color coding:
```bash
# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
print_success() { echo -e "${GREEN}✅${NC} $1"; }
print_error()   { echo -e "${RED}❌${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠️${NC} $1"; }
print_info()    { echo -e "${BLUE}ℹ️${NC} $1"; }
```

#### Progress Tracking
Scripts provide detailed progress feedback:
```bash
# Example from setup.sh
echo "🚀 Setting up WonderNest Development Environment..."
print_status "Checking Docker..."
print_success "Docker is running"
print_status "Starting PostgreSQL..."
print_success "PostgreSQL is ready!"
```

## Monitoring and Observability

### Prometheus Configuration

The monitoring stack provides comprehensive observability:

#### Metrics Collection
```yaml
# prometheus.yml configuration
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'wondernest-api'
    static_configs:
      - targets: ['api:8080']
    scrape_interval: 5s
    metrics_path: /metrics
    
  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres:5432']
    scrape_interval: 15s
    
  - job_name: 'redis'
    static_configs:
      - targets: ['redis:6379']
    scrape_interval: 15s
```

#### Application Metrics

KTOR application exposes metrics via Micrometer:
```kotlin
// Automatic metrics
http_requests_total          // Request count by endpoint
http_request_duration_seconds // Response time distribution
jvm_memory_used_bytes        // JVM memory usage
jvm_gc_collection_seconds    // Garbage collection timing

// Custom metrics (example)
val userRegistrationCounter = Counter.builder("user_registrations_total")
    .description("Total user registrations")
    .register(meterRegistry)
```

### Grafana Dashboards

Visualization setup for key metrics:

#### System Health Dashboard
- CPU and memory usage
- Request rate and response times  
- Error rate trending
- Database connection pool status

#### Business Metrics Dashboard
- User activity metrics
- Feature usage analytics
- Performance bottlenecks
- Error analysis

#### Infrastructure Dashboard
- Database performance
- Redis hit/miss ratios
- Container resource usage
- Network metrics

### Health Checks

Comprehensive health monitoring at multiple levels:

#### Application Health Endpoint
```kotlin
// /health endpoint implementation
data class HealthStatus(
    val status: String,
    val timestamp: Instant,
    val services: Map<String, ServiceHealth>
)

data class ServiceHealth(
    val status: String,
    val responseTime: Long,
    val details: Map<String, Any>? = null
)
```

#### Service-Level Health Checks
```yaml
# Docker health checks
postgres:
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U postgres -d wondernest_prod"]
    interval: 10s
    timeout: 5s
    retries: 10
    start_period: 30s

redis:
  healthcheck:  
    test: ["CMD", "redis-cli", "--no-auth-warning", "-a", "password", "ping"]
    interval: 10s
    timeout: 5s
    retries: 5
    start_period: 10s

api:
  healthcheck:
    test: ["CMD", "wget", "--spider", "-q", "http://localhost:8080/health"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 60s
```

### Logging Strategy

Structured logging with correlation IDs:

#### Log Configuration
```xml
<!-- logback.xml configuration -->
<configuration>
    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <encoder class="net.logstash.logback.encoder.LoggingEventCompositeJsonEncoder">
            <providers>
                <timestamp/>
                <logLevel/>
                <loggerName/>
                <message/>
                <mdc/>
                <arguments/>
            </providers>
        </encoder>
    </appender>
    
    <logger name="com.wondernest" level="DEBUG"/>
    <root level="INFO">
        <appender-ref ref="STDOUT"/>
    </root>
</configuration>
```

#### Request Tracing
```kotlin
// Automatic request correlation
install(CallId) {
    header(HttpHeaders.XRequestId)
    generate { UUID.randomUUID().toString() }
}

install(CallLogging) {
    level = Level.INFO
    format { call ->
        val status = call.response.status()
        val httpMethod = call.request.httpMethod.value
        val userAgent = call.request.headers["User-Agent"]
        "Status: $status, HTTP method: $httpMethod, User agent: $userAgent"
    }
}
```

### Alerting

Alert rules for critical system events:

```yaml
# alert_rules.yml (example)
groups:
  - name: wondernest_alerts
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: High error rate detected
          
      - alert: DatabaseConnectionsHigh
        expr: pg_stat_activity_count > 80
        for: 1m
        labels:
          severity: warning
        annotations:
          summary: Database connection pool nearly exhausted
```

## Security Considerations

### Authentication and Authorization

#### JWT Implementation
```kotlin
// Secure JWT configuration
jwt {
    issuer = "wondernest-api"
    audience = "wondernest-users"
    realm = "WonderNest API"
    
    // Environment-based secret management
    secret = System.getenv("JWT_SECRET") ?: error("JWT_SECRET must be set")
    
    validate { credential ->
        // Token validation logic
        if (credential.payload.getClaim("userId").asString() != "") {
            JWTPrincipal(credential.payload)
        } else null
    }
}
```

#### Password Security
```kotlin
// BCrypt password hashing
private val passwordEncoder = BCryptPasswordEncoder(12) // Strong cost factor

fun hashPassword(plainPassword: String): String {
    return passwordEncoder.encode(plainPassword)
}

fun verifyPassword(plainPassword: String, hashedPassword: String): Boolean {
    return passwordEncoder.matches(plainPassword, hashedPassword)
}
```

### Database Security

#### Connection Security
```ini
# PostgreSQL security settings (pg_hba.conf)
# SCRAM-SHA-256 authentication for all connections
host    all    all    172.16.0.0/12    scram-sha-256
host    all    all    192.168.0.0/16   scram-sha-256
host    all    all    10.0.0.0/8       scram-sha-256
```

#### User Permissions
```sql
-- Principle of least privilege
GRANT USAGE ON SCHEMA core TO wondernest_app;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA core TO wondernest_app;

-- Read-only analytics user
GRANT USAGE ON SCHEMA core TO wondernest_analytics;
GRANT SELECT ON ALL TABLES IN SCHEMA core TO wondernest_analytics;
```

### Network Security

#### Container Isolation
```yaml
# Custom network for service isolation
networks:
  wondernest:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

#### CORS Configuration
```kotlin
install(CORS) {
    allowMethod(HttpMethod.Get)
    allowMethod(HttpMethod.Post)
    allowMethod(HttpMethod.Put)
    allowMethod(HttpMethod.Delete)
    
    allowHeader(HttpHeaders.Authorization)
    allowHeader(HttpHeaders.ContentType)
    
    // Environment-specific origins
    val allowedOrigins = System.getenv("CORS_ALLOWED_ORIGINS")
        ?.split(",") 
        ?: listOf("http://localhost:3000")
        
    allowedOrigins.forEach { origin ->
        allowHost(origin, schemes = listOf("http", "https"))
    }
}
```

### Secrets Management

#### Development Secrets
```bash
# .env file (not committed to repository)
DB_PASSWORD=secure_development_password
JWT_SECRET=development-jwt-secret-at-least-32-chars
REDIS_PASSWORD=redis_development_password
SENDGRID_API_KEY=SG.development-api-key
```

#### Production Secrets
```yaml
# Production deployment (example with Docker Secrets)
services:
  api:
    environment:
      DB_PASSWORD_FILE: /run/secrets/db_password
      JWT_SECRET_FILE: /run/secrets/jwt_secret
    secrets:
      - db_password
      - jwt_secret

secrets:
  db_password:
    external: true
  jwt_secret:
    external: true
```

### Security Headers

```kotlin
install(DefaultHeaders) {
    header("X-Content-Type-Options", "nosniff")
    header("X-Frame-Options", "DENY")
    header("X-XSS-Protection", "1; mode=block")
    header("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
    header("Content-Security-Policy", "default-src 'self'")
}
```

### Input Validation

```kotlin
// Using Yavi for validation
val userValidator = ValidatorBuilder.of<CreateUserRequest>()
    .constraint(CreateUserRequest::email, "email") {
        it.notNull().email()
    }
    .constraint(CreateUserRequest::password, "password") {
        it.notNull().greaterThanOrEqual(8).lessThanOrEqual(128)
    }
    .build()

// Request validation
post("/users") {
    val request = call.receive<CreateUserRequest>()
    val validation = userValidator.validate(request)
    
    if (!validation.isValid) {
        call.respond(HttpStatusCode.BadRequest, validation.toList())
        return@post
    }
    
    // Process valid request
    val user = userService.create(request)
    call.respond(HttpStatusCode.Created, user)
}
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Docker-related Issues

**Problem: Port already in use**
```bash
# Symptoms
Error: bind: address already in use

# Diagnosis
netstat -tulpn | grep :5433
lsof -i :5433

# Solutions
# Option 1: Stop conflicting service
brew services stop postgresql@14

# Option 2: Change port mapping in docker-compose.yml
postgres:
  ports:
    - "5433:5432"  # Use different external port
```

**Problem: Permission denied for volume mounts**
```bash
# Symptoms
Error: permission denied

# Diagnosis
ls -la docker/volumes/

# Solution
chmod 755 docker/volumes/postgres
chmod 755 docker/volumes/redis
chmod 755 docker/volumes/pgadmin
```

**Problem: Container fails to start**
```bash
# Diagnosis
docker compose logs postgres
docker compose ps

# Common solutions
# 1. Check disk space
df -h

# 2. Clear Docker cache
docker system prune -a

# 3. Remove corrupted volumes
docker compose down -v
sudo rm -rf docker/volumes/*
```

#### 2. Database Issues

**Problem: Connection refused**
```bash
# Symptoms
FATAL: connection refused

# Diagnosis steps
# 1. Check container status
docker compose ps postgres

# 2. Check container logs
docker compose logs postgres

# 3. Test internal connectivity
docker compose exec api ping postgres

# Solutions
# 1. Wait for PostgreSQL to fully start
timeout=60
while [ $timeout -gt 0 ]; do
    if docker compose exec postgres pg_isready -U postgres; then
        echo "PostgreSQL is ready"
        break
    fi
    sleep 2
    timeout=$((timeout-2))
done

# 2. Check configuration
docker compose exec postgres cat /etc/postgresql/postgresql.conf
```

**Problem: Authentication failed**
```bash
# Symptoms  
FATAL: password authentication failed for user "wondernest_app"

# Diagnosis
docker compose exec postgres psql -U postgres -c "\du"

# Solutions
# 1. Recreate user
docker compose exec postgres psql -U postgres -d wondernest_prod -c "
DROP ROLE IF EXISTS wondernest_app;
CREATE ROLE wondernest_app WITH LOGIN PASSWORD 'wondernest_secure_password_dev';
"

# 2. Check pg_hba.conf
docker compose exec postgres cat /etc/postgresql/pg_hba.conf
```

**Problem: Database does not exist**
```bash
# Symptoms
FATAL: database "wondernest_prod" does not exist

# Solution - recreate database
docker compose exec postgres psql -U postgres -c "
CREATE DATABASE wondernest_prod;
"
```

#### 3. Application Issues

**Problem: Application fails to start**
```bash
# Symptoms
Application startup errors

# Diagnosis
# 1. Check environment variables
./run-app.sh --check-only

# 2. Verify database connectivity
docker compose exec postgres psql -U wondernest_app -d wondernest_prod -c "SELECT 1;"

# 3. Check application logs
./gradlew run

# Solutions
# 1. Fix missing environment variables
export DB_PASSWORD=wondernest_secure_password_dev
export JWT_SECRET=development-jwt-secret-change-in-production

# 2. Clear Gradle cache
./gradlew clean build
```

**Problem: Health check failures**
```bash
# Symptoms
Health check endpoint returns 500

# Diagnosis
curl -v http://localhost:8080/health

# Solutions
# 1. Check service dependencies
docker compose ps

# 2. Verify database connectivity
docker compose exec postgres pg_isready -U postgres

# 3. Check Redis connectivity
docker compose exec redis redis-cli -a wondernest_redis_password_dev ping
```

#### 4. Performance Issues

**Problem: Slow database queries**
```sql
-- Diagnosis
-- Check for slow queries
SELECT query, calls, total_time, mean_time 
FROM pg_stat_statements 
ORDER BY total_time DESC 
LIMIT 10;

-- Check for missing indexes
SELECT schemaname, tablename, attname, n_distinct, correlation
FROM pg_stats
WHERE schemaname NOT IN ('information_schema', 'pg_catalog');

-- Solutions
-- 1. Add missing indexes
CREATE INDEX CONCURRENTLY idx_users_email ON core.users(email);

-- 2. Update table statistics
ANALYZE;

-- 3. Increase work_mem for complex queries
SET work_mem = '256MB';
```

**Problem: High memory usage**
```bash
# Diagnosis
docker stats
free -h

# Solutions
# 1. Adjust PostgreSQL memory settings
# In docker/postgres/postgresql.conf:
shared_buffers = 128MB     # Reduce if needed
work_mem = 4MB            # Reduce if needed

# 2. Limit JVM heap size
# In Dockerfile:
ENV JAVA_OPTS="-XX:MaxRAMPercentage=50.0"
```

### Health Check Procedures

#### Service Health Verification
```bash
#!/bin/bash
# health-check.sh - Comprehensive health verification

echo "🏥 WonderNest Health Check"
echo "========================="

# 1. Docker Health
echo "1. Checking Docker services..."
docker compose ps

# 2. Database Health  
echo "2. Checking PostgreSQL..."
if docker compose exec postgres pg_isready -U postgres -d wondernest_prod; then
    echo "✅ PostgreSQL is healthy"
else
    echo "❌ PostgreSQL is unhealthy"
fi

# 3. Redis Health
echo "3. Checking Redis..."
if docker compose exec redis redis-cli --no-auth-warning -a wondernest_redis_password_dev ping; then
    echo "✅ Redis is healthy"
else
    echo "❌ Redis is unhealthy"  
fi

# 4. Application Health
echo "4. Checking Application..."
if curl -sf http://localhost:8080/health > /dev/null; then
    echo "✅ Application is healthy"
else
    echo "❌ Application is unhealthy"
fi

# 5. Database Connectivity
echo "5. Checking Database Connectivity..."
if docker compose exec postgres psql -U wondernest_app -d wondernest_prod -c "SELECT 1;" > /dev/null; then
    echo "✅ Database connectivity is healthy"
else
    echo "❌ Database connectivity is unhealthy"
fi
```

#### Log Analysis
```bash
# Automated log analysis for common issues
#!/bin/bash
# analyze-logs.sh

echo "🔍 Log Analysis"
echo "==============="

# Check for common error patterns
echo "Checking for database connection errors..."
docker compose logs postgres | grep -i "connection\|authentication\|error" | tail -10

echo "Checking for application errors..."
docker compose logs api | grep -i "error\|exception\|failed" | tail -10

echo "Checking for Redis issues..."
docker compose logs redis | grep -i "error\|warning" | tail -10

# Memory usage analysis
echo "Memory usage analysis..."
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
```

### Log Locations and Analysis

#### Container Logs
```bash
# Real-time log monitoring
docker compose logs -f api          # Application logs
docker compose logs -f postgres     # Database logs  
docker compose logs -f redis        # Cache logs
docker compose logs -f pgadmin      # Admin interface logs

# Search specific patterns
docker compose logs api | grep "ERROR"
docker compose logs postgres | grep "FATAL"
```

#### Application Logs
```bash
# Structured log analysis with jq
docker compose logs api | grep "{" | jq '.level, .message, .timestamp'

# Filter by log level
docker compose logs api | grep '"level":"ERROR"' | jq '.'
```

#### Database Logs
```bash
# Query performance analysis
docker compose exec postgres tail -f /var/log/postgresql/postgresql.log

# Connection monitoring
docker compose exec postgres psql -U postgres -c "
SELECT pid, usename, application_name, client_addr, state, query
FROM pg_stat_activity
WHERE state = 'active';
"
```

## Production Considerations

### Performance Optimization

#### Database Tuning
```ini
# Production PostgreSQL configuration
# Memory settings (for 8GB server)
shared_buffers = 2GB              # 25% of RAM
effective_cache_size = 6GB        # 75% of RAM
maintenance_work_mem = 512MB      # For maintenance operations
work_mem = 32MB                   # Per connection

# Connection settings
max_connections = 200             # Based on expected load
idle_in_transaction_session_timeout = 60min

# Performance settings
random_page_cost = 1.1            # SSD optimization
effective_io_concurrency = 200    # Number of concurrent I/O operations
checkpoint_completion_target = 0.9
wal_buffers = 64MB
```

#### Application Optimization
```kotlin
// Production KTOR configuration
embeddedServer(Netty, 
    port = 8080,
    host = "0.0.0.0"
) {
    // Production-optimized settings
    connector {
        connectionGroupSize = 2
        workerGroupSize = 5
        callGroupSize = 10
    }
}

// Database connection pool optimization
val config = HikariConfig().apply {
    jdbcUrl = dbUrl
    username = dbUser
    password = dbPassword
    maximumPoolSize = 50          // Increase for production
    minimumIdle = 10              // Maintain minimum connections
    connectionTimeout = 30000     // 30 seconds
    idleTimeout = 600000          // 10 minutes
    maxLifetime = 1800000         // 30 minutes
    leakDetectionThreshold = 60000 // 1 minute
}
```

### Security Hardening

#### Production Secrets Management
```yaml
# Example using Docker Swarm secrets
version: '3.8'
services:
  api:
    environment:
      DB_PASSWORD_FILE: /run/secrets/db_password
      JWT_SECRET_FILE: /run/secrets/jwt_secret
      REDIS_PASSWORD_FILE: /run/secrets/redis_password
    secrets:
      - db_password
      - jwt_secret  
      - redis_password

secrets:
  db_password:
    external: true
    name: wondernest_db_password_v1
  jwt_secret:
    external: true
    name: wondernest_jwt_secret_v1
  redis_password:
    external: true
    name: wondernest_redis_password_v1
```

#### Network Security
```yaml
# Production network configuration
networks:
  frontend:
    driver: overlay
    external: true
  backend:
    driver: overlay
    internal: true  # No external access

services:
  api:
    networks:
      - frontend  # Exposed to load balancer
      - backend   # Access to database/redis
      
  postgres:
    networks:
      - backend   # Internal only
      
  redis:
    networks:
      - backend   # Internal only
```

#### SSL/TLS Configuration
```nginx
# Nginx reverse proxy configuration
server {
    listen 443 ssl http2;
    server_name api.wondernest.com;
    
    ssl_certificate /etc/ssl/certs/wondernest.crt;
    ssl_certificate_key /etc/ssl/private/wondernest.key;
    
    # Security headers
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
    
    location / {
        proxy_pass http://wondernest_api:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Scaling Considerations

#### Horizontal Scaling
```yaml
# Docker Swarm deployment example
version: '3.8'
services:
  api:
    image: wondernest/api:latest
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
      restart_policy:
        condition: on-failure
        max_attempts: 3
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

#### Database Scaling
```yaml
# PostgreSQL with read replicas
services:
  postgres_primary:
    image: postgres:15.5
    environment:
      POSTGRES_REPLICATION_MODE: master
      POSTGRES_REPLICATION_USER: replicator
      POSTGRES_REPLICATION_PASSWORD: ${REPLICATION_PASSWORD}
      
  postgres_replica:
    image: postgres:15.5
    depends_on:
      - postgres_primary
    environment:
      POSTGRES_REPLICATION_MODE: slave
      POSTGRES_MASTER_HOST: postgres_primary
      POSTGRES_REPLICATION_USER: replicator
      POSTGRES_REPLICATION_PASSWORD: ${REPLICATION_PASSWORD}
```

### Monitoring and Alerting

#### Production Monitoring Stack
```yaml
# Complete monitoring setup
services:
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./monitoring/alerts.yml:/etc/prometheus/alerts.yml
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--web.enable-lifecycle'
      - '--alertmanager.url=http://alertmanager:9093'

  alertmanager:
    image: prom/alertmanager:latest
    volumes:
      - ./monitoring/alertmanager.yml:/etc/alertmanager/alertmanager.yml
    
  grafana:
    image: grafana/grafana:latest
    environment:
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_ADMIN_PASSWORD}
      GF_SMTP_ENABLED: true
      GF_SMTP_HOST: smtp.gmail.com:587
      GF_SMTP_USER: ${SMTP_USER}
      GF_SMTP_PASSWORD: ${SMTP_PASSWORD}
```

#### Custom Metrics
```kotlin
// Production metrics
val registry = PrometheusMeterRegistry(PrometheusConfig.DEFAULT)

// Business metrics
val userRegistrations = Counter.builder("user_registrations_total")
    .description("Total number of user registrations")
    .register(registry)

val activeUsers = Gauge.builder("active_users_current")
    .description("Currently active users")
    .register(registry) { userService.getActiveUserCount().toDouble() }

// Performance metrics
val databaseQueryTimer = Timer.builder("database_query_duration")
    .description("Database query execution time")
    .register(registry)
```

### Backup and Disaster Recovery

#### Automated Backup Strategy
```bash
#!/bin/bash
# production-backup.sh

BACKUP_RETENTION_DAYS=30
BACKUP_DIR="/backups/$(date +%Y/%m/%d)"
mkdir -p "$BACKUP_DIR"

# Database backup with compression
pg_dump -h postgres -U postgres -d wondernest_prod \
    | gzip > "$BACKUP_DIR/database-$(date +%H%M%S).sql.gz"

# Redis backup
cp /var/lib/redis/dump.rdb "$BACKUP_DIR/redis-$(date +%H%M%S).rdb"

# Application data backup  
tar -czf "$BACKUP_DIR/app-data-$(date +%H%M%S).tar.gz" /app/uploads/

# Upload to cloud storage (AWS S3 example)
aws s3 sync /backups/ s3://wondernest-backups/production/

# Cleanup old backups
find /backups -type f -mtime +$BACKUP_RETENTION_DAYS -delete
```

#### Disaster Recovery Procedures
```bash
#!/bin/bash
# disaster-recovery.sh

echo "🚨 WonderNest Disaster Recovery"
echo "==============================="

# 1. Stop all services
docker compose down

# 2. Restore database from backup
LATEST_BACKUP=$(find /backups -name "database-*.sql.gz" | sort | tail -1)
echo "Restoring from: $LATEST_BACKUP"

docker compose up -d postgres
sleep 30  # Wait for PostgreSQL to start

gunzip -c "$LATEST_BACKUP" | docker compose exec -T postgres psql -U postgres -d wondernest_prod

# 3. Restore Redis data
LATEST_REDIS_BACKUP=$(find /backups -name "redis-*.rdb" | sort | tail -1)
cp "$LATEST_REDIS_BACKUP" docker/volumes/redis/dump.rdb

# 4. Restore application data
LATEST_APP_BACKUP=$(find /backups -name "app-data-*.tar.gz" | sort | tail -1)
tar -xzf "$LATEST_APP_BACKUP" -C /

# 5. Start all services
docker compose up -d

echo "✅ Disaster recovery completed"
```

---

This infrastructure guide provides comprehensive documentation for understanding, setting up, and migrating the WonderNest backend architecture. The modular design and comprehensive automation make it suitable for adaptation to various project types and deployment scenarios.

For additional support or questions about migration, refer to the [Migration Checklist](MIGRATION_CHECKLIST.md) for a step-by-step implementation guide.