#!/bin/bash
# WonderNest Database Reset Script
# Completely reset the database for development

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

echo "🔄 WonderNest Database Reset"
echo
print_warning "This will:"
print_warning "  • Stop the PostgreSQL container"
print_warning "  • Remove all database data (PostgreSQL volumes)"
print_warning "  • Restart PostgreSQL with fresh initialization"
print_warning "  • All data will be permanently lost!"
echo

# Confirmation prompt
read -p "Are you sure you want to reset the database? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Database reset cancelled"
    exit 0
fi

echo
read -p "Type 'RESET' to confirm: " CONFIRM
if [[ "$CONFIRM" != "RESET" ]]; then
    print_status "Database reset cancelled"
    exit 0
fi

echo
print_status "Starting database reset..."

# Stop PostgreSQL and any services that depend on it
print_status "Stopping services..."
$COMPOSE_CMD stop api postgres pgadmin

# Remove PostgreSQL container to ensure clean state
print_status "Removing PostgreSQL container..."
$COMPOSE_CMD rm -f postgres

# Remove PostgreSQL volume data
print_status "Removing database data..."
if [ -d "$PROJECT_ROOT/docker/volumes/postgres" ]; then
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        # Windows
        rm -rf "$PROJECT_ROOT/docker/volumes/postgres/"*
    else
        # Unix/Linux/macOS - may need sudo for some files
        if sudo -n true 2>/dev/null; then
            sudo rm -rf "$PROJECT_ROOT/docker/volumes/postgres/"*
        else
            rm -rf "$PROJECT_ROOT/docker/volumes/postgres/"* 2>/dev/null || {
                print_warning "Some files require sudo to remove"
                sudo rm -rf "$PROJECT_ROOT/docker/volumes/postgres/"*
            }
        fi
    fi
fi

# Recreate the directory
mkdir -p "$PROJECT_ROOT/docker/volumes/postgres"

print_success "Database data removed"

# Start PostgreSQL with fresh initialization
print_status "Starting PostgreSQL with fresh database..."
$COMPOSE_CMD up -d postgres

# Wait for PostgreSQL to be ready
print_status "Waiting for PostgreSQL to initialize..."
timeout=120  # Longer timeout for initial setup
while [ $timeout -gt 0 ]; do
    if $COMPOSE_CMD exec postgres pg_isready -U postgres -d wondernest_prod >/dev/null 2>&1; then
        print_success "PostgreSQL is ready!"
        break
    fi
    sleep 3
    timeout=$((timeout-3))
    echo -n "."
done

echo

if [ $timeout -le 0 ]; then
    print_error "PostgreSQL failed to start within 2 minutes"
    print_status "Checking logs..."
    $COMPOSE_CMD logs postgres
    exit 1
fi

# Verify the database initialization
print_status "Verifying database initialization..."
SCHEMAS_COUNT=$($COMPOSE_CMD exec postgres psql -U postgres -d wondernest_prod -t -c "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name IN ('core', 'family', 'content', 'audio', 'analytics');" | tr -d ' ')

if [ "$SCHEMAS_COUNT" -eq "5" ]; then
    print_success "Database schemas properly initialized"
else
    print_error "Database initialization may have failed (found $SCHEMAS_COUNT/5 schemas)"
    print_status "Check the initialization logs:"
    $COMPOSE_CMD logs postgres
fi

# Test application user connection
if $COMPOSE_CMD exec postgres psql -U wondernest_app -d wondernest_prod -c "SELECT 1;" >/dev/null 2>&1; then
    print_success "Application user can connect"
else
    print_error "Application user connection failed"
fi

# Restart other services
print_status "Starting other services..."
$COMPOSE_CMD up -d redis pgadmin

echo
print_success "Database reset completed!"
echo
echo "📊 Database Information:"
echo "  Host: localhost:5432"
echo "  Database: wondernest_prod"
echo "  App User: wondernest_app"
echo "  Password: wondernest_secure_password_dev"
echo
echo "🖥️  pgAdmin: http://localhost:5050"
echo "  Email: admin@wondernest.dev"
echo "  Password: wondernest_pgadmin_password"
echo
echo "The database is now fresh and ready for development!"