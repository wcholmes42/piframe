import QtQuick 2.15

Item {
    id: slideshow

    // Crystal ball mode toggle - wired to config
    property bool crystalBallEnabled: configManager.crystalBallEnabled
    property real crystalBallCrossfade: 0.0  // 0.0 to 1.0 during transitions

    // Animation properties for crystal ball effect
    property real ballTime: 0.0
    property real ballScale: 1.0
    property real ballRotation: 0
    property real ballOffsetX: 0
    property real ballOffsetY: 0

    // Animation timer - ALWAYS runs for Ken Burns - EXTREME VALUES FOR TESTING!
    Timer {
        id: kenBurnsTimer
        running: true  // Always running!
        repeat: true
        interval: 16  // 60 FPS for smooth motion
        onTriggered: {
            // Safety check for valid dimensions
            if (slideshow.width === 0 || slideshow.height === 0) return

            ballTime += 0.016 * 2.0  // FASTER for visibility
            var intensity = 1.0  // ALWAYS FULL INTENSITY

            // MASSIVE motion so you HAVE to see it
            ballOffsetX = Math.sin(ballTime * 0.7) * slideshow.width * 0.3 * intensity
            ballOffsetY = Math.sin(ballTime * 0.9) * slideshow.height * 0.3 * intensity
            // HUGE zoom
            ballScale = 1.2 + (0.5 * Math.sin(ballTime * 0.6)) * intensity
            // BIG rotation
            ballRotation = 20 * Math.sin(ballTime * 0.5) * intensity

            // DEBUG - log every 60 frames
            if (Math.floor(ballTime * 60) % 60 === 0) {
                console.log("KEN BURNS ACTIVE - scale:", ballScale.toFixed(2), "offsetX:", ballOffsetX.toFixed(0), "rotation:", ballRotation.toFixed(1))
            }
        }

        Component.onCompleted: {
            console.log("Ken Burns timer initialized - EXTREME MODE")
        }
    }

    // Two image layers for crossfade transitions
    Image {
        id: currentImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        cache: true
        autoTransform: false
        opacity: 0.0
        scale: 1.0
        x: 0
        y: 0
        visible: false

        // NO transforms here - will be applied to ball shader output
        layer.enabled: false
        layer.smooth: true

        onStatusChanged: {
            if (status === Image.Error) {
                console.error("Failed to load image:", source);
            }
        }
    }

    Image {
        id: nextImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        cache: true
        autoTransform: false
        opacity: 0.0
        scale: 1.0
        x: 0
        y: 0
        visible: false

        // NO transforms here - will be applied to ball shader output
        layer.enabled: false
        layer.smooth: true

        onStatusChanged: {
            if (status === Image.Error) {
                console.error("Failed to load image:", source);
            }
        }
    }

    // Shader texture sources for crystal ball mode
    ShaderEffectSource {
        id: texture1
        sourceItem: currentImage
        hideSource: false
        visible: false
        live: true
    }

    ShaderEffectSource {
        id: texture2
        sourceItem: nextImage
        hideSource: false
        visible: false
        live: true
    }

    // Crystal ball effect layer - ALWAYS SHOW KEN BURNS!
    CrystalBallEffect {
        id: crystalBall
        anchors.fill: parent
        source1: texture1
        source2: texture2
        crossfade: crystalBallCrossfade
        enabled: true  // ALWAYS enabled to show Ken Burns
        visible: true  // ALWAYS visible
        z: 1

        // Apply Ken Burns transforms to the BALL output!
        transform: [
            Translate {
                x: ballOffsetX
                y: ballOffsetY
            },
            Scale {
                origin.x: crystalBall.width / 2
                origin.y: crystalBall.height / 2
                xScale: ballScale
                yScale: ballScale
            },
            Rotation {
                origin.x: crystalBall.width / 2
                origin.y: crystalBall.height / 2
                angle: ballRotation
            }
        ]
    }
    // Transition animation
    SequentialAnimation {
        id: transitionAnimation
        ParallelAnimation {
            NumberAnimation { target: slideshow; property: "crystalBallCrossfade"; from: 0.0; to: 1.0; duration: configManager.transitionDuration; easing.type: Easing.InOutQuad }
        }
        ScriptAction {
            script: {
                currentImage.source = nextImage.source
                currentImage.opacity = 1.0
                nextImage.opacity = 0.0
                nextImage.source = ""
                crystalBallCrossfade = 0.0
            }
        }
    }

    // Error message
    Text {
        id: errorText
        anchors.centerIn: parent
        color: "white"
        font.pixelSize: 32
        text: photoModel.photoCount === 0 ? "No photos found" : ""
        visible: text !== ""
    }

    // React to photo changes from C++ model
    Connections {
        target: photoModel

        function onCurrentPhotoChanged(photo) {
            if (photo === "") {
                return;
            }

            console.log("Loading photo:", photo);

            // Load next image in background
            nextImage.source = "file:///" + photo;

            // Wait for image to load, then transition
            if (nextImage.status === Image.Ready) {
                startTransition();
            } else {
                // Image not ready yet, wait for it
                nextImage.statusChanged.connect(function() {
                    if (nextImage.status === Image.Ready) {
                        startTransition();
                    }
                });
            }
        }

        function onPhotoCountChanged(count) {
            console.log("Photo count changed:", count);
            if (count === 0) {
                currentImage.source = "";
                nextImage.source = "";
            }
        }
    }

    function startTransition() {
        // Don't transition if this is the first photo
        if (currentImage.source === "") {
            currentImage.source = nextImage.source;
            currentImage.opacity = 1.0;
            nextImage.opacity = 0.0;
            nextImage.source = "";
            return;
        }

        // Select transition type
        var transType = configManager.transitionType;

        if (transType === "fade") {
            transitionAnimation.start();
        } else if (transType === "slide") {
            slideTransition.start();
        } else if (transType === "zoom") {
            zoomTransition.start();
        } else {
            // Default to fade
            transitionAnimation.start();
        }
    }

    // Initialize first photo
    // Initialize first photo and trigger color update
    Component.onCompleted: {
        if (photoModel.currentPhoto !== "") {
            currentImage.source = "file:///" + photoModel.currentPhoto;
        }
        // Trigger initial color calculation
        Qt.callLater(function() {
            if (photoModel.currentPhoto !== "") {
                // Force color update on startup
            }
        });
    }
}

