#!/bin/bash
# Find the active X display
export DISPLAY=$(ps aux | grep '[X]org' | grep -o ':[0-9]*' | head -1)
if [ -z "$DISPLAY" ]; then
    echo "No X server running, starting X..."
    startx </dev/null >/dev/null 2>&1 &
    sleep 8
    export DISPLAY=:0
fi
# Kill any existing chromium
killall chromium 2>/dev/null
sleep 1
# Start chromium with slideshow
chromium --kiosk --no-sandbox --window-size=1920,1080 --noerrdialogs --disable-infobars --incognito http://localhost:5000/slideshow >/dev/null 2>&1 &
