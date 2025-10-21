# Backrest Quick Start Guide

Get your backup solution running in 10 minutes!

## Prerequisites

- Docker and Docker Compose installed
- Traefik running on `dim_network_traefik`
- Domain configured: `backrest.do-it.media`
- Backup storage location prepared

## Installation Steps

### 1. Setup Environment

```bash
cd /opt/docker_backrest
cp .env.example .env
nano .env
```

Update these values:
```bash
BACKREST_DOMAIN=backrest.do-it.media
TZ=Europe/Berlin
BACKUP_STORAGE_PATH=/mnt/backups
```

### 2. Create Backup Storage

```bash
# For local storage
sudo mkdir -p /mnt/backups
sudo chown dimdev:dimdev /mnt/backups

# Or mount your NAS/external drive to /mnt/backups
```

### 3. Initialize Backrest

```bash
./init-backrest.sh
```

### 4. Access Web UI

Open browser: `https://backrest.do-it.media`

### 5. Create Repository

1. Click **"Add Repository"**
2. **Name**: `local-backups`
3. **Type**: `Local`
4. **Path**: `/backups/repo1`
5. **Password**: Generate strong password (SAVE THIS!)
   ```bash
   openssl rand -base64 32
   ```
6. Click **"Initialize Repository"**

### 6. Create Backup Plan

1. Click **"Add Plan"**
2. **Name**: `daily-docker-backup`
3. **Repository**: `local-backups`
4. **Paths**: Add paths to backup
   ```
   /backup-sources/opt/docker_vaultwarden
   /backup-sources/opt/docker_psono
   /backup-sources/opt/docker_passbolt
   ```
5. **Schedule**: `0 2 * * *` (Daily at 2 AM)
6. **Retention**:
   - Daily: Keep 7
   - Weekly: Keep 4
   - Monthly: Keep 12
7. **Exclusions** (optional):
   ```
   **/*.log
   **/cache/**
   **/tmp/**
   ```
8. Click **"Save Plan"**

### 7. Run First Backup

1. Find your backup plan in the list
2. Click **"Run Now"** button
3. Watch progress in real-time
4. Wait for completion (green checkmark)

### 8. Verify Backup

1. Go to **"Snapshots"** tab
2. See your first snapshot listed
3. Click **"Browse"** to explore files
4. Test restore by downloading a file

Done! Your automated backup system is ready.

## Common Backup Sources

Add these to your backup plan paths:

```bash
# Docker application data
/backup-sources/opt/docker_vaultwarden
/backup-sources/opt/docker_psono
/backup-sources/opt/docker_passbolt
/backup-sources/opt/docker_mailu

# Docker volumes (all applications)
/backup-sources/docker-volumes

# System configurations
/backup-sources/opt
```

## Schedule Examples

```bash
# Every day at 2 AM
0 2 * * *

# Every 6 hours
0 */6 * * *

# Every Sunday at 3 AM
0 3 * * 0

# Every day at 2 AM and 2 PM
0 2,14 * * *

# Every hour
0 * * * *
```

## Cloud Storage Setup

### Amazon S3

1. Create S3 bucket
2. Create IAM user with S3 access
3. Add to `.env`:
   ```bash
   AWS_ACCESS_KEY_ID=your_key
   AWS_SECRET_ACCESS_KEY=your_secret
   AWS_DEFAULT_REGION=us-east-1
   ```
4. In Backrest UI:
   - Type: **S3**
   - Bucket: `your-bucket-name`
   - Path: `/backups/server1`

### Backblaze B2

1. Create B2 bucket
2. Create application key
3. Add to `.env`:
   ```bash
   B2_ACCOUNT_ID=your_account_id
   B2_ACCOUNT_KEY=your_key
   ```
4. In Backrest UI:
   - Type: **B2**
   - Bucket: `your-bucket-name`

## Quick Commands

```bash
# View logs
docker compose logs -f backrest

# Restart
docker compose restart backrest

# Stop
docker compose down

# Update
docker compose pull && docker compose up -d

# Access shell
docker exec -it backrest sh

# List snapshots
docker exec backrest restic -r /backups/repo1 snapshots

# Check repository
docker exec backrest restic -r /backups/repo1 check
```

## Email Notifications

Configure in Web UI:

