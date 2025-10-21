#!/bin/bash
set -e

echo "=========================================="
echo "Backrest Initialization Script"
echo "=========================================="
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "ERROR: .env file not found!"
    echo "Please copy .env.example to .env and configure it first:"
    echo "  cp .env.example .env"
    echo "  nano .env"
    exit 1
fi

# Source .env file
source .env

# Check if BACKREST_DOMAIN is set
if [ -z "$BACKREST_DOMAIN" ]; then
    echo "ERROR: BACKREST_DOMAIN not set in .env!"
    echo "Please set BACKREST_DOMAIN in your .env file."
    exit 1
fi

# Check if backup storage path is set
if [ -z "$BACKUP_STORAGE_PATH" ]; then
    echo "WARNING: BACKUP_STORAGE_PATH not set in .env!"
    echo "Using default: /mnt/backups"
    echo ""
fi

# Create backup storage directory if it doesn't exist (skip if using remote storage)
if [ -n "$BACKUP_STORAGE_PATH" ] && [ "$BACKUP_STORAGE_PATH" != "/mnt/backups" ]; then
    if [ ! -d "$BACKUP_STORAGE_PATH" ]; then
        echo "Backup storage directory does not exist: $BACKUP_STORAGE_PATH"
        echo "Please create it manually with appropriate permissions."
        echo ""
        read -p "Do you want to continue without creating it? (y/N) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
fi

echo "Starting Backrest..."
docker compose up -d

echo ""
echo "Waiting for Backrest to be ready..."
sleep 10

# Check if container is running
if docker ps | grep -q backrest; then
    echo "✓ Backrest container is running"
else
    echo "ERROR: Backrest container is not running!"
    echo "Check logs with: docker compose logs backrest"
    exit 1
fi

# Check if Backrest web UI is responding
echo "Checking Backrest web UI..."
for i in {1..30}; do
    if docker exec backrest wget -q --spider http://localhost:9898 2>/dev/null; then
        echo "✓ Backrest web UI is responding"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "WARNING: Backrest web UI is not responding yet. It may still be starting up."
    fi
    sleep 2
done

echo ""
echo "=========================================="
echo "✓ Backrest initialization complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Access Backrest at: https://${BACKREST_DOMAIN}"
echo ""
echo "2. Configure your first backup repository:"
echo "   - Click 'Add Repository'"
echo "   - Choose storage location (local, S3, B2, etc.)"
echo "   - Set repository password (IMPORTANT: Save this!)"
echo ""
echo "3. Configure backup plans:"
echo "   - Click 'Add Plan'"
echo "   - Select repository"
echo "   - Choose paths to backup"
echo "   - Set schedule (cron expression)"
echo ""
echo "4. Test your backup:"
echo "   - Click 'Run Now' on your backup plan"
echo "   - Monitor progress in the UI"
echo ""
echo "5. Verify backups:"
echo "   - Check 'Snapshots' tab"
echo "   - Use 'Browse' to view files"
echo "   - Test restore functionality"
echo ""
echo "Backup Sources Mounted:"
echo "  - /opt → /backup-sources/opt (read-only)"
echo "  - /var/lib/docker/volumes → /backup-sources/docker-volumes (read-only)"
echo ""
echo "Local Backup Storage:"
echo "  - ${BACKUP_STORAGE_PATH:-/mnt/backups} → /backups"
echo ""
echo "Useful Commands:"
echo "  - View logs: docker compose logs -f backrest"
echo "  - Restart: docker compose restart backrest"
echo "  - Shell access: docker exec -it backrest sh"
echo ""
