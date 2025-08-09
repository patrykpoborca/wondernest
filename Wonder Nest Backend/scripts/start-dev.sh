#!/bin/bash
# WonderNest Development Environment Start Script
# Quickly start the full development environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

# Detect docker-compose command
if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
else
    COMPOSE_CMD="docker compose"
fi

cd "$PROJECT_ROOT"

echo "🚀 Starting WonderNest Development Environment..."

# Check if setup has been run
if [ ! -d "$PROJECT_ROOT/docker/volumes/postgres" ]; then
    print_warning "Development environment not set up yet."
    print_status "Running initial setup..."
    "$SCRIPT_DIR/setup.sh"
    exit 0
fi

# Start all services
print_status "Starting all services..."
$COMPOSE_CMD up -d postgres redis pgadmin

# Wait for services to be healthy
print_status "Waiting for services to be ready..."

# Wait for PostgreSQL
timeout=60
while [ $timeout -gt 0 ]; do
    if $COMPOSE_CMD exec postgres pg_isready -U postgres -d wondernest_prod >/dev/null 2>&1; then
        break
    fi
    sleep 2
    timeout=$((timeout-2))
done

if [ $timeout -le 0 ]; then
    echo "❌ PostgreSQL failed to start"
    exit 1
fi

# Wait for Redis
timeout=30
while [ $timeout -gt 0 ]; do
    if $COMPOSE_CMD exec redis redis-cli --no-auth-warning -a wondernest_redis_password_dev ping >/dev/null 2>&1; then
        break
    fi
    sleep 1
    timeout=$((timeout-1))
done

if [ $timeout -le 0 ]; then
    echo "❌ Redis failed to start"
    exit 1
fi

print_success "All services are ready!"

echo
echo "🎉 WonderNest Development Environment is running!"
echo
echo "Services:"
echo "  📊 PostgreSQL: localhost:5432"
echo "  🗄️  Redis: localhost:6379" 
echo "  🖥️  pgAdmin: http://localhost:5050"
echo
echo "To start the API server:"
echo "  $COMPOSE_CMD up -d api"
echo
echo "To view logs:"
echo "  $COMPOSE_CMD logs -f [service_name]"
echo
echo "To stop all services:"
echo "  $COMPOSE_CMD down"
echo