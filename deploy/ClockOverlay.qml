import QtQuick 2.15

Item {
    id: clockOverlay
    width: 600
    height: 180

    // SMOOTH fade using Rectangle gradient (no shader needed!)
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        
        // Center to edge radial using multiple rectangles with gradient
        Rectangle {
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            radius: 25
            
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "#60000000" }
                GradientStop { position: 0.2; color: "#70000000" }
                GradientStop { position: 0.5; color: "#70000000" }
                GradientStop { position: 0.8; color: "#50000000" }
                GradientStop { position: 1.0; color: "#20000000" }
            }
            
            // Additional horizontal fade
            opacity: 0.9
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: overlayManager.currentTime
            font.pixelSize: 72
            font.bold: true
            font.family: "DejaVu Sans"
            color: overlayManager.adaptiveTextColor
            style: Text.Outline
            styleColor: "black"

            Behavior on color { ColorAnimation { duration: 600 } }
        }

        Text {
            text: overlayManager.currentDate
            font.pixelSize: 24
            font.family: "DejaVu Sans"
            color: overlayManager.adaptiveTextColor
            style: Text.Outline
            styleColor: "black"

            Behavior on color { ColorAnimation { duration: 600 } }
        }
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: {
            var photo = photoModel.currentPhoto.toLowerCase()
            var brightness = 0.5
            var dominant = Qt.rgba(0.5, 0.5, 0.5, 1.0)

            if (photo.indexOf("/bright/") >= 0) {
                brightness = 0.85
                dominant = Qt.rgba(0.9, 0.8, 0.6, 1.0)
            } else if (photo.indexOf("/dim/") >= 0) {
                brightness = 0.15  // DARK -> will make text BRIGHT
                dominant = Qt.rgba(0.25, 0.3, 0.4, 1.0)
            } else if (photo.indexOf("/medium/") >= 0) {
                brightness = 0.5
                dominant = Qt.rgba(0.5, 0.55, 0.5, 1.0)
            } else {
                // Default for uncategorized
                brightness = 0.5
                dominant = Qt.rgba(0.5, 0.5, 0.5, 1.0)
            }

            overlayManager.backgroundBrightness = brightness
            overlayManager.dominantColor = dominant
        }
    }
}
