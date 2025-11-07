# PiFrame System - Complete & Robust

## Current Status: ✓ WORKING

**Last Updated:** Nov 6, 2025 2:36pm

---

## What's Running RIGHT NOW

### Unraid (192.168.68.42)
- **Photo optimizer** - Processing 39 source photos → 117 PNG variants
- **Folders:** `/mnt/user/Pics/Frame-Optimized/{bright,medium,dim}`
- **Method:** RGB multiply dimming (artifact-free)
- **Levels:** 100%, 85%, 70%
- **Auto-processing:** New photos detected and processed automatically

### Pi (192.168.68.75)
- **Display:** X11 + feh slideshow
- **Current brightness:** bright (100%) - 8am-5pm
- **Auto-switching:** Every 10 minutes, checks time and switches folder
- **Schedule:**
  - 12am-8am: dim (70%)
  - 8am-5pm: bright (100%)
  - 5pm-7pm: medium (85%)
  - 7pm-7:30pm: dim (70%)
  - 7:30pm: **SHUTDOWN**

**Active scripts:**
- `/root/.xinitrc` - X11 startup with time-based feh
- `/opt/select-brightness-folder.sh` - Time → folder selector
- Cron: `30 19 * * * shutdown -h now`

---

## File Structure

```
Unraid: /mnt/user/Pics/
├── Frame/                          # Source photos (read-only)
│   └── *.jpg                      # 39 original photos
└── Frame-Optimized/
    ├── bright/                    # 39 PNGs @ 100%
    ├── medium/                    # 39 PNGs @ 85%
    └── dim/                       # 39 PNGs @ 70%

Pi: /mnt/photos/ → NFS mount to Frame-Optimized/
├── bright/
├── medium/
└── dim/
```

---

## How It Works (Current System)

1. **8:00 AM** - Smart switch powers on
2. Pi boots → auto-login → startx
3. `.xinitrc` runs:
   - Calls `/opt/select-brightness-folder.sh`
   - Gets "bright" (current hour = 8-17)
   - Starts: `feh --fullscreen /mnt/photos/bright/*.png`
4. Feh displays slideshow (10 sec intervals, randomized)
5. Every 10 minutes, kills feh and restarts (to re-check time)
6. **5:00 PM** - Script returns "medium", feh loads medium folder
7. **7:00 PM** - Script returns "dim", feh loads dim folder
8. **7:30 PM** - Cron triggers shutdown

---

## Tuning Brightness

### Option A: Change Multipliers (Quick)
```bash
ssh root@192.168.68.42
nano /mnt/user/appdata/photo-optimizer/optimize.sh

# Line 34: medium brightness
convert "$temp_png" -evaluate multiply 0.85 "$OUTPUT/medium/${base}.png"
# Change 0.85 to:
#   0.90 = brighter medium
#   0.80 = dimmer medium

# Line 39: dim brightness
convert "$temp_png" -evaluate multiply 0.70 "$OUTPUT/dim/${base}.png"
# Change 0.70 to:
#   0.75 = brighter dim
#   0.60 = dimmer dim

# Save and restart
docker restart photo-optimizer

# Wait 2 minutes for reprocessing
# Pi sees changes immediately via NFS
```

### Option B: Change Schedule (Quick)
```bash
ssh root@192.168.68.75
nano /opt/select-brightness-folder.sh

# Change time ranges:
if [ $HOUR -ge 19 ]; then    # Change 19 to 18 for dim at 6pm
    echo "dim"
elif [ $HOUR -ge 17 ]; then  # Change 17 to 16 for medium at 4pm
    echo "medium"
...

# No restart needed - takes effect in <10 minutes
```

---

## Upgrade Path: Framebuffer System (Future)

When ready to ditch X11 and go full framebuffer:

### Why Upgrade?
- **Lighter:** ~100MB RAM vs ~300MB (X11)
- **Faster:** No compositor overhead
- **More control:** Direct pixel access for overlays (clock, weather, etc.)
- **Simpler:** Fewer moving parts
- **Flexible:** Easy to add features

