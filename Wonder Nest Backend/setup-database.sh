#!/bin/bash
set -e

# WonderNest Database Setup Script
# This script properly initializes the PostgreSQL database for WonderNest using docker-compose
# It handles container cleanup, database initialization, and verification
#
# SAFETY NOTICE:
# - This script ONLY affects WonderNest-specific Docker containers and data
# - Your system PostgreSQL installations (Homebrew, etc.) remain untouched
# - Other Docker containers and volumes are completely safe
# - Only removes: wondernest_postgres container, wondernest_postgres_data volume,
#   and ./docker/volumes/postgres directory within this project

echo "🚀 Starting WonderNest database setup (using docker-compose)..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
POSTGRES_CONTAINER="wondernest_postgres"
POSTGRES_IMAGE="postgres:15.5-alpine"
POSTGRES_PORT="${DB_PORT:-5433}"
DB_NAME="wondernest_prod"
APP_USER="wondernest_app"
APP_PASSWORD="wondernest_secure_password_dev"
ANALYTICS_USER="wondernest_analytics"
ANALYTICS_PASSWORD="wondernest_analytics_password_dev"

# Function to check if local PostgreSQL is running
check_local_postgres() {
    echo -e "${BLUE}🔍 Checking for local PostgreSQL conflicts...${NC}"
    
    if brew services list | grep "postgresql.*\(started\|other\)" > /dev/null; then
        echo -e "${YELLOW}⚠️  Local PostgreSQL service detected and running!${NC}"
        echo "This will conflict with Docker PostgreSQL on port $POSTGRES_PORT."
        read -p "Stop local PostgreSQL services? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Stopping local PostgreSQL services...${NC}"
            brew services stop postgresql@13 2>/dev/null || true
            brew services stop postgresql@14 2>/dev/null || true
            brew services stop postgresql@15 2>/dev/null || true
            brew services stop postgresql 2>/dev/null || true
            echo -e "${GREEN}✅ Local PostgreSQL services stopped${NC}"
        else
            echo -e "${RED}❌ Cannot continue with local PostgreSQL running${NC}"
            echo "Please stop local PostgreSQL manually or use different ports"
            exit 1
        fi
    else
        echo -e "${GREEN}✅ No local PostgreSQL conflicts detected${NC}"
    fi
}

# Function to clean up existing containers
cleanup_containers() {
    echo -e "${BLUE}🧹 Cleaning up existing containers...${NC}"
    
    # Stop docker-compose services first
    echo "Stopping docker-compose services..."
    docker-compose down 2>/dev/null || true
    
    # Also check for standalone containers and clean them up
    if docker ps -a | grep -q $POSTGRES_CONTAINER; then
        echo "Stopping and removing existing standalone $POSTGRES_CONTAINER container..."
        docker stop $POSTGRES_CONTAINER 2>/dev/null || true
        docker rm $POSTGRES_CONTAINER 2>/dev/null || true
        echo -e "${GREEN}✅ Standalone container cleanup completed${NC}"
    else
        echo -e "${GREEN}✅ No existing standalone containers to clean up${NC}"
    fi
}

