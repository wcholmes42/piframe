#!/bin/bash
# Disable framebuffer console to prevent white bar artifacts
# This must run before FBI starts

# Unbind all virtual consoles from framebuffer
for vtcon in /sys/class/vtconsole/vtcon*/bind; do
    echo 0 > "$vtcon" 2>/dev/null
done

# Hide cursor on VT1
TERM=linux setterm --cursor off --blank 0 > /dev/tty1 2>/dev/null
printf '\033[?25l' > /dev/tty1 2>/dev/null

# Clear framebuffer to remove boot artifacts
dd if=/dev/zero of=/dev/fb0 bs=1M count=9 2>/dev/null

# Wait for FBI to start and clear the white bar it creates
sleep 5
dd if=/dev/zero of=/dev/fb0 bs=3840 seek=1055 count=25 conv=notrunc 2>/dev/null

echo "Framebuffer console disabled and white bar cleared"
