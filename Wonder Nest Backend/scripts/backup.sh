#!/bin/bash
# WonderNest Database Backup Script
# Creates a backup of the PostgreSQL database

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

# Default backup directory
BACKUP_DIR="$PROJECT_ROOT/backups"
mkdir -p "$BACKUP_DIR"

# Generate backup filename with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="wondernest_backup_${TIMESTAMP}.sql"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILE"

# Parse command line arguments
INCLUDE_DATA=true
COMPRESS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --schema-only)
            INCLUDE_DATA=false
            shift
            ;;
        --compress|-c)
            COMPRESS=true
            BACKUP_FILE="wondernest_backup_${TIMESTAMP}.sql.gz"
            BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILE"
            shift
            ;;
        --output|-o)
            BACKUP_PATH="$2"
            BACKUP_FILE=$(basename "$BACKUP_PATH")
            shift 2
            ;;
        --help|-h)
            echo "WonderNest Database Backup Tool"
            echo
            echo "Usage: $0 [OPTIONS]"
            echo
            echo "Options:"
            echo "  --schema-only    Backup schema only (no data)"
            echo "  --compress, -c   Compress the backup file"
            echo "  --output, -o     Specify output file path"
            echo "  --help, -h       Show this help message"
            echo
            echo "Examples:"
            echo "  $0                           # Full backup"
            echo "  $0 --schema-only            # Schema only backup"
            echo "  $0 --compress               # Compressed full backup"
            echo "  $0 -o /path/to/backup.sql   # Custom output path"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "💾 WonderNest Database Backup"
echo

# Check if PostgreSQL is running
if ! $COMPOSE_CMD exec postgres pg_isready -U postgres -d wondernest_prod >/dev/null 2>&1; then
    print_error "PostgreSQL is not running or not accessible"
    print_status "Start the database with: ./scripts/start-dev.sh"
    exit 1
fi

print_status "Creating backup of wondernest_prod database..."
print_status "Output file: $BACKUP_PATH"

if [ "$INCLUDE_DATA" = true ]; then
    print_status "Backup type: Full (schema + data)"
else
    print_status "Backup type: Schema only"
fi

# Prepare pg_dump options
PG_DUMP_OPTS="--verbose --clean --if-exists --create"

if [ "$INCLUDE_DATA" = false ]; then
    PG_DUMP_OPTS="$PG_DUMP_OPTS --schema-only"
fi

# Create the backup
print_status "Starting backup process..."

if [ "$COMPRESS" = true ]; then
    print_status "Creating compressed backup..."
    if $COMPOSE_CMD exec -T postgres pg_dump -U postgres $PG_DUMP_OPTS wondernest_prod | gzip > "$BACKUP_PATH"; then
        print_success "Backup created successfully"
    else
        print_error "Backup failed"
        exit 1
    fi
else
    print_status "Creating uncompressed backup..."
    if $COMPOSE_CMD exec -T postgres pg_dump -U postgres $PG_DUMP_OPTS wondernest_prod > "$BACKUP_PATH"; then
        print_success "Backup created successfully"
    else
        print_error "Backup failed"
        exit 1
    fi
fi

# Get backup file size
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    BACKUP_SIZE=$(stat -f%z "$BACKUP_PATH" | awk '{printf "%.2f MB", $1/1024/1024}')
else
    # Linux and others
    BACKUP_SIZE=$(stat --format="%s" "$BACKUP_PATH" 2>/dev/null | awk '{printf "%.2f MB", $1/1024/1024}' || echo "Unknown")
fi

# Verify backup integrity
print_status "Verifying backup integrity..."
if [ "$COMPRESS" = true ]; then
    if gzip -t "$BACKUP_PATH" 2>/dev/null; then
        print_success "Backup file integrity verified"
    else
        print_warning "Backup file may be corrupted"
    fi
else
    # Check if SQL file is valid by looking for key patterns
    if grep -q "PostgreSQL database dump" "$BACKUP_PATH" 2>/dev/null; then
        print_success "Backup file appears valid"
    else
        print_warning "Backup file may be invalid"
    fi
fi

# Summary
echo
print_success "Backup completed!"
echo
echo "📄 Backup Details:"
echo "  File: $BACKUP_PATH"
echo "  Size: $BACKUP_SIZE"
echo "  Type: $([ "$INCLUDE_DATA" = true ] && echo "Full backup" || echo "Schema only")"
echo "  Compressed: $([ "$COMPRESS" = true ] && echo "Yes" || echo "No")"
echo "  Created: $(date)"
echo
echo "📝 To restore this backup:"
echo "  ./scripts/restore.sh \"$BACKUP_PATH\""
echo

# Cleanup old backups (keep last 10)
print_status "Cleaning up old backups (keeping 10 most recent)..."
OLD_BACKUPS=$(ls -t "$BACKUP_DIR"/wondernest_backup_*.sql* 2>/dev/null | tail -n +11)
if [ ! -z "$OLD_BACKUPS" ]; then
    echo "$OLD_BACKUPS" | xargs rm -f
    CLEANED_COUNT=$(echo "$OLD_BACKUPS" | wc -l | tr -d ' ')
    print_status "Removed $CLEANED_COUNT old backup(s)"
else
    print_status "No old backups to clean up"
fi

print_success "Backup process completed!"