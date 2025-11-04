#!/bin/bash
# PiFrame Connection Monitor
# Checks NFS mount health and attempts recovery

NFS_MOUNT="/mnt/photos"
NFS_SERVER="192.168.68.42:/mnt/user/Pics/Frame-Optimized"
UNRAID_API="http://192.168.68.42:5000"
REBOOT_FLAG="/tmp/piframe-rebooted"
MAX_RETRIES=3
RETRY_DELAY=10

check_mount() {
    # Check if mount exists and is accessible
    if mountpoint -q "$NFS_MOUNT" && ls "$NFS_MOUNT" >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

show_warning() {
    local message="$1"
    curl -s -X POST "$UNRAID_API/api/overlay" \
        -H 'Content-Type: application/json' \
        -d "{\"text\":\"$message\",\"startTime\":\"\",\"endTime\":\"\"}" >/dev/null 2>&1
}

clear_warning() {
    curl -s -X DELETE "$UNRAID_API/api/overlay" >/dev/null 2>&1
}

# Main check
if check_mount; then
    # Mount is healthy, clear any warnings
    clear_warning
    rm -f "$REBOOT_FLAG" 2>/dev/null
    exit 0
fi

# Mount is unhealthy - show warning and try to recover
show_warning "NFS Connection Lost - Attempting Recovery..."

# Try to remount (with retries)
for i in $(seq 1 $MAX_RETRIES); do
    echo "Remount attempt $i of $MAX_RETRIES..."

    # Unmount if stale
    umount -f "$NFS_MOUNT" 2>/dev/null
    sleep 2

    # Try to mount
    mount -t nfs -o vers=3,nolock "$NFS_SERVER" "$NFS_MOUNT" 2>/dev/null

    sleep $RETRY_DELAY

    # Check if successful
    if check_mount; then
        echo "Remount successful on attempt $i"
        clear_warning
        rm -f "$REBOOT_FLAG" 2>/dev/null
        exit 0
    fi
done

# All retries failed - check if we've already rebooted
if [ -f "$REBOOT_FLAG" ]; then
    # We already rebooted once, don't do it again
    show_warning "CRITICAL: NFS Mount Failed - Manual Intervention Required"
    echo "NFS mount permanently failed. Manual intervention required."
    exit 1
fi

# Mark that we're about to reboot
touch "$REBOOT_FLAG"
show_warning "NFS Mount Failed - Rebooting Pi..."
sleep 5

# Reboot to try fresh network/mount initialization
reboot
