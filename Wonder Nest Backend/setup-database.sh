#!/bin/bash
set -e

# WonderNest Database Setup Script
# This script properly initializes the PostgreSQL database for WonderNest
# It handles container cleanup, database initialization, and verification

echo "🚀 Starting WonderNest database setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
POSTGRES_CONTAINER="wondernest_postgres"
POSTGRES_IMAGE="postgres:15.5-alpine"
POSTGRES_PORT="5432"
DB_NAME="wondernest_prod"
APP_USER="wondernest_app"
APP_PASSWORD="wondernest_secure_password_dev"
ANALYTICS_USER="wondernest_analytics"
ANALYTICS_PASSWORD="wondernest_analytics_password_dev"

# Function to check if local PostgreSQL is running
check_local_postgres() {
    echo -e "${BLUE}🔍 Checking for local PostgreSQL conflicts...${NC}"
    
    if brew services list | grep "postgresql.*started" > /dev/null; then
        echo -e "${YELLOW}⚠️  Local PostgreSQL service detected and running!${NC}"
        echo "This will conflict with Docker PostgreSQL on port 5432."
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
    
    # Stop and remove wondernest_postgres container if it exists
    if docker ps -a | grep -q $POSTGRES_CONTAINER; then
        echo "Stopping and removing existing $POSTGRES_CONTAINER container..."
        docker stop $POSTGRES_CONTAINER 2>/dev/null || true
        docker rm $POSTGRES_CONTAINER 2>/dev/null || true
        echo -e "${GREEN}✅ Container cleanup completed${NC}"
    else
        echo -e "${GREEN}✅ No existing containers to clean up${NC}"
    fi
}

# Function to clean up volumes if requested
cleanup_volumes() {
    read -p "Remove existing PostgreSQL data volumes? This will delete all data! (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Removing PostgreSQL data volumes...${NC}"
        docker volume rm wondernest_postgres_data 2>/dev/null || true
        rm -rf "./docker/volumes/postgres" 2>/dev/null || true
        echo -e "${GREEN}✅ Volumes cleaned up${NC}"
    else
        echo -e "${BLUE}ℹ️  Keeping existing volumes${NC}"
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

# Function to start PostgreSQL container
start_postgres() {
    echo -e "${BLUE}🐘 Starting PostgreSQL container...${NC}"
    
    docker run -d \
        --name $POSTGRES_CONTAINER \
        -p $POSTGRES_PORT:5432 \
        -e POSTGRES_DB=$DB_NAME \
        -e POSTGRES_USER=postgres \
        -e POSTGRES_PASSWORD=wondernest_postgres_superuser_password \
        -e WONDERNEST_DB_NAME=$DB_NAME \
        -e WONDERNEST_APP_USER=$APP_USER \
        -e WONDERNEST_APP_PASSWORD=$APP_PASSWORD \
        -e WONDERNEST_ANALYTICS_USER=$ANALYTICS_USER \
        -e WONDERNEST_ANALYTICS_PASSWORD=$ANALYTICS_PASSWORD \
        -v "$(pwd)/scripts/01-init-wondernest-complete.sh:/docker-entrypoint-initdb.d/01-init-wondernest-complete.sh:ro" \
        -v "$(pwd)/docker/volumes/postgres:/var/lib/postgresql/data" \
        $POSTGRES_IMAGE
    
    echo -e "${GREEN}✅ PostgreSQL container started${NC}"
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
    echo -e "${BLUE}🔍 Verifying database initialization...${NC}"
    
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
    if PGPASSWORD=$APP_PASSWORD psql -h localhost -p $POSTGRES_PORT -U $APP_USER -d $DB_NAME -c "SELECT 1" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ External connection from host works${NC}"
    else
        echo -e "${RED}❌ External connection from host failed${NC}"
        return 1
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
    if ! verify_initialization; then
        echo -e "${RED}❌ Setup failed: Database initialization failed${NC}"
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