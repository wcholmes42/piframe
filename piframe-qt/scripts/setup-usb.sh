#!/bin/bash
#
# USB Auto-Mount Setup for Photo Cache
# Sets up automatic mounting of USB drive for photo storage
#

set -e

echo "======================================"
echo "  USB Auto-Mount Setup"
echo "======================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Detect USB drive
echo "Scanning for USB drives..."
USB_DEVICES=$(lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,LABEL | grep disk | grep -v "mmcblk" || true)

if [ -z "$USB_DEVICES" ]; then
    echo "No USB drives detected."
    echo "Please insert a USB drive and run this script again."
    exit 1
fi

echo ""
echo "Available USB devices:"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,LABEL,FSTYPE | grep -v "mmcblk"
echo ""

# Auto-detect first USB partition
USB_PARTITION=$(lsblk -nro NAME,TYPE | grep part | grep -v "mmcblk" | head -1 | awk '{print $1}')

if [ -z "$USB_PARTITION" ]; then
    echo "No USB partitions found. Creating partition..."
    USB_DEVICE=$(lsblk -nro NAME,TYPE | grep disk | grep -v "mmcblk" | head -1 | awk '{print $1}')

    if [ -z "$USB_DEVICE" ]; then
        echo "Error: No USB device found"
        exit 1
    fi

    echo "Partitioning /dev/$USB_DEVICE..."
    echo "WARNING: This will erase all data on the USB drive!"
    read -p "Continue? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "Aborted."
        exit 1
    fi

    # Create partition table and format
    parted -s /dev/$USB_DEVICE mklabel gpt
    parted -s /dev/$USB_DEVICE mkpart primary ext4 0% 100%
    sleep 2

    # Format as ext4
    mkfs.ext4 -F -L "piframe-cache" /dev/${USB_DEVICE}1
    USB_PARTITION="${USB_DEVICE}1"
fi

echo ""
echo "Using partition: /dev/$USB_PARTITION"

# Get UUID
USB_UUID=$(blkid -s UUID -o value /dev/$USB_PARTITION)
echo "UUID: $USB_UUID"

# Create mount point
MOUNT_POINT="/mnt/photocache"
mkdir -p $MOUNT_POINT

# Add to fstab if not already present
if ! grep -q "$USB_UUID" /etc/fstab; then
    echo "Adding to /etc/fstab..."
    echo "UUID=$USB_UUID $MOUNT_POINT ext4 defaults,noatime,nofail 0 2" >> /etc/fstab
else
    echo "Already in /etc/fstab"
fi

# Mount
echo "Mounting..."
mount -a

# Verify mount
if mountpoint -q $MOUNT_POINT; then
    echo "Successfully mounted at $MOUNT_POINT"
    df -h $MOUNT_POINT
else
    echo "Error: Failed to mount"
    exit 1
fi

# Create brightness directories
echo ""
echo "Creating photo cache directories..."
mkdir -p $MOUNT_POINT/bright
mkdir -p $MOUNT_POINT/medium
mkdir -p $MOUNT_POINT/dim
chown -R root:root $MOUNT_POINT
chmod -R 755 $MOUNT_POINT

echo ""
echo "======================================"
echo "  USB Setup Complete!"
echo "======================================"
echo ""
echo "USB drive mounted at: $MOUNT_POINT"
echo "Available space:"
df -h $MOUNT_POINT
echo ""
echo "Next: Run photo sync to populate cache"
echo "  sudo /opt/piframe/sync-photos.sh"
echo ""
