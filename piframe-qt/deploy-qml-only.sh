#!/bin/bash
# Deploy QML files only - no compilation

PI_HOST="root@192.168.68.75"
PI_DIR="~/piframe-qt"

echo "=== Deploying QML files to Pi (no compilation) ==="

# Copy QML files
scp qml/ClockOverlay.qml $PI_HOST:$PI_DIR/qml/
scp qml/PhotoSlideshow.qml $PI_HOST:$PI_DIR/qml/
scp qml/main.qml $PI_HOST:$PI_DIR/qml/

echo "=== QML files copied ==="
echo "Restart the app to see changes: ssh $PI_HOST 'cd $PI_DIR && ./launch.sh'"
