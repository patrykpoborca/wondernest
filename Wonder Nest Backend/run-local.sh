#!/bin/bash

# Run backend locally without Docker for fastest development iteration
# Uses Docker only for PostgreSQL and Redis

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 Running backend locally (using Docker for DB/Redis only)${NC}"

# Export environment variables
export DB_HOST=localhost
export DB_PORT=5433
export DB_NAME=wondernest_prod
export DB_USERNAME=wondernest_app
export DB_PASSWORD=wondernest_secure_password_dev
export REDIS_HOST=localhost
export REDIS_PORT=6379
export JWT_SECRET="development-jwt-secret-change-in-production"
export KTOR_ENV=development
export KTOR_DEVELOPMENT=true

# Stop the Docker API container if running
if docker ps | grep -q wondernestbackend-api-1; then
    echo -e "${YELLOW}Stopping Docker API container...${NC}"
    docker stop wondernestbackend-api-1
fi

echo -e "${GREEN}✅ Starting local backend with auto-reload...${NC}"
echo -e "${YELLOW}The server will auto-restart when you save changes!${NC}"

# Run with continuous build (auto-recompiles on save)
./gradlew run --continuous