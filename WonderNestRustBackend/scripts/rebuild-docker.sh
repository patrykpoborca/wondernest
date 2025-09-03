#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🦀 Rebuilding WonderNest Rust Backend Docker Container...${NC}"
echo ""

# Stop and remove the existing container if running
echo -e "${YELLOW}📦 Stopping existing container...${NC}"
docker stop wondernest-rust-backend 2>/dev/null || true
docker rm wondernest-rust-backend 2>/dev/null || true

# Remove old image to force rebuild
echo -e "${YELLOW}🗑️  Removing old image...${NC}"
docker rmi wondernest-rust-backend 2>/dev/null || true

# Build the new image with no cache
echo -e "${YELLOW}🔨 Building new image (this may take a few minutes)...${NC}"
docker build --no-cache -t wondernest-rust-backend .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build successful!${NC}"
    echo ""
    
    # Check if we should use docker-compose or standalone
    if [ -f "docker-compose.yml" ] && [ "$1" != "--standalone" ]; then
        echo -e "${YELLOW}🚀 Starting container with docker-compose...${NC}"
        docker-compose up -d rust-backend
        CONTAINER_NAME="wondernestrust-backend-rust-backend-1"
    else
        echo -e "${YELLOW}🚀 Starting container in standalone mode...${NC}"
        docker run -d \
            --name wondernest-rust-backend \
            -p 8082:8080 \
            -e DATABASE_URL="postgresql://wondernest_app:wondernest_secure_password_dev@host.docker.internal:5433/wondernest_prod" \
            -e REDIS_URL="redis://host.docker.internal:6379" \
            -e JWT_SECRET="your-super-secret-jwt-key-change-this-in-production" \
            -e RUST_LOG="debug" \
            --add-host host.docker.internal:host-gateway \
            wondernest-rust-backend
        CONTAINER_NAME="wondernest-rust-backend"
    fi
    
    # Wait for container to be ready
    echo -e "${YELLOW}⏳ Waiting for backend to be healthy...${NC}"
    sleep 5
    
    # Check if container is running
    if docker ps | grep -q "$CONTAINER_NAME"; then
        echo -e "${GREEN}✅ Container is running!${NC}"
        
        # Test the health endpoint
        echo -e "${YELLOW}🏥 Testing health endpoint...${NC}"
        HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8082/health)
        if [ "$HEALTH_CHECK" = "200" ]; then
            echo -e "${GREEN}✅ Backend is responding on port 8082!${NC}"
            echo -e "${GREEN}🎉 Rust backend rebuild complete!${NC}"
            echo ""
            
            # Show recent logs
            echo -e "${YELLOW}📋 Recent logs:${NC}"
            docker logs "$CONTAINER_NAME" --tail 20
            echo ""
            echo -e "${BLUE}💡 Useful commands:${NC}"
            echo "  View logs:        docker logs -f $CONTAINER_NAME"
            echo "  Stop container:   docker stop $CONTAINER_NAME"
            echo "  Restart:          ./restart-docker.sh"
            echo "  Test auth:        ./test-auth.sh"
            echo ""
            echo -e "${GREEN}🌐 Rust backend available at: http://localhost:8082${NC}"
        else
            echo -e "${RED}❌ Backend is not responding on port 8082${NC}"
            echo -e "${YELLOW}📋 Container logs:${NC}"
            docker logs "$CONTAINER_NAME" --tail 30
        fi
    else
        echo -e "${RED}❌ Container failed to start${NC}"
        echo -e "${YELLOW}Check logs with: docker logs $CONTAINER_NAME${NC}"
    fi
else
    echo -e "${RED}❌ Build failed! Check the errors above.${NC}"
    exit 1
fi