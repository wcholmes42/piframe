#!/bin/bash
# Find the active X display
export DISPLAY=$(ps aux | grep '[X]org' | grep -o ':[0-9]*' | head -1)
if [ -z "$DISPLAY" ]; then
    export DISPLAY=:0
fi
# Kill chromium
killall chromium 2>/dev/null
sleep 1
# Launch chromium with black page
chromium --kiosk --no-sandbox --window-size=1920,1080 --incognito 'data:text/html,<html><head><style>*{margin:0;padding:0;background:#000;cursor:none}</style></head><body></body></html>' >/dev/null 2>&1 &