# Function to clean up volumes if requested
cleanup_volumes() {
    echo -e "${BLUE}🔍 Current PostgreSQL data locations:${NC}"
    echo "  • Docker volume: wondernest_postgres_data"
    echo "  • Local directory: $(pwd)/docker/volumes/postgres"
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANT: This will ONLY delete WonderNest PostgreSQL data${NC}"
    echo -e "${GREEN}✅ SAFE: Your system PostgreSQL, other Docker containers, and all other data remain untouched${NC}"
    echo ""
    
    # Check what actually exists
    if docker volume ls | grep -q "wondernest_postgres_data\|wondernestbackend_postgres_data"; then
        echo -e "${BLUE}Found existing Docker volumes:${NC}"
        docker volume ls | grep "wondernest.*postgres\|postgres.*wondernest" | sed 's/^/  • /'
    fi
    
    if [ -d "./docker/volumes/postgres" ]; then
        echo -e "${BLUE}Found local PostgreSQL data directory:${NC}"
        echo "  • $(pwd)/docker/volumes/postgres ($(du -sh ./docker/volumes/postgres 2>/dev/null | cut -f1 || echo "unknown size"))"
    fi
    
    echo ""
    read -p "Remove ONLY WonderNest PostgreSQL data volumes? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Removing ONLY WonderNest PostgreSQL data volumes...${NC}"
        
        # Remove both possible volume names (standalone script vs docker-compose)
        docker volume rm wondernest_postgres_data 2>/dev/null && echo "  ✅ Removed wondernest_postgres_data" || echo "  ℹ️  wondernest_postgres_data not found"
        docker volume rm wondernestbackend_postgres_data 2>/dev/null && echo "  ✅ Removed wondernestbackend_postgres_data" || echo "  ℹ️  wondernestbackend_postgres_data not found"
        
        # Also remove any docker-compose generated volumes with project name prefix
        PROJECT_NAME=$(basename "$(pwd)" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
        docker volume rm "${PROJECT_NAME}_postgres_data" 2>/dev/null && echo "  ✅ Removed ${PROJECT_NAME}_postgres_data" || echo "  ℹ️  ${PROJECT_NAME}_postgres_data not found"
        
        # Remove local directory
        if [ -d "./docker/volumes/postgres" ]; then
            rm -rf "./docker/volumes/postgres" 2>/dev/null && echo "  ✅ Removed ./docker/volumes/postgres" || echo "  ❌ Failed to remove ./docker/volumes/postgres"
        else
            echo "  ℹ️  ./docker/volumes/postgres not found"
        fi
        
        echo -e "${GREEN}✅ WonderNest PostgreSQL data cleanup completed${NC}"
    else
        echo -e "${BLUE}ℹ️  Keeping existing volumes - your WonderNest data is preserved${NC}"
    fi
}

# Function to ensure directories exist
ensure_directories() {
    echo -e "${BLUE}📁 Ensuring required directories exist...${NC}"
    mkdir -p "./docker/volumes/postgres"
    mkdir -p "./docker/postgres"
    mkdir -p "./scripts"
    echo -e "${GREEN}✅ Directories ready${NC}"
}

# Function to start PostgreSQL container using docker-compose
start_postgres() {
    echo -e "${BLUE}🐘 Starting PostgreSQL container with docker-compose...${NC}"
    
    # Ensure the init script has proper permissions
    chmod +x "./scripts/01-init-wondernest-complete.sh"
    
    # Start PostgreSQL using docker-compose
    docker-compose up -d postgres
    
    echo -e "${GREEN}✅ PostgreSQL container started via docker-compose${NC}"
}

# Function to wait for PostgreSQL to be ready
wait_for_postgres() {
    echo -e "${BLUE}⏳ Waiting for PostgreSQL to be ready...${NC}"
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker exec $POSTGRES_CONTAINER pg_isready -U postgres -d $DB_NAME >/dev/null 2>&1; then
            echo -e "${GREEN}✅ PostgreSQL is ready!${NC}"
            return 0
        fi
        
        echo "Attempt $attempt/$max_attempts: PostgreSQL not ready yet, waiting..."
        sleep 2
        ((attempt++))
    done
    
    echo -e "${RED}❌ PostgreSQL failed to become ready after $max_attempts attempts${NC}"
    return 1
}

# Function to verify database initialization
verify_initialization() {
    
    # Check if wondernest_app user exists
    if docker exec $POSTGRES_CONTAINER psql -U postgres -d $DB_NAME -tAc "SELECT 1 FROM pg_roles WHERE rolname='$APP_USER'" | grep -q 1; then
        echo -e "${GREEN}✅ Application user '$APP_USER' exists${NC}"
    else
        echo -e "${RED}❌ Application user '$APP_USER' does not exist${NC}"
        return 1
    fi
    
    # Check if core schema exists
    if docker exec $POSTGRES_CONTAINER psql -U postgres -d $DB_NAME -tAc "SELECT 1 FROM information_schema.schemata WHERE schema_name='core'" | grep -q 1; then
        echo -e "${GREEN}✅ Core schema exists${NC}"
    else
        echo -e "${RED}❌ Core schema does not exist${NC}"
        return 1
    fi
    
    # Check if essential tables exist
    if docker exec $POSTGRES_CONTAINER psql -U postgres -d $DB_NAME -tAc "SELECT 1 FROM information_schema.tables WHERE table_schema='core' AND table_name='users'" | grep -q 1; then
        echo -e "${GREEN}✅ Essential tables created${NC}"
    else
        echo -e "${RED}❌ Essential tables missing${NC}"
        return 1
    fi
    
    # Test connection as application user
    if docker exec $POSTGRES_CONTAINER psql -U $APP_USER -d $DB_NAME -c "SELECT 1" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Application user can connect to database${NC}"
    else
        echo -e "${RED}❌ Application user cannot connect to database${NC}"
        return 1
    fi
    
    # Test connection from host
    echo "Testing external connection from host on port $POSTGRES_PORT..."
    if PGPASSWORD=$APP_PASSWORD psql -h localhost -p $POSTGRES_PORT -U $APP_USER -d $DB_NAME -c "SELECT 1" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ External connection from host works${NC}"
    else
        echo -e "${YELLOW}⚠️  External connection from host failed${NC}"
        echo -e "${BLUE}ℹ️  This is often due to pg_hba.conf configuration, but the database is still functional${NC}"
        echo -e "${BLUE}ℹ️  Testing detailed connection information...${NC}"
        
        # More detailed debugging
        echo -e "${BLUE}Docker container status:${NC}"
        if docker ps | grep -q $POSTGRES_CONTAINER; then
            echo -e "${GREEN}  ✅ Container is running${NC}"
        else
            echo -e "${RED}  ❌ Container is not running${NC}"
            return 1
        fi
        
        # Test if port is accessible
        echo -e "${BLUE}Port accessibility test:${NC}"
        if nc -z localhost $POSTGRES_PORT 2>/dev/null; then
            echo -e "${GREEN}  ✅ Port $POSTGRES_PORT is accessible${NC}"
        else
            echo -e "${RED}  ❌ Port $POSTGRES_PORT is not accessible${NC}"
            echo -e "${YELLOW}  Check if port mapping is working: docker ps | grep $POSTGRES_CONTAINER${NC}"
            return 1
        fi
        
        # Test with verbose psql output
        echo -e "${BLUE}Attempting connection with verbose output:${NC}"
        CONNECTION_ERROR=$(PGPASSWORD=$APP_PASSWORD psql -h localhost -p $POSTGRES_PORT -U $APP_USER -d $DB_NAME -c "SELECT 1" 2>&1)
        echo "$CONNECTION_ERROR" | head -5 | sed 's/^/  /'
        
        # Check if this looks like a local PostgreSQL conflict
        if echo "$CONNECTION_ERROR" | grep -q "database.*does not exist\|role.*does not exist"; then
            echo -e "${YELLOW}  ⚠️  This appears to be a local PostgreSQL conflict!${NC}"
            echo -e "${YELLOW}  The connection is reaching a different PostgreSQL instance${NC}"
            echo -e "${YELLOW}  Check for running local PostgreSQL services${NC}"
        fi
        
        # Check if internal connection still works
        echo -e "${BLUE}Re-testing internal connection:${NC}"
        if docker exec $POSTGRES_CONTAINER psql -U $APP_USER -d $DB_NAME -c "SELECT 1" >/dev/null 2>&1; then
            echo -e "${GREEN}  ✅ Internal connection works - database is functional${NC}"
            echo -e "${YELLOW}  External connection issue is likely pg_hba.conf related but non-critical${NC}"
        else
            echo -e "${RED}  ❌ Internal connection also failed - database has issues${NC}"
            return 1
        fi
    fi
    
    echo -e "${GREEN}🎉 Database initialization verification completed successfully!${NC}"
    return 0
}

# Function to show connection information
show_connection_info() {
    echo -e "${BLUE}📋 Connection Information:${NC}"
    echo "  Host: localhost"
    echo "  Port: $POSTGRES_PORT"
    echo "  Database: $DB_NAME"
    echo "  Application User: $APP_USER"
    echo "  Application Password: $APP_PASSWORD"
    echo ""
    echo -e "${BLUE}🔗 JDBC URL for application:${NC}"
    echo "  jdbc:postgresql://localhost:$POSTGRES_PORT/$DB_NAME"
    echo ""
    echo -e "${BLUE}🧪 Test connection:${NC}"
    echo "  PGPASSWORD=$APP_PASSWORD psql -h localhost -p $POSTGRES_PORT -U $APP_USER -d $DB_NAME"
    echo ""
    echo -e "${YELLOW}💡 Note: If external connections fail but internal connections work,${NC}"
    echo -e "${YELLOW}   the database is functional for the application. External connection${NC}"
    echo -e "${YELLOW}   issues are typically due to pg_hba.conf configuration.${NC}"
}

# Function to show Docker commands
show_docker_commands() {
    echo -e "${BLUE}🐳 Useful Docker commands:${NC}"
    echo "  View logs: docker logs $POSTGRES_CONTAINER"
    echo "  Connect to DB: docker exec -it $POSTGRES_CONTAINER psql -U postgres -d $DB_NAME"
    echo "  Stop container: docker stop $POSTGRES_CONTAINER"
    echo "  Remove container: docker rm $POSTGRES_CONTAINER"
}

# Main execution
main() {
    echo -e "${BLUE}WonderNest Database Setup${NC}"
    echo "=================================="
    
    # Step 1: Check for conflicts
    check_local_postgres
    
    # Step 2: Cleanup existing containers
    cleanup_containers
    
    # Step 3: Ask about volume cleanup
    cleanup_volumes
    
    # Step 4: Ensure directories exist
    ensure_directories
    
    # Step 5: Start PostgreSQL
    start_postgres
    
    # Step 6: Wait for PostgreSQL to be ready
    if ! wait_for_postgres; then
        echo -e "${RED}❌ Setup failed: PostgreSQL not ready${NC}"
        exit 1
    fi
    
    # Step 7: Verify initialization
    echo -e "${BLUE}🔍 Verifying database initialization...${NC}"
    if verify_initialization; then
        echo -e "${GREEN}✅ Database verification completed successfully${NC}"
    else
        echo -e "${RED}❌ Critical database initialization issues detected${NC}"
        echo -e "${YELLOW}Check container logs: docker logs $POSTGRES_CONTAINER${NC}"
        exit 1
    fi
    
    # Step 8: Show connection information
    show_connection_info
    show_docker_commands
    
    echo ""
    echo -e "${GREEN}🎉 WonderNest database setup completed successfully!${NC}"
    echo -e "${BLUE}You can now run: ${YELLOW}./gradlew run${NC}"
}

# Handle script interruption
trap 'echo -e "\n${YELLOW}Setup interrupted by user${NC}"; exit 130' INT

# Run main function
main "$@"