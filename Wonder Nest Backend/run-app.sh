#!/bin/bash
set -e

# WonderNest Application Run Script
# This script properly sets up environment variables and runs the KTOR application

echo "🚀 Starting WonderNest application..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Database configuration
export DB_HOST=${DB_HOST:-localhost}
export DB_PORT=${DB_PORT:-5432}
export DB_NAME=${DB_NAME:-wondernest_prod}
export DB_USERNAME=${DB_USERNAME:-wondernest_app}
export DB_PASSWORD=${DB_PASSWORD:-wondernest_secure_password_dev}
export DB_URL=${DB_URL:-"jdbc:postgresql://$DB_HOST:$DB_PORT/$DB_NAME"}
export DB_MAX_POOL_SIZE=${DB_MAX_POOL_SIZE:-20}
export DB_MIN_IDLE=${DB_MIN_IDLE:-5}

# Redis configuration
export REDIS_HOST=${REDIS_HOST:-localhost}
export REDIS_PORT=${REDIS_PORT:-6379}
export REDIS_PASSWORD=${REDIS_PASSWORD:-wondernest_redis_password_dev}

# JWT configuration
export JWT_SECRET=${JWT_SECRET:-development-jwt-secret-change-in-production}

# Application configuration
export KTOR_ENV=${KTOR_ENV:-development}

# Function to check if PostgreSQL is available
check_postgres() {
    echo -e "${BLUE}🔍 Checking PostgreSQL connection...${NC}"
    
    if command -v psql >/dev/null 2>&1; then
        if PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USERNAME -d $DB_NAME -c "SELECT 1" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ PostgreSQL connection successful${NC}"
            return 0
        else
            echo -e "${RED}❌ Cannot connect to PostgreSQL${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  psql not available, skipping connection test${NC}"
        return 0
    fi
}

# Function to check if local PostgreSQL is conflicting
check_postgres_conflict() {
    if brew services list 2>/dev/null | grep "postgresql.*started" >/dev/null; then
        echo -e "${YELLOW}⚠️  Warning: Local PostgreSQL service is running!${NC}"
        echo "This might conflict with Docker PostgreSQL on port 5432."
        echo "If you experience connection issues, run: brew services stop postgresql@14"
        echo ""
    fi
}

# Function to show environment configuration
show_config() {
    echo -e "${BLUE}📋 Application Configuration:${NC}"
    echo "  Environment: $KTOR_ENV"
    echo "  Database Host: $DB_HOST:$DB_PORT"
    echo "  Database Name: $DB_NAME"
    echo "  Database User: $DB_USERNAME"
    echo "  Redis Host: $REDIS_HOST:$REDIS_PORT"
    echo "  JWT Secret: ${JWT_SECRET:0:20}..." # Only show first 20 chars
    echo ""
}

# Function to check if Docker services are running
check_docker_services() {
    echo -e "${BLUE}🐳 Checking Docker services...${NC}"
    
    # Check PostgreSQL
    if docker ps | grep -q wondernest_postgres; then
        echo -e "${GREEN}✅ PostgreSQL container is running${NC}"
    else
        echo -e "${YELLOW}⚠️  PostgreSQL container is not running${NC}"
        echo "Run: ./setup-database.sh to set up the database"
        return 1
    fi
    
    # Check Redis (optional)
    if docker ps | grep -q wondernest_redis; then
        echo -e "${GREEN}✅ Redis container is running${NC}"
    else
        echo -e "${YELLOW}⚠️  Redis container is not running${NC}"
        echo "Redis is optional for basic functionality"
    fi
    
    return 0
}

# Function to run the application
run_application() {
    echo -e "${BLUE}🎯 Starting KTOR application...${NC}"
    echo ""
    
    # Run with environment variables already exported
    ./gradlew run
}

# Function to handle cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}Application stopped${NC}"
}

# Main function
main() {
    echo -e "${BLUE}WonderNest Application Runner${NC}"
    echo "============================="
    
    # Check for PostgreSQL conflicts
    check_postgres_conflict
    
    # Show configuration
    show_config
    
    # Check Docker services
    if ! check_docker_services; then
        echo -e "${RED}❌ Required services not running${NC}"
        echo "Run ./setup-database.sh first to set up the database"
        exit 1
    fi
    
    # Check PostgreSQL connection
    if ! check_postgres; then
        echo -e "${RED}❌ Cannot connect to database${NC}"
        echo "Ensure PostgreSQL is running and accessible"
        exit 1
    fi
    
    # Set up cleanup handler
    trap cleanup EXIT INT TERM
    
    # Run the application
    run_application
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            echo "WonderNest Application Runner"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --help, -h     Show this help message"
            echo "  --check-only   Only check dependencies, don't run"
            echo ""
            echo "Environment Variables:"
            echo "  DB_HOST        Database host (default: localhost)"
            echo "  DB_PORT        Database port (default: 5432)"
            echo "  DB_NAME        Database name (default: wondernest_prod)"
            echo "  DB_USERNAME    Database username (default: wondernest_app)"
            echo "  DB_PASSWORD    Database password (default: wondernest_secure_password_dev)"
            echo "  REDIS_HOST     Redis host (default: localhost)"
            echo "  REDIS_PORT     Redis port (default: 6379)"
            echo "  JWT_SECRET     JWT secret key"
            echo "  KTOR_ENV       KTOR environment (default: development)"
            exit 0
            ;;
        --check-only)
            # Only run checks, don't start the application
            check_postgres_conflict
            show_config
            check_docker_services
            check_postgres
            echo -e "${GREEN}✅ All checks passed${NC}"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
    shift
done

# Run main function
main "$@"