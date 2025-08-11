#!/bin/bash
# WonderNest Database Restore Script
# Restores a PostgreSQL database backup

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect docker-compose command
if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
else
    COMPOSE_CMD="docker compose"
fi

cd "$PROJECT_ROOT"

# Show usage if no arguments provided
if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "WonderNest Database Restore Tool"
    echo
    echo "Usage: $0 <backup_file> [OPTIONS]"
    echo
    echo "Arguments:"
    echo "  backup_file      Path to the backup file (.sql or .sql.gz)"
    echo
    echo "Options:"
    echo "  --force          Skip confirmation prompts"
    echo "  --help, -h       Show this help message"
    echo
    echo "Examples:"
    echo "  $0 backups/wondernest_backup_20241201_143022.sql"
    echo "  $0 /path/to/backup.sql.gz --force"
    echo
    echo "⚠️  WARNING: This will replace all existing data!"
    exit 0
fi

BACKUP_FILE="$1"
FORCE=false

# Parse additional arguments
shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "📥 WonderNest Database Restore"
echo

# Validate backup file
if [ ! -f "$BACKUP_FILE" ]; then
    print_error "Backup file not found: $BACKUP_FILE"
    
    # Suggest available backups
    BACKUP_DIR="$PROJECT_ROOT/backups"
    if [ -d "$BACKUP_DIR" ]; then
        AVAILABLE_BACKUPS=$(ls -t "$BACKUP_DIR"/wondernest_backup_*.sql* 2>/dev/null | head -5)
        if [ ! -z "$AVAILABLE_BACKUPS" ]; then
            echo
            print_status "Available backups (5 most recent):"
            echo "$AVAILABLE_BACKUPS" | while read backup; do
                SIZE=$(stat -f%z "$backup" 2>/dev/null | awk '{printf "%.1f MB", $1/1024/1024}' || echo "Unknown size")
                DATE=$(stat -f%Sm -t '%Y-%m-%d %H:%M' "$backup" 2>/dev/null || echo "Unknown date")
                echo "  $(basename "$backup") ($SIZE, $DATE)"
            done
        fi
    fi
    exit 1
fi

# Determine if file is compressed
if [[ "$BACKUP_FILE" == *.gz ]]; then
    COMPRESSED=true
    print_status "Detected compressed backup file"
    
    # Verify gzip file integrity
    if ! gzip -t "$BACKUP_FILE" 2>/dev/null; then
        print_error "Backup file is corrupted or not a valid gzip file"
        exit 1
    fi
else
    COMPRESSED=false
    print_status "Detected uncompressed backup file"
fi

# Get backup file info
BACKUP_SIZE=$(stat -f%z "$BACKUP_FILE" 2>/dev/null | awk '{printf "%.2f MB", $1/1024/1024}' || echo "Unknown")
BACKUP_DATE=$(stat -f%Sm -t '%Y-%m-%d %H:%M:%S' "$BACKUP_FILE" 2>/dev/null || echo "Unknown")

echo "📄 Backup Information:"
echo "  File: $BACKUP_FILE"
echo "  Size: $BACKUP_SIZE"
echo "  Created: $BACKUP_DATE"
echo "  Compressed: $([ "$COMPRESSED" = true ] && echo "Yes" || echo "No")"
echo

# Check if PostgreSQL is running
if ! $COMPOSE_CMD exec postgres pg_isready -U postgres -d wondernest_prod >/dev/null 2>&1; then
    print_error "PostgreSQL is not running or not accessible"
    print_status "Start the database with: ./scripts/start-dev.sh"
    exit 1
fi

# Warning about data loss
if [ "$FORCE" = false ]; then
    echo
    print_warning "⚠️  WARNING: This will completely replace the current database!"
    print_warning "All existing data will be permanently lost!"
    echo
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Restore cancelled"
        exit 0
    fi
    
    echo
    read -p "Type 'RESTORE' to confirm: " CONFIRM
    if [[ "$CONFIRM" != "RESTORE" ]]; then
        print_status "Restore cancelled"
        exit 0
    fi
