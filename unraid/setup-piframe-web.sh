#!/bin/bash
# Unraid PiFrame Web Server Setup Script

set -e

echo "================================"
echo "PiFrame Web Server Setup (Unraid)"
echo "================================"
echo ""

# Create directories
echo "[1/4] Creating directories..."
mkdir -p /mnt/user/appdata/piframe-web/config
mkdir -p /mnt/user/appdata/piframe-web/app

# Copy application files (you'll need to scp these from your dev machine)
echo "[2/4] Application files should be in /mnt/user/appdata/piframe-web/app/"
echo "Copy app.py and templates/ directory there"

# Build Docker image
echo "[3/4] Building Docker image..."
cd /mnt/user/appdata/piframe-web/app
docker build -t piframe-web:latest .

# Stop existing container if present
echo "[4/4] Creating Docker container..."
docker stop piframe-web 2>/dev/null || true
docker rm piframe-web 2>/dev/null || true

# Create and start web server container
docker run -d \
  --name piframe-web \
  --restart unless-stopped \
  -p 5000:5000 \
  -v /mnt/user/Pics/Frame-Optimized:/photos:ro \
  -v /mnt/user/appdata/piframe-web/config:/config \
  -e CONFIG_FILE=/config/piframe-config.json \
  -e OVERLAY_FILE=/config/piframe-overlay.json \
  -e PHOTO_DIR=/photos \
  piframe-web:latest

echo ""
echo "================================"
echo "PiFrame Web Server Running!"
echo "================================"
echo ""
echo "Access control panel: http://192.168.68.42:5000"
echo "Slideshow URL: http://192.168.68.42:5000/slideshow"
echo ""
echo "Update Pi to point to: http://192.168.68.42:5000/slideshow"
echo ""
docker logs piframe-web --tail 10
