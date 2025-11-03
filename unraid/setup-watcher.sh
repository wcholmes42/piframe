#!/bin/bash
# Unraid Photo Watcher Setup Script

set -e

PI_IP="${1:-192.168.68.75}"

echo "================================"
echo "PiFrame Watcher Setup (Unraid)"
echo "================================"
echo ""
echo "Pi IP: $PI_IP"
echo ""

# Stop existing container if present
echo "[1/2] Cleaning up old watcher..."
docker stop photo-watcher 2>/dev/null || true
docker rm photo-watcher 2>/dev/null || true

# Create and start watcher container
echo "[2/2] Creating Docker watcher..."
docker run -d \
  --name photo-watcher \
  --restart unless-stopped \
  --network host \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /mnt/user/Pics/Frame:/watch:ro \
  -v /root/.ssh:/root/.ssh:ro \
  docker:cli \
  sh -c "apk add --no-cache inotify-tools openssh && while true; do inotifywait -e create -e moved_to /watch && echo 'New photo detected' && docker restart photo-optimizer && sleep 5 && ssh -o StrictHostKeyChecking=no root@$PI_IP 'killall feh'; done"

echo ""
echo "================================"
echo "Watcher Setup Complete!"
echo "================================"
echo ""
echo "Watching: /mnt/user/Pics/Frame"
echo "On new photo: Optimize + Refresh Pi"
echo ""
echo "Checking status..."
sleep 3
docker logs photo-watcher | tail -5
echo ""
echo "Watcher is running! Add a photo to test."
