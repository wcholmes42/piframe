# Brightness Variant Photo System - DEPLOYED ✓

## Current Status

**Deployed:** November 5, 2025
**Unraid Optimizer:** Running and processing photos
**Photos Processed:** 39/39 (100%)

## Folder Structure

```
/mnt/user/Pics/
├── Frame/                    # Source photos (read-only, 39 photos)
└── Frame-Optimized/
    ├── bright/              # 100% brightness (39 photos, ~22MB)
    ├── medium/              # 70% brightness (39 photos)
    └── dim/                 # 40% brightness (39 photos)
```

## Docker Containers

### photo-optimizer
- **Image:** dpokidov/imagemagick
- **Status:** Running
- **Function:** Processes Frame/ photos into 3 brightness variants
- **Trigger:** Hourly + on restart (via watcher)
- **Config:** `/mnt/user/appdata/photo-optimizer/optimize.sh`

### photo-watcher
- **Image:** docker:cli
- **Status:** Running
- **Function:** Watches Frame/ for new photos, triggers optimizer
- **Monitors:** `/mnt/user/Pics/Frame`

## How It Works

1. New photo added to `Frame/`
2. Watcher detects file creation
3. Watcher restarts optimizer container
4. Optimizer processes new photo:
   - Resizes to 1920x1080
   - Creates 3 brightness variants:
     - `bright/`: Original brightness (100%)
     - `medium/`: 70% brightness (-modulate 70)
     - `dim/`: 40% brightness (-modulate 40)
5. Pi displays appropriate folder based on time of day

## Storage Impact

- **Source (Frame/):** ~23MB (39 photos)
- **Per variant:** ~22MB
- **Total optimized:** ~66MB (3 variants × 22MB)
- **Overhead:** 3x source size (acceptable)

## Next Steps for Pi Integration

1. Update Pi to select folder based on time:
   ```python
   hour = datetime.now().hour
   if hour < 17:
       folder = "bright"
   elif hour < 19:
       folder = "medium"
   else:
       folder = "dim"
   ```

2. Options:
   - **Simple:** Update feh command to use subfolder
   - **Advanced:** Framebuffer slideshow with time-based folder switching

## Brightness Levels

- **bright (100%):** 8am-5pm (full brightness, daytime)
- **medium (70%):** 5pm-7pm (comfortable evening)
- **dim (40%):** 7pm-7:30pm shutdown (minimal eye strain)

## Testing

To verify brightness variants are different:
```bash
ssh root@192.168.68.42 "ls -lh /mnt/user/Pics/Frame-Optimized/{bright,medium,dim}/20160528_152019.jpg"
```

Should show 3 files with similar but different sizes.

## Maintenance

- **Add photos:** Drop in `Frame/`, watcher auto-processes
- **Re-process all:** `docker restart photo-optimizer`
- **Check logs:** `docker logs photo-optimizer`
- **View status:** `docker ps | grep photo`

## Config Files

- Optimizer script: `/mnt/user/appdata/photo-optimizer/optimize.sh`
- Setup script: `unraid/setup-optimizer-v2.sh` (this repo)
