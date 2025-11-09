import QtQuick 2.15

/*
 * CrystalBallEffect.qml
 *
 * GPU-accelerated spherical lens distortion with chromatic aberration
 * Inspired by classic 90s demoscene aesthetics
 *
 * Features:
 * - Real spherical lens physics (z = √(1 - r²))
 * - Chromatic aberration (RGB channel splitting)
 * - Lissajous curve motion (sine wave patterns)
 * - Pulsing radius and distortion strength
 * - Dissolve transitions between photos
 * - Specular highlights and edge darkening
 */

Item {
    id: root

    // Properties
    property variant source1  // Current photo texture
    property variant source2  // Next photo texture (for crossfade)
    property real crossfade: 0.0  // 0.0 = show source1, 1.0 = show source2
    property bool enabled: true
    property bool paused: false

    // Crystal ball parameters
    property real baseRadius: 0.25  // Base radius (0.0 - 1.0, relative to width)
    property real baseStrength: 2.5  // Base distortion strength
    property real speedMultiplier: 1.0

    // Lissajous curve frequencies (for classic demoscene motion)
    property real freqX1: 0.7
    property real freqX2: 1.3
    property real freqY1: 0.9
    property real freqY2: 1.1

    // Internal animation time
    property real time: 0.0

    // Computed sphere position and properties
    property real sphereCenterX: width * 0.5
    property real sphereCenterY: height * 0.5
    property real sphereRadius: Math.min(width, height) * currentRadius
    property real currentStrength: baseStrength + pulsingStrength

    // Z-depth bounce modulation - bouncy ball effect!
    property real bouncePhase: Math.abs(Math.sin(time * 1.2))  // Bounce frequency
    property real currentRadius: baseRadius + 0.15 * bouncePhase * bouncePhase  // Quadratic for bounce feel
    property real pulsingStrength: 0.5 * Math.sin(time * 0.7)

    // Time animation
    Timer {
        id: timeAnimator
        interval: 16  // ~60 FPS
        running: root.enabled && !root.paused
        repeat: true
        onTriggered: {
            root.time += 0.016 * root.speedMultiplier
            updateSpherePosition()
        }
    }

    // Update sphere position using Lissajous curves
    function updateSpherePosition() {
        // Classic demoscene Lissajous motion
        // Combine two sine waves with different frequencies for each axis
        var lissajousX = Math.sin(time * freqX1) * 0.3 + Math.sin(time * freqX2) * 0.2
        var lissajousY = Math.sin(time * freqY1) * 0.3 + Math.sin(time * freqY2) * 0.2

        // Map to screen coordinates (keep sphere mostly on screen)
        sphereCenterX = width * (0.5 + lissajousX * 0.5)
        sphereCenterY = height * (0.5 + lissajousY * 0.5)
    }

    // Main shader effect
    ShaderEffect {
        id: shaderEffect
        anchors.fill: parent
        visible: root.enabled

        // Texture inputs
        property variant tex1: source1
        property variant tex2: source2

        // Uniforms
        property real crossfade: root.crossfade
        property vector2d sphereCenter: Qt.vector2d(root.sphereCenterX, root.sphereCenterY)
        property real sphereRadius: root.sphereRadius
        property real strength: root.currentStrength
        property vector2d resolution: Qt.vector2d(width, height)

        // Compiled shaders for Qt 6
        vertexShader: "qrc:/shaders/crystalball.vert.qsb"
        fragmentShader: "qrc:/shaders/crystalball.frag.qsb"

        // Old inline shader (Qt 6 requires compiled .qsb files)
        /*
        fragmentShader: "
            varying highp vec2 fragCoord;
            uniform sampler2D tex1;
            uniform sampler2D tex2;
            uniform lowp float crossfade;
            uniform highp vec2 sphereCenter;
            uniform highp float sphereRadius;
            uniform highp float strength;
            uniform highp vec2 resolution;
            uniform lowp float qt_Opacity;

            // Random noise function for dissolve effect
            highp float random(vec2 st) {
                return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
            }

            void main() {
                highp vec2 uv = fragCoord;
                highp vec2 center = sphereCenter / resolution;
                highp float radius = sphereRadius / resolution.x;

                highp vec2 delta = uv - center;
                highp float dist = length(delta);

                // Generate dissolve pattern (organic random noise)
                highp float dissolveNoise = random(uv * 500.0);

                // Smooth dissolve with soft edges
                lowp float dissolveEdge = 0.15;
                lowp float dissolveMix = smoothstep(crossfade - dissolveEdge, crossfade + dissolveEdge, dissolveNoise);

                // Sample both textures with dissolve effect
                lowp vec3 color1 = texture2D(tex1, uv).rgb;
                lowp vec3 color2 = texture2D(tex2, uv).rgb;
                lowp vec3 baseColor = mix(color1, color2, dissolveMix);

                // Crystal ball lens distortion (inside sphere radius)
                if (dist < radius) {
                    highp float normDist = dist / radius;
                    highp float z = sqrt(1.0 - normDist * normDist);  // Sphere surface
                    highp float distortion = 1.0 / (1.0 + strength * (1.0 - z));  // Magnification

                    highp vec2 distortedDelta = delta * distortion;
                    highp vec2 sourceUV = center + distortedDelta;

                    // Chromatic aberration (RGB channel splitting like real glass)
                    highp float aberration = 0.01 * normDist;
                    highp vec2 deltaDir = normalize(delta);

                    lowp vec3 color1_distorted;
                    color1_distorted.r = texture2D(tex1, sourceUV - aberration * deltaDir).r;
                    color1_distorted.g = texture2D(tex1, sourceUV).g;
                    color1_distorted.b = texture2D(tex1, sourceUV + aberration * deltaDir).b;

                    lowp vec3 color2_distorted;
                    color2_distorted.r = texture2D(tex2, sourceUV - aberration * deltaDir).r;
                    color2_distorted.g = texture2D(tex2, sourceUV).g;
                    color2_distorted.b = texture2D(tex2, sourceUV + aberration * deltaDir).b;

                    // Apply dissolve to distorted colors
                    highp float dissolveNoise_sphere = random(sourceUV * 100.0);
                    highp float dissolveThreshold = crossfade + (dissolveNoise_sphere - 0.5) * 0.1;
                    lowp float dissolveMix_sphere = smoothstep(dissolveThreshold - 0.1, dissolveThreshold + 0.1, dissolveNoise_sphere);

                    lowp vec3 color = mix(color1_distorted, color2_distorted, dissolveMix_sphere);

                    // Specular highlight (top-left of sphere)
                    highp vec2 highlightPos = center + vec2(-0.3, -0.3) * radius;
                    highp float highlightDist = length(uv - highlightPos);
                    if (highlightDist < radius * 0.3) {
                        highp float intensity = pow(1.0 - highlightDist / (radius * 0.3), 2.0);
                        color += vec3(intensity * 0.5);
                    }

                    // Edge darkening (ambient occlusion)
                    highp float edgeDarken = 1.0 - 0.4 * pow(normDist, 2.0);
                    color *= edgeDarken;

                    gl_FragColor = vec4(color, 1.0) * qt_Opacity;
                } else {
                    // Outside sphere - show base photo with dissolve
                    gl_FragColor = vec4(baseColor, 1.0) * qt_Opacity;
                }
            }
        */
    }

    // Fallback: show source1 if shader is disabled
    Item {
        anchors.fill: parent
        visible: !root.enabled

        ShaderEffectSource {
            id: fallbackSource
            anchors.fill: parent
            sourceItem: source1
        }
    }

    // Public methods
    function pause() {
        root.paused = true
    }

    function resume() {
        root.paused = false
    }

    function reset() {
        root.time = 0.0
        updateSpherePosition()
    }

    // Initialize
    Component.onCompleted: {
        updateSpherePosition()
        console.log("CrystalBallEffect initialized - demoscene mode active!")
    }
}
