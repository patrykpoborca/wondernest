#!/bin/bash
# WonderNest Local Development Script
# Starts Docker services and runs KTOR locally with proper configuration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect docker-compose command
if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
else
    COMPOSE_CMD="docker compose"
fi

cd "$PROJECT_ROOT"

echo "🚀 Starting WonderNest Local Development..."

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker Desktop and try again."
    exit 1
fi

# Start required services (database and Redis)
print_status "Starting Docker services (PostgreSQL, Redis)..."
$COMPOSE_CMD up -d postgres redis

# Wait for services to be healthy
print_status "Waiting for services to be ready..."

# Wait for PostgreSQL
print_status "Waiting for PostgreSQL..."
timeout=60
while [ $timeout -gt 0 ]; do
    if docker exec wondernest_postgres pg_isready -U postgres -d wondernest_prod >/dev/null 2>&1; then
        break
    fi
    sleep 2
    timeout=$((timeout-2))
done

if [ $timeout -le 0 ]; then
    print_error "PostgreSQL failed to start within 60 seconds"
    print_status "Checking PostgreSQL logs:"
    $COMPOSE_CMD logs postgres
    exit 1
fi

# Wait for Redis
print_status "Waiting for Redis..."
timeout=30
while [ $timeout -gt 0 ]; do
    if docker exec wondernest_redis redis-cli --no-auth-warning -a wondernest_redis_password_dev ping >/dev/null 2>&1; then
        break
    fi
    sleep 1
    timeout=$((timeout-1))
done

if [ $timeout -le 0 ]; then
    print_error "Redis failed to start within 30 seconds"
    print_status "Checking Redis logs:"
    $COMPOSE_CMD logs redis
    exit 1
fi

print_success "Docker services are ready!"

# Set environment variables for local development
print_status "Setting up local environment variables..."

# Database configuration (connect to localhost since services are exposed)
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=wondernest_prod
export DB_USERNAME=wondernest_app
export DB_PASSWORD=wondernest_secure_password_dev
export DB_URL="jdbc:postgresql://localhost:5432/wondernest_prod"
export DB_MAX_POOL_SIZE=20
export DB_MIN_IDLE=5

# Redis configuration
export REDIS_HOST=localhost
export REDIS_PORT=6379
export REDIS_PASSWORD=wondernest_redis_password_dev
export REDIS_DATABASE=0

# JWT configuration
export JWT_SECRET=development-jwt-secret-change-in-production

# Application configuration
export KTOR_ENV=development

# AWS/LocalStack (if needed)
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

print_success "Environment variables set for local development"

echo
echo "🎉 Docker services are running and configured!"
echo
echo "Services:"
echo "  📊 PostgreSQL: localhost:5432"
echo "  🗄️  Redis: localhost:6379"
echo
echo "Environment variables set for KTOR to connect to localhost"
echo

# Start the KTOR application
print_status "Starting KTOR application..."
echo "Running: ./gradlew run"
echo

# Run the application with proper environment
./gradlew run

# Cleanup function
cleanup() {
    print_status "Shutting down..."
    print_status "Docker services will continue running. Use '$COMPOSE_CMD down' to stop them."
}

trap cleanup EXIT