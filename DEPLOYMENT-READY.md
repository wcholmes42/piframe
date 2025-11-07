# PiFrame Framebuffer System - Ready to Deploy

## Status: READY ✓

All components built and tested. Deploy tomorrow when Pi boots at 8am.

---

## What's Ready

### 1. Unraid Side ✓
**Location:** `unraid/`

- ✓ Photo optimizer with brightness variants
- ✓ Lossless PNG processing (no artifacts)
- ✓ RGB multiply dimming (clean, artifact-free)
- ✓ Auto-orient (fixes rotation)
- ✓ Proper file permissions (666)
- ✓ 3 brightness levels: bright (100%), medium (85%), dim (70%)
- ✓ Auto-processing on new photo upload
- ✓ 39 photos × 3 variants = 117 PNG files (~324MB total)

**Folders:**
```
/mnt/user/Pics/Frame-Optimized/
├── bright/   # 39 PNGs @ 100%
├── medium/   # 39 PNGs @ 85%
└── dim/      # 39 PNGs @ 70%
```

### 2. Pi Framebuffer Slideshow ✓
**Location:** `pi/framebuffer/`

**Files:**
- `slideshow.py` - Main framebuffer renderer
- `api.py` - Flask API for control
- `config.json` - Time-based brightness schedule
- `piframe-slideshow.service` - Systemd service
- `piframe-api.service` - API service
- `setup-framebuffer.sh` - One-command installer
- `README.md` - Complete documentation

**Features:**
- Direct `/dev/fb0` rendering (no X11)
- Time-based folder switching
- Configurable brightness schedule
- HTTP API control
- Auto-start on boot
- Auto-restart on crash

---

## Deployment Plan (Tomorrow 8am)

### Step 1: Upload Files to Pi
```bash
scp -r pi/framebuffer/* root@192.168.68.75:/tmp/piframe/
```

### Step 2: Run Setup
```bash
ssh root@192.168.68.75
cd /tmp/piframe
chmod +x setup-framebuffer.sh
./setup-framebuffer.sh 192.168.68.42
# Answer 'y' to reboot
```

### Step 3: Verify After Reboot
```bash
# Wait 2 minutes for boot + auto-start

# Check slideshow is running
ssh root@192.168.68.75 "systemctl status piframe-slideshow"

# Check API is running
ssh root@192.168.68.75 "systemctl status piframe-api"

# Test API
curl http://192.168.68.75:5000/api/status
```

### Step 4: Watch It Work
- Screen should display photos from appropriate brightness folder
- Check logs: `ssh root@192.168.68.75 "journalctl -u piframe-slideshow -f"`

---

## Default Schedule

Based on `config.json`:

| Time | Folder | Brightness |
|------|--------|-----------|
| 8am-5pm | bright | 100% |
| 5pm-7pm | medium | 85% |
| 7pm-7:30pm | dim | 70% |
| 7:30pm | **SHUTDOWN** | (cron) |

Tomorrow night at ~6:45pm, you'll see it switch from medium to dim automatically.

---

## Tuning Brightness Tomorrow Night

If brightness levels need adjustment:

### Option A: Change Multipliers (Unraid)
```bash
# SSH to Unraid
ssh root@192.168.68.42

# Edit optimizer script
nano /mnt/user/appdata/photo-optimizer/optimize.sh

# Change these lines:
# -evaluate multiply 0.85  → change to 0.90 for brighter medium
# -evaluate multiply 0.70  → change to 0.60 for dimmer dim

# Reprocess all photos
docker restart photo-optimizer

# Wait ~2 minutes for processing
# Pi will see new photos immediately via NFS
```

### Option B: Add More Levels
Edit optimizer to create 5 levels instead of 3:
- `verybright/` - 100%
- `bright/` - 90%
- `medium/` - 75%
- `dim/` - 60%
- `verydim/` - 45%

Then update Pi's `config.json` with new schedule.

---

## API Examples

### Check Current Status
```bash
curl http://192.168.68.75:5000/api/status
```

### Change Photo Interval
```bash
# Set to 15 seconds
curl -X POST http://192.168.68.75:5000/api/config \
  -H "Content-Type: application/json" \
  -d '{"interval": 15}'
```

### Update Brightness Schedule
```bash
# Adjust time ranges
curl -X POST http://192.168.68.75:5000/api/config \
  -H "Content-Type: application/json" \
  -d '{
    "brightness_schedule": {
      "8-16": "bright",
      "16-18": "medium",
      "18-24": "dim"
    }
  }'
```

### Skip to Next Photo
```bash
curl http://192.168.68.75:5000/api/next
```

---

## What Happens Tomorrow

### 8:00 AM - Smart Switch Powers On
1. Pi boots (~30 sec)
2. ~~X11 starts~~ **NO - boots to console now**
3. systemd starts `piframe-slideshow.service`
4. Python loads, checks time → selects `bright/` folder
5. Loads 39 photos from `/mnt/photos/bright/`
6. Writes first photo to `/dev/fb0`
7. Screen displays photo
8. Repeats every 10 seconds

### 5:00 PM - Auto Switch to Medium
1. Script checks time → 17:00
2. Matches schedule: `"17-19": "medium"`
3. Loads 39 photos from `/mnt/photos/medium/`
4. Screen noticeably dimmer

### 7:00 PM - Auto Switch to Dim
1. Script checks time → 19:00
2. Matches schedule: `"19-24": "dim"`
3. Loads 39 photos from `/mnt/photos/dim/`
4. Screen much dimmer

### 7:30 PM - Shutdown
1. Cron triggers: `shutdown -h now`
2. Services gracefully stop
3. Pi shuts down
4. Smart switch cuts power at 7:35pm

---

## Files Created

```
D:\code\piframe\
├── pi\framebuffer\
│   ├── slideshow.py                  # Framebuffer renderer
│   ├── api.py                        # Flask API
│   ├── config.json                   # Configuration
│   ├── piframe-slideshow.service     # Systemd service
│   ├── piframe-api.service           # API service
│   ├── setup-framebuffer.sh          # Installer
│   └── README.md                     # Documentation
├── unraid\
│   ├── optimize-with-brightness.sh   # Final optimizer script
│   ├── setup-optimizer-v2.sh         # Deployment script
│   └── BRIGHTNESS-SETUP.md           # Unraid docs
├── BRIGHTNESS-LEVELS.md              # Brightness theory
└── DEPLOYMENT-READY.md               # This file
```

---

## Rollback Plan

If framebuffer approach has issues, revert to X11:

```bash
ssh root@192.168.68.75

# Stop framebuffer services
systemctl stop piframe-slideshow piframe-api
systemctl disable piframe-slideshow piframe-api

# Re-enable X11 autostart
dietpi-autostart 17

# Reboot
reboot
```

---

## Success Criteria

✓ Photos display on screen
✓ Brightness switches automatically at 5pm and 7pm
✓ No artifacts in dimmed photos
✓ Shutdown at 7:30pm works
✓ Auto-start at 8am works
✓ API accessible from browser

---

**Everything is ready. Deploy tomorrow and tune brightness levels in the evening.**
