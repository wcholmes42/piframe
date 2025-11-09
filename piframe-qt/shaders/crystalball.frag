#version 440

layout(location = 0) in vec2 fragCoord;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 sphereCenter;
    float sphereRadius;
    float strength;
    vec2 resolution;
    float crossfade;
} ubuf;

layout(binding = 1) uniform sampler2D tex1;
layout(binding = 2) uniform sampler2D tex2;

// Random noise function for dissolve effect
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void main() {
    vec2 uv = fragCoord;
    vec2 center = ubuf.sphereCenter / ubuf.resolution;
    float radius = ubuf.sphereRadius / ubuf.resolution.x;

    vec2 delta = uv - center;
    float dist = length(delta);

    // Generate dissolve pattern
    float dissolveNoise = random(uv * 500.0);

    // Smooth dissolve with soft edges
    float dissolveEdge = 0.15;
    float dissolveMix = smoothstep(ubuf.crossfade - dissolveEdge, ubuf.crossfade + dissolveEdge, dissolveNoise);

    // Sample both textures with dissolve effect
    vec3 color1 = texture(tex1, uv).rgb;
    vec3 color2 = texture(tex2, uv).rgb;
    vec3 baseColor = mix(color1, color2, dissolveMix);

    // Crystal ball lens distortion (inside sphere radius)
    if (dist < radius) {
        float normDist = dist / radius;
        float z = sqrt(1.0 - normDist * normDist);  // Sphere surface
        float distortion = 1.0 / (1.0 + ubuf.strength * (1.0 - z));  // Magnification

        vec2 distortedDelta = delta * distortion;
        vec2 sourceUV = center + distortedDelta;

        // Chromatic aberration
        float aberration = 0.01 * normDist;
        vec2 deltaDir = normalize(delta);

        vec3 color1_distorted;
        color1_distorted.r = texture(tex1, sourceUV - aberration * deltaDir).r;
        color1_distorted.g = texture(tex1, sourceUV).g;
        color1_distorted.b = texture(tex1, sourceUV + aberration * deltaDir).b;

        vec3 color2_distorted;
        color2_distorted.r = texture(tex2, sourceUV - aberration * deltaDir).r;
        color2_distorted.g = texture(tex2, sourceUV).g;
        color2_distorted.b = texture(tex2, sourceUV + aberration * deltaDir).b;

        // Apply dissolve
        float dissolveNoise_sphere = random(sourceUV * 100.0);
        float dissolveThreshold = ubuf.crossfade + (dissolveNoise_sphere - 0.5) * 0.1;
        float dissolveMix_sphere = smoothstep(dissolveThreshold - 0.1, dissolveThreshold + 0.1, dissolveNoise_sphere);

        vec3 color = mix(color1_distorted, color2_distorted, dissolveMix_sphere);

        // Specular highlight
        vec2 highlightPos = center + vec2(-0.3, -0.3) * radius;
        float highlightDist = length(uv - highlightPos);
        if (highlightDist < radius * 0.3) {
            float intensity = pow(1.0 - highlightDist / (radius * 0.3), 2.0);
            color += vec3(intensity * 0.5);
        }

        // Edge darkening
        float edgeDarken = 1.0 - 0.4 * pow(normDist, 2.0);
        color *= edgeDarken;

        fragColor = vec4(color, 1.0) * ubuf.qt_Opacity;
    } else {
        // Outside sphere
        fragColor = vec4(baseColor, 1.0) * ubuf.qt_Opacity;
    }
}