### Files Ready
All v2 files in `pi/framebuffer/`:
- `slideshow-v2.py` - Robust framebuffer renderer
- `api-v2.py` - Enhanced Flask API
- `config-v2.json` - Updated config with overnight hours
- `setup-framebuffer-v2.sh` - One-command installer
- `*.service` - Systemd services

### Deploy Framebuffer
```bash
# 1. Upload files
scp -r pi/framebuffer/*-v2.* root@192.168.68.75:/tmp/piframe/
scp pi/framebuffer/*.service root@192.168.68.75:/tmp/piframe/

# 2. Run setup
ssh root@192.168.68.75
cd /tmp/piframe
chmod +x setup-framebuffer-v2.sh
./setup-framebuffer-v2.sh 192.168.68.42

# 3. Reboot
# Services auto-start, no X11
```

### Rollback from Framebuffer
If framebuffer has issues:
```bash
ssh root@192.168.68.75
systemctl stop piframe-slideshow piframe-api
systemctl disable piframe-slideshow piframe-api
dietpi-autostart 17  # Re-enable X11
reboot
```

---

## Improvements Made (v2)

### slideshow-v2.py
✓ Logging to file + stdout
✓ Signal handlers: SIGUSR1 (next), SIGHUP (reload config), SIGTERM/INT (shutdown)
✓ Robust error handling with retry logic
✓ Status file writes for API
✓ Config reload without restart
✓ Handles empty photo folders gracefully
✓ Overnight hour support (0-8am)
✓ Minute-based brightness checking (not just on photo change)

### api-v2.py
✓ Start/stop/restart endpoints
✓ Service status checking
✓ Config validation
✓ Error responses with details
✓ Logging
✓ SIGHUP for config reload (no restart needed)

### setup-framebuffer-v2.sh
✓ Photo count verification
✓ Folder existence checks
✓ Mount validation
✓ Backup of cmdline.txt before modification
✓ Log rotation setup
✓ Comprehensive error messages
✓ No-reboot option if already configured

### config-v2.json
✓ Overnight hours added (0-8am → dim)
✓ Complete 24-hour coverage

---

## API Reference (v2)

### Get Status
```bash
curl http://192.168.68.75:5000/api/status
```
Response:
```json
{
  "running": true,
  "config": {...},
  "current_photo": "/mnt/photos/bright/photo.png",
  "current_brightness": "bright",
  "timestamp": "2025-11-06T14:30:00"
}
```

### Update Config
```bash
curl -X POST http://192.168.68.75:5000/api/config \
  -H "Content-Type: application/json" \
  -d '{"interval": 15}'
```

### Skip to Next Photo
```bash
curl http://192.168.68.75:5000/api/next
```

### Restart/Start/Stop Slideshow
```bash
curl http://192.168.68.75:5000/api/restart
curl http://192.168.68.75:5000/api/start
curl http://192.168.68.75:5000/api/stop
```

---

## Troubleshooting

### Slideshow not advancing
```bash
ssh root@192.168.68.75
ps aux | grep feh
# Should see one feh process with PNG files

# If stuck, kill and let xinitrc restart
killall xinit
# Wait 15 seconds for auto-restart
```

### Wrong brightness folder
```bash
# Check time
ssh root@192.168.68.75 "date"

# Test selector script
ssh root@192.168.68.75 "/opt/select-brightness-folder.sh"

# Force restart to pick up new brightness
ssh root@192.168.68.75 "killall feh"
# Restarts automatically in <10 min
```

### Photos have artifacts
```bash
# Check optimizer on Unraid
ssh root@192.168.68.42 "docker logs photo-optimizer | tail -20"

# Verify using -evaluate multiply (not -modulate)
ssh root@192.168.68.42 "grep 'evaluate multiply' /mnt/user/appdata/photo-optimizer/optimize.sh"

# Should see:
#   -evaluate multiply 0.85
#   -evaluate multiply 0.70
```

