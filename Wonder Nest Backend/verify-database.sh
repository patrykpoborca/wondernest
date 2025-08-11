#!/bin/bash
set -e

# WonderNest Database Verification Script
# This script verifies that the PostgreSQL database is properly set up

echo "🔍 Verifying WonderNest database setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
POSTGRES_CONTAINER="wondernest_postgres"
DB_NAME="wondernest_prod"
APP_USER="wondernest_app"
APP_PASSWORD="wondernest_secure_password_dev"
POSTGRES_PORT="${DB_PORT:-5433}"

# Function to check container status
check_container() {
    echo -e "${BLUE}📦 Checking container status...${NC}"
    
    if docker ps | grep -q $POSTGRES_CONTAINER; then
        echo -e "${GREEN}✅ Container '$POSTGRES_CONTAINER' is running${NC}"
        return 0
    elif docker ps -a | grep -q $POSTGRES_CONTAINER; then
        echo -e "${RED}❌ Container '$POSTGRES_CONTAINER' exists but is not running${NC}"
        echo "Try: docker-compose up -d postgres"
        return 1
    else
        echo -e "${RED}❌ Container '$POSTGRES_CONTAINER' does not exist${NC}"
        echo "Try: docker-compose up -d postgres"
        return 1
    fi
}

# Function to verify database exists
verify_database() {
    echo -e "${BLUE}🗄️  Verifying database exists...${NC}"
    
    if docker exec $POSTGRES_CONTAINER psql -U postgres -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
        echo -e "${GREEN}✅ Database '$DB_NAME' exists${NC}"
        return 0
    else
        echo -e "${RED}❌ Database '$DB_NAME' does not exist${NC}"
        return 1
    fi
}

# Function to verify users exist
verify_users() {
    echo -e "${BLUE}👤 Verifying users exist...${NC}"
    
    if docker exec $POSTGRES_CONTAINER psql -U postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='$APP_USER'" | grep -q 1; then
        echo -e "${GREEN}✅ User '$APP_USER' exists${NC}"
    else
        echo -e "${RED}❌ User '$APP_USER' does not exist${NC}"
        return 1
    fi
    
    if docker exec $POSTGRES_CONTAINER psql -U postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='wondernest_analytics'" | grep -q 1; then
        echo -e "${GREEN}✅ User 'wondernest_analytics' exists${NC}"
    else
        echo -e "${RED}❌ User 'wondernest_analytics' does not exist${NC}"
        return 1
    fi
    
    return 0
}

# Function to verify schemas
verify_schemas() {
    echo -e "${BLUE}🏗️  Verifying schemas exist...${NC}"
    
    local schemas=("core" "family" "content" "audit")
    local missing_schemas=()
    
    for schema in "${schemas[@]}"; do
        if docker exec $POSTGRES_CONTAINER psql -U postgres -d $DB_NAME -tAc "SELECT 1 FROM information_schema.schemata WHERE schema_name='$schema'" | grep -q 1; then
            echo -e "${GREEN}✅ Schema '$schema' exists${NC}"
        else
            echo -e "${RED}❌ Schema '$schema' does not exist${NC}"
            missing_schemas+=("$schema")
        fi
    done
    
    if [ ${#missing_schemas[@]} -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Function to verify tables
verify_tables() {
    echo -e "${BLUE}📋 Verifying core tables exist...${NC}"
    
    local tables=("core.users" "core.user_sessions" "family.families" "content.stories")
    local missing_tables=()
    
    for table in "${tables[@]}"; do
        local schema=$(echo $table | cut -d. -f1)
        local table_name=$(echo $table | cut -d. -f2)
        
        if docker exec $POSTGRES_CONTAINER psql -U postgres -d $DB_NAME -tAc "SELECT 1 FROM information_schema.tables WHERE table_schema='$schema' AND table_name='$table_name'" | grep -q 1; then
            echo -e "${GREEN}✅ Table '$table' exists${NC}"
        else
            echo -e "${RED}❌ Table '$table' does not exist${NC}"
            missing_tables+=("$table")
        fi
    done
    
    if [ ${#missing_tables[@]} -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Function to test connectivity
test_connectivity() {
    echo -e "${BLUE}🔗 Testing database connectivity...${NC}"
    
    # Test as postgres user
    if docker exec $POSTGRES_CONTAINER psql -U postgres -d $DB_NAME -c "SELECT 1" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Connection as postgres user works${NC}"
    else
        echo -e "${RED}❌ Connection as postgres user failed${NC}"
        return 1
    fi
    
    # Test as application user
    if docker exec $POSTGRES_CONTAINER psql -U $APP_USER -d $DB_NAME -c "SELECT 1" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Connection as application user works${NC}"
    else
        echo -e "${RED}❌ Connection as application user failed${NC}"
        return 1
    fi
    
    # Test external connection (if psql is available on host)
    if command -v psql >/dev/null 2>&1; then
        if PGPASSWORD=$APP_PASSWORD psql -h localhost -p $POSTGRES_PORT -U $APP_USER -d $DB_NAME -c "SELECT 1" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ External connection from host works${NC}"
        else
            echo -e "${YELLOW}⚠️  External connection from host failed (but this might be expected)${NC}"
        fi
    else
        echo -e "${BLUE}ℹ️  psql not available on host, skipping external connection test${NC}"
    fi
    
    return 0
}

# Function to show summary
show_summary() {
    echo ""
    echo -e "${BLUE}📋 Database Connection Information:${NC}"
    echo "  Host: localhost"
    echo "  Port: $POSTGRES_PORT"
    echo "  Database: $DB_NAME"
    echo "  Application User: $APP_USER"
    echo "  JDBC URL: jdbc:postgresql://localhost:$POSTGRES_PORT/$DB_NAME"
    echo ""
    echo -e "${BLUE}🧪 Test connection:${NC}"
    echo "  docker exec -it $POSTGRES_CONTAINER psql -U $APP_USER -d $DB_NAME"
    echo ""
    echo -e "${BLUE}🚀 Start your application:${NC}"
    echo "  ./gradlew run"
}

# Main verification
main() {
    echo -e "${BLUE}WonderNest Database Verification${NC}"
    echo "===================================="
    
    local failed=0
    
    # Check each component
    check_container || failed=1
    verify_database || failed=1
    verify_users || failed=1
    verify_schemas || failed=1
    verify_tables || failed=1
    test_connectivity || failed=1
    
    echo ""
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}🎉 All verifications passed! Database is ready.${NC}"
        show_summary
        exit 0
    else
        echo -e "${RED}❌ Some verifications failed. Please check the errors above.${NC}"
        echo -e "${YELLOW}💡 Try running: ./setup-database.sh${NC}"
        exit 1
    fi
}

# Run main function
main "$@"