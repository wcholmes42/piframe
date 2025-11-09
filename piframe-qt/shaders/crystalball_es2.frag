#version 100
precision highp float;

varying highp vec2 fragCoord;

uniform float qt_Opacity;
uniform vec2 sphereCenter;
uniform float sphereRadius;
uniform float strength;
uniform vec2 resolution;
uniform float crossfade;

uniform sampler2D tex1;
uniform sampler2D tex2;

// Random noise function
float random(vec2 st) {
    return fract(sin(dot(st, vec2(12.9898, 78.233))) * 43758.5453123);
}

void main() {
    vec2 uv = fragCoord;
    vec2 center = sphereCenter / resolution;
    float radius = sphereRadius / resolution.x;

    vec2 delta = uv - center;
    float dist = length(delta);

    // Dissolve pattern
    float dissolveNoise = random(uv * 500.0);
    float dissolveEdge = 0.15;
    float dissolveMix = smoothstep(crossfade - dissolveEdge, crossfade + dissolveEdge, dissolveNoise);

    // Sample both textures
    vec3 color1 = texture2D(tex1, uv).rgb;
    vec3 color2 = texture2D(tex2, uv).rgb;
    vec3 baseColor = mix(color1, color2, dissolveMix);

    // Crystal ball lens distortion
    if (dist < radius) {
        float normDist = dist / radius;
        float z = sqrt(1.0 - normDist * normDist);
        float distortion = 1.0 / (1.0 + strength * (1.0 - z));

        vec2 distortedDelta = delta * distortion;
        vec2 sourceUV = center + distortedDelta;

        // Chromatic aberration
        float aberration = 0.01 * normDist;
        vec2 deltaDir = normalize(delta);

        vec3 color1_distorted;
        color1_distorted.r = texture2D(tex1, sourceUV - aberration * deltaDir).r;
        color1_distorted.g = texture2D(tex1, sourceUV).g;
        color1_distorted.b = texture2D(tex1, sourceUV + aberration * deltaDir).b;

        vec3 color2_distorted;
        color2_distorted.r = texture2D(tex2, sourceUV - aberration * deltaDir).r;
        color2_distorted.g = texture2D(tex2, sourceUV).g;
        color2_distorted.b = texture2D(tex2, sourceUV + aberration * deltaDir).b;

        // Dissolve for distorted
        float dissolveNoise_sphere = random(sourceUV * 100.0);
        float dissolveThreshold = crossfade + (dissolveNoise_sphere - 0.5) * 0.1;
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

        gl_FragColor = vec4(color, 1.0) * qt_Opacity;
    } else {
        gl_FragColor = vec4(baseColor, 1.0) * qt_Opacity;
    }
}
