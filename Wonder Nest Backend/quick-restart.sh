#!/bin/bash

# Quick rebuild without cache clearing (faster)
echo "🔄 Quick rebuilding WonderNest Backend..."

# Rebuild and restart in one command
docker-compose up -d --build api

# Check status
sleep 3
if docker ps | grep -q wondernestbackend-api-1; then
    echo "✅ Container restarted successfully!"
    echo "📋 Recent logs:"
    docker logs wondernestbackend-api-1 --tail 5
else
    echo "❌ Container failed to start"
    docker-compose logs api --tail 20
fi