Next Steps

  1. Create Backup Storage

  # For local storage
  sudo mkdir -p /mnt/backups
  sudo chown dimdev:dimdev /mnt/backups

  2. Configure Environment

  cd /opt/docker_backrest
  cp .env.example .env
  nano .env

  Update:
  BACKREST_DOMAIN=backrest.do-it.media
  BACKUP_STORAGE_PATH=/mnt/backups

  3. Start Backrest

  ./init-backrest.sh

  4. Access Web UI

  Open: https://backrest.do-it.media

  5. Create Repository

  1. Click "Add Repository"
  2. Type: Local
  3. Path: /backups/repo1
  4. Password: Generate with openssl rand -base64 
  32 (SAVE THIS!)

  6. Create Backup Plan

  1. Click "Add Plan"
  2. Repository: Select your repository
  3. Paths to backup:
  /backup-sources/opt/docker_vaultwarden
  /backup-sources/opt/docker_psono
  /backup-sources/opt/docker_passbolt
  4. Schedule: 0 2 * * * (Daily at 2 AM)
  5. Retention: Keep 7 daily, 4 weekly, 12 monthly

  7. Run First Backup

  Click "Run Now" and verify it completes
  successfully!

  Backup Strategy Included

  The setup supports the 3-2-1 backup rule:
  - 3 copies of data
  - 2 different storage types (local + cloud)
  - 1 offsite backup

  Example:
  1. Original data on server
  2. Local backup to /mnt/backups (NAS)
  3. Cloud backup to Backblaze B2 or AWS S3

  Database Backup Recommendation

  The QUICK_START.md includes a script to backup
  all your PostgreSQL databases before file backups
   run. This ensures consistent database backups!

  Check the QUICK_START.md for the complete
  10-minute setup guide or README.md for
  comprehensive documentation including cloud
  storage setup, restore procedures, and
  troubleshooting!