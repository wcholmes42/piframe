import QtQuick 2.15

// Adaptive text that changes color based on background brightness
ShaderEffect {
    id: root

    property variant textSource  // The text to display
    property variant backgroundSource  // The photo behind it
    property color baseColor: "white"
    property real contrastStrength: 1.0

    vertexShader: "qrc:/shaders/textshadow.vert.qsb"
    fragmentShader: "qrc:/shaders/textshadow.frag.qsb"

    // Expose properties to shader
    property vector2d shadowOffset: Qt.vector2d(2, 2)
    property real shadowSpread: 3.0
    property vector4d shadowColor: Qt.vector4d(0, 0, 0, 1)
}
