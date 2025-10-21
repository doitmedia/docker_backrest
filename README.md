# Backrest - Web UI for Restic Backups with Docker and Traefik

Backrest is a modern web-based UI and orchestrator for restic backup. It provides scheduled backups, monitoring, and easy restore functionality with support for local and cloud storage.

## Features

- **Web-based UI**: Easy-to-use interface for managing backups
- **Scheduled Backups**: Cron-based scheduling for automated backups
- **Multiple Repositories**: Support for multiple backup destinations
- **Cloud Storage**: S3, B2, Azure, Google Cloud, and more
- **Restic Backend**: Proven, secure, and efficient backup engine
- **Monitoring**: Real-time backup status and notifications
- **Easy Restore**: Browse and restore files from any snapshot
- **Docker-based**: Simple deployment with Docker Compose
- **Automatic HTTPS**: Traefik integration with Let's Encrypt

## Why Backrest?

| Feature | Backrest | Traditional Restic | Duplicati |
|---------|----------|-------------------|-----------|
| Web UI | ✅ Modern | ❌ CLI only | ✅ Yes |
| Scheduling | ✅ Built-in | ⚠️ Cron required | ✅ Built-in |
| Monitoring | ✅ Real-time | ❌ Manual | ✅ Yes |
| Restic Backend | ✅ Yes | ✅ Yes | ❌ Own format |
| Cloud Support | ✅ Extensive | ✅ Yes | ✅ Limited |
| Docker Native | ✅ Yes | ⚠️ Manual | ✅ Yes |
| Setup Complexity | Very Simple | Complex | Medium |

## Prerequisites

- Docker and Docker Compose installed
- Traefik reverse proxy running on `dim_network_traefik` network
- Domain pointing to your server (e.g., `backrest.do-it.media`)
- Backup storage location (local disk, NAS, or cloud storage)

## Quick Start

### 1. Clone or Copy Configuration

```bash
cd /opt/docker_backrest
```

### 2. Create Environment File

```bash
cp .env.example .env
nano .env
```

Configure the following values:

```bash
# Domain Configuration
BACKREST_DOMAIN=backrest.do-it.media

# Timezone
TZ=Europe/Berlin

# Local Backup Storage Path
BACKUP_STORAGE_PATH=/mnt/backups
```

### 3. Create Backup Storage Directory

```bash
sudo mkdir -p /mnt/backups
sudo chown -R dimdev:dimdev /mnt/backups
```

Or mount your NAS/external drive to `/mnt/backups`.

### 4. Initialize Backrest

```bash
./init-backrest.sh
```

### 5. Access Backrest

Open your browser and navigate to:
```
https://backrest.do-it.media
```

### 6. Configure First Repository

1. Click **"Add Repository"**
2. **Repository Name**: `local-backups`
3. **Repository Type**: Choose one:
   - **Local**: File system path
   - **S3**: Amazon S3 or compatible
   - **B2**: Backblaze B2
   - **Azure**: Azure Blob Storage
   - **GCS**: Google Cloud Storage
   - **SFTP**: Remote server via SSH

4. **For Local Storage**:
   - Path: `/backups/repo1`
   - Password: Generate strong password (save this!)

5. Click **"Initialize Repository"**

### 7. Create Backup Plan

1. Click **"Add Plan"**
2. **Plan Name**: `daily-docker-backup`
3. **Repository**: Select `local-backups`
4. **Paths to Backup**: Add paths from mounted volumes:
   ```
   /backup-sources/opt/docker_vaultwarden
   /backup-sources/opt/docker_psono
   /backup-sources/opt/docker_passbolt
   ```
5. **Schedule**: Cron expression
   - Daily at 2 AM: `0 2 * * *`
   - Every 6 hours: `0 */6 * * *`
   - Weekly on Sunday: `0 2 * * 0`

6. **Retention Policy**:
   - Keep last 7 daily backups
   - Keep last 4 weekly backups
   - Keep last 12 monthly backups

7. Click **"Save Plan"**

### 8. Run First Backup

1. Find your backup plan
2. Click **"Run Now"**
3. Monitor progress in the UI

### 9. Verify Backup

1. Go to **"Snapshots"** tab
2. Select a snapshot
3. Click **"Browse"** to view files
4. Test restore by downloading a file

## Architecture

