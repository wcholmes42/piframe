#version 310 es
precision highp float;

layout(location = 0) in highp vec2 fragCoord;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 textPosition;  // Position of text on screen (0-1)
    vec2 textSize;      // Size of text area (0-1)
};

layout(binding = 1) uniform sampler2D source;      // The text itself
layout(binding = 2) uniform sampler2D background;  // The photo behind

// Calculate luminance
float luminance(vec3 color) {
    return dot(color, vec3(0.299, 0.587, 0.114));
}

void main() {
    vec4 textPixel = texture(source, fragCoord);

    // Sample background at this text position
    vec3 bgColor = texture(background, fragCoord).rgb;
    float bgLuminance = luminance(bgColor);

    // Adaptive color - flip to opposite of background
    vec3 adaptiveColor;
    float textAlpha = textPixel.a;

    if (textAlpha > 0.01) {
        // We have text here - make it contrast
        if (bgLuminance > 0.5) {
            // Bright background -> very dark text
            adaptiveColor = vec3(0.0, 0.0, 0.05);
        } else {
            // Dark background -> very bright text
            adaptiveColor = vec3(1.0, 1.0, 1.0);
        }

        // Add outline/glow for extra pop
        float outlineAlpha = 0.0;
        float outlineRadius = 0.005;
        for (float angle = 0.0; angle < 6.28; angle += 0.785) {  // 8 samples
            vec2 offset = vec2(cos(angle), sin(angle)) * outlineRadius;
            outlineAlpha += texture(source, fragCoord + offset).a;
        }
        outlineAlpha = min(outlineAlpha * 0.2, 1.0);

        // Black outline
        vec3 outlineColor = vec3(0.0);
        vec3 finalColor = mix(outlineColor, adaptiveColor, textPixel.a);
        float finalAlpha = max(textAlpha, outlineAlpha * 0.9);

        fragColor = vec4(finalColor, finalAlpha) * qt_Opacity;
    } else {
        // No text - transparent
        fragColor = vec4(0.0, 0.0, 0.0, 0.0);
    }
}
