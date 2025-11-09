#version 100

attribute vec4 qt_Vertex;
attribute vec2 qt_MultiTexCoord0;

varying highp vec2 fragCoord;

uniform mat4 qt_Matrix;

void main() {
    fragCoord = qt_MultiTexCoord0;
    gl_Position = qt_Matrix * qt_Vertex;
}
