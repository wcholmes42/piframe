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
            font.family: "Sans Serif"
            color: "white"
            horizontalAlignment: Text.AlignRight
            width: 300  // Fixed width to prevent pulsing
            elide: Text.ElideNone
            renderType: Text.NativeRendering

            // GPU-accelerated layer
            layer.enabled: true
        }

        // Date display
        Text {
            id: dateText
            text: overlayManager.currentDate
            font.pixelSize: 24
            font.family: "Arial"
            color: "white"
            horizontalAlignment: Text.AlignRight
            width: timeText.width

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
