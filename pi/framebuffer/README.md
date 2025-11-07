# PiFrame Framebuffer Slideshow

Direct framebuffer rendering for Pi 5 with time-based brightness control. No X11, no overhead.

## Features

- **Direct framebuffer rendering** - writes to `/dev/fb0`, no X11
- **Time-based brightness** - automatically switches between bright/medium/dim folders
- **Lossless PNGs** - no compression artifacts
- **Flask API** - remote control via HTTP
- **Systemd services** - auto-start, auto-recover
- **Configurable** - JSON config file

## Architecture

```
┌─────────────────┐
│   Framebuffer   │  /dev/fb0 (1920x1080@32bpp)
│   (/dev/fb0)    │
└────────▲────────┘
         │
    ┌────┴──────┐
    │ slideshow │  Python script
    │   .py     │  - Reads photos from /mnt/photos/{bright,medium,dim}
    └────▲──────┘  - Time-based folder switching
         │          - Writes raw RGB to framebuffer
    ┌────┴──────┐
    │ Systemd   │  piframe-slideshow.service
    │  Service  │  - Auto-start on boot
    └───────────┘  - Auto-restart on crash
```

## Installation

```bash
# From your dev machine
scp -r pi/framebuffer/* root@192.168.68.75:/tmp/piframe/

# On the Pi
cd /tmp/piframe
chmod +x setup-framebuffer.sh
./setup-framebuffer.sh 192.168.68.42

# Reboot to apply framebuffer config
reboot
```

## Configuration

Edit `/etc/piframe/config.json`:

```json
{
  "photo_dir": "/mnt/photos",
  "interval": 10,
  "brightness_schedule": {
    "8-17": "bright",
    "17-19": "medium",
    "19-24": "dim"
  },
  "width": 1920,
  "height": 1080,
  "framebuffer_device": "/dev/fb0"
}
```

**Brightness schedule format:**
- Key: `"START_HOUR-END_HOUR"`
- Value: folder name (`"bright"`, `"medium"`, or `"dim"`)
- Hours are 0-23 (24-hour format)

After editing config:
```bash
systemctl restart piframe-slideshow
```

## API Endpoints

### Get Status
```bash
curl http://192.168.68.75:5000/api/status
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

### Restart Slideshow
```bash
curl http://192.168.68.75:5000/api/restart
```

## File Structure

```
/opt/piframe/
├── slideshow.py         # Main framebuffer slideshow
└── api.py              # Flask API server

/etc/piframe/
└── config.json         # Configuration

/etc/systemd/system/
├── piframe-slideshow.service
└── piframe-api.service

/mnt/photos/            # NFS mount from Unraid
├── bright/            # 100% brightness PNGs
├── medium/            # 85% brightness PNGs
└── dim/               # 70% brightness PNGs
```

## Services

### View Logs
```bash
# Slideshow logs
journalctl -u piframe-slideshow -f

# API logs
journalctl -u piframe-api -f
```

### Control Services
```bash
# Restart slideshow
systemctl restart piframe-slideshow

# Stop slideshow
systemctl stop piframe-slideshow

# Check status
systemctl status piframe-slideshow
systemctl status piframe-api
```

## Troubleshooting

### No display / black screen
```bash
# Check if slideshow is running
systemctl status piframe-slideshow

# Check logs
journalctl -u piframe-slideshow -n 50

# Verify framebuffer
ls -l /dev/fb0

# Check photos are mounted
ls /mnt/photos/bright/
```

### Wrong brightness folder
```bash
# Check current time
date

# Check config
cat /etc/piframe/config.json

# Manually test time logic
python3 -c "from datetime import datetime; print(datetime.now().hour)"
```

### Photos not loading
```bash
# Check mount
mount | grep photos

# Re-mount
mount -a

# Check permissions
ls -la /mnt/photos/bright/ | head
```

## Tuning Brightness Levels

If you want to adjust the brightness percentages:

1. Update optimizer on Unraid (see `unraid/optimize-with-brightness.sh`)
2. Change `-evaluate multiply` values (currently 0.85 and 0.70)
3. Reprocess photos: `docker restart photo-optimizer` on Unraid
4. Photos auto-update on Pi via NFS mount

## Advantages over X11/feh

- **Faster** - no X server overhead
- **Lighter** - ~100MB RAM vs ~300MB with X11
- **More control** - direct pixel access for overlays
- **Reliable** - fewer moving parts, less to crash
- **Flexible** - easy to add clock, weather, etc. overlays

## Future Enhancements

- Clock overlay (top-right corner)
- Smooth crossfade transitions
- Photo metadata display
- Remote photo upload
- Motion detection integration
