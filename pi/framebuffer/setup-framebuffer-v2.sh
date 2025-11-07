#!/bin/bash
# PiFrame Framebuffer Setup Script - v2 Robust Edition
# Installs direct framebuffer slideshow (no X11)

set -e

UNRAID_IP="${1:-192.168.68.42}"
PHOTO_SOURCE="Pics/Frame-Optimized"

echo "================================"
echo "PiFrame Framebuffer Setup v2"
echo "================================"
echo ""

# Install dependencies
echo "[1/9] Installing dependencies..."
apt-get update
apt-get install -y python3-pip python3-pil python3-flask cifs-utils nfs-common

# Create directories
echo "[2/9] Creating directories..."
mkdir -p /opt/piframe
mkdir -p /etc/piframe
mkdir -p /mnt/photos
mkdir -p /var/log

# Copy application files
echo "[3/9] Installing application files..."
cp slideshow-v2.py /opt/piframe/slideshow.py
cp api-v2.py /opt/piframe/api.py
cp config-v2.json /etc/piframe/config.json
chmod +x /opt/piframe/*.py

# Setup mount for photo folders
echo "[4/9] Configuring network mount..."
# Remove old mounts
sed -i "/$UNRAID_IP/d" /etc/fstab

# Add new mount
echo "//$UNRAID_IP/$PHOTO_SOURCE /mnt/photos cifs guest,uid=0,iocharset=utf8,cache=none,noperm 0 0" >> /etc/fstab

# Unmount if already mounted
umount /mnt/photos 2>/dev/null || true

# Mount
mount /mnt/photos || {
    echo "ERROR: Failed to mount /mnt/photos"
    echo "Check that Unraid is accessible at $UNRAID_IP"
    exit 1
}

# Verify folders
if [ ! -d "/mnt/photos/bright" ] || [ ! -d "/mnt/photos/medium" ] || [ ! -d "/mnt/photos/dim" ]; then
    echo "ERROR: Brightness folders not found in /mnt/photos"
    echo "Expected: bright/, medium/, dim/"
    ls -la /mnt/photos/
    exit 1
fi

echo "   Found brightness folders:"
ls -d /mnt/photos/*/ 2>/dev/null | xargs -n1 basename || echo "   (none found)"

# Count photos
BRIGHT_COUNT=$(ls /mnt/photos/bright/*.png 2>/dev/null | wc -l)
MEDIUM_COUNT=$(ls /mnt/photos/medium/*.png 2>/dev/null | wc -l)
DIM_COUNT=$(ls /mnt/photos/dim/*.png 2>/dev/null | wc -l)

echo "   Photo counts:"
echo "     bright: $BRIGHT_COUNT"
echo "     medium: $MEDIUM_COUNT"
echo "     dim: $DIM_COUNT"

if [ "$BRIGHT_COUNT" -eq 0 ]; then
    echo "ERROR: No photos found in /mnt/photos/bright/"
    exit 1
fi

# Configure framebuffer for 32bpp
echo "[5/9] Configuring framebuffer..."
if ! grep -q "video=HDMI-A-1:-32" /boot/firmware/cmdline.txt; then
    cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.backup
    sed -i '1s/$/ video=HDMI-A-1:-32/' /boot/firmware/cmdline.txt
    echo "   32bpp framebuffer configured (requires reboot)"
    NEED_REBOOT=true
else
    echo "   Framebuffer already configured"
    NEED_REBOOT=false
fi

# Disable X11 autostart
echo "[6/9] Disabling X11..."
systemctl disable lightdm 2>/dev/null || true
systemctl stop lightdm 2>/dev/null || true

# Set DietPi to boot to console
if command -v dietpi-autostart &> /dev/null; then
    dietpi-autostart 7 2>/dev/null || true
fi

# Install systemd services
echo "[7/9] Installing systemd services..."
cat > /etc/systemd/system/piframe-slideshow.service << 'EOF'
[Unit]
Description=PiFrame Framebuffer Slideshow
After=network-online.target local-fs.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/piframe
ExecStart=/usr/bin/python3 /opt/piframe/slideshow.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Security hardening
PrivateTmp=yes
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/piframe-api.service << 'EOF'
[Unit]
Description=PiFrame API Server
After=network.target piframe-slideshow.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/piframe
ExecStart=/usr/bin/python3 /opt/piframe/api.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable piframe-slideshow
systemctl enable piframe-api

# Update cron for shutdown
echo "[8/9] Configuring shutdown schedule..."
(crontab -l 2>/dev/null | grep -v "shutdown" | grep -v "^#.*shutdown"; cat << 'CRON'
# Shutdown at 7:30 PM for smart switch power-off
30 19 * * * /sbin/shutdown -h now
CRON
) | crontab -

# Enable NTP
timedatectl set-ntp true

# Create log rotation
echo "[9/9] Setting up log rotation..."
cat > /etc/logrotate.d/piframe << 'EOF'
/var/log/piframe-slideshow.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
}
EOF

echo ""
echo "================================"
echo "Framebuffer Setup Complete!"
echo "================================"
echo ""
echo "Configuration:"
echo "  Photos: /mnt/photos/{bright,medium,dim}"
echo "  Counts: bright=$BRIGHT_COUNT, medium=$MEDIUM_COUNT, dim=$DIM_COUNT"
echo "  API: http://$(hostname -I | awk '{print $1}'):5000"
echo "  Config: /etc/piframe/config.json"
echo "  Logs: journalctl -u piframe-slideshow -f"
echo ""
echo "Services installed:"
echo "  - piframe-slideshow (framebuffer display)"
echo "  - piframe-api (Flask control API)"
echo ""

if [ "$NEED_REBOOT" = true ]; then
    echo "IMPORTANT: Reboot required for framebuffer changes"
    echo ""
    read -p "Reboot now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        reboot
    fi
else
    echo "Starting services..."
    systemctl start piframe-slideshow
    systemctl start piframe-api
    sleep 3
    systemctl status piframe-slideshow --no-pager
fi
