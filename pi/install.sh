#!/bin/bash
# PiFrame Installation Script for Raspberry Pi
# Tested on: DietPi (Debian Bookworm) + Raspberry Pi 5

set -e

# Configuration - EDIT THESE
UNRAID_IP="192.168.68.42"
PHOTO_SOURCE="Pics/Frame-Optimized"
FAN_TEMP_TRIGGER=40000  # 40°C in millidegrees
NIGHT_HOUR=19  # 7:30pm
MORNING_HOUR=8  # 8am

echo "================================"
echo "PiFrame Installation"
echo "================================"
echo ""

# Install required packages
echo "[1/8] Installing packages..."
apt-get update
apt-get install -y feh cifs-utils python3-flask imagemagick git

# Create directories
echo "[2/8] Creating directories..."
mkdir -p /mnt/photos /opt/piframe-web/templates

# Mount Unraid share
echo "[3/8] Setting up network mount..."
if ! grep -q "$UNRAID_IP" /etc/fstab; then
    echo "//$UNRAID_IP/$PHOTO_SOURCE /mnt/photos cifs guest,uid=0,iocharset=utf8,cache=none,noperm 0 0" >> /etc/fstab
fi
mkdir -p /mnt/photos
mount -a

# Verify mount
if [ -z "$(ls -A /mnt/photos)" ]; then
    echo "ERROR: Photo mount is empty. Check Unraid connection."
    exit 1
fi

echo "   Found $(ls /mnt/photos | wc -l) photos"

# Create black screen image
echo "[4/8] Creating black screen image..."
convert -size 1920x1080 xc:black /opt/black.png

# Configure Pi 5 fan
echo "[5/8] Configuring fan..."
if ! grep -q "cooling_fan" /boot/firmware/config.txt; then
    cat >> /boot/firmware/config.txt << EOF

# Pi 5 fan control
dtparam=cooling_fan
dtparam=fan_temp0=$FAN_TEMP_TRIGGER
EOF
fi

# Create .xinitrc
echo "[6/8] Setting up X11 autostart..."
cat > /root/.xinitrc << 'EOF'
#!/bin/bash
xset s off
xset -dpms
xset s noblank

while true; do
    if [ -f /tmp/nightmode ]; then
        feh --fullscreen --hide-pointer /opt/black.png
    else
        feh --fullscreen --hide-pointer --slideshow-delay 10 --randomize --recursive /mnt/photos
    fi
    sleep 1
done
EOF
chmod +x /root/.xinitrc

# Create autostart script
mkdir -p /var/lib/dietpi/dietpi-autostart
cat > /var/lib/dietpi/dietpi-autostart/custom.sh << 'EOF'
#!/bin/bash
xinit /root/.xinitrc -- :0 vt1
EOF
chmod +x /var/lib/dietpi/dietpi-autostart/custom.sh

# Set DietPi autostart
dietpi-autostart 17

# Setup cron schedule
echo "[7/8] Configuring schedule..."
(crontab -l 2>/dev/null | grep -v "shutdown"; cat << CRON
# Shutdown at ${NIGHT_HOUR}:30 for smart switch power-off
30 $NIGHT_HOUR * * * /sbin/shutdown -h now
CRON
) | crontab -

# Enable NTP
timedatectl set-ntp true

# Download web UI files
echo "[8/8] Installing web UI..."
cd /tmp
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/piframe/main/pi/web-ui/app.py -o /opt/piframe-web/app.py
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/piframe/main/pi/web-ui/templates/index.html -o /opt/piframe-web/templates/index.html
chmod +x /opt/piframe-web/app.py

# Create systemd service
cat > /etc/systemd/system/piframe-web.service << 'EOF'
[Unit]
Description=PiFrame Web Interface
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/piframe-web
ExecStart=/usr/bin/python3 /opt/piframe-web/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable piframe-web
systemctl start piframe-web

echo ""
echo "================================"
echo "Installation Complete!"
echo "================================"
echo ""
echo "Access web UI: http://$(hostname -I | awk '{print $1}'):5000"
echo "Photos: $(ls /mnt/photos | wc -l) loaded"
echo ""
echo "Rebooting in 5 seconds..."
sleep 5
reboot
