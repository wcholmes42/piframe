import QtQuick 2.15

Item {
    id: slideshow

    property bool crystalBallEnabled: configManager.crystalBallEnabled
    property real crystalBallCrossfade: 0.0

    property real ballTime: 0.0
    property real kenBurnsScale: 1.0
    property real kenBurnsRotation: 0
    property real kenBurnsX: 0
    property real kenBurnsY: 0

    Timer {
        id: kenBurnsTimer
        running: true
        repeat: true
        interval: 16
        onTriggered: {
            if (slideshow.width === 0 || slideshow.height === 0) return

            ballTime += 0.016 * 2.0
            var intensity = 1.0

            kenBurnsX = Math.sin(ballTime * 0.7) * slideshow.width * 0.3 * intensity
            kenBurnsY = Math.sin(ballTime * 0.9) * slideshow.height * 0.3 * intensity
            kenBurnsScale = 1.2 + (0.5 * Math.sin(ballTime * 0.6)) * intensity
            kenBurnsRotation = 20 * Math.sin(ballTime * 0.5) * intensity

            if (Math.floor(ballTime * 60) % 60 === 0) {
                console.log("KEN BURNS ACTIVE - scale:", kenBurnsScale.toFixed(2), "offsetX:", kenBurnsX.toFixed(0), "rotation:", kenBurnsRotation.toFixed(1))
            }
        }

        Component.onCompleted: {
            console.log("Ken Burns timer initialized - EXTREME MODE")
        }
    }

    Image {
        id: currentImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        smooth: true
        asynchronous: true
        cache: true
        autoTransform: true
        opacity: 0.0
        visible: false

        transform: [
            Translate { x: kenBurnsX; y: kenBurnsY },
            Scale {
                origin.x: currentImage.width / 2
                origin.y: currentImage.height / 2
                xScale: kenBurnsScale
                yScale: kenBurnsScale
            },
            Rotation {
                origin.x: currentImage.width / 2
                origin.y: currentImage.height / 2
                angle: kenBurnsRotation
            }
        ]

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
        cache: true
        autoTransform: true
        opacity: 0.0
        visible: false

        transform: [
            Translate { x: kenBurnsX; y: kenBurnsY },
            Scale {
                origin.x: nextImage.width / 2
                origin.y: nextImage.height / 2
                xScale: kenBurnsScale
                yScale: kenBurnsScale
            },
            Rotation {
                origin.x: nextImage.width / 2
                origin.y: nextImage.height / 2
                angle: kenBurnsRotation
            }
        ]

        layer.enabled: true
        layer.smooth: true

        onStatusChanged: {
            if (status === Image.Error) {
                console.error("Failed to load image:", source);
            }
        }
    }

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

    CrystalBallEffect {
        id: crystalBall
        anchors.fill: parent
        source1: texture1
        source2: texture2
        crossfade: crystalBallCrossfade
        enabled: true
        visible: true
        z: 1
    }

    SequentialAnimation {
        id: transitionAnimation
        ParallelAnimation {
            NumberAnimation { target: currentImage; property: "opacity"; to: 0.0; duration: configManager.transitionDuration; easing.type: Easing.InOutQuad }
            NumberAnimation { target: nextImage; property: "opacity"; to: 1.0; duration: configManager.transitionDuration; easing.type: Easing.InOutQuad }
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

    SequentialAnimation {
        id: slideTransition
        ParallelAnimation {
            NumberAnimation { target: currentImage; property: "x"; from: 0; to: -slideshow.width; duration: configManager.transitionDuration; easing.type: Easing.InOutCubic }
            NumberAnimation { target: nextImage; property: "x"; from: slideshow.width; to: 0; duration: configManager.transitionDuration; easing.type: Easing.InOutCubic }
            NumberAnimation { target: currentImage; property: "opacity"; to: 0.0; duration: configManager.transitionDuration / 2 }
            NumberAnimation { target: nextImage; property: "opacity"; to: 1.0; duration: configManager.transitionDuration / 2 }
            NumberAnimation { target: slideshow; property: "crystalBallCrossfade"; from: 0.0; to: 1.0; duration: configManager.transitionDuration; easing.type: Easing.InOutQuad }
        }
        ScriptAction {
            script: {
                currentImage.x = 0
                nextImage.x = 0
                currentImage.source = nextImage.source
                currentImage.opacity = 1.0
                nextImage.opacity = 0.0
                nextImage.source = ""
                crystalBallCrossfade = 0.0
            }
        }
    }

    SequentialAnimation {
        id: zoomTransition
        ParallelAnimation {
            NumberAnimation { target: currentImage; property: "scale"; from: 1.0; to: 0.8; duration: configManager.transitionDuration; easing.type: Easing.InOutQuad }
            NumberAnimation { target: currentImage; property: "opacity"; to: 0.0; duration: configManager.transitionDuration }
            NumberAnimation { target: nextImage; property: "scale"; from: 1.2; to: 1.0; duration: configManager.transitionDuration; easing.type: Easing.InOutQuad }
            NumberAnimation { target: nextImage; property: "opacity"; to: 1.0; duration: configManager.transitionDuration }
            NumberAnimation { target: slideshow; property: "crystalBallCrossfade"; from: 0.0; to: 1.0; duration: configManager.transitionDuration; easing.type: Easing.InOutQuad }
        }
        ScriptAction {
            script: {
                currentImage.scale = 1.0
                nextImage.scale = 1.0
                currentImage.source = nextImage.source
                currentImage.opacity = 1.0
                nextImage.opacity = 0.0
                nextImage.source = ""
                crystalBallCrossfade = 0.0
            }
        }
    }

    Text {
        id: errorText
        anchors.centerIn: parent
        color: "white"
        font.pixelSize: 32
        text: photoModel.photoCount === 0 ? "No photos found" : ""
        visible: text !== ""
    }

    Connections {
        target: photoModel
        function onCurrentPhotoChanged(photo) {
            if (photo === "") return
            console.log("Loading photo:", photo)
            nextImage.source = "file:///" + photo
            if (nextImage.status === Image.Ready) {
                startTransition()
            } else {
                nextImage.statusChanged.connect(function() {
                    if (nextImage.status === Image.Ready) startTransition()
                })
            }
        }
        function onPhotoCountChanged(count) {
            console.log("Photo count changed:", count)
            if (count === 0) {
                currentImage.source = ""
                nextImage.source = ""
            }
        }
    }

    function startTransition() {
        if (currentImage.source === "") {
            currentImage.source = nextImage.source
            currentImage.opacity = 1.0
            nextImage.opacity = 0.0
            nextImage.source = ""
            return
        }
        var transType = configManager.transitionType
        if (transType === "fade") transitionAnimation.start()
        else if (transType === "slide") slideTransition.start()
        else if (transType === "zoom") zoomTransition.start()
        else transitionAnimation.start()
    }

    Component.onCompleted: {
        if (photoModel.currentPhoto !== "") {
            currentImage.source = "file:///" + photoModel.currentPhoto
        }
    }
}
