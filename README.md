# PiFrame - Automated Digital Picture Frame

Raspberry Pi 5 powered digital picture frame with automatic photo optimization, web UI control, and scheduled display blanking.

## Features

- 🖼️ **Auto-boot slideshow** - Starts automatically on power-on
- 🎨 **Automatic optimization** - Resizes photos to 1920x1080 with letterboxing
- 📡 **Network streaming** - No SD card writes, streams from Unraid
- 🌙 **Scheduled blanking** - Display off 8pm-8am automatically
- 🌐 **Web UI** - Manual controls at http://piframe-ip:5000
- 🔄 **Auto-refresh** - Detects new photos instantly
- ❄️ **Fan control** - Temperature-based cooling

## Hardware Requirements

- Raspberry Pi 5 (4GB+ recommended)
- Official Pi 5 fan
- 1920x1080 HDMI display
- MicroSD card (16GB+)
- Unraid server (or adapt for other NAS)

## Quick Start

### On Raspberry Pi

1. Flash DietPi to SD card
2. Configure WiFi in `dietpi-wifi.txt` before first boot
3. Boot Pi and SSH in
4. Run installation:
```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/piframe/main/pi/install.sh | bash
```

### On Unraid

1. SSH to Unraid server
2. Run optimizer setup:
```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/piframe/main/unraid/setup-optimizer.sh | bash
```

3. Run watcher setup:
```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/piframe/main/unraid/setup-watcher.sh | bash
```

## Configuration

Before running install.sh, you may want to customize:
- Unraid server IP (default: 192.168.68.42)
- Photo source path (default: /Pics/Frame)
- Fan temperature trigger (default: 40°C)
- Display schedule (default: off 8pm-8am)

Edit variables at the top of `pi/install.sh`

## Usage

### Adding Photos

1. Drop images into `\\UNRAID\Pics\Frame`
2. Optimizer processes automatically (every hour + on file change)
3. Pi detects optimized photos and displays within seconds

### Web UI

Access: `http://piframe-ip:5000`

Features:
- Manual display on/off button
- Trigger photo re-optimization
- Adjust slideshow delay
- Toggle random order
- View status and photo count

### Automatic Schedule

- **8:00 PM** - Display turns off (solid black screen)
- **8:00 AM** - Display turns on (resumes slideshow)

## Architecture

```
Original Photos → Unraid Docker Optimizer → Optimized (1920x1080) → Pi Slideshow
   (Frame/)              (letterbox +              (Frame-Optimized/)        (feh)
                          resize)                                              ↑
                                                                               |
                                                    File Watcher ──────────────┘
                                                    (auto-refresh)
```

### Photo Optimization Process

The Docker optimizer:
1. Reads originals from `Frame/` (read-only)
2. Resizes to fit 1920x1080 (maintains aspect ratio)
3. Adds black letterbox/pillarbox bars
4. Centers the image
5. Outputs to `Frame-Optimized/`

**Your originals are never modified.**

## Directory Structure

```
piframe/
├── pi/
│   ├── install.sh              # Main Pi installation script
│   ├── config/
│   │   ├── xinitrc             # X11 startup with feh loop
│   │   ├── autostart.sh        # DietPi autostart script
│   │   └── piframe-web.service # Systemd service for web UI
│   └── web-ui/
│       ├── app.py              # Flask web application
│       └── templates/
│           └── index.html      # Web UI interface
├── unraid/
│   ├── setup-optimizer.sh      # Docker optimizer setup
│   ├── setup-watcher.sh        # Docker watcher setup
│   └── optimize.sh             # ImageMagick optimization script
└── docs/
    └── SETUP.md                # Detailed setup guide
```

## Troubleshooting

**Slideshow not starting:**
```bash
systemctl status piframe-web
ps aux | grep feh
journalctl -u piframe-web -f
```

**Photos not updating:**
```bash
# On Unraid
docker logs photo-optimizer
docker logs photo-watcher

# On Pi
ls /mnt/photos
```

**Display won't turn off:**
```bash
# Check if nightmode flag is created
ls -la /tmp/nightmode

# Check cron
crontab -l

# Test manually
touch /tmp/nightmode
killall feh
```

**Fan not working:**
```bash
vcgencmd measure_temp
cat /sys/class/thermal/cooling_device0/cur_state
```

## License

MIT

## Credits

Built for bedroom ambiance with maximum wife approval factor.

**Technologies:**
- DietPi OS
- feh (image viewer)
- Flask (web UI)
- ImageMagick (optimization)
- inotify-tools (file watching)
- Docker (Unraid containers)
