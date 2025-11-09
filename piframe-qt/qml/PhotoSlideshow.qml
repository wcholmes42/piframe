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

    // Animation timer - ALWAYS runs for Ken Burns, amplified when crystal ball active
    Timer {
        running: true  // Always running!
        repeat: true
        interval: 16  // 60 FPS for smooth motion
        onTriggered: {
            ballTime += 0.016 * 0.8
            // Ken Burns motion - smooth and beautiful
            var intensity = crystalBallEnabled ? 1.0 : 0.4  // Gentler when ball off
            ballOffsetX = Math.sin(ballTime * 0.7) * width * 0.15 * intensity + Math.sin(ballTime * 1.1) * width * 0.08 * intensity
            ballOffsetY = Math.sin(ballTime * 0.9) * height * 0.15 * intensity + Math.sin(ballTime * 1.3) * height * 0.08 * intensity
            // Pulsing zoom
            ballScale = 1.05 + (0.25 * Math.sin(ballTime * 0.6) + 0.2 * Math.sin(ballTime * 1.0)) * intensity
            // Rotation
            ballRotation = 8 * Math.sin(ballTime * 0.5) * intensity
        }
    }

    // Two image layers for crossfade transitions
    Image {
        id: currentImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        smooth: true
        asynchronous: true
        cache: true  // Enable cache to prevent reload on source copy
        autoTransform: true  // Automatically apply EXIF orientation
        opacity: 1.0  // Always visible (shader handles visibility)

        // Ken Burns transforms - ALWAYS ACTIVE with crystal ball!
        transform: [
            Translate {
                x: ballOffsetX
                y: ballOffsetY
            },
            Scale {
                origin.x: currentImage.width / 2
                origin.y: currentImage.height / 2
                xScale: ballScale
                yScale: ballScale
            },
            Rotation {
                origin.x: currentImage.width / 2
                origin.y: currentImage.height / 2
                angle: ballRotation
            }
        ]

        // Hardware acceleration
        layer.enabled: true
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
        fillMode: Image.PreserveAspectFit
        smooth: true
        asynchronous: true
        cache: true  // Enable cache to prevent reload on source copy
        autoTransform: true  // Automatically apply EXIF orientation
        opacity: 0.0  // Hidden initially (shader controls during transition)

        // Ken Burns transforms - ALWAYS ACTIVE with crystal ball!
        transform: [
            Translate {
                x: ballOffsetX
                y: ballOffsetY
            },
            Scale {
                origin.x: nextImage.width / 2
                origin.y: nextImage.height / 2
                xScale: ballScale
                yScale: ballScale
            },
            Rotation {
                origin.x: nextImage.width / 2
                origin.y: nextImage.height / 2
                angle: ballRotation
            }
        ]

        // Hardware acceleration
        layer.enabled: true
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

    // Crystal ball effect layer
    CrystalBallEffect {
        id: crystalBall
        anchors.fill: parent
        source1: texture1
        source2: texture2
        crossfade: crystalBallCrossfade
        enabled: crystalBallEnabled
        visible: crystalBallEnabled
        z: 1
    }
    // Transition animation
    SequentialAnimation {
        id: transitionAnimation

        ParallelAnimation {
            // Fade out current image (normal mode)
            NumberAnimation {
                target: currentImage
                property: "opacity"
                to: 0.0
                duration: configManager.transitionDuration
                easing.type: Easing.InOutQuad
            }

            // Fade in next image (normal mode)
            NumberAnimation {
                target: nextImage
                property: "opacity"
                to: 1.0
                duration: configManager.transitionDuration
                easing.type: Easing.InOutQuad
            }

            // Crystal ball crossfade (crystal ball mode)
            NumberAnimation {
                target: slideshow
                property: "crystalBallCrossfade"
                from: 0.0
                to: 1.0
                duration: configManager.transitionDuration
                easing.type: Easing.InOutQuad
            }
        }

        ScriptAction {
            script: {
                // Copy to currentImage (uses cache, instant)
                currentImage.source = nextImage.source;
                currentImage.opacity = 1.0;

                // Reset nextImage for next photo
                nextImage.opacity = 0.0;
                nextImage.source = "";

                // Reset crystal ball crossfade
                crystalBallCrossfade = 0.0;
            }
        }
    }

    // Slide transition (alternative)
    SequentialAnimation {
        id: slideTransition

        ParallelAnimation {
            // Slide current image out to left (normal mode)
            NumberAnimation {
                target: currentImage
                property: "x"
                from: 0
                to: -slideshow.width
                duration: configManager.transitionDuration
                easing.type: Easing.InOutCubic
            }

            // Slide next image in from right (normal mode)
            NumberAnimation {
                target: nextImage
                property: "x"
                from: slideshow.width
                to: 0
                duration: configManager.transitionDuration
                easing.type: Easing.InOutCubic
            }

            // Fade animations for smoother look (normal mode)
            NumberAnimation {
                target: currentImage
                property: "opacity"
                to: 0.0
                duration: configManager.transitionDuration / 2
            }

            NumberAnimation {
                target: nextImage
                property: "opacity"
                to: 1.0
                duration: configManager.transitionDuration / 2
            }

            // Crystal ball crossfade (crystal ball mode)
            NumberAnimation {
                target: slideshow
                property: "crystalBallCrossfade"
                from: 0.0
                to: 1.0
                duration: configManager.transitionDuration
                easing.type: Easing.InOutQuad
            }
        }

        ScriptAction {
            script: {
                // Reset positions
                currentImage.x = 0;
                nextImage.x = 0;

                // Copy to currentImage (uses cache)
                currentImage.source = nextImage.source;
                currentImage.opacity = 1.0;

                // Reset nextImage
                nextImage.opacity = 0.0;
                nextImage.source = "";

                // Reset crystal ball crossfade
                crystalBallCrossfade = 0.0;
            }
        }
    }

    // Zoom transition (alternative)
    SequentialAnimation {
        id: zoomTransition

        ParallelAnimation {
            // Zoom out current image (normal mode)
            NumberAnimation {
                target: currentImage
                property: "scale"
                from: 1.0
                to: 0.8
                duration: configManager.transitionDuration
                easing.type: Easing.InOutQuad
            }

            NumberAnimation {
                target: currentImage
                property: "opacity"
                to: 0.0
                duration: configManager.transitionDuration
            }

            // Zoom in next image (normal mode)
            NumberAnimation {
                target: nextImage
                property: "scale"
                from: 1.2
                to: 1.0
                duration: configManager.transitionDuration
                easing.type: Easing.InOutQuad
            }

            NumberAnimation {
                target: nextImage
                property: "opacity"
                to: 1.0
                duration: configManager.transitionDuration
            }

            // Crystal ball crossfade (crystal ball mode)
            NumberAnimation {
                target: slideshow
                property: "crystalBallCrossfade"
                from: 0.0
                to: 1.0
                duration: configManager.transitionDuration
                easing.type: Easing.InOutQuad
            }
        }

        ScriptAction {
            script: {
                // Reset scale
                currentImage.scale = 1.0;
                nextImage.scale = 1.0;

                // Copy to currentImage (uses cache)
                currentImage.source = nextImage.source;
                currentImage.opacity = 1.0;

                // Reset nextImage
                nextImage.opacity = 0.0;
                nextImage.source = "";

                // Reset crystal ball crossfade
                crystalBallCrossfade = 0.0;
            }
        }
    }

    // Loading indicator (disabled - images load fast enough)
    Rectangle {
        id: loadingIndicator
        anchors.centerIn: parent
        width: 100
        height: 100
        radius: 50
        color: "#40FFFFFF"
        visible: false  // Disabled - no more loading spinner

        RotationAnimation on rotation {
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 1000
            running: loadingIndicator.visible
        }

        Rectangle {
            width: 20
            height: 20
            radius: 10
            color: "white"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 10
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

