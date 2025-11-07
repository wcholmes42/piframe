#!/bin/bash
# PiFrame DRM Setup Script - Pi 5 Compatible
# Uses pydrm library for direct KMS/DRM access

set -e

UNRAID_IP="${1:-192.168.68.42}"
PHOTO_SOURCE="Pics/Frame-Optimized"

echo "================================"
echo "PiFrame DRM Setup (Pi 5)"
echo "================================"
echo ""

# Install dependencies
echo "[1/10] Installing dependencies..."
apt-get update
apt-get install -y python3-pip python3-pil python3-flask cifs-utils git

# Install pydrm
echo "[2/10] Installing pydrm library..."
pip3 install --break-system-packages git+https://github.com/notro/pydrm.git || {
    echo "   Trying alternative install method..."
    cd /tmp
    git clone https://github.com/notro/pydrm.git
    cd pydrm
    python3 setup.py install
    cd ..
    rm -rf pydrm
}

# Create directories
echo "[3/10] Creating directories..."
mkdir -p /opt/piframe
mkdir -p /etc/piframe
mkdir -p /mnt/photos
mkdir -p /var/log

# Copy application files
echo "[4/10] Installing application files..."
cp slideshow-drm.py /opt/piframe/slideshow.py
cp api-v2.py /opt/piframe/api.py
cp config-v2.json /etc/piframe/config.json
chmod +x /opt/piframe/*.py

# Setup mount for photo folders
echo "[5/10] Configuring network mount..."
sed -i "/$UNRAID_IP/d" /etc/fstab
echo "//$UNRAID_IP/$PHOTO_SOURCE /mnt/photos cifs guest,uid=0,iocharset=utf8,cache=none,noperm 0 0" >> /etc/fstab

umount /mnt/photos 2>/dev/null || true
mount /mnt/photos || {
    echo "ERROR: Failed to mount /mnt/photos"
    exit 1
}

# Verify folders
if [ ! -d "/mnt/photos/bright" ] || [ ! -d "/mnt/photos/medium" ] || [ ! -d "/mnt/photos/dim" ]; then
    echo "ERROR: Brightness folders not found"
    exit 1
fi

BRIGHT_COUNT=$(ls /mnt/photos/bright/*.png 2>/dev/null | wc -l)
echo "   Photo counts: bright=$BRIGHT_COUNT"

# Enable KMS/DRM video driver for Pi 5
echo "[6/10] Enabling KMS/DRM video driver..."
if ! grep -q "^dtoverlay=vc4-kms-v3d" /boot/firmware/config.txt; then
    echo "" >> /boot/firmware/config.txt
    echo "# Enable KMS/DRM for direct framebuffer access" >> /boot/firmware/config.txt
    echo "dtoverlay=vc4-kms-v3d-pi5" >> /boot/firmware/config.txt
    echo "   vc4-kms-v3d-pi5 enabled (requires reboot)"
    NEED_REBOOT=true
else
    echo "   KMS/DRM already enabled"
    NEED_REBOOT=false
fi

# Disable X11/Wayland autostart
echo "[7/10] Disabling GUI..."
systemctl disable lightdm 2>/dev/null || true
systemctl stop lightdm 2>/dev/null || true
systemctl set-default multi-user.target

# Set DietPi to boot to console if available
if command -v dietpi-autostart &> /dev/null; then
    dietpi-autostart 7 2>/dev/null || true
fi

# Install systemd services
echo "[8/10] Installing systemd services..."
cat > /etc/systemd/system/piframe-slideshow.service << 'EOF'
[Unit]
Description=PiFrame DRM Slideshow
After=network-online.target local-fs.target
Wants=network-online.target
Conflicts=graphical.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/piframe
ExecStart=/usr/bin/python3 /opt/piframe/slideshow.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

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
echo "[9/10] Configuring shutdown schedule..."
(crontab -l 2>/dev/null | grep -v "shutdown" | grep -v "^#.*shutdown"; cat << 'CRON'
# Shutdown at 7:30 PM for smart switch power-off
30 19 * * * /sbin/shutdown -h now
CRON
) | crontab -

timedatectl set-ntp true

# Create log rotation
echo "[10/10] Setting up log rotation..."
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
echo "DRM Setup Complete!"
echo "================================"
echo ""
echo "Configuration:"
echo "  Photos: /mnt/photos/{bright,medium,dim}"
echo "  Count: $BRIGHT_COUNT photos"
echo "  API: http://$(hostname -I | awk '{print $1}'):5000"
echo "  Config: /etc/piframe/config.json"
echo "  Logs: journalctl -u piframe-slideshow -f"
echo ""
echo "Video driver: vc4-kms-v3d-pi5"
echo "Library: pydrm (direct KMS/DRM access)"
echo ""

if [ "$NEED_REBOOT" = true ]; then
    echo "IMPORTANT: Reboot required to activate KMS/DRM driver"
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
