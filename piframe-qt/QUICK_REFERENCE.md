# PiFrame Qt - Quick Reference

Essential commands and troubleshooting for daily operations.

## Common Commands

### Service Control
```bash
# Start PiFrame
sudo systemctl start piframe

# Stop PiFrame
sudo systemctl stop piframe

# Restart PiFrame
sudo systemctl restart piframe

# Check status
sudo systemctl status piframe

# Enable auto-start on boot
sudo systemctl enable piframe

# Disable auto-start
sudo systemctl disable piframe
```

### View Logs
```bash
# Follow live logs
journalctl -u piframe -f

# Last 50 lines
journalctl -u piframe -n 50

# Since boot
journalctl -u piframe -b

# With timestamps
journalctl -u piframe -o short-precise
```

### Photo Management
```bash
# Manual photo sync from Unraid
sudo /opt/piframe/sync-photos.sh

# Check photo count
find /mnt/photocache -type f \( -name "*.png" -o -name "*.jpg" \) | wc -l

# List photos by folder
ls -lh /mnt/photocache/bright/
ls -lh /mnt/photocache/medium/
ls -lh /mnt/photocache/dim/
```

### Configuration
```bash
# Edit main config
sudo nano /opt/piframe/config.json

# Restart to apply changes
sudo systemctl restart piframe

# Backup config
sudo cp /opt/piframe/config.json ~/piframe-config-backup.json
```

### Development Mode
```bash
# Run in windowed mode
cd /opt/piframe
./piframe-qt --dev

# With verbose Qt debug
export QT_DEBUG_PLUGINS=1
./piframe-qt --dev
```

## Web API Examples

### Check Status
```bash
curl http://localhost:5000/api/status | jq
```

### Control Playback
```bash
# Next photo
curl -X POST http://localhost:5000/api/control \
  -H "Content-Type: application/json" \
  -d '{"action":"next"}'

# Pause
curl -X POST http://localhost:5000/api/control \
  -H "Content-Type: application/json" \
  -d '{"action":"pause"}'

# Resume
curl -X POST http://localhost:5000/api/control \
  -H "Content-Type: application/json" \
  -d '{"action":"play"}'

# Refresh photos
curl -X POST http://localhost:5000/api/control \
  -H "Content-Type: application/json" \
  -d '{"action":"refresh"}'
```

### Send Messages
```bash
# Simple message
curl -X POST http://localhost:5000/api/message \
  -H "Content-Type: application/json" \
  -d '{"text":"Hello World!", "duration":10}'

# Birthday message
curl -X POST http://localhost:5000/api/message \
  -H "Content-Type: application/json" \
  -d '{"text":"Happy Birthday! 🎉", "duration":30}'
```

### Get/Set Config
```bash
# Get current config
curl http://localhost:5000/api/config | jq

# Set slideshow interval to 15 seconds
curl -X POST http://localhost:5000/api/config \
  -H "Content-Type: application/json" \
  -d '{"slideshow_interval":15}'

# Enable shuffle
curl -X POST http://localhost:5000/api/config \
  -H "Content-Type: application/json" \
  -d '{"shuffle":true}'
```

## Troubleshooting

### "Black screen, nothing displays"

```bash
# Check if service is running
sudo systemctl status piframe

# Check for errors in logs
journalctl -u piframe -n 100

# Try dev mode to see GUI
cd /opt/piframe
./piframe-qt --dev

# Check Qt platform
export QT_QPA_PLATFORM=eglfs
export QT_DEBUG_PLUGINS=1
./piframe-qt
```

### "No photos showing"

```bash
# Check photo count
find /mnt/photocache -type f \( -name "*.png" -o -name "*.jpg" \) | wc -l

# Check USB mount
df -h /mnt/photocache
ls -l /mnt/photocache/

# Re-sync photos
sudo /opt/piframe/sync-photos.sh

# Check logs for photo errors
journalctl -u piframe -n 50 | grep -i photo
```

### "Clock is flickering"

This should NEVER happen with Qt implementation! If it does:

```bash
# Check GPU memory
vcgencmd get_mem gpu

# Should be at least 256MB, increase if needed:
sudo nano /boot/firmware/config.txt
# Add: gpu_mem=256

# Reboot
sudo reboot
```

### "Web interface not accessible"

```bash
# Check if port 5000 is listening
sudo netstat -tlnp | grep 5000

# Test locally
curl http://localhost:5000/api/status

# Check firewall
sudo ufw status
sudo ufw allow 5000/tcp

# Access from browser
http://<pi-ip-address>:5000
```

### "Service keeps crashing"

