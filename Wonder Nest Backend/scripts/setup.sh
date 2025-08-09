#!/bin/bash
# WonderNest Development Environment Setup Script
# This script sets up the complete development environment including database, cache, and services

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_success "Docker is running"
}

# Check if docker-compose is available
check_docker_compose() {
    if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
        print_error "docker-compose is not installed or not in PATH"
        exit 1
    fi
    
    if command -v docker-compose >/dev/null 2>&1; then
        COMPOSE_CMD="docker-compose"
    else
        COMPOSE_CMD="docker compose"
    fi
    print_success "Docker Compose is available: $COMPOSE_CMD"
}

# Create necessary directories
create_directories() {
    print_status "Creating necessary directories..."
    
    # Create volume directories
    mkdir -p "$PROJECT_ROOT/docker/volumes/postgres"
    mkdir -p "$PROJECT_ROOT/docker/volumes/redis"
    mkdir -p "$PROJECT_ROOT/docker/volumes/pgadmin"
    
    # Set proper permissions
    if [[ "$OSTYPE" != "msys" && "$OSTYPE" != "win32" ]]; then
        # Unix/Linux/macOS permissions
        chmod 755 "$PROJECT_ROOT/docker/volumes/postgres"
        chmod 755 "$PROJECT_ROOT/docker/volumes/redis"
        chmod 755 "$PROJECT_ROOT/docker/volumes/pgadmin"
    fi
    
    print_success "Directories created"
}

# Check if services are already running
check_existing_services() {
    if $COMPOSE_CMD -f "$PROJECT_ROOT/docker-compose.yml" ps --quiet postgres redis > /dev/null 2>&1; then
        RUNNING_SERVICES=$($COMPOSE_CMD -f "$PROJECT_ROOT/docker-compose.yml" ps --services --filter status=running)
        if [ ! -z "$RUNNING_SERVICES" ]; then
            print_warning "Some services are already running:"
            echo "$RUNNING_SERVICES"
            read -p "Do you want to stop existing services and recreate them? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                print_status "Stopping existing services..."
                $COMPOSE_CMD -f "$PROJECT_ROOT/docker-compose.yml" down
            else
                print_status "Keeping existing services running"
                return 0
            fi
        fi
    fi
}

# Start the database and related services
start_services() {
    print_status "Starting WonderNest services..."
    
    cd "$PROJECT_ROOT"
    
    # Start PostgreSQL first and wait for it to be healthy
    print_status "Starting PostgreSQL..."
    $COMPOSE_CMD up -d postgres
    
    # Wait for PostgreSQL to be healthy
    print_status "Waiting for PostgreSQL to be ready..."
    timeout=60
    while [ $timeout -gt 0 ]; do
        if $COMPOSE_CMD exec postgres pg_isready -U postgres -d wondernest_prod >/dev/null 2>&1; then
            print_success "PostgreSQL is ready!"
            break
        fi
        sleep 2
        timeout=$((timeout-2))
    done
    
    if [ $timeout -le 0 ]; then
        print_error "PostgreSQL failed to start within 60 seconds"
        $COMPOSE_CMD logs postgres
        exit 1
    fi
    
    # Start Redis
    print_status "Starting Redis..."
    $COMPOSE_CMD up -d redis
    
    # Wait for Redis to be healthy
    print_status "Waiting for Redis to be ready..."
    timeout=30
    while [ $timeout -gt 0 ]; do
        if $COMPOSE_CMD exec redis redis-cli --no-auth-warning -a wondernest_redis_password_dev ping >/dev/null 2>&1; then
            print_success "Redis is ready!"
            break
        fi
        sleep 1
        timeout=$((timeout-1))
    done
    
    if [ $timeout -le 0 ]; then
        print_error "Redis failed to start within 30 seconds"
        $COMPOSE_CMD logs redis
        exit 1
    fi
    
    # Start pgAdmin
    print_status "Starting pgAdmin..."
    $COMPOSE_CMD up -d pgadmin
    
    print_success "All core services are running!"
}

