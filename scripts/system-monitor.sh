#!/usr/bin/env bash
# system-monitor.sh - basic system health report (macOS and Linux).
# Prints: date/time, hostname, CPU, memory, disk, uptime.
# Output is shown on screen AND appended to logs/system-monitor.log.
#
# Usage: ./scripts/system-monitor.sh [log_file]

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${1:-$SCRIPT_DIR/../logs/system-monitor.log}"
mkdir -p "$(dirname "$LOG_FILE")"

OS="$(uname -s)"

cpu_usage() {
  if [ "$OS" = "Darwin" ]; then
    # top -l 2 gives a real sample on the 2nd iteration
    top -l 2 -n 0 -s 1 | awk '/^CPU usage/ {line=$0} END {print line}' | sed 's/^CPU usage: //'
  else
    top -bn1 | awk '/Cpu\(s\)/ {print $0; exit}'
  fi
}

memory_usage() {
  if [ "$OS" = "Darwin" ]; then
    local page_size total_bytes free_pages active inactive wired
    page_size="$(vm_stat | awk '/page size of/ {print $8}')"
    total_bytes="$(sysctl -n hw.memsize)"
    free_pages="$(vm_stat | awk '/Pages free/ {gsub("\\.","",$3); print $3}')"
    active="$(vm_stat | awk '/Pages active/ {gsub("\\.","",$3); print $3}')"
    inactive="$(vm_stat | awk '/Pages inactive/ {gsub("\\.","",$3); print $3}')"
    wired="$(vm_stat | awk '/Pages wired down/ {gsub("\\.","",$4); print $4}')"
    awk -v ps="$page_size" -v tot="$total_bytes" -v f="$free_pages" -v a="$active" -v i="$inactive" -v w="$wired" 'BEGIN {
      used = (a + w) * ps; free = (f + i) * ps;
      printf "Total: %.2f GB | Used: %.2f GB (%.1f%%) | Free/Reclaimable: %.2f GB\n",
        tot/1073741824, used/1073741824, used*100/tot, free/1073741824
    }'
  else
    free -h
  fi
}

report() {
  echo "=============================================="
  echo " System Monitor Report"
  echo "=============================================="
  echo "Date/Time : $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo "Hostname  : $(hostname)"
  echo "CPU Usage : $(cpu_usage)"
  echo "Memory    : $(memory_usage)"
  echo "Disk Usage (/):"
  df -h / | sed 's/^/  /'
  echo "Uptime    : $(uptime)"
  echo
}

report | tee -a "$LOG_FILE"
echo "Saved to: $LOG_FILE"
