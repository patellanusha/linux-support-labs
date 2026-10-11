#!/bin/bash
# health_check.sh - checks disk, memory, CPU load and services
DISK_LIMIT=80
MEM_LIMIT=80
LOAD_LIMIT=2.0
SERVICES=("ssh" "cron")
LOG_DIR="$HOME/logs"
LOG_FILE="$LOG_DIR/health.log"
mkdir -p "$LOG_DIR"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] $2" | tee -a "$LOG_FILE"; }

disk=$(df / | awk 'NR==2 {gsub("%",""); print $5}')
mem=$(free | awk '/Mem:/ {printf "%d", ($2-$7)/$2*100}')
load=$(awk '{print $1}' /proc/loadavg)

if [ "$disk" -ge "$DISK_LIMIT" ]; then log WARN "Disk usage ${disk}%"; else log OK "Disk usage ${disk}%"; fi
if [ "$mem" -ge "$MEM_LIMIT" ]; then log WARN "Memory usage ${mem}%"; else log OK "Memory usage ${mem}%"; fi
if awk -v l="$load" -v m="$LOAD_LIMIT" 'BEGIN{exit !(l>m)}'; then log WARN "Load average ${load}"; else log OK "Load average ${load}"; fi

for s in "${SERVICES[@]}"; do
  if systemctl is-active --quiet "$s"; then log OK "Service $s running"; else log ERROR "Service $s NOT running"; fi
done
