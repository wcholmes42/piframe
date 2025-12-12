import QtQuick 2.15
import QtQuick.Window 2.15

Window {
    id: root
    visible: true
    width: devMode ? 1280 : configManager.displayWidth
    height: devMode ? 720 : configManager.displayHeight
    visibility: devMode ? Window.Windowed : Window.FullScreen
    title: "PiFrame Qt"
    color: "black"

    // Hide cursor
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.BlankCursor
        propagateComposedEvents: true
        z: 1000
    }

    PhotoSlideshow {
        id: slideshow
        anchors.fill: parent
        z: 0
    }

    ClockOverlay {
        id: clockOverlay
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 20
        z: 100
        visible: overlayManager.clockEnabled
    }

    WeatherOverlay {
        id: weatherOverlay
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: 20
        z: 100
        visible: overlayManager.weatherEnabled
    }

    TextOverlay {
        id: textOverlay
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 80
        width: parent.width * 0.8
        z: 100
        visible: overlayManager.currentMessage !== ""
    }

    HolidayOverlay {
        id: holidayOverlay
        anchors.fill: parent
        z: 50
        visible: overlayManager.holidayEnabled && overlayManager.activeHoliday !== ""
    }

    Rectangle {
        visible: devMode
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: debugText.width + 20
        height: debugText.height + 20
        color: "#80000000"
        z: 200

        Text {
            id: debugText
            anchors.centerIn: parent
            color: "white"
            font.pixelSize: 12
            text: "DEV MODE\n" +
                  "Photos: " + photoModel.photoCount + "\n" +
                  "Index: " + photoModel.currentIndex + "\n" +
                  "Playing: " + photoModel.isPlaying + "\n" +
                  "Interval: " + configManager.slideshowInterval + "s"
        }
    }

    Item {
        anchors.fill: parent
        z: -1
        focus: true

        Keys.onPressed: (event) => {
            if (devMode) {
                if (event.key === Qt.Key_Space) {
                    photoModel.next();
                    event.accepted = true;
                }
                else if (event.key === Qt.Key_P) {
                    if (photoModel.isPlaying) {
                        photoModel.pause();
                    } else {
                        photoModel.resume();
                    }
                    event.accepted = true;
                }
                else if (event.key === Qt.Key_R) {
                    photoModel.refreshPhotos();
                    event.accepted = true;
                }
                else if (event.key === Qt.Key_Q || event.key === Qt.Key_Escape) {
                    Qt.quit();
                    event.accepted = true;
                }
                else if (event.key === Qt.Key_C) {
                    overlayManager.clockEnabled = !overlayManager.clockEnabled;
                    event.accepted = true;
                }
                else if (event.key === Qt.Key_H) {
                    overlayManager.holidayEnabled = !overlayManager.holidayEnabled;
                    event.accepted = true;
                }
                else if (event.key === Qt.Key_T) {
                    overlayManager.sendMessage("Test message from keyboard!", 5);
                    event.accepted = true;
                }
            }
        }
    }

    Component.onCompleted: {
        if (devMode) {
            console.log("=== PiFrame Qt Dev Mode ===");
            console.log("Keyboard shortcuts:");
            console.log("  SPACE: Next photo");
            console.log("  P: Play/Pause");
            console.log("  R: Refresh photos");
            console.log("  C: Toggle clock");
            console.log("  H: Toggle holiday animations");
            console.log("  T: Test message");
            console.log("  Q/ESC: Quit");
            console.log("========================");
        }
    }
}
