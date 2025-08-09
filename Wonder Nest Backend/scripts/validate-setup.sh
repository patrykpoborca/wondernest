#!/bin/bash
# WonderNest Database Setup Validation Script
# Validates the setup without actually starting services

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ️${NC} $1"
}

echo "🔍 WonderNest Database Setup Validation"
echo "======================================"
echo

# Check Docker
print_info "Checking Docker..."
if docker --version >/dev/null 2>&1; then
    DOCKER_VERSION=$(docker --version)
    print_success "Docker available: $DOCKER_VERSION"
else
    print_error "Docker is not installed or not available"
    exit 1
fi

# Check Docker Compose
print_info "Checking Docker Compose..."
if docker compose version >/dev/null 2>&1; then
    COMPOSE_VERSION=$(docker compose version)
    print_success "Docker Compose available: $COMPOSE_VERSION"
    COMPOSE_CMD="docker compose"
elif docker-compose --version >/dev/null 2>&1; then
    COMPOSE_VERSION=$(docker-compose --version)
    print_success "Docker Compose available: $COMPOSE_VERSION"
    COMPOSE_CMD="docker-compose"
else
    print_error "Docker Compose is not installed or not available"
    exit 1
fi

# Validate docker-compose.yml
print_info "Validating docker-compose.yml..."
cd "$PROJECT_ROOT"
if $COMPOSE_CMD config >/dev/null 2>&1; then
    print_success "docker-compose.yml is valid"
else
    print_error "docker-compose.yml has configuration errors"
    $COMPOSE_CMD config
    exit 1
fi

# Check required directories
print_info "Checking directory structure..."
REQUIRED_DIRS=(
    "docker/postgres"
    "docker/redis" 
    "docker/pgadmin"
    "docker/volumes"
    "scripts"
    "src/main/resources/db/migration"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$PROJECT_ROOT/$dir" ]; then
        print_success "Directory exists: $dir"
    else
        print_error "Missing directory: $dir"
        exit 1
    fi
done

# Check required files
print_info "Checking configuration files..."
REQUIRED_FILES=(
    "docker/postgres/postgresql.conf"
    "docker/postgres/pg_hba.conf"
    "docker/redis/redis.conf"
    "docker/pgadmin/servers.json"
    "scripts/init-database.sh"
    "scripts/setup.sh"
    "scripts/start-dev.sh"
    "scripts/reset-db.sh"
    "scripts/backup.sh"
    "scripts/restore.sh"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$PROJECT_ROOT/$file" ]; then
        print_success "File exists: $file"
    else
        print_error "Missing file: $file"
        exit 1
    fi
done

# Check script permissions
print_info "Checking script permissions..."
SCRIPTS=(
    "scripts/init-database.sh"
    "scripts/setup.sh"
    "scripts/start-dev.sh"
    "scripts/reset-db.sh"
    "scripts/backup.sh"
    "scripts/restore.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [ -x "$PROJECT_ROOT/$script" ]; then
        print_success "Executable: $script"
    else
        print_warning "Not executable: $script"
        chmod +x "$PROJECT_ROOT/$script"
        print_success "Fixed permissions: $script"
    fi
done

# Check database files accessibility
print_info "Checking database files..."
if [ -d "$PROJECT_ROOT/../database" ]; then
    if [ -f "$PROJECT_ROOT/../database/01_create_database.sql" ]; then
        print_success "Database initialization files found"
    else
        print_error "Database SQL files not found in ../database/"
        exit 1
    fi
else
    print_error "Database directory not found at ../database/"
    exit 1
fi

# Check Docker daemon
print_info "Checking Docker daemon..."
if docker info >/dev/null 2>&1; then
    print_success "Docker daemon is running"
else
    print_error "Docker daemon is not running - please start Docker"
    exit 1
fi

# Test Docker Compose syntax
print_info "Testing Docker Compose configuration..."
if $COMPOSE_CMD -f docker-compose.yml config --quiet; then
    print_success "Docker Compose configuration is valid"
else
    print_error "Docker Compose configuration has issues"
    exit 1
fi

# Summary
echo
echo "🎉 Setup Validation Complete!"
echo "==============================="
echo
print_success "All checks passed!"
echo
echo "📋 Next steps:"
echo "  1. Run initial setup: ./scripts/setup.sh"
echo "  2. Start development: ./scripts/start-dev.sh"
echo "  3. Access pgAdmin: http://localhost:5050"
echo "  4. Check health: http://localhost:8080/health/detailed"
echo
echo "🗂️  Data will be stored in:"
echo "  - PostgreSQL: $PROJECT_ROOT/docker/volumes/postgres/"
echo "  - Redis: $PROJECT_ROOT/docker/volumes/redis/"
echo "  - pgAdmin: $PROJECT_ROOT/docker/volumes/pgadmin/"
echo
echo "💾 Backups will be stored in:"
echo "  - Backups: $PROJECT_ROOT/backups/"
echo