#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Restarting WonderNest Rust Backend Container...${NC}"
echo ""

# Determine which container name to use
if docker ps -a | grep -q "wondernestrust-backend-rust-backend-1"; then
    CONTAINER_NAME="wondernestrust-backend-rust-backend-1"
    USE_COMPOSE=true
elif docker ps -a | grep -q "wondernest-rust-backend"; then
    CONTAINER_NAME="wondernest-rust-backend"
    USE_COMPOSE=false
else
    echo -e "${RED}❌ No Rust backend container found!${NC}"
    echo -e "${YELLOW}💡 Run ./rebuild-docker.sh first to build the container${NC}"
    exit 1
fi

# Stop the container
echo -e "${YELLOW}⏹️  Stopping container...${NC}"
docker stop "$CONTAINER_NAME"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Container stopped${NC}"
else
    echo -e "${YELLOW}⚠️  Container was not running${NC}"
fi

# Start the container
echo -e "${YELLOW}▶️  Starting container...${NC}"
if [ "$USE_COMPOSE" = true ]; then
    docker-compose up -d rust-backend
else
    docker start "$CONTAINER_NAME"
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Container started${NC}"
    
    # Wait for health check
    echo -e "${YELLOW}⏳ Waiting for backend to be ready...${NC}"
    sleep 3
    
    # Test the health endpoint
    HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8082/health 2>/dev/null)
    if [ "$HEALTH_CHECK" = "200" ]; then
        echo -e "${GREEN}✅ Backend is healthy and responding!${NC}"
        echo ""
        
        # Show recent logs
        echo -e "${YELLOW}📋 Recent logs:${NC}"
        docker logs "$CONTAINER_NAME" --tail 10
        echo ""
        echo -e "${GREEN}🎉 Restart complete!${NC}"
        echo -e "${GREEN}🌐 Rust backend available at: http://localhost:8082${NC}"
    else
        echo -e "${RED}❌ Backend health check failed${NC}"
        echo -e "${YELLOW}📋 Container logs:${NC}"
        docker logs "$CONTAINER_NAME" --tail 20
    fi
else
    echo -e "${RED}❌ Failed to start container${NC}"
    exit 1
fi