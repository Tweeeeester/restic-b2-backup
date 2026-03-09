#!/bin/sh

# Setup Environment Variables
export RESTIC_REPOSITORY=/app/repo

# Initialize Repository
if restic cat config >/dev/null 2>&1; then
    echo "Restic repository already initialized."
else
    echo "Restic repository not found, initializing..."
    restic init
fi

# Change to backup directory
# Ensures restic uses expected folder structure with /app/backup/ as the root dir
cd /app/backup/

# Backup
restic backup .

# Prune
if [ -n "$RESTIC_PRUNE" ]; then
  echo "Prune with the following command: restic forget $RESTIC_PRUNE --prune"
  restic forget $RESTIC_PRUNE --prune
fi

# Sync
if [ -n "$B2_BUCKET" ]; then
  echo "Sync with B2 using the following command: rclone sync $RESTIC_REPOSITORY :b2:$B2_BUCKET --b2-account '$B2_ACCOUNT' --b2-key 'XXX' --fast-list --b2-hard-delete --transfers 10"
  rclone sync $RESTIC_REPOSITORY :b2:$B2_BUCKET --b2-account "$B2_ACCOUNT" --b2-key "$B2_KEY" --fast-list --b2-hard-delete --transfers 10
fi

