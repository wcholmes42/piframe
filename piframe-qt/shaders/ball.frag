#version 310 es
precision highp float;

layout(location = 0) in highp vec2 fragCoord;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float crossfade;
    vec2 sphereCenter;
    float sphereRadius;
    float strength;
    vec2 resolution;
};

layout(binding = 1) uniform sampler2D tex1;
layout(binding = 2) uniform sampler2D tex2;

void main() {
    vec2 uv = fragCoord;
    vec2 center = sphereCenter / resolution;
    float radius = sphereRadius / resolution.x;

    vec2 delta = uv - center;
    float dist = length(delta);

    // Simple crossfade
    vec3 color1 = texture(tex1, uv).rgb;
    vec3 color2 = texture(tex2, uv).rgb;
    vec3 baseColor = mix(color1, color2, crossfade);

    // Crystal ball lens distortion
    if (dist < radius) {
        float normDist = dist / radius;
        float z = sqrt(max(0.0, 1.0 - normDist * normDist));
        float distortion = 1.0 / (1.0 + strength * 0.5 * (1.0 - z));  // Reduced magnification (was 1.0)

        vec2 distortedDelta = delta * distortion;
        vec2 sourceUV = clamp(center + distortedDelta, vec2(0.0), vec2(1.0));

        // Chromatic aberration - reduced
        float aberration = 0.003 * normDist;  // Reduced from 0.008
        vec2 deltaDir = normalize(delta);

        vec3 color1_dist;
        color1_dist.r = texture(tex1, clamp(sourceUV - aberration * deltaDir, vec2(0.0), vec2(1.0))).r;
        color1_dist.g = texture(tex1, sourceUV).g;
        color1_dist.b = texture(tex1, clamp(sourceUV + aberration * deltaDir, vec2(0.0), vec2(1.0))).b;

        vec3 color2_dist;
        color2_dist.r = texture(tex2, clamp(sourceUV - aberration * deltaDir, vec2(0.0), vec2(1.0))).r;
        color2_dist.g = texture(tex2, sourceUV).g;
        color2_dist.b = texture(tex2, clamp(sourceUV + aberration * deltaDir, vec2(0.0), vec2(1.0))).b;

        vec3 color = mix(color1_dist, color2_dist, crossfade);

        // Bright specular highlight
        vec2 highlightPos = center + vec2(-0.2, -0.2) * radius;
        float highlightDist = length(uv - highlightPos);
        if (highlightDist < radius * 0.35) {
            float intensity = pow(1.0 - highlightDist / (radius * 0.35), 3.0);
            color += vec3(intensity * 0.8);
        }

        // Subtle edge darkening
        float edgeDarken = 1.0 - 0.25 * pow(normDist, 2.5);
        color *= edgeDarken;

        fragColor = vec4(color, 1.0) * qt_Opacity;
    } else {
        fragColor = vec4(baseColor, 1.0) * qt_Opacity;
    }
}
