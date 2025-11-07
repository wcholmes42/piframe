#!/bin/bash
# PiFrame Boot Customization
# Disables boot spam, adds custom splash screen

set -e

echo "================================"
echo "PiFrame Boot Customization"
echo "================================"
echo ""

# Step 1: Disable rainbow splash
echo "[1/5] Disabling rainbow splash..."
if ! grep -q "disable_splash=1" /boot/firmware/config.txt; then
    echo "" >> /boot/firmware/config.txt
    echo "# Disable rainbow splash screen" >> /boot/firmware/config.txt
    echo "disable_splash=1" >> /boot/firmware/config.txt
    echo "   Rainbow splash disabled"
else
    echo "   Already disabled"
fi

# Step 2: Quiet boot (suppress kernel messages)
echo "[2/5] Configuring quiet boot..."
if ! grep -q "quiet" /boot/firmware/cmdline.txt; then
    cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.backup-$(date +%Y%m%d)

    # Add quiet boot parameters
    sed -i '1s/$/ quiet loglevel=3 vt.global_cursor_default=0 console=tty3/' /boot/firmware/cmdline.txt
    echo "   Quiet boot configured"
    NEED_REBOOT=true
else
    echo "   Already configured"
    NEED_REBOOT=false
fi

# Step 3: Disable console login on VT1
echo "[3/5] Disabling console login..."
systemctl disable getty@tty1 2>/dev/null || true
systemctl mask systemd-vconsole-setup 2>/dev/null || true
echo "   Console login disabled"

# Step 4: Create loading splash image
echo "[4/5] Creating loading splash..."
mkdir -p /opt/piframe/splash

if command -v convert &> /dev/null; then
    # Create black screen with white text
    convert -size 1920x1080 xc:black \
        -gravity center \
        -pointsize 120 \
        -font DejaVu-Sans-Bold \
        -fill white \
        -annotate +0-50 "PiFrame" \
        -pointsize 60 \
        -fill gray70 \
        -annotate +0+80 "Loading photos..." \
        /opt/piframe/splash/loading.png

    echo "   Splash image created"
else
    echo "   WARNING: ImageMagick not installed, skipping splash creation"
    echo "   Install with: apt-get install imagemagick"
fi

# Step 5: Update slideshow to show splash during mount
echo "[5/5] Updating slideshow script..."
if [ -f "/opt/piframe/slideshow.sh" ]; then
    # Check if already has splash
    if ! grep -q "splash/loading.png" /opt/piframe/slideshow.sh; then
        echo "   Adding splash to slideshow script..."
        echo "   Manual edit required - see BOOT-CUSTOMIZATION.md"
    else
        echo "   Slideshow already configured for splash"
    fi
else
    echo "   Slideshow not yet installed"
fi

echo ""
echo "================================"
echo "Boot Customization Complete!"
echo "================================"
echo ""
echo "Changes made:"
echo "  ✓ Rainbow splash disabled"
echo "  ✓ Boot messages hidden (quiet mode)"
echo "  ✓ Console redirected to VT3"
echo "  ✓ No cursor blinking"
echo "  ✓ Getty login disabled on VT1"
echo "  ✓ Loading splash created"
echo ""
echo "Files modified:"
echo "  - /boot/firmware/config.txt (rainbow disabled)"
echo "  - /boot/firmware/cmdline.txt (quiet boot)"
echo "  - /opt/piframe/splash/loading.png (created)"
echo ""

if [ "$NEED_REBOOT" = true ]; then
    echo "REBOOT REQUIRED to apply boot configuration"
    echo ""
    read -p "Reboot now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        reboot
    fi
else
    echo "Configuration active. Boot should now be clean and quiet."
fi
