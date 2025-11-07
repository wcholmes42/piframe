#!/bin/bash
# PiFrame FBI Slideshow - Direct Framebuffer (No X11)
# Shows original photos without timestamps (clock overlay runs separately)

PHOTO_DIR="/mnt/photos"
INTERVAL=10
LOG_FILE="/var/log/piframe-fbi.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

get_brightness_folder() {
    local hour=$(date +%H)

    if [ $hour -ge 19 ] || [ $hour -lt 8 ]; then
        echo "dim"
    elif [ $hour -ge 17 ]; then
        echo "medium"
    else
        echo "bright"
    fi
}

log "PiFrame FBI Slideshow starting"

LAST_BRIGHTNESS=""

while true; do
    # Get current brightness folder
    BRIGHTNESS=$(get_brightness_folder)

    # If brightness changed, restart slideshow
    if [ "$BRIGHTNESS" != "$LAST_BRIGHTNESS" ]; then
        log "Switching to $BRIGHTNESS brightness"

        # Kill existing fbi
        killall fbi 2>/dev/null

        # Start new slideshow with original photos
        FOLDER="$PHOTO_DIR/$BRIGHTNESS"

        if [ -d "$FOLDER" ]; then
            PHOTO_COUNT=$(ls "$FOLDER"/*.png 2>/dev/null | wc -l)
            log "Starting slideshow: $PHOTO_COUNT photos from $FOLDER/"

            # fbi options:
            # -a = autoscale images
            # --noverbose = no text overlay
            # -t $INTERVAL = seconds between photos
            # -u = random order
            # -l = loop forever
            # Use openvt to properly start on VT1 (prevents white bar artifact)
            openvt -c 1 -s -f -- fbi -a --noverbose -t $INTERVAL -u -l "$FOLDER"/*.png &
            FBI_PID=$!
            echo $FBI_PID > /tmp/fbi.pid
            log "FBI started (PID: $FBI_PID)"
        else
            log "ERROR: Folder not found: $FOLDER"
        fi

        LAST_BRIGHTNESS="$BRIGHTNESS"
    fi

    # Check every 60 seconds for brightness changes
    sleep 60
done
