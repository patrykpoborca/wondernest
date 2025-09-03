#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${CYAN}📊 WonderNest Rust Backend - Docker Status${NC}"
echo -e "${CYAN}==========================================${NC}"
echo ""

# Check if container exists
if docker ps -a | grep -q "wondernest-rust-backend\|wondernestrust-backend-rust-backend-1"; then
    # Get container name
    if docker ps -a | grep -q "wondernestrust-backend-rust-backend-1"; then
        CONTAINER_NAME="wondernestrust-backend-rust-backend-1"
    else
        CONTAINER_NAME="wondernest-rust-backend"
    fi
    
    # Check if running
    if docker ps | grep -q "$CONTAINER_NAME"; then
        echo -e "${GREEN}✅ Container Status: RUNNING${NC}"
        echo ""
        
        # Get container details
        echo -e "${BLUE}📦 Container Information:${NC}"
        docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo ""
        
        # Check health endpoint
        echo -e "${BLUE}🏥 Health Check:${NC}"
        HEALTH_RESPONSE=$(curl -s http://localhost:8082/health 2>/dev/null)
        if echo "$HEALTH_RESPONSE" | grep -q "UP"; then
            echo -e "${GREEN}✅ Backend is healthy${NC}"
            echo "Response: $HEALTH_RESPONSE"
        else
            echo -e "${RED}❌ Backend is not responding${NC}"
        fi
        echo ""
        
        # Check detailed health
        echo -e "${BLUE}🔍 Detailed Health:${NC}"
        DETAILED=$(curl -s http://localhost:8082/health/detailed 2>/dev/null | head -c 200)
        if [ -n "$DETAILED" ]; then
            echo "$DETAILED..."
        else
            echo -e "${YELLOW}⚠️  Detailed health endpoint not responding${NC}"
        fi
        echo ""
        
        # Resource usage
        echo -e "${BLUE}💻 Resource Usage:${NC}"
        docker stats --no-stream "$CONTAINER_NAME" --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
        echo ""
        
        # Recent logs
        echo -e "${BLUE}📋 Recent Logs (last 5 lines):${NC}"
        docker logs "$CONTAINER_NAME" --tail 5
        echo ""
        
    else
        echo -e "${YELLOW}⚠️  Container Status: STOPPED${NC}"
        echo -e "Container '$CONTAINER_NAME' exists but is not running"
        echo ""
        echo -e "${BLUE}💡 To start the container:${NC}"
        echo "  ./restart-docker.sh"
    fi
    
    # Show available commands
    echo -e "${MAGENTA}🛠️  Available Commands:${NC}"
    echo "  View logs:        docker logs -f $CONTAINER_NAME"
    echo "  Enter container:  docker exec -it $CONTAINER_NAME /bin/bash"
    echo "  Stop container:   docker stop $CONTAINER_NAME"
    echo "  Restart:          ./restart-docker.sh"
    echo "  Rebuild:          ./rebuild-docker.sh"
    echo "  Quick rebuild:    ./quick-rebuild.sh"
    echo "  Test auth:        ./test-auth.sh"
    
else
    echo -e "${RED}❌ No Rust backend container found${NC}"
    echo ""
    echo -e "${BLUE}💡 To create and start the container:${NC}"
    echo "  ./rebuild-docker.sh"
fi

echo ""
echo -e "${CYAN}==========================================${NC}"

# Check if Kotlin backend is also running
if docker ps | grep -q "wondernestbackend-api-1\|wondernest-backend"; then
    echo ""
    echo -e "${YELLOW}⚠️  Note: Kotlin backend is also running${NC}"
    echo "  Kotlin backend: http://localhost:8080"
    echo "  Rust backend:   http://localhost:8082"
fi