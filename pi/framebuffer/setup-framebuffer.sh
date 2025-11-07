#!/bin/bash
# PiFrame Framebuffer Setup Script
# Installs direct framebuffer slideshow (no X11)

set -e

UNRAID_IP="${1:-192.168.68.42}"
PHOTO_SOURCE="Pics/Frame-Optimized"

echo "================================"
echo "PiFrame Framebuffer Setup"
echo "================================"
echo ""

# Install dependencies
echo "[1/8] Installing dependencies..."
apt-get update
apt-get install -y python3-pip python3-pil python3-flask cifs-utils

# Create directories
echo "[2/8] Creating directories..."
mkdir -p /opt/piframe
mkdir -p /etc/piframe
mkdir -p /mnt/photos

# Copy application files
echo "[3/8] Installing application files..."
cp slideshow.py /opt/piframe/
cp api.py /opt/piframe/
cp config.json /etc/piframe/
chmod +x /opt/piframe/*.py

# Setup NFS mount for photo folders
echo "[4/8] Configuring network mount..."
if ! grep -q "$UNRAID_IP" /etc/fstab; then
    echo "//$UNRAID_IP/$PHOTO_SOURCE /mnt/photos cifs guest,uid=0,iocharset=utf8,cache=none,noperm 0 0" >> /etc/fstab
fi
mount -a

# Verify mount and folders
if [ ! -d "/mnt/photos/bright" ]; then
    echo "ERROR: /mnt/photos/bright not found. Check Unraid mount."
    exit 1
fi

echo "   Found brightness folders:"
ls -d /mnt/photos/*/ | xargs -n1 basename

# Configure framebuffer for 32bpp
echo "[5/8] Configuring framebuffer..."
if ! grep -q "video=HDMI-A-1:-32" /boot/firmware/cmdline.txt; then
    sed -i '1s/$/ video=HDMI-A-1:-32/' /boot/firmware/cmdline.txt
    echo "   32bpp framebuffer configured (requires reboot)"
fi

# Disable X11 autostart
echo "[6/8] Disabling X11..."
# Set DietPi to boot to console
dietpi-autostart 7 2>/dev/null || true

# Remove X11 packages to save space (optional)
# apt-get remove -y xserver-xorg xinit chromium-browser || true

# Install systemd services
echo "[7/8] Installing systemd services..."
cp piframe-slideshow.service /etc/systemd/system/
cp piframe-api.service /etc/systemd/system/

systemctl daemon-reload
systemctl enable piframe-slideshow
systemctl enable piframe-api

# Update cron for shutdown
echo "[8/8] Configuring shutdown schedule..."
(crontab -l 2>/dev/null | grep -v "shutdown"; cat << CRON
# Shutdown at 7:30 PM for smart switch power-off
30 19 * * * /sbin/shutdown -h now
CRON
) | crontab -

# Enable NTP
timedatectl set-ntp true

echo ""
echo "================================"
echo "Framebuffer Setup Complete!"
echo "================================"
echo ""
echo "Configuration:"
echo "  Photos: /mnt/photos/{bright,medium,dim}"
echo "  API: http://$(hostname -I | awk '{print $1}'):5000"
echo "  Config: /etc/piframe/config.json"
echo ""
echo "Services installed:"
echo "  - piframe-slideshow (framebuffer display)"
echo "  - piframe-api (Flask control API)"
echo ""
echo "IMPORTANT: Reboot required for framebuffer changes"
echo ""
read -p "Reboot now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    reboot
fi
