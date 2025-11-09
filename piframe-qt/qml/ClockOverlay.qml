import QtQuick 2.15

Item {
    id: clockOverlay
    width: clockColumn.width
    height: clockColumn.height

    // Hardware-accelerated layer for GPU compositing
    layer.enabled: true
    layer.smooth: true

    Column {
        id: clockColumn
        spacing: 5

        // Time display
        Text {
            id: timeText
            text: overlayManager.currentTime
            font.pixelSize: 72
            font.bold: true
            font.family: "DejaVu Sans"
            color: "white"
            horizontalAlignment: Text.AlignRight
            width: 450  // Extra space for "12:59:59 PM"
            elide: Text.ElideNone
            renderType: Text.QtRendering

            // GPU-accelerated layer
            layer.enabled: true
        }

        // Date display
        Text {
            id: dateText
            text: overlayManager.currentDate
            font.pixelSize: 24
            font.family: "DejaVu Sans"
            color: "white"
            horizontalAlignment: Text.AlignRight
            width: 450  // Match time width
            elide: Text.ElideNone
            renderType: Text.QtRendering

            // GPU-accelerated layer
            layer.enabled: true
        }
    }

    // Smooth fade in/out when visibility changes
    Behavior on opacity {
        NumberAnimation {
            duration: 300
            easing.type: Easing.InOutQuad
        }
    }

    // Debug: Log when clock updates
    Connections {
        target: overlayManager
        function onCurrentTimeChanged(time) {
            // Only log in dev mode to avoid spam
            if (devMode && time.endsWith("00")) {
                console.log("Clock updated:", time);
            }
        }
    }
}
