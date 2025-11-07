#!/bin/bash
# PiFrame FBI Setup - Direct Framebuffer Slideshow (No X11)

set -e

UNRAID_IP="${1:-192.168.68.42}"
PHOTO_SOURCE="Pics/Frame-Optimized"

echo "================================"
echo "PiFrame FBI Setup"
echo "================================"
echo ""

# Install dependencies
echo "[1/5] Installing dependencies..."
apt-get update
apt-get install -y fbi cifs-utils python3-flask

# Create directories
echo "[2/5] Creating directories..."
mkdir -p /opt/piframe
mkdir -p /etc/piframe
mkdir -p /mnt/photos

# Setup mount
echo "[3/5] Configuring network mount..."
sed -i "/$UNRAID_IP/d" /etc/fstab
echo "//$UNRAID_IP/$PHOTO_SOURCE /mnt/photos cifs guest,uid=0,iocharset=utf8,cache=none,noperm 0 0" >> /etc/fstab

umount /mnt/photos 2>/dev/null || true
mount /mnt/photos || {
    echo "ERROR: Failed to mount /mnt/photos"
    exit 1
}

# Verify folders and photos
if [ ! -d "/mnt/photos/bright" ]; then
    echo "ERROR: Brightness folders not found"
    exit 1
fi

BRIGHT_COUNT=$(ls /mnt/photos/bright/*.png 2>/dev/null | wc -l)
echo "   Photo count: $BRIGHT_COUNT"

# Install slideshow script
echo "[4/5] Installing slideshow script..."
cp slideshow-fbi.sh /opt/piframe/slideshow.sh
chmod +x /opt/piframe/slideshow.sh

# Create systemd service
cat > /etc/systemd/system/piframe-fbi.service << 'EOF'
[Unit]
Description=PiFrame FBI Framebuffer Slideshow
After=network-online.target local-fs.target
Wants=network-online.target
Conflicts=graphical.target

[Service]
Type=simple
User=root
ExecStart=/opt/piframe/slideshow.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Install API if provided
if [ -f "api-v2.py" ]; then
    cp api-v2.py /opt/piframe/api.py
    cp config-v2.json /etc/piframe/config.json
    chmod +x /opt/piframe/api.py

    cat > /etc/systemd/system/piframe-api.service << 'EOF'
[Unit]
Description=PiFrame API Server
After=network.target piframe-fbi.service

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
    systemctl enable piframe-api
fi

systemctl daemon-reload
systemctl enable piframe-fbi

# Disable GUI
echo "[5/5] Disabling GUI..."
systemctl disable lightdm 2>/dev/null || true
systemctl stop lightdm 2>/dev/null || true
systemctl set-default multi-user.target

if command -v dietpi-autostart &> /dev/null; then
    dietpi-autostart 7 2>/dev/null || true
fi

# Configure shutdown
(crontab -l 2>/dev/null | grep -v "shutdown" | grep -v "^#.*shutdown"; cat << 'CRON'
# Shutdown at 7:30 PM
30 19 * * * /sbin/shutdown -h now
CRON
) | crontab -

timedatectl set-ntp true

echo ""
echo "================================"
echo "FBI Setup Complete!"
echo "================================"
echo ""
echo "Configuration:"
echo "  Photos: /mnt/photos/{bright,medium,dim}"
echo "  Count: $BRIGHT_COUNT"
echo "  Method: fbi (direct framebuffer)"
echo "  Logs: journalctl -u piframe-fbi -f"
echo ""
echo "Starting slideshow..."
systemctl start piframe-fbi
sleep 3
systemctl status piframe-fbi --no-pager
