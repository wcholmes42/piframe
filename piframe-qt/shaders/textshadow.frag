#version 310 es
precision highp float;

layout(location = 0) in highp vec2 fragCoord;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 shadowOffset;
    float shadowSpread;
    vec4 shadowColor;
};

layout(binding = 1) uniform sampler2D source;

void main() {
    vec4 textColor = texture(source, fragCoord);

    // Multi-sample shadow for smooth edges
    float shadow = 0.0;
    float samples = 8.0;
    float spread = shadowSpread * 0.003;

    for (float angle = 0.0; angle < 6.28318; angle += 6.28318 / samples) {
        vec2 offset = vec2(cos(angle), sin(angle)) * spread;
        shadow += texture(source, fragCoord + offset).a;
    }

    shadow = min(shadow / samples * 2.0, 1.0);

    // Black shadow under text
    vec4 shadowResult = vec4(0.0, 0.0, 0.0, shadow * 0.8);
    fragColor = mix(shadowResult, textColor, textColor.a) * qt_Opacity;
}
