#!/bin/bash
#
# Photo Sync Script
# Syncs optimized photos from Unraid server to local USB cache
#

# Load configuration
CONFIG_FILE="/opt/piframe/config.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found: $CONFIG_FILE"
    exit 1
fi

# Parse JSON config (requires jq, or use grep fallback)
if command -v jq &> /dev/null; then
    UNRAID_HOST=$(jq -r '.network.unraid_host' $CONFIG_FILE)
    UNRAID_SHARE=$(jq -r '.network.unraid_share' $CONFIG_FILE)
    USB_MOUNT=$(jq -r '.storage.usb_mount' $CONFIG_FILE)
else
    # Fallback parsing without jq
    UNRAID_HOST=$(grep -oP '"unraid_host":\s*"\K[^"]+' $CONFIG_FILE)
    UNRAID_SHARE=$(grep -oP '"unraid_share":\s*"\K[^"]+' $CONFIG_FILE)
    USB_MOUNT=$(grep -oP '"usb_mount":\s*"\K[^"]+' $CONFIG_FILE)
fi

# Defaults if parsing failed
UNRAID_HOST=${UNRAID_HOST:-"192.168.68.42"}
UNRAID_SHARE=${UNRAID_SHARE:-"Pics/Frame-Optimized"}
USB_MOUNT=${USB_MOUNT:-"/mnt/photocache"}

echo "======================================"
echo "  PiFrame Photo Sync"
echo "======================================"
echo "Source: //$UNRAID_HOST/$UNRAID_SHARE"
echo "Target: $USB_MOUNT"
echo "Started: $(date)"
echo ""

# Check if mount point exists and is writable
if [ ! -d "$USB_MOUNT" ]; then
    echo "Error: Mount point does not exist: $USB_MOUNT"
    exit 1
fi

if [ ! -w "$USB_MOUNT" ]; then
    echo "Error: Mount point is not writable: $USB_MOUNT"
    exit 1
fi

# Check if Unraid server is reachable
if ! ping -c 1 -W 2 $UNRAID_HOST > /dev/null 2>&1; then
    echo "Warning: Unraid server $UNRAID_HOST is not reachable"
    echo "Skipping sync..."
    exit 0
fi

# Create temporary mount point for CIFS
TEMP_MOUNT="/tmp/piframe-unraid"
mkdir -p $TEMP_MOUNT

# Mount Unraid share
echo "Mounting Unraid share..."
if mount -t cifs -o guest,ro "//$UNRAID_HOST/$UNRAID_SHARE" $TEMP_MOUNT 2>/dev/null; then
    echo "Mounted successfully"
else
    echo "Failed to mount Unraid share"
    echo "Trying with different options..."

    # Try without guest
    if mount -t cifs -o username=,password=,ro "//$UNRAID_HOST/$UNRAID_SHARE" $TEMP_MOUNT 2>/dev/null; then
        echo "Mounted successfully (no auth)"
    else
        echo "Error: Could not mount Unraid share"
        rmdir $TEMP_MOUNT
        exit 1
    fi
fi

# Sync photos using rsync
echo ""
echo "Syncing photos..."
echo "This may take a while on first run..."
echo ""

# Sync each brightness level
for LEVEL in bright medium dim; do
    echo "Syncing $LEVEL photos..."

    if [ -d "$TEMP_MOUNT/$LEVEL" ]; then
        rsync -av --delete \
            --progress \
            --stats \
            --exclude=".*" \
            --exclude="Thumbs.db" \
            "$TEMP_MOUNT/$LEVEL/" \
            "$USB_MOUNT/$LEVEL/" 2>&1 | grep -v "sending incremental"
    else
        echo "Warning: $LEVEL directory not found on Unraid"
    fi

    echo ""
done

# Unmount Unraid share
echo "Unmounting Unraid share..."
umount $TEMP_MOUNT
rmdir $TEMP_MOUNT

# Count synced photos
PHOTO_COUNT=$(find $USB_MOUNT -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | wc -l)

echo ""
echo "======================================"
echo "  Sync Complete!"
echo "======================================"
echo "Total photos: $PHOTO_COUNT"
echo "Completed: $(date)"
echo ""

# Show disk usage
df -h $USB_MOUNT

exit 0
