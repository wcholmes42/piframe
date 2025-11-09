import QtQuick 2.15

Item {
    id: weatherOverlay
    width: weatherRow.width
    height: weatherRow.height

    // Hardware-accelerated layer
    layer.enabled: true
    layer.smooth: true

    Row {
        id: weatherRow
        spacing: 15

        // Weather icon (placeholder - could load actual icons)
        Rectangle {
            width: 80
            height: 80
            radius: 40
            color: "#60FFFFFF"

            Text {
                anchors.centerIn: parent
                text: getWeatherIcon()
                font.pixelSize: 48
                color: "white"
            }

            layer.enabled: true
        }

        Column {
            spacing: 5
            anchors.verticalCenter: parent.verticalCenter

            // Temperature
            Text {
                text: overlayManager.weatherTemp + "°F"
                font.pixelSize: 48
                font.bold: true
                font.family: "Arial"
                color: "white"

                layer.enabled: true
            }

            // Weather description
            Text {
                text: overlayManager.weatherInfo
                font.pixelSize: 24
                font.family: "Arial"
                color: "white"

                layer.enabled: true
            }
        }
    }

    // Smooth fade transitions
    Behavior on opacity {
        NumberAnimation {
            duration: 300
            easing.type: Easing.InOutQuad
        }
    }

    // Helper function to get weather icon (emoji/unicode)
    function getWeatherIcon() {
        var info = overlayManager.weatherInfo.toLowerCase();

        if (info.includes("sunny") || info.includes("clear")) {
            return "☀";
        } else if (info.includes("cloud")) {
            return "☁";
        } else if (info.includes("rain")) {
            return "🌧";
        } else if (info.includes("snow")) {
            return "❄";
        } else if (info.includes("storm")) {
            return "⛈";
        } else if (info.includes("fog")) {
            return "🌫";
        } else {
            return "🌤";
        }
    }

    // Update animation when weather data changes
    Connections {
        target: overlayManager

        function onWeatherInfoChanged(info) {
            // Subtle scale animation on update
            scaleAnimation.start();
        }
    }

    SequentialAnimation {
        id: scaleAnimation

        NumberAnimation {
            target: weatherRow
            property: "scale"
            to: 1.1
            duration: 200
            easing.type: Easing.OutQuad
        }

        NumberAnimation {
            target: weatherRow
            property: "scale"
            to: 1.0
            duration: 200
            easing.type: Easing.InQuad
        }
    }
}
