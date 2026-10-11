#!/bin/bash
# restore.sh - restore one file from a named backup and verify it
# usage: ./restore.sh <backup_folder_name> <file_name>
BACKUPS="$HOME/backups"
DEST="$HOME/data"
LOG="$HOME/logs/restore.log"
mkdir -p "$(dirname "$LOG")"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] $2" | tee -a "$LOG"; }

if [ $# -ne 2 ]; then echo "Usage: $0 <backup_name> <file_name>"; exit 1; fi

SRC_FILE="$BACKUPS/$1/$2"
if [ ! -f "$SRC_FILE" ]; then log ERROR "$SRC_FILE not found"; exit 1; fi

if rsync -a "$SRC_FILE" "$DEST/"; then
  if diff -q "$SRC_FILE" "$DEST/$2" > /dev/null; then
    log OK "Restored $2 from $1 and contents verified"
  else
    log ERROR "Restored $2 but contents differ from backup"; exit 1
  fi
else
  log ERROR "rsync failed with exit code $?"; exit 1
fi