# Verify the database setup
verify_setup() {
    print_status "Verifying database setup..."
    
    # Check if schemas exist
    SCHEMAS_COUNT=$($COMPOSE_CMD exec postgres psql -U postgres -d wondernest_prod -t -c "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name IN ('core', 'family', 'content', 'audio', 'analytics');" | tr -d ' ')
    
    if [ "$SCHEMAS_COUNT" -eq "5" ]; then
        print_success "Database schemas are properly initialized"
    else
        print_error "Database schemas are not properly initialized (found $SCHEMAS_COUNT/5 schemas)"
        return 1
    fi
    
    # Check if application user exists and can connect
    if $COMPOSE_CMD exec postgres psql -U wondernest_app -d wondernest_prod -c "SELECT 1;" >/dev/null 2>&1; then
        print_success "Application user can connect to database"
    else
        print_error "Application user cannot connect to database"
        return 1
    fi
    
    # Verify Redis is working
    if $COMPOSE_CMD exec redis redis-cli --no-auth-warning -a wondernest_redis_password_dev ping >/dev/null 2>&1; then
        print_success "Redis is working correctly"
    else
        print_error "Redis is not working correctly"
        return 1
    fi
    
    return 0
}

# Print connection information
print_connection_info() {
    echo
    echo "🎉 WonderNest Development Environment Setup Complete!"
    echo
    echo "📋 Service Information:"
    echo "  📊 PostgreSQL: localhost:5432"
    echo "      Database: wondernest_prod"
    echo "      Username: wondernest_app"
    echo "      Password: wondernest_secure_password_dev"
    echo
    echo "  🗄️  Redis: localhost:6379"
    echo "      Password: wondernest_redis_password_dev"
    echo
    echo "  🖥️  pgAdmin: http://localhost:5050"
    echo "      Email: admin@wondernest.dev"
    echo "      Password: wondernest_pgadmin_password"
    echo
    echo "🔗 Connection URLs:"
    echo "  PostgreSQL: postgresql://wondernest_app:wondernest_secure_password_dev@localhost:5432/wondernest_prod"
    echo "  Redis: redis://:wondernest_redis_password_dev@localhost:6379/0"
    echo
    echo "📁 Volume locations:"
    echo "  PostgreSQL data: $PROJECT_ROOT/docker/volumes/postgres"
    echo "  Redis data: $PROJECT_ROOT/docker/volumes/redis"
    echo "  pgAdmin data: $PROJECT_ROOT/docker/volumes/pgadmin"
    echo
    echo "🛠️  Useful commands:"
    echo "  Start all services: ./scripts/start-dev.sh"
    echo "  Stop all services: docker-compose down"
    echo "  Reset database: ./scripts/reset-db.sh"
    echo "  Backup database: ./scripts/backup.sh"
    echo "  View logs: docker-compose logs -f [service_name]"
}

# Main execution
main() {
    echo "🚀 Setting up WonderNest Development Environment..."
    
    check_docker
    check_docker_compose
    create_directories
    check_existing_services
    start_services
    
    # Give services a moment to fully initialize
    print_status "Allowing services to fully initialize..."
    sleep 5
    
    if verify_setup; then
        print_connection_info
    else
        print_error "Setup verification failed. Check the logs for details."
        echo
        echo "To view service logs:"
        echo "  docker-compose logs postgres"
        echo "  docker-compose logs redis"
        echo "  docker-compose logs pgadmin"
        exit 1
    fi
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "WonderNest Development Environment Setup"
        echo
        echo "Usage: $0 [OPTIONS]"
        echo
        echo "Options:"
        echo "  --help, -h    Show this help message"
        echo "  --reset       Reset the environment (stop services and remove volumes)"
        echo
        echo "This script will:"
        echo "  1. Check Docker and Docker Compose availability"
        echo "  2. Create necessary directories and set permissions"
        echo "  3. Start PostgreSQL, Redis, and pgAdmin services"
        echo "  4. Initialize the database with WonderNest schema and data"
        echo "  5. Verify the setup and display connection information"
        ;;
    --reset)
        print_warning "This will stop all services and remove all data volumes!"
        read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cd "$PROJECT_ROOT"
            $COMPOSE_CMD down -v
            sudo rm -rf "$PROJECT_ROOT/docker/volumes/"*
            print_success "Environment reset complete. Run './scripts/setup.sh' to reinitialize."
        else
            print_status "Reset cancelled"
        fi
        ;;
    *)
        main
        ;;
esac