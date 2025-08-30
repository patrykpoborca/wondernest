#!/bin/bash

# Quick JAR update without full Docker rebuild
# This builds locally and copies the JAR into the running container

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔄 Building new JAR...${NC}"

# Build the JAR locally (much faster than in Docker)
./gradlew shadowJar -x test

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build successful!${NC}"
    
    # Copy the new JAR into the container
    echo -e "${YELLOW}Copying JAR to container...${NC}"
    docker cp build/libs/*-all.jar wondernestbackend-api-1:/app/app.jar
    
    # Restart the container to use the new JAR
    echo -e "${YELLOW}Restarting container...${NC}"
    docker restart wondernestbackend-api-1
    
    # Wait for health check
    echo -e "${YELLOW}Waiting for backend to be healthy...${NC}"
    sleep 5
    
    # Check if it's running
    if curl -s http://localhost:8080/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Backend updated and running!${NC}"
    else
        echo -e "${RED}⚠️ Backend might still be starting. Check logs:${NC}"
        echo "docker logs wondernestbackend-api-1 --tail 20"
    fi
else
    echo -e "${RED}❌ Build failed! Check the errors above.${NC}"
    exit 1
fi