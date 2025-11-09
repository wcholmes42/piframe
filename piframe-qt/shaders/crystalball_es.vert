#version 310 es

layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;

layout(location = 0) out highp vec2 fragCoord;

uniform mat4 qt_Matrix;

void main() {
    fragCoord = qt_MultiTexCoord0;
    gl_Position = qt_Matrix * qt_Vertex;
}