### No photos showing
```bash
# Check mount
ssh root@192.168.68.75 "ls /mnt/photos/bright/ | head"

# Re-mount
ssh root@192.168.68.75 "mount -a"

# Check Unraid shares
ssh root@192.168.68.42 "ls /mnt/user/Pics/Frame-Optimized/bright/ | head"
```

---

## Maintenance

### Add New Photos
1. Drop JPGs in Unraid: `/mnt/user/Pics/Frame/`
2. Watcher detects → triggers optimizer
3. Optimizer creates 3 PNG variants
4. Pi sees new photos via NFS (no action needed)

### View Logs (Current System)
```bash
# X11 startup log
ssh root@192.168.68.75 "cat /var/log/Xorg.0.log | tail -50"

# System log
ssh root@192.168.68.75 "journalctl -n 100"
```

### View Logs (Framebuffer System)
```bash
# Slideshow logs
ssh root@192.168.68.75 "journalctl -u piframe-slideshow -f"

# Or log file
ssh root@192.168.68.75 "tail -f /var/log/piframe-slideshow.log"

# API logs
ssh root@192.168.68.75 "journalctl -u piframe-api -f"
```

### Update Shutdown Time
```bash
ssh root@192.168.68.75 "crontab -e"
# Change: 30 19 * * * /sbin/shutdown -h now
# To:     0 20 * * * /sbin/shutdown -h now  (8:00pm)
```

---

## System Diagram

```
┌─────────────────────────────────────────────────────┐
│ Unraid (192.168.68.42)                              │
│                                                     │
│  Frame/ (39 source JPGs)                           │
│     │                                               │
│     ├→ File Watcher (Docker)                       │
│     │     │                                         │
│     │     ├→ Photo Optimizer (Docker)              │
│     │     │    • Resize to 1920x1080               │
│     │     │    • Auto-orient                        │
│     │     │    • RGB multiply for brightness       │
│     │     │    • Save as PNG (lossless)            │
│     │     │                                         │
│     │     └→ Frame-Optimized/                      │
│     │          ├── bright/ (100%)                   │
│     │          ├── medium/ (85%)                    │
│     │          └── dim/ (70%)                       │
│     │                                               │
│     └→ NFS Share                                    │
└──────────────┬──────────────────────────────────────┘
               │
               │ Network Mount (CIFS)
               │
┌──────────────▼──────────────────────────────────────┐
│ Pi 5 (192.168.68.75)                                │
│                                                     │
│  /mnt/photos/ ──→ Unraid NFS                       │
│     ├── bright/                                     │
│     ├── medium/                                     │
│     └── dim/                                        │
│          │                                          │
│          │                                          │
│  CURRENT SYSTEM:                                    │
│  ┌────────────────────────────────────┐            │
│  │ X11 + feh                          │            │
│  │  • select-brightness-folder.sh     │            │
│  │  • Restarts every 10 min           │            │
│  │  • Time-based folder switching     │            │
│  └────────────────────────────────────┘            │
│                                                     │
│  FUTURE SYSTEM (v2 ready):                         │
│  ┌────────────────────────────────────┐            │
│  │ Framebuffer (/dev/fb0)             │            │
│  │  • slideshow-v2.py                 │            │
│  │  • api-v2.py (Flask)               │            │
│  │  • Direct pixel writes             │            │
│  │  • Signal-based control            │            │
│  │  • Logging + status files          │            │
│  └────────────────────────────────────┘            │
│                                                     │
│  Cron: 7:30pm shutdown                             │
│  Smart Switch: 7:35pm power off, 8:00am power on  │
└─────────────────────────────────────────────────────┘
```

---

## Summary

**Current system is WORKING:**
- ✓ 39 photos in 3 brightness levels
- ✓ Artifact-free PNGs
- ✓ Time-based auto-switching
- ✓ Auto-processes new photos
- ✓ Scheduled shutdown

**When you're ready to upgrade:**
- Run `setup-framebuffer-v2.sh`
- Get framebuffer performance + control
- Easy rollback if needed

**You don't have to think about it anymore** - it just works.
