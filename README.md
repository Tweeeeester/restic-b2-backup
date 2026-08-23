# Restic B2 Backup
[![Docker Pulls](https://img.shields.io/badge/github-repo-blue?logo=github)](https://github.com/Tweeeeester/restic-b2-backup)
[![Docker Pulls](https://img.shields.io/docker/v/tweeeeester/restic-b2-backup?sort=semver)](https://hub.docker.com/r/tweeeeester/restic-b2-backup)
___

Simple docker build to run backups with Restic and Backblaze B2 

## .ENV
```commandline
RESTIC_HOST="HOST_NAME"
RESTIC_PASSWORD="XXXXXXXXXXXXXXXXXXXXXXXXX"
RESTIC_PRUNE="--keep-daily 30 --keep-weekly 4 --keep-monthly 12"

B2_BUCKET="BUCKET_NAME"
B2_ACCOUNT="XXXXXXXXXXXXXXXXXXXXXXXXX"
B2_KEY="XXXXXXXXXXXXXXXXXXXXXXXXX"
```

`B2_ACCOUNT`/`B2_KEY` should be a scoped application key restricted to the target bucket, not your B2 master key. `scripts/create-b2-rclone-key.sh` mints one with just the capabilities rclone's sync needs (`listBuckets,listFiles,writeFiles,deleteFiles` — no `readFiles`, so the key can't be used to read/download backed-up data).

```bash
./scripts/create-b2-rclone-key.sh <bucket-name> [key-name]
```

You'll be prompted for your B2 master `applicationKeyId`/`applicationKey` (from the B2 web UI's App Keys page). The script prints the new key's `keyID` and `applicationKey` — use those as `B2_ACCOUNT` and `B2_KEY`.

### Backing up to multiple buckets

B2 application keys can only be scoped two ways: restricted to **one** bucket, or **account-wide** (every bucket on the account, including any created later — there's no "these N buckets" option). By default the script creates a single-bucket key, which is the safer choice — running it once per bucket, each producing its own `B2_ACCOUNT`/`B2_KEY` pair, keeps a compromised key limited to one bucket's data.

If you'd rather use one key across multiple buckets, pass `--all-buckets` instead of a bucket name:

```bash
./scripts/create-b2-rclone-key.sh --all-buckets [key-name]

# Example
./scripts/create-b2-rclone-key.sh --all-buckets rclone-sync-key-all
```

This still grants only `listBuckets,listFiles,writeFiles,deleteFiles` (no `readFiles`), but that write/delete access now applies account-wide — a leaked key can write or delete in *every* bucket on the account, not just the one this tool backs up. Only use `--all-buckets` if you specifically need a single key shared across buckets and accept that broader blast radius.

## Docker Compose
### Docker Hub Image
```docker
services:
  restic-b2-backup:
    env_file: .env
    image: tweeeeester/restic-b2-backup:latest
    volumes:
      - "/path/to/my/restic/repo:/app/repo"
      - "/path/to/my/backup/files_1:/app/backup/files_1"
      - "/path/to/my/backup/files_2:/app/backup/files_2"
```

### Build From Scratch
```docker
services:
  restic-b2-backup:
    build:
      context: .
      args:
        RESTIC_VERISON: 0.18.1
        RCLONE_VERSION: 1.73.2
    env_file: .env
    image: tweeeeester/restic-b2-backup:1.0.0
    volumes:
      - "/path/to/my/restic/repo:/app/repo"
      - "/path/to/my/backup/files_1:/app/backup/files_1"
      - "/path/to/my/backup/files_2:/app/backup/files_2"
```
## Volumes
- The restic repo location should be mounted to `/app/repo`.
- All backup folder locations should be mounted to `/app/backup`
