import QtQuick 2.15

Rectangle {
    id: textOverlay
    height: messageText.height + 40
    color: "#D0000000"
    radius: 20
    visible: overlayManager.currentMessage !== ""

    // Hardware-accelerated layer
    layer.enabled: true
    layer.smooth: true

    // Semi-transparent background with blur effect

    Text {
        id: messageText
        anchors.centerIn: parent
        anchors.margins: 20
        width: parent.width - 40
        text: overlayManager.currentMessage
        font.pixelSize: 42
        font.bold: true
        font.family: "Arial"
        color: "white"
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
    }

    // Fade in animation when message appears
    SequentialAnimation {
        id: fadeInAnimation
        running: false

        NumberAnimation {
            target: textOverlay
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 400
            easing.type: Easing.OutCubic
        }
    }

    // Fade out animation when message disappears
    SequentialAnimation {
        id: fadeOutAnimation
        running: false

        NumberAnimation {
            target: textOverlay
            property: "opacity"
            from: 1.0
            to: 0.0
            duration: 400
            easing.type: Easing.InCubic
        }
    }

    // Slide up entrance animation (alternative)
    SequentialAnimation {
        id: slideUpAnimation
        running: false

        ParallelAnimation {
            NumberAnimation {
                target: textOverlay
                property: "anchors.bottomMargin"
                from: -textOverlay.height
                to: 80
                duration: 500
                easing.type: Easing.OutBack
                easing.overshoot: 1.2
            }

            NumberAnimation {
                target: textOverlay
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 300
                easing.type: Easing.OutCubic
            }
        }
    }

    // React to message changes
    Connections {
        target: overlayManager

        function onCurrentMessageChanged(message) {
            if (message !== "") {
                console.log("Showing message:", message);
                fadeInAnimation.start();
                // slideUpAnimation.start();  // Alternative entrance
            } else {
                fadeOutAnimation.start();
            }
        }
    }

    // Pulse animation for emphasis (optional, can be triggered)
    SequentialAnimation {
        id: pulseAnimation
        running: false
        loops: 3

        NumberAnimation {
            target: messageText
            property: "scale"
            to: 1.1
            duration: 200
            easing.type: Easing.OutQuad
        }

        NumberAnimation {
            target: messageText
            property: "scale"
            to: 1.0
            duration: 200
            easing.type: Easing.InQuad
        }
    }

    // Optional: Auto-start pulse on new messages
    onVisibleChanged: {
        if (visible && overlayManager.currentMessage !== "") {
            // pulseAnimation.start();  // Uncomment for pulse effect
        }
    }
}
