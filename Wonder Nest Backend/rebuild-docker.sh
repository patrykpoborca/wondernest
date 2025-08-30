#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔄 Rebuilding WonderNest Backend Docker Container...${NC}"

# Stop and remove the existing container
echo -e "${YELLOW}Stopping existing container...${NC}"
docker-compose down api

# Rebuild the image with no cache to ensure fresh build
echo -e "${YELLOW}Building new image...${NC}"
docker-compose build --no-cache api

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build successful!${NC}"
    
    # Start the new container
    echo -e "${YELLOW}Starting container...${NC}"
    docker-compose up -d api
    
    # Wait for health check
    echo -e "${YELLOW}Waiting for backend to be healthy...${NC}"
    sleep 5
    
    # Check if container is running
    if docker ps | grep -q wondernestbackend-api-1; then
        echo -e "${GREEN}✅ Container is running!${NC}"
        
        # Test the health endpoint
        echo -e "${YELLOW}Testing health endpoint...${NC}"
        curl -s http://localhost:8080/health > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Backend is responding!${NC}"
            echo -e "${GREEN}🎉 Docker rebuild complete!${NC}"
            
            # Show logs
            echo -e "${YELLOW}Recent logs:${NC}"
            docker logs wondernestbackend-api-1 --tail 10
        else
            echo -e "${RED}❌ Backend is not responding on port 8080${NC}"
            echo -e "${YELLOW}Check logs with: docker logs wondernestbackend-api-1${NC}"
        fi
    else
        echo -e "${RED}❌ Container failed to start${NC}"
        echo -e "${YELLOW}Check logs with: docker-compose logs api${NC}"
    fi
else
    echo -e "${RED}❌ Build failed! Check the errors above.${NC}"
    exit 1
fi