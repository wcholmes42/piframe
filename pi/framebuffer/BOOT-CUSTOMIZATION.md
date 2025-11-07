# Pi Framebuffer Boot Customization

Complete boot experience customization for Pi framebuffer slideshow.

## Goals

1. **Replace rainbow splash** - Custom boot logo instead of Raspberry Pi rainbow
2. **Quiet boot** - Suppress kernel/systemd console spam
3. **Loading splash** - Show "Loading..." while mounting network storage

## 1. Custom Boot Logo (Replace Rainbow)

### How It Works

The Raspberry Pi rainbow splash is displayed by the GPU firmware during boot. To replace it:

**Option A: Disable Rainbow** (Simple)
- Add `disable_splash=1` to `/boot/firmware/config.txt`
- Screen stays black during boot

**Option B: Custom Splash Image** (Advanced)
- Create 1920x1080 PNG splash image
- Convert to firmware-compatible format
- Replace `/boot/firmware/splash.png`

### Implementation

```bash
# Disable rainbow splash
echo "disable_splash=1" >> /boot/firmware/config.txt

# OR create custom splash
# 1. Design splash.png (1920x1080)
# 2. Convert to RGB565 format
# 3. Install as /boot/firmware/splash.bin
```

## 2. Quiet Boot (Suppress Console Spam)

### Boot Message Sources

1. **Kernel messages** - Linux kernel output
2. **Systemd messages** - Service startup logs
3. **Login prompt** - Getty asking for login

### Suppression Strategy

**Kernel quiet:**
```bash
# In /boot/firmware/cmdline.txt add:
quiet loglevel=3 plymouth.ignore-serial-consoles
```

**Hide cursor:**
```bash
# In /boot/firmware/cmdline.txt add:
vt.global_cursor_default=0
```

**Disable console autologin:**
```bash
systemctl disable getty@tty1
```

**Redirect systemd to serial:**
```bash
# Prevents systemd spam on HDMI
systemctl mask systemd-vconsole-setup
```

### Full Cmdline Example

```
console=serial0,115200 console=tty3 root=PARTUUID=xxx rootfstype=ext4 fsck.repair=yes rootwait quiet loglevel=3 vt.global_cursor_default=0 logo.nologo plymouth.ignore-serial-consoles video=HDMI-A-1:-32
```

Note: `console=tty3` redirects messages to VT3 instead of VT1 (where FBI runs)

## 3. Splash Screen While Mounting Network

### Approaches

**A. Static Image via FBI**
- Show loading.png on VT1 before slideshow
- Simple, uses existing FBI binary

**B. Plymouth Boot Splash**
- Full boot splash system
- Complex, heavyweight for our use case

**C. Framebuffer Direct Write**
- Python script writes "Loading..." to /dev/fb0
- Fast, lightweight

### Implementation: Static FBI Splash

```bash
#!/bin/bash
# Show splash while mounting network

# Display loading image
fbi -T 1 -a --noverbose /opt/piframe/splash/loading.png &
SPLASH_PID=$!

# Mount network storage
mount /mnt/photos

# Kill splash, start slideshow
kill $SPLASH_PID
exec /opt/piframe/slideshow.sh
```

### Create Loading Splash

```bash
# Generate simple loading screen
convert -size 1920x1080 xc:black \
    -gravity center \
    -pointsize 120 \
    -font DejaVu-Sans-Bold \
    -fill white \
    -annotate +0+0 "Loading Photos..." \
    loading.png
```

## 4. Complete Boot Flow

```
Power On
  ↓
GPU Firmware (custom splash OR disabled)
  ↓
Linux Kernel (quiet, no cursor)
  ↓
Systemd (redirected to serial)
  ↓
Network Mount (FBI shows loading.png)
  ↓
FBI Slideshow (seamless transition)
```

## Installation Steps

### Step 1: Disable Rainbow

```bash
echo "disable_splash=1" >> /boot/firmware/config.txt
```

### Step 2: Quiet Kernel

```bash
# Backup cmdline
cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.backup

# Edit cmdline.txt
nano /boot/firmware/cmdline.txt

# Add to existing line:
# quiet loglevel=3 vt.global_cursor_default=0 console=tty3
```

### Step 3: Disable Console Login

```bash
systemctl disable getty@tty1
systemctl mask systemd-vconsole-setup
```

### Step 4: Create Loading Splash

```bash
mkdir -p /opt/piframe/splash

convert -size 1920x1080 xc:black \
    -gravity center \
    -pointsize 120 \
    -font DejaVu-Sans-Bold \
    -fill white \
    -annotate +0+0 "PiFrame Loading..." \
    -pointsize 48 \
    -annotate +0+150 "Mounting network storage..." \
    /opt/piframe/splash/loading.png
```

### Step 5: Update Slideshow Script

Add splash display before mount in slideshow.sh:

```bash
# Show loading splash
fbi -T 1 -a --noverbose /opt/piframe/splash/loading.png &
SPLASH_PID=$!

# Wait for network mount
while ! mountpoint -q /mnt/photos; do
    sleep 1
done

# Kill splash
kill $SPLASH_PID 2>/dev/null
```

## Result

- **Boot screen:** Black (or custom image)
- **No text spam:** Clean, silent boot
- **Loading message:** "PiFrame Loading..." while mounting
- **Seamless transition:** Direct to slideshow

## Advanced: Custom Boot Logo

To create a proper custom boot splash:

```bash
# 1. Design 1920x1080 PNG logo
# 2. Convert to raw RGB565:
convert splash.png -resize 1920x1080! -depth 16 rgb:splash.rgb

# 3. Package for firmware:
# This requires specific firmware tools - complex
# Easier to just disable and use FBI for early display
```

## Troubleshooting

**Still seeing boot messages:**
- Check `/boot/firmware/cmdline.txt` has `quiet console=tty3`
- Verify getty disabled: `systemctl status getty@tty1`

**Splash not showing:**
- Check FBI can access /dev/fb0: `fbi -T 1 -l /opt/piframe/splash/loading.png`
- Verify splash.png exists and is 1920x1080

**Screen flickers:**
- FBI is restarting - normal during mount wait
- Can add `fbset -depth 32` before FBI to stabilize
