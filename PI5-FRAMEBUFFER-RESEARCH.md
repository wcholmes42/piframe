# Pi 5 Direct Framebuffer Research - Nov 6, 2025

## Goal
Achieve direct framebuffer/DRM display without X11 on Raspberry Pi 5 for slideshow application.

## What Doesn't Work

### 1. Direct `/dev/fb0` Writes
**Error:** `[Errno 28] No space left on device`

**Why:** Pi 5 uses DRM/KMS driver (vc4-kms-v3d-pi5). When X11 is running OR when DRM is active, `/dev/fb0` is "evicted" and cannot be written to directly.

**Reference:**
- GitHub Issue #6867: No scanout framebuffer exposed on Pi 5 VC6
- Pi 5 with vc4-kms-v3d doesn't support traditional framebuffer writes

### 2. pydrm Library
**Installed:** Successfully via pip from `notro/pydrm`

**Error:** `could not find a connector`

**Why:** pydrm library appears to have issues with Pi 5's multi-card DRM setup:
- `/dev/dri/card0` = v3d (3D rendering, minor 0)
- `/dev/dri/card1` = vc4 (HDMI output, minor 1)

When querying either card, pydrm reports:
- Driver: v3d
- Connectors: 0

**Testing:**
```python
from pydrm import Drm, SimpleDrm

# Both fail with "could not find a connector"
drm = SimpleDrm(format='XR24')  # Fails
drm = Drm()  # Shows v3d, 0 connectors
```

**dmesg shows:**
```
[3.565357] [drm] Initialized v3d 1.0.0 for 1002000000.v3d on minor 0
[4.192450] [drm] Initialized vc4 0.0.0 for axi:gpu on minor 1
```

But pydrm can't properly enumerate/access the vc4 (HDMI) connector.

### 3. xrandr Gamma/Brightness
**Error:** `Gamma size is 0`

**Why:** Pi's video driver doesn't support gamma tables needed for xrandr brightness adjustment.

### 4. HDMI-CEC
**Error:** `Found devices: NONE`

**Why:** Pi 5 removed/broke HDMI-CEC support present in Pi 4.

### 5. DDC/CI (Monitor Control)
**Attempted:** `ddcutil` with i2c

**Why Failed:** Pi's HDMI i2c not exposed for DDC/CI access. Only GPIO i2c available.

## What MIGHT Work (Not Tested)

### 1. libdrm + DRM ioctls directly
Use C library `libdrm` with proper DRM mode setting. This is what `kmscube` does successfully.

**Requirements:**
- Write C code or use ctypes/cffi in Python
- Manually handle:
  - DRM card enumeration
  - Connector detection
  - Mode setting
  - Dumb buffer creation
  - Page flipping

**Complexity:** Very high. Essentially reimplementing what pydrm should do.

### 2. SDL2 with KMSDRM backend
**Pros:**
- SDL2 officially supports KMSDRM
- Works on Pi 4
- Python bindings via pygame

**Cons:**
- GitHub Issue #8579: Pi 5 KMSDRM displays garbage
- Requires reverting to older SDL2 commits with ATOMIC modesetting
- Still experimental

**Install:**
```bash
apt-get install libdrm-dev libgbm-dev
# Compile SDL2 with --enable-video-kmsdrm
pip3 install pygame
```

### 3. Direct GBM/EGL OpenGL
Use Generic Buffer Management (GBM) + EGL for OpenGL rendering without X11.

**Example:** `kmscube` successfully renders 3D on Pi 5 console.

**Complexity:** High. Requires OpenGL knowledge and manual buffer management.

### 4. Wayland Compositor
Run minimal Wayland compositor (like `weston`) without full desktop.

**Pros:** Official path for modern Linux graphics
**Cons:** Heavier than desired, more complex than X11

## What DOES Work

### X11 + feh (Current Solution)
**Status:** ✓ WORKING PERFECTLY

**Implementation:**
- X11 server renders to DRM
- feh displays images
- Time-based folder switching every 10 minutes
- Auto-selects bright/medium/dim based on hour

**Performance:**
- ~300MB RAM
- CPU: negligible
- Photo transitions: smooth
- Reliable, proven

**Code:**
```bash
# /opt/select-brightness-folder.sh
HOUR=$(date +%H)
if [ $HOUR -ge 19 ]; then echo "dim"
elif [ $HOUR -ge 17 ]; then echo "medium"
else echo "bright"; fi

# /root/.xinitrc
while true; do
    FOLDER=$(/opt/select-brightness-folder.sh)
    feh --fullscreen --slideshow-delay 10 /mnt/photos/${FOLDER}/*.png &
    sleep 600
    killall feh
done
```

## Technical Details Discovered

### Pi 5 DRM Architecture
- **card0** (`/dev/dri/card0`): v3d - 3D GPU (Broadcom V3D)
  - Capabilities: No dumb buffers
  - Purpose: 3D rendering only

- **card1** (`/dev/dri/card1`): vc4 - 2D display (VC4 KMS)
  - Should handle: HDMI output, connectors, mode setting
  - Issue: pydrm can't find connectors (library bug or Pi 5 incompatibility)

- **renderD128**: Render node for GPU access

### KMS/DRM Overlay
Enable with: `dtoverlay=vc4-kms-v3d-pi5` in `/boot/firmware/config.txt`

Creates `/dev/dri/` devices but requires proper userspace library support.

### Framebuffer Size Calculation
For 1920x1080 @ 32bpp:
```
1920 × 1080 × 4 bytes = 8,294,400 bytes (~8MB)
```

Writing image.tobytes() of exactly this size should work, but DRM blocks it.

## Recommendations

**For This Project:**
Stick with X11 + feh. It's working, reliable, and meets all requirements:
- ✓ Time-based brightness switching
- ✓ Smooth photo display
- ✓ Auto-restart on crash
- ✓ Low resource usage
- ✓ Easy to maintain

**For Future/Advanced Users:**
If direct framebuffer is critical:
1. Write C program using libdrm directly
2. Or wait for pydrm to support Pi 5 properly
3. Or use SDL2/pygame with patched KMSDRM backend
4. Or switch to Pi 4 (has working CEC, simpler DRM)

## Libraries Tested

| Library | Status | Notes |
|---------|--------|-------|
| pydrm | ✗ Failed | Can't find connectors on Pi 5 |
| PIL/Pillow | ✓ Works | Image processing |
| feh | ✓ Works | Via X11 |
| ddcutil | ✗ Failed | No DDC/CI on Pi HDMI |
| cec-client | ✗ Failed | CEC removed in Pi 5 |
| xrandr | ✗ Failed | No gamma support |

## Conclusion

**Direct framebuffer on Pi 5 is currently impractical** due to:
- vc4-kms-v3d driver restrictions
- pydrm library incompatibility
- Lack of working examples for Pi 5

**X11 + feh solution is production-ready** and should be used.

**Estimated effort to make framebuffer work:** 20-40 hours of C programming + DRM API learning.

**Value gained:** Minimal. Would save ~200MB RAM but lose stability and simplicity.
