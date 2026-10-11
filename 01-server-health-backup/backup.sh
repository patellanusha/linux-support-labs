#!/bin/bash
# backup.sh - rsync backup with 7-day retention and logging
SRC="$HOME/data"
DEST="$HOME/backups"
KEEP_DAYS=7
LOG="$HOME/logs/backup.log"
TS=$(date +%F_%H%M%S)
mkdir -p "$DEST" "$(dirname "$LOG")"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] $2" | tee -a "$LOG"; }

if [ ! -d "$SRC" ]; then log ERROR "Source $SRC not found"; exit 1; fi

if rsync -a "$SRC/" "$DEST/backup_$TS/"; then
  log OK "Backup created: backup_$TS"
else
  log ERROR "rsync failed with exit code $?"; exit 1
fi

find "$DEST" -maxdepth 1 -type d -name 'backup_*' -mtime +"$KEEP_DAYS" -exec rm -rf {} + \
  && log OK "Retention cleanup done (older than $KEEP_DAYS days)"
