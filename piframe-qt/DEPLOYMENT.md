# PiFrame Qt Deployment Guide

Complete guide for deploying PiFrame Qt on Raspberry Pi 5.

## Prerequisites

- Raspberry Pi 5 (4GB+ RAM recommended)
- DietPi or Raspberry Pi OS Bookworm (64-bit)
- USB thumb drive (32GB+ for photo cache)
- Network connection to Unraid server
- HDMI display

## Quick Start

### 1. Initial Setup

```bash
# Clone or copy the piframe-qt directory to your Pi
cd ~
git clone <repository-url> piframe-qt

# Or use scp to copy files
scp -r piframe-qt/ pi@192.168.68.75:~/
```

### 2. Run Installation Script

```bash
cd piframe-qt
chmod +x scripts/install.sh
sudo ./scripts/install.sh
```

The installation script will:
- Install Qt 6 and dependencies
- Install Python and Flask
- Build the Qt application
- Set up directories and services
- Configure tmpfs for logs

### 3. Configure Settings

Edit the configuration file:

```bash
sudo nano /opt/piframe/config.json
```

Important settings to update:
- `network.unraid_host`: Your Unraid server IP
- `network.unraid_share`: Path to photos on Unraid
- `slideshow.interval_seconds`: Time between photos
- `brightness.schedule`: Auto-brightness schedule

### 4. Set Up USB Drive

```bash
# Plug in USB drive, then:
sudo /opt/piframe/setup-usb.sh
```

This will format and mount the USB drive at `/mnt/photocache`.

### 5. Sync Photos

```bash
# Initial photo sync from Unraid
sudo /opt/piframe/sync-photos.sh
```

This will copy all photos from Unraid to the USB cache. May take a while on first run.

### 6. Start the Service

```bash
# Start PiFrame
sudo systemctl start piframe

# Enable auto-start on boot
sudo systemctl enable piframe

# Check status
sudo systemctl status piframe

# View logs
journalctl -u piframe -f
```

### 7. Access Web Interface

Open a browser and navigate to:
```
http://<pi-ip-address>:5000
```

Example: `http://192.168.68.75:5000`

## Development Mode

For testing and development, run in windowed mode:

```bash
cd /opt/piframe
./piframe-qt --dev
```

Keyboard shortcuts in dev mode:
- `SPACE`: Next photo
- `P`: Play/Pause
- `R`: Refresh photos
- `C`: Toggle clock
- `H`: Toggle holiday animations
- `T`: Test message
- `Q` or `ESC`: Quit

## Troubleshooting

### Display Not Working

If you see a black screen:

1. Check service status:
```bash
sudo systemctl status piframe
journalctl -u piframe -n 50
```

2. Try running in dev mode to see errors:
```bash
sudo /opt/piframe/piframe-qt --dev
```

3. Check Qt platform plugin:
```bash
export QT_QPA_PLATFORM=eglfs
export QT_DEBUG_PLUGINS=1
/opt/piframe/piframe-qt
```

### No Photos Showing

1. Check photo count:
```bash
find /mnt/photocache -type f -name "*.png" -o -name "*.jpg" | wc -l
```

2. Verify USB mount:
```bash
df -h /mnt/photocache
```

3. Re-sync photos:
```bash
sudo /opt/piframe/sync-photos.sh
```

### Web Interface Not Accessible

1. Check if service is running:
```bash
sudo netstat -tlnp | grep 5000
```

2. Test API directly:
```bash
curl http://localhost:5000/api/status
```

3. Check firewall:
```bash
sudo ufw status
sudo ufw allow 5000/tcp
```

### Clock/Overlays Flickering

**This should NOT happen with the Qt implementation!** If you see flickering:

1. Check GPU memory allocation:
```bash
# Edit /boot/firmware/config.txt
gpu_mem=256
```

2. Verify hardware acceleration:
```bash
glxinfo | grep OpenGL
```

3. Check logs for GPU errors:
```bash
dmesg | grep -i drm
```

## Configuration Tips

### Brightness Schedule

The `brightness.schedule` setting auto-selects photo folders based on time of day:

```json
"schedule": {
  "0-8": "dim",
  "8-17": "bright",
  "17-19": "medium",
  "19-24": "dim"
}
```

This maps hour ranges to folder names (bright/medium/dim).

### Transition Types

Available transitions:
- `fade`: Smooth crossfade (recommended)
- `slide`: Slide left/right
- `zoom`: Zoom in/out effect

### Photo Sync Frequency

Edit the timer for automatic syncing:

```bash
sudo nano /etc/systemd/system/piframe-sync.timer

# Change OnUnitActiveSec value:
OnUnitActiveSec=1h  # Every hour
OnUnitActiveSec=4h  # Every 4 hours
OnUnitActiveSec=1d  # Daily
```

Then reload:
```bash
sudo systemctl daemon-reload
sudo systemctl restart piframe-sync.timer
```

## Performance Tuning

### Reduce CPU Usage

In `config.json`:
```json
"display": {
  "framerate": 30  // Reduce from 60 if needed
}
```

### Memory Optimization

Check memory usage:
```bash
free -h
ps aux | grep piframe-qt
```

Typical usage: 150-250MB RAM (vs 400-500MB with X11)

### SD Card Protection

Logs are already on tmpfs (`/var/log/piframe`), but you can make the entire system read-only:

```bash
sudo raspi-config
# Advanced Options > Overlay File System > Enable
```

## Uninstallation

```bash
# Stop and disable service
sudo systemctl stop piframe
sudo systemctl disable piframe

# Remove files
sudo rm -rf /opt/piframe
sudo rm /etc/systemd/system/piframe.service
sudo rm /etc/systemd/system/piframe-sync.*

# Remove fstab entries
sudo nano /etc/fstab
# Delete lines with /mnt/photocache and /var/log/piframe

# Reload systemd
sudo systemctl daemon-reload
```

## Backup & Restore

### Backup Configuration

```bash
# Backup config and USB photos
sudo tar czf piframe-backup.tar.gz \
  /opt/piframe/config.json \
  /mnt/photocache
```

### Restore

```bash
# Restore config
sudo tar xzf piframe-backup.tar.gz -C /
sudo systemctl restart piframe
```

## Advanced Features

### Send Messages via Command Line

```bash
curl -X POST http://localhost:5000/api/message \
  -H "Content-Type: application/json" \
  -d '{"text":"Hello from CLI!", "duration":10}'
```

### Control via API

```bash
# Next photo
curl -X POST http://localhost:5000/api/control \
  -H "Content-Type: application/json" \
  -d '{"action":"next"}'

# Get status
curl http://localhost:5000/api/status | jq
```

### Custom Holiday Animations

Edit `qml/HolidayOverlay.qml` to add custom holidays or modify animations.

### Weather Integration

To enable weather:

1. Get API key from OpenWeatherMap or similar service
2. Update `config.json`:
```json
"weather": {
  "enabled": true,
  "api_key": "your-api-key",
  "location": "your-city"
}
```

3. Implement weather API in `src/overlaymanager.cpp` (TODO)

## Support

For issues or questions:
- Check logs: `journalctl -u piframe -f`
- GitHub issues: [repository-url]/issues
- Documentation: See README.md

## Credits

Built with Qt 6, QML, and lots of frustration with FBI/framebuffer approaches.

Video toaster quality achieved. 🎉
