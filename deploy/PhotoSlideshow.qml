import QtQuick 2.15

Item {
    id: slideshow

    // Ken Burns animation time tracker
    property real kbTime: 0.0

    // Ken Burns timer - smooth continuous animation
    Timer {
        id: kbTimer
        interval: 33  // ~30fps
        running: true
        repeat: true
        onTriggered: {
            kbTime += 0.033
        }
    }

    Image {
        id: currentImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        cache: true
        autoTransform: true
        opacity: 1.0

        // Ken Burns - ensures image always covers screen at max rotation
        // For 3° rotation on 16:9, need min scale ~1.10 to cover corners
        // Scale: 1.12x to 1.18x, Rotation: -3 to +3 degrees
        scale: 1.15 + 0.03 * Math.sin(kbTime * 0.15)
        rotation: 3 * Math.sin(kbTime * 0.12)
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

        // Same Ken Burns effect
        scale: 1.15 + 0.03 * Math.sin(kbTime * 0.15)
        rotation: 3 * Math.sin(kbTime * 0.12)
    }

    SequentialAnimation {
        id: transitionAnimation
        ParallelAnimation {
            NumberAnimation { target: currentImage; property: "opacity"; to: 0.0; duration: configManager.transitionDuration }
            NumberAnimation { target: nextImage; property: "opacity"; to: 1.0; duration: configManager.transitionDuration }
        }
        ScriptAction {
            script: {
                currentImage.source = nextImage.source;
                currentImage.opacity = 1.0;
                nextImage.opacity = 0.0;
                nextImage.source = "";
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
