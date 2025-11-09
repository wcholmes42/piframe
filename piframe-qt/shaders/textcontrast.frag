#version 310 es
precision highp float;

layout(location = 0) in highp vec2 fragCoord;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec3 textColor;
    float contrastBoost;
};

layout(binding = 1) uniform sampler2D source;
layout(binding = 2) uniform sampler2D background;

float luminance(vec3 color) {
    return dot(color, vec3(0.299, 0.587, 0.114));
}

void main() {
    vec4 textSample = texture(source, fragCoord);
    vec3 bgSample = texture(background, fragCoord).rgb;

    float bgLum = luminance(bgSample);

    // Adaptive text color
    vec3 adaptiveColor;
    if (bgLum > 0.5) {
        adaptiveColor = mix(vec3(0.0), textColor * 0.3, contrastBoost);
    } else {
        adaptiveColor = mix(vec3(1.0), textColor * 1.5, contrastBoost);
    }

    float alpha = textSample.a;
    if (alpha > 0.01) {
        vec3 finalColor = adaptiveColor;
        float glowAmount = smoothstep(0.3, 0.7, 1.0 - bgLum);
        finalColor += vec3(glowAmount * 0.2);
        fragColor = vec4(finalColor, alpha) * qt_Opacity;
    } else {
        // Shadow halo
        float shadowRadius = 0.01;
        float shadow = 0.0;
        for (float y = -shadowRadius; y <= shadowRadius; y += shadowRadius) {
            for (float x = -shadowRadius; x <= shadowRadius; x += shadowRadius) {
                shadow += texture(source, fragCoord + vec2(x, y)).a;
            }
        }
        shadow = min(shadow * 0.15, 0.7);
        fragColor = vec4(0.0, 0.0, 0.0, shadow) * qt_Opacity;
    }
}