fi

echo
print_status "Starting database restore..."

# Stop the API service if it's running
print_status "Stopping API service..."
$COMPOSE_CMD stop api 2>/dev/null || true

# Create a backup of the current database before restore
CURRENT_BACKUP_FILE="$PROJECT_ROOT/backups/pre_restore_backup_$(date +%Y%m%d_%H%M%S).sql"
mkdir -p "$(dirname "$CURRENT_BACKUP_FILE")"

print_status "Creating backup of current database..."
if $COMPOSE_CMD exec -T postgres pg_dump -U postgres --clean --if-exists --create wondernest_prod > "$CURRENT_BACKUP_FILE" 2>/dev/null; then
    print_status "Current database backed up to: $CURRENT_BACKUP_FILE"
else
    print_warning "Could not create backup of current database"
fi

# Perform the restore
print_status "Restoring database from backup..."

if [ "$COMPRESSED" = true ]; then
    print_status "Restoring from compressed backup..."
    if gunzip -c "$BACKUP_FILE" | $COMPOSE_CMD exec -T postgres psql -U postgres -d postgres; then
        print_success "Database restore completed successfully"
    else
        print_error "Database restore failed"
        
        if [ -f "$CURRENT_BACKUP_FILE" ]; then
            print_status "Attempting to restore previous database..."
            if $COMPOSE_CMD exec -T postgres psql -U postgres -d postgres < "$CURRENT_BACKUP_FILE"; then
                print_success "Previous database restored"
            else
                print_error "Could not restore previous database"
            fi
        fi
        exit 1
    fi
else
    print_status "Restoring from uncompressed backup..."
    if $COMPOSE_CMD exec -T postgres psql -U postgres -d postgres < "$BACKUP_FILE"; then
        print_success "Database restore completed successfully"
    else
        print_error "Database restore failed"
        
        if [ -f "$CURRENT_BACKUP_FILE" ]; then
            print_status "Attempting to restore previous database..."
            if $COMPOSE_CMD exec -T postgres psql -U postgres -d postgres < "$CURRENT_BACKUP_FILE"; then
                print_success "Previous database restored"
            else
                print_error "Could not restore previous database"
            fi
        fi
        exit 1
    fi
fi

# Verify the restore
print_status "Verifying database restore..."

# Check if schemas exist
SCHEMAS_COUNT=$($COMPOSE_CMD exec postgres psql -U postgres -d wondernest_prod -t -c "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name IN ('core', 'family', 'content', 'audio', 'analytics');" 2>/dev/null | tr -d ' ') || SCHEMAS_COUNT=0

if [ "$SCHEMAS_COUNT" -eq "5" ]; then
    print_success "Database schemas verified"
else
    print_warning "Database may not be fully restored (found $SCHEMAS_COUNT/5 schemas)"
fi

# Test application user connection
if $COMPOSE_CMD exec postgres psql -U wondernest_app -d wondernest_prod -c "SELECT 1;" >/dev/null 2>&1; then
    print_success "Application user can connect"
else
    print_warning "Application user connection failed"
fi

# Clean up the pre-restore backup if restore was successful
if [ -f "$CURRENT_BACKUP_FILE" ] && [ "$SCHEMAS_COUNT" -eq "5" ]; then
    rm -f "$CURRENT_BACKUP_FILE"
    print_status "Cleaned up temporary backup"
fi

echo
print_success "Database restore completed!"
echo
echo "📊 Database Information:"
echo "  Host: localhost:5433"
echo "  Database: wondernest_prod"
echo "  App User: wondernest_app"
echo
echo "🖥️  pgAdmin: http://localhost:5050"
echo
echo "You can now restart the API service:"
echo "  $COMPOSE_CMD up -d api"