1. **Settings** → **Notifications**
2. **Add SMTP**:
   - Host: `mail.do-it.media`
   - Port: `587`
   - Username: `backrest@do-it.media`
   - Password: Your SMTP password
   - From: `backrest@do-it.media`
3. **Enable notifications**:
   - ✅ On backup failure
   - ☐ On backup success (optional)

## Database Backups

Databases need special handling:

### PostgreSQL Backup Script

Create `/opt/scripts/backup-databases.sh`:

```bash
#!/bin/bash
BACKUP_DIR=/mnt/backups/db-dumps
mkdir -p $BACKUP_DIR
DATE=$(date +%Y%m%d)

# Vaultwarden
docker exec vaultwarden_db pg_dump -U vaultwarden vaultwarden > \
  $BACKUP_DIR/vaultwarden-$DATE.sql

# Psono
docker exec psono_db pg_dump -U psono psono > \
  $BACKUP_DIR/psono-$DATE.sql

# Passbolt
docker exec passbolt_db pg_dump -U passbolt passbolt > \
  $BACKUP_DIR/passbolt-$DATE.sql

# Delete dumps older than 7 days
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
```

Make executable:
```bash
chmod +x /opt/scripts/backup-databases.sh
```

Add to crontab:
```bash
crontab -e
# Add: Run daily at 1 AM (before Backrest at 2 AM)
0 1 * * * /opt/scripts/backup-databases.sh
```

Add `/mnt/backups/db-dumps` to Backrest backup plan.

## Restore Files

### Via Web UI

1. **Snapshots** tab
2. Select snapshot date
3. Click **Browse**
4. Navigate to file/folder
5. Click **Download** or **Restore**

### Via Command Line

```bash
# Restore specific file
docker exec -e RESTIC_PASSWORD=your_password backrest \
  restic -r /backups/repo1 restore latest \
  --target /restore \
  --include /backup-sources/opt/docker_vaultwarden/docker-compose.yml

# Restore entire directory
docker exec -e RESTIC_PASSWORD=your_password backrest \
  restic -r /backups/repo1 restore latest \
  --target /restore \
  --include /backup-sources/opt/docker_vaultwarden
```

## Troubleshooting

**Cannot access web UI?**
```bash
docker compose logs backrest
docker ps | grep backrest
nslookup backrest.do-it.media
```

**Backup fails?**
```bash
# Check logs
docker compose logs backrest

# Check disk space
df -h

# Check permissions
docker exec backrest ls -la /backup-sources
```

**Repository locked?**
```bash
docker exec -e RESTIC_PASSWORD=your_password backrest \
  restic -r /backups/repo1 unlock
```

**Forgot repository password?**
⚠️ **Cannot be recovered!** The data is encrypted.
Always save repository passwords securely.

## Security Tips

1. **Repository Password**:
   - Save in password manager
   - Never lose it (data is encrypted!)
   - Use strong, unique password

2. **Regular Testing**:
   - Test restore monthly
   - Verify snapshots exist
   - Check backup completion

3. **3-2-1 Rule**:
   - 3 copies of data
   - 2 different storage types
   - 1 offsite backup

4. **Monitor**:
   - Enable email notifications
   - Check dashboard weekly
   - Review backup logs

## What to Backup

**Essential** ✅:
- Docker application configs (`/opt/docker_*`)
- Docker volumes (`/var/lib/docker/volumes`)
- Database dumps (`/mnt/backups/db-dumps`)
- User data (`/home`)

**Optional** ⚠️:
- System configs (`/etc`)
- Web server data (`/var/www`)
- Logs (if needed)

**Exclude** ❌:
- Temporary files (`/tmp`)
- Cache directories
- System binaries (`/bin`, `/usr`)
- Large media (if backed up elsewhere)

## Next Steps

1. ✅ **Test restore** - Download a file to verify
2. ✅ **Set up cloud backup** - Add S3/B2 repository
3. ✅ **Configure notifications** - Get alerts on failures
4. ✅ **Schedule database dumps** - Before file backups
5. ✅ **Document recovery** - Write restore procedures
6. ✅ **Test disaster recovery** - Restore to test system

For detailed documentation, see [README.md](README.md)

---

**Remember**: A backup you haven't tested is Schrödinger's backup - it simultaneously exists and doesn't exist until you try to restore it! 🐱
