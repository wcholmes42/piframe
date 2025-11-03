#!/bin/bash
rm -f /tmp/nightmode
killall -9 chromium xinit Xorg 2>/dev/null
sleep 2
startx </dev/null >/dev/null 2>&1 &