```
┌─────────────────┐
│    Traefik      │
│  Reverse Proxy  │
└────────┬────────┘
         │ HTTPS (Let's Encrypt)
         │
    ┌────┴──────────┐
    │   Backrest    │
    │   Web UI      │
    │  (Port 9898)  │
    └───────┬───────┘
            │
    ┌───────┴───────────────────┐
    │                           │
┌───▼──────────┐      ┌─────────▼────────┐
│ Backup       │      │ Backup           │
│ Sources      │      │ Destinations     │
│ (mounted)    │      │ (repositories)   │
└──────────────┘      └──────────────────┘
│                     │
├─ /opt              ├─ Local: /backups
├─ Docker volumes    ├─ S3: s3.amazonaws.com
└─ Custom paths      ├─ B2: b2.backblaze.com
                     └─ SFTP: remote-server
```

## Container Details

### backrest
- **Image**: `garethgeorge/backrest:latest`
- **Purpose**: Web UI and backup orchestrator for restic
- **Port**: 9898 (internal only)
- **Volumes**:
  - `backrest_data`: Config and backup metadata
  - `backrest_cache`: Restic cache for performance
  - `/opt`: Backup source (read-only)
  - `/var/lib/docker/volumes`: Docker volumes (read-only)
  - `BACKUP_STORAGE_PATH`: Local backup destination

## Configuration

### Backup Sources

Edit `docker-compose.yml` to add/modify backup sources:

```yaml
volumes:
  # Add your custom paths here
  - /home:/backup-sources/home:ro
  - /etc:/backup-sources/etc:ro
  - /var/www:/backup-sources/var-www:ro
```

### Cloud Storage Setup

#### Amazon S3

```bash
# Add to .env
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_DEFAULT_REGION=us-east-1
```

In Backrest UI:
- Repository Type: **S3**
- Endpoint: `s3.amazonaws.com`
- Bucket: `your-bucket-name`
- Path: `/backups/server1`

#### Backblaze B2

```bash
# Add to .env
B2_ACCOUNT_ID=your_account_id
B2_ACCOUNT_KEY=your_account_key
```

In Backrest UI:
- Repository Type: **B2**
- Bucket: `your-bucket-name`
- Path: `/backups/server1`

#### Google Cloud Storage

```bash
# Add to .env
GOOGLE_PROJECT_ID=your_project_id
GOOGLE_APPLICATION_CREDENTIALS=/config/gcs-credentials.json
```

Copy service account JSON to container:
```bash
docker cp credentials.json backrest:/config/gcs-credentials.json
```

### Notification Setup

Configure email notifications in Backrest UI:

1. Go to **Settings**
2. Click **"Notifications"**
3. Add **SMTP** configuration:
   - Host: `mail.do-it.media`
   - Port: `587`
   - Username: `backrest@do-it.media`
   - Password: Your SMTP password
   - From: `backrest@do-it.media`
4. Set notification triggers:
   - On backup failure
   - On backup success (optional)

## Useful Commands

### View Logs

```bash
# Real-time logs
docker compose logs -f backrest

# Last 100 lines
docker compose logs --tail=100 backrest
```

### Restart Service

```bash
docker compose restart backrest
```

### Stop Service

```bash
docker compose down
```

### Update Backrest

```bash
docker compose pull
docker compose up -d
```

### Access Container Shell

```bash
docker exec -it backrest sh
```

### Manual Restic Commands

```bash
# List snapshots
docker exec backrest restic -r /backups/repo1 snapshots

# Check repository
docker exec backrest restic -r /backups/repo1 check

# Show repository stats
docker exec backrest restic -r /backups/repo1 stats
```

### Backup Backrest Configuration

```bash
# Backup config
docker cp backrest:/data/config.json ./backrest-config-backup.json

# Restore config
docker cp ./backrest-config-backup.json backrest:/data/config.json
docker compose restart backrest
```

## Backup Strategies

### 3-2-1 Backup Rule

- **3** copies of your data
- **2** different storage types
- **1** offsite backup

**Example Implementation:**

1. **Primary**: Original data on server
2. **Local Backup**: `/mnt/backups` on local NAS
3. **Cloud Backup**: Backblaze B2 or AWS S3

### Recommended Retention Policy

```
Daily backups:   Keep last 7 days
Weekly backups:  Keep last 4 weeks
Monthly backups: Keep last 12 months
Yearly backups:  Keep last 3 years
```

Configure in Backrest UI under Plan → Retention.

### What to Backup

**Essential:**
- Docker volumes: `/var/lib/docker/volumes`
- Application configs: `/opt/docker_*`
- Databases: Export dumps before backup
- User data: `/home`

**Optional:**
- System configs: `/etc`
- Web server data: `/var/www`
- Logs: `/var/log` (if needed)

**Exclude:**
- Temporary files: `/tmp`, `/var/tmp`
- Cache: `/var/cache`
- System binaries: `/bin`, `/sbin`, `/usr`

## Database Backups

For databases, export dumps before backing up:

### PostgreSQL

