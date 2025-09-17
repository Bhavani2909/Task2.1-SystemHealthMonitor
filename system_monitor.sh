#!/bin/bash

# Threshold values
CPU_THRESHOLD=80
MEM_THRESHOLD=80
DISK_THRESHOLD=90

# Log file
LOGFILE="/home/bhavani/system_monitor.log"

# Function to log messages with timestamp
log() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') $message" | tee -a "$LOGFILE"
}

# CPU usage (integer)
get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | awk '{print int(100 - $8)}'
}

# Memory usage (integer)
get_mem_usage() {
    free | awk '/Mem/ {printf "%d", $3/$2 * 100}'
}

# Disk usage (root /)
get_disk_usage() {
    df / | awk 'NR==2 {gsub("%","",$5); print $5}'
}

# Main function
main() {
    log "=== System Health Check Starting ==="

    cpu_usage=$(get_cpu_usage)
    mem_usage=$(get_mem_usage)
    disk_usage=$(get_disk_usage)

    log "CPU usage: $cpu_usage% (threshold $CPU_THRESHOLD%)"
    log "Memory usage: $mem_usage% (threshold $MEM_THRESHOLD%)"
    log "Disk usage: $disk_usage% (threshold $DISK_THRESHOLD%)"

    ALERT=0

    # CPU check
    if (( cpu_usage > CPU_THRESHOLD )); then
        log "ALERT: CPU usage too high!"
        ALERT=1
    fi

    # Memory check
    if (( mem_usage > MEM_THRESHOLD )); then
        log "ALERT: Memory usage too high!"
        ALERT=1
    fi

    # Disk check
    if (( disk_usage > DISK_THRESHOLD )); then
        log "ALERT: Disk usage too high!"
        ALERT=1
    fi

    # Check high resource processes
    TOP_PROCESSES=$(ps -eo pid,comm,%cpu,%mem --sort=-%cpu | awk 'NR>1 && ($3>30 || $4>50){print}')
    if [ -n "$TOP_PROCESSES" ]; then
        log "ALERT: High resource processes detected:"
        echo "$TOP_PROCESSES" | while read line; do log "$line"; done
        ALERT=1
    else
        log "No processes exceeding 30% CPU or 50% MEM found."
    fi

    # System OK if no alerts
    if [ $ALERT -eq 0 ]; then
        log "System OK — no alerts."
    fi

    log "=== System Health Check Finished ==="
}

# Run main
main

