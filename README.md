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
