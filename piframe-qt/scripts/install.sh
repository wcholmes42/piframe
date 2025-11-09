#!/bin/bash
#
# PiFrame Qt Installation Script
# For Raspberry Pi 5 running DietPi or Raspberry Pi OS (Bookworm)
#

set -e  # Exit on error

echo "======================================"
echo "  PiFrame Qt Installation Script"
echo "======================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME=$NAME
    echo "Detected OS: $OS_NAME"
else
    echo "Cannot detect OS"
    exit 1
fi

# Update package lists
echo ""
echo "[1/10] Updating package lists..."
apt-get update

# Install Qt 6 and dependencies
echo ""
echo "[2/10] Installing Qt 6 and dependencies..."
apt-get install -y \
    qt6-base-dev \
    qt6-declarative-dev \
    qml6-module-qtquick \
    qml6-module-qtquick-controls \
    qml6-module-qtquick-particles \
    qml6-module-qtquick-window \
    qml6-module-qtgraphicaleffects5compat \
    libqt6network6 \
    libqt6websockets6-dev \
    libgles2-mesa-dev \
    build-essential \
    cmake \
    git

# Install Python and Flask for web API
echo ""
echo "[3/10] Installing Python and Flask..."
apt-get install -y \
    python3 \
    python3-pip \
    python3-flask \
    python3-flask-cors

# Install rsync for photo sync
echo ""
echo "[4/10] Installing rsync and CIFS utilities..."
apt-get install -y rsync cifs-utils

# Create installation directory
echo ""
echo "[5/10] Creating installation directories..."
INSTALL_DIR="/opt/piframe"
mkdir -p $INSTALL_DIR
mkdir -p $INSTALL_DIR/web
mkdir -p /mnt/photocache
mkdir -p /var/log/piframe

# Copy files
echo ""
echo "[6/10] Copying application files..."
cd "$(dirname "$0")/.."

# Build Qt application
echo "Building Qt application..."
if [ ! -f "piframe-qt.pro" ]; then
    echo "Error: piframe-qt.pro not found. Run this script from the piframe-qt directory."
    exit 1
fi

qmake6 piframe-qt.pro
make -j4

# Copy binary
cp piframe-qt $INSTALL_DIR/
chmod +x $INSTALL_DIR/piframe-qt

# Copy configuration
cp config/config.json $INSTALL_DIR/

# Copy web files (if they exist)
if [ -d "web" ]; then
    cp -r web/* $INSTALL_DIR/web/
fi

# Copy scripts
cp scripts/*.sh $INSTALL_DIR/
chmod +x $INSTALL_DIR/*.sh

# Set up tmpfs for logs (SD card protection)
echo ""
echo "[7/10] Configuring tmpfs for logs..."
if ! grep -q "/var/log/piframe" /etc/fstab; then
    echo "tmpfs /var/log/piframe tmpfs defaults,noatime,size=50M 0 0" >> /etc/fstab
    mount -a
fi

# Install systemd services
echo ""
echo "[8/10] Installing systemd services..."
cp services/piframe.service /etc/systemd/system/
cp services/piframe-sync.service /etc/systemd/system/
cp services/piframe-sync.timer /etc/systemd/system/

systemctl daemon-reload

# Configure USB auto-mount
echo ""
echo "[9/10] Setting up USB auto-mount..."
./scripts/setup-usb.sh

# Set up photo sync
echo ""
echo "[10/10] Configuring photo sync from Unraid..."
echo "Note: Edit /opt/piframe/config.json to set your Unraid server details"

# Enable services (but don't start yet)
echo ""
echo "Enabling services..."
systemctl enable piframe.service
systemctl enable piframe-sync.timer

echo ""
echo "======================================"
echo "  Installation Complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "  1. Edit /opt/piframe/config.json with your settings"
echo "  2. Ensure USB drive is connected for photo cache"
echo "  3. Run initial photo sync: sudo /opt/piframe/sync-photos.sh"
echo "  4. Start the service: sudo systemctl start piframe"
echo "  5. Access web interface at: http://$(hostname -I | awk '{print $1}'):5000"
echo ""
echo "To enable auto-start on boot: sudo systemctl enable piframe"
echo "To view logs: journalctl -u piframe -f"
echo ""
echo "Development mode (windowed): /opt/piframe/piframe-qt --dev"
echo ""