```bash
# Check crash logs
journalctl -u piframe -n 200

# Check system resources
free -h
df -h
top

# Check for OOM kills
dmesg | grep -i "out of memory"

# Reduce memory limit if needed
sudo nano /etc/systemd/system/piframe.service
# Change: MemoryLimit=512M to MemoryLimit=1G

sudo systemctl daemon-reload
sudo systemctl restart piframe
```

### "Photos not syncing from Unraid"

```bash
# Check network
ping 192.168.68.42

# Test manual mount
sudo mount -t cifs //192.168.68.42/Pics/Frame-Optimized /tmp/test

# Check sync script
sudo /opt/piframe/sync-photos.sh

# Check timer status
sudo systemctl status piframe-sync.timer

# Manual sync trigger
sudo systemctl start piframe-sync.service
```

## Performance Monitoring

### Check Resource Usage
```bash
# CPU and Memory
top -p $(pgrep piframe-qt)

# Detailed stats
ps aux | grep piframe-qt

# GPU memory
vcgencmd get_mem gpu

# Temperature
vcgencmd measure_temp
```

### Check Display Performance
```bash
# Enable FPS counter in dev mode
# (Add to config.json later if we implement it)

# Check for frame drops in logs
journalctl -u piframe -n 100 | grep -i "frame\|fps\|drop"
```

## Maintenance

### Update Photos
```bash
# Sync from Unraid
sudo /opt/piframe/sync-photos.sh

# Or trigger via API
curl -X POST http://localhost:5000/api/control \
  -H "Content-Type: application/json" \
  -d '{"action":"refresh"}'
```

### Clear Logs
```bash
# Clear journal logs older than 7 days
sudo journalctl --vacuum-time=7d

# Clear all logs for piframe
sudo journalctl --vacuum-time=1s -u piframe
```

### Backup Configuration
```bash
# Backup config
sudo cp /opt/piframe/config.json ~/piframe-backup-$(date +%Y%m%d).json

# Restore config
sudo cp ~/piframe-backup-20250108.json /opt/piframe/config.json
sudo systemctl restart piframe
```

### Update Application
```bash
# Stop service
sudo systemctl stop piframe

# Pull new code
cd ~/piframe-qt
git pull

# Rebuild
qmake6 piframe-qt.pro
make -j4

# Copy new binary
sudo cp piframe-qt /opt/piframe/

# Restart
sudo systemctl start piframe
```

## Keyboard Shortcuts (Dev Mode)

| Key | Action |
|-----|--------|
| `SPACE` | Next photo |
| `P` | Play/Pause toggle |
| `R` | Refresh photo list |
| `C` | Toggle clock overlay |
| `H` | Toggle holiday animations |
| `W` | Toggle weather overlay |
| `T` | Send test message |
| `Q` or `ESC` | Quit application |

## Config File Quick Reference

```json
{
  "slideshow": {
    "interval_seconds": 10,        // Time between photos
    "transition_type": "fade",     // fade, slide, or zoom
    "shuffle": true                // Random order
  },
  "brightness": {
    "mode": "auto",                // auto or manual
    "schedule": {
      "8-17": "bright",            // Hour ranges
      "17-19": "medium",
      "19-24": "dim"
    }
  },
  "overlays": {
    "clock": {"enabled": true},
    "weather": {"enabled": false},
    "holiday": {"enabled": true}
  }
}
```

## URLs

- **Web Interface**: `http://<pi-ip>:5000`
- **API Status**: `http://<pi-ip>:5000/api/status`
- **API Control**: `http://<pi-ip>:5000/api/control`

## Emergency Recovery

### Complete Reset
```bash
# Stop service
sudo systemctl stop piframe

# Reset to default config
sudo cp /opt/piframe/config/config.json /opt/piframe/

# Clear cache
sudo rm -rf /mnt/photocache/*

# Resync
sudo /opt/piframe/sync-photos.sh

# Restart
sudo systemctl start piframe
```

### Nuclear Option (Reinstall)
```bash
# Stop and disable
sudo systemctl stop piframe
sudo systemctl disable piframe

# Remove
sudo rm -rf /opt/piframe

# Reinstall
cd ~/piframe-qt
sudo ./scripts/install.sh
```

## Getting Help

1. Check logs first: `journalctl -u piframe -f`
2. Try dev mode: `./piframe-qt --dev`
3. Test API: `curl http://localhost:5000/api/status`
4. Check resources: `free -h`, `df -h`, `top`
5. Verify USB: `ls /mnt/photocache`
6. Test network: `ping 192.168.68.42`

---

**Keep this file bookmarked for quick access!** 📌
