#!/bin/bash
set -e

# WonderNest Database Initialization Wrapper
# This script runs as part of PostgreSQL Docker entrypoint to initialize the database
# It calls the main init script from the mounted directory

echo "🚀 Starting WonderNest database initialization wrapper..."

# Execute the main initialization script
if [ -f "/opt/wondernest/scripts/init-database.sh" ]; then
    echo "📋 Executing main WonderNest initialization script..."
    bash /opt/wondernest/scripts/init-database.sh
else
    echo "❌ Main initialization script not found at /opt/wondernest/scripts/init-database.sh"
    exit 1
fi

echo "✅ WonderNest database initialization wrapper completed!"