#!/bin/bash
# PiFrame FBI Slideshow with Boot Splash
# Shows loading screen during network mount, then starts slideshow

PHOTO_DIR="/mnt/photos"
TEMP_DIR="/tmp/photos-with-clock"
INTERVAL=10
LOG_FILE="/var/log/piframe-fbi.log"
SPLASH_IMAGE="/opt/piframe/splash/loading.png"

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

generate_timestamped_photos() {
    local folder=$1
    local time_text=$(date +"%I:%M %p" | sed 's/^0//')
    local source="$PHOTO_DIR/$folder"
    local output="$TEMP_DIR/$folder"

    mkdir -p "$output"
    rm -f "$output"/*.png

    log "Adding timestamp '$time_text' to photos..."

    local count=0
    for photo in "$source"/*.png; do
        if [ -f "$photo" ]; then
            filename=$(basename "$photo")
            convert "$photo" \
                -gravity North \
                -pointsize 72 \
                -font DejaVu-Sans-Bold \
                -fill black \
                -annotate +2+22 "$time_text" \
                -fill white \
                -annotate +0+20 "$time_text" \
                "$output/$filename" 2>/dev/null && ((count++))
        fi
    done

    log "   Generated $count timestamped photos"
}

# Show loading splash during mount
show_loading_splash() {
    if [ -f "$SPLASH_IMAGE" ]; then
        log "Displaying loading splash..."
        fbi -T 1 -a --noverbose "$SPLASH_IMAGE" </dev/null >/dev/null 2>&1 &
        SPLASH_PID=$!
        echo $SPLASH_PID > /tmp/splash.pid
    fi
}

hide_loading_splash() {
    if [ -f "/tmp/splash.pid" ]; then
        local pid=$(cat /tmp/splash.pid)
        kill $pid 2>/dev/null || true
        rm -f /tmp/splash.pid
    fi
}

# Wait for network mount with splash
wait_for_mount() {
    show_loading_splash

    log "Waiting for network mount: $PHOTO_DIR"

    local timeout=60
    local elapsed=0

    while ! mountpoint -q "$PHOTO_DIR"; do
        if [ $elapsed -ge $timeout ]; then
            log "ERROR: Mount timeout after ${timeout}s"
            hide_loading_splash
            return 1
        fi

        sleep 1
        ((elapsed++))
    done

    log "Network mount ready"
    hide_loading_splash
    return 0
}

# Main execution
log "PiFrame FBI Slideshow starting"

# Wait for network mount (shows splash)
if ! wait_for_mount; then
    log "FATAL: Cannot start without mounted photos"
    exit 1
fi

# Main slideshow loop
LAST_BRIGHTNESS=""

while true; do
    # Get current brightness folder
    BRIGHTNESS=$(get_brightness_folder)

    # If brightness changed, restart slideshow
    if [ "$BRIGHTNESS" != "$LAST_BRIGHTNESS" ]; then
        log "Switching to $BRIGHTNESS brightness"

        # Kill existing fbi
        killall fbi 2>/dev/null

        # Generate timestamped photos
        generate_timestamped_photos "$BRIGHTNESS"

        # Start new slideshow
        FOLDER="$TEMP_DIR/$BRIGHTNESS"

        if [ -d "$FOLDER" ]; then
            PHOTO_COUNT=$(ls "$FOLDER"/*.png 2>/dev/null | wc -l)
            log "Starting slideshow: $PHOTO_COUNT photos from $FOLDER/"

            # fbi options:
            # -T 1 = use VT1 (console 1)
            # -a = autoscale images
            # --noverbose = no text overlay
            # -t $INTERVAL = seconds between photos
            # -u = random order
            # -l = loop forever
            fbi -T 1 -a --noverbose -t $INTERVAL -u -l "$FOLDER"/*.png </dev/null >/dev/null 2>&1 &
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
