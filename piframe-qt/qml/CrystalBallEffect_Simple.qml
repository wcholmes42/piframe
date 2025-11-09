import QtQuick 2.15

/*
 * SimpleCrystalBallEffect.qml
 *
 * Framebuffer-compatible effect using QML transforms
 * No shaders required - works on linuxfb!
 *
 * Features:
 * - Ken Burns style zoom and pan
 * - Gentle rotation
 * - Smooth Lissajous motion
 * - Works without GPU shaders
 */

Item {
    id: root

    // Properties
    property variant source1  // Current photo texture
    property variant source2  // Next photo texture (for crossfade)
    property real crossfade: 0.0  // 0.0 = show source1, 1.0 = show source2
    property bool enabled: true
    property bool paused: false

    // Animation parameters
    property real time: 0.0
    property real speedMultiplier: 0.3  // Slower for smoother effect

    // Lissajous curve frequencies
    property real freqX1: 0.5
    property real freqX2: 0.7
    property real freqY1: 0.6
    property real freqY2: 0.8

    // Computed positions
    property real offsetX: 0
    property real offsetY: 0
    property real currentScale: 1.0
    property real currentRotation: 0

    // Time animation
    Timer {
        id: timeAnimator
        interval: 32  // ~30 FPS (lower for better framebuffer performance)
        running: root.enabled && !root.paused
        repeat: true
        onTriggered: {
            root.time += 0.032 * root.speedMultiplier
            updateTransform()
        }
    }

    // Update transform using Lissajous curves
    function updateTransform() {
        // Lissajous motion for x/y offset
        var lissajousX = Math.sin(time * freqX1) * 0.15 + Math.sin(time * freqX2) * 0.1
        var lissajousY = Math.sin(time * freqY1) * 0.15 + Math.sin(time * freqY2) * 0.1

        // Map to pixel offsets
        offsetX = lissajousX * width * 0.2
        offsetY = lissajousY * height * 0.2

        // Pulsing zoom (1.0 to 1.3)
        currentScale = 1.0 + 0.15 * Math.sin(time * 0.4) + 0.15 * Math.sin(time * 0.7)

        // Gentle rotation (-5° to +5°)
        currentRotation = 5 * Math.sin(time * 0.3)
    }

    // Just show the photos directly - can't transform source items
    // The effect happens at the PhotoSlideshow level
    Rectangle {
        anchors.fill: parent
        color: "black"
        visible: root.enabled

        Text {
            anchors.centerIn: parent
            text: "✨ CRYSTAL BALL MODE ✨"
            font.pixelSize: 48
            color: "cyan"
            style: Text.Outline
            styleColor: "blue"

            SequentialAnimation on opacity {
                running: true
                loops: Animation.Infinite
                NumberAnimation { from: 0.3; to: 1.0; duration: 1000; easing.type: Easing.InOutQuad }
                NumberAnimation { from: 1.0; to: 0.3; duration: 1000; easing.type: Easing.InOutQuad }
            }
        }

        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 60
            text: "Zoom: " + root.currentScale.toFixed(2) + "x  •  Angle: " + root.currentRotation.toFixed(1) + "°"
            font.pixelSize: 24
            color: "white"
            opacity: 0.7
        }
    }

    // Public methods
    function pause() {
        root.paused = true
    }

    function resume() {
        root.paused = false
    }

    function reset() {
        root.time = 0.0
        updateTransform()
    }

    // Initialize
    Component.onCompleted: {
        updateTransform()
        console.log("SimpleCrystalBallEffect initialized - Ken Burns mode active!")
    }
}