```bash
# Vaultwarden database
docker exec vaultwarden_db pg_dump -U vaultwarden vaultwarden > /mnt/backups/dumps/vaultwarden.sql

# Schedule with cron
0 1 * * * docker exec vaultwarden_db pg_dump -U vaultwarden vaultwarden > /mnt/backups/dumps/vaultwarden-$(date +\%Y\%m\%d).sql
```

Add `/mnt/backups/dumps` to Backrest backup plan.

## Restore Procedures

### Restore Single File

1. Go to **Snapshots** tab
2. Select snapshot date
3. Click **Browse**
4. Navigate to file
5. Click **Download** or **Restore**

### Restore Entire Directory

Via Backrest UI:
1. Select snapshot
2. Select directory
3. Click **Restore to Original Location** or **Custom Location**

Via CLI:
```bash
docker exec -e RESTIC_PASSWORD=your_password backrest \
  restic -r /backups/repo1 restore latest \
  --target /restore \
  --include /backup-sources/opt/docker_vaultwarden
```

### Disaster Recovery

Complete system restore:

1. **Install fresh system**
2. **Install Docker and Backrest**
3. **Configure repository** (same password!)
4. **Browse snapshots** to verify
5. **Restore data** to original locations
6. **Start services** and verify

## Security Best Practices

1. **Repository Passwords**:
   - Use strong, unique passwords
   - Store in password manager
   - Never commit to Git

2. **Encryption**:
   - Restic encrypts all backups by default
   - Encryption keys derived from repository password

3. **Access Control**:
   - Use Traefik basic auth for additional security
   - Limit access by IP if possible
   - Use strong passwords

4. **Regular Testing**:
   - Test restore procedures monthly
   - Verify backup integrity
   - Check notification alerts

5. **Offsite Backups**:
   - Always maintain cloud/offsite copy
   - Different location from primary data
   - Protected from local disasters

## Troubleshooting

### Backup Fails with "Permission Denied"

Container runs as root but may need access to protected files:

```bash
# Check file permissions
ls -la /path/to/backup/source

# Fix permissions if needed (be careful!)
sudo chmod -R +r /path/to/backup/source
```

### Repository Locked

```bash
# Unlock repository
docker exec -e RESTIC_PASSWORD=your_password backrest \
  restic -r /backups/repo1 unlock
```

### Slow Backups

1. **Increase cache size**: More disk space for restic cache
2. **Exclude unnecessary files**: Add exclusions in backup plan
3. **Use compression**: Enable in repository settings
4. **Network bandwidth**: Check if using cloud storage

### Cannot Access Web UI

1. Check if container is running:
```bash
docker ps | grep backrest
```

2. Check container logs:
```bash
docker compose logs backrest
```

3. Verify Traefik is running:
```bash
docker ps | grep traefik
```

4. Check DNS resolution:
```bash
nslookup backrest.do-it.media
```

### Restore Fails

1. **Check repository password**: Must match original
2. **Verify snapshot exists**: Check snapshots tab
3. **Check disk space**: Ensure enough space for restore
4. **Check permissions**: Restore location must be writable

## Performance Optimization

### Restic Cache

Larger cache improves performance:

```yaml
# In docker-compose.yml
environment:
  RESTIC_CACHE_SIZE: "4096"  # MB
```

### Parallel Uploads

For cloud storage:

```yaml
environment:
  RESTIC_PARALLEL: "4"  # Number of parallel uploads
```

### Compression

Enable in repository settings for smaller backups (trades CPU for storage).

## Monitoring

### Check Backup Status

1. **Dashboard**: View all plans and last run status
2. **Snapshots**: Verify recent backups exist
3. **Logs**: Review backup logs for errors
4. **Notifications**: Configure email alerts

### Prometheus/Grafana (Advanced)

Backrest can export metrics for monitoring:

```yaml
# Add to docker-compose.yml
environment:
  BACKREST_PROMETHEUS_ENABLED: "true"
  BACKREST_PROMETHEUS_PORT: "9090"
```

## Resources

- [Backrest GitHub](https://github.com/garethgeorge/backrest)
- [Backrest Documentation](https://github.com/garethgeorge/backrest/wiki)
- [Restic Documentation](https://restic.readthedocs.io/)
- [Docker Hub - Backrest](https://hub.docker.com/r/garethgeorge/backrest)

## Support

For issues with:
- **Backrest**: [GitHub Issues](https://github.com/garethgeorge/backrest/issues)
- **Restic**: [Restic Forum](https://forum.restic.net/)
- **This setup**: Check logs and troubleshooting section above

## License

Backrest is open-source software. Check the [GitHub repository](https://github.com/garethgeorge/backrest) for license details.

---

**Remember**: Test your backups regularly. A backup you can't restore is useless!
