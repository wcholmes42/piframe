import QtQuick 2.15

Item {
    id: slideshow

    property bool crystalBallEnabled: configManager.crystalBallEnabled
    property real crystalBallCrossfade: 0.0

    Image {
        id: currentImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop  // Try Crop instead of Fit
        smooth: true
        asynchronous: true
        cache: true
        autoTransform: true
        opacity: 1.0
        
        // Animated properties - let Qt handle them
        NumberAnimation on scale {
            from: 1.0; to: 1.4; duration: 8000
            loops: Animation.Infinite
            easing.type: Easing.InOutSine
        }
        
        NumberAnimation on rotation {
            from: -10; to: 10; duration: 12000
            loops: Animation.Infinite
            easing.type: Easing.InOutSine
        }
    }

    Image {
        id: nextImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        cache: true
        autoTransform: true
        opacity: 0.0
        
        NumberAnimation on scale {
            from: 1.0; to: 1.4; duration: 8000
            loops: Animation.Infinite
            easing.type: Easing.InOutSine
        }
        
        NumberAnimation on rotation {
            from: -10; to: 10; duration: 12000
            loops: Animation.Infinite
            easing.type: Easing.InOutSine
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
        enabled: crystalBallEnabled
        visible: crystalBallEnabled
        z: 1
    }

    SequentialAnimation {
        id: transitionAnimation
        ParallelAnimation {
            NumberAnimation { target: currentImage; property: "opacity"; to: 0.0; duration: configManager.transitionDuration }
            NumberAnimation { target: nextImage; property: "opacity"; to: 1.0; duration: configManager.transitionDuration }
            NumberAnimation { target: slideshow; property: "crystalBallCrossfade"; from: 0.0; to: 1.0; duration: configManager.transitionDuration }
        }
        ScriptAction {
            script: {
                currentImage.source = nextImage.source;
                currentImage.opacity = 1.0;
                nextImage.opacity = 0.0;
                nextImage.source = "";
                crystalBallCrossfade = 0.0;
            }
        }
    }

    Connections {
        target: photoModel
        function onCurrentPhotoChanged(photo) {
            if (photo === "") return;
            nextImage.source = "file:///" + photo;
            if (nextImage.status === Image.Ready) startTransition();
            else nextImage.statusChanged.connect(function() { if (nextImage.status === Image.Ready) startTransition(); });
        }
    }

    function startTransition() {
        if (currentImage.source === "") {
            currentImage.source = nextImage.source;
            currentImage.opacity = 1.0;
            nextImage.opacity = 0.0;
            nextImage.source = "";
            return;
        }
        transitionAnimation.start();
    }

    Component.onCompleted: {
        if (photoModel.currentPhoto !== "") {
            currentImage.source = "file:///" + photoModel.currentPhoto;
        }
    }
}
