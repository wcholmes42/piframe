import QtQuick 2.15
import QtQuick.Particles 2.15

Item {
    id: holidayOverlay

    // Hardware acceleration
    layer.enabled: true
    layer.smooth: true

    // Christmas snowflakes
    ParticleSystem {
        id: snowSystem
        anchors.fill: parent
        running: overlayManager.activeHoliday === "christmas"
        visible: running

        ImageParticle {
            source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='32' height='32'><text x='0' y='24' font-size='24' fill='white' opacity='0.8'>❄</text></svg>"
            alpha: 0.8
            colorVariation: 0.2
        }

        Emitter {
            anchors.fill: parent
            emitRate: 30
            lifeSpan: 8000
            lifeSpanVariation: 2000

            velocity: AngleDirection {
                angle: 90
                angleVariation: 15
                magnitude: 50
                magnitudeVariation: 20
            }

            acceleration: AngleDirection {
                angle: 90
                magnitude: 10
            }

            size: 16
            sizeVariation: 8
        }

        // Gentle sideways drift
        Wander {
            anchors.fill: parent
            xVariance: 100
            pace: 100
        }
    }

    // Halloween bats/ghosts
    ParticleSystem {
        id: halloweenSystem
        anchors.fill: parent
        running: overlayManager.activeHoliday === "halloween"
        visible: running

        ImageParticle {
            source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='32' height='32'><text x='0' y='24' font-size='24' fill='orange' opacity='0.7'>🦇</text></svg>"
            alpha: 0.7
            colorVariation: 0.3
        }

        Emitter {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 50
            emitRate: 8
            lifeSpan: 12000
            lifeSpanVariation: 3000

            velocity: AngleDirection {
                angle: 90
                angleVariation: 45
                magnitude: 30
                magnitudeVariation: 15
            }

            size: 24
            sizeVariation: 12
        }

        // Wandering motion
        Wander {
            anchors.fill: parent
            xVariance: 200
            yVariance: 100
            pace: 80
        }
    }

    // New Year fireworks
    ParticleSystem {
        id: fireworksSystem
        anchors.fill: parent
        running: overlayManager.activeHoliday === "newyear"
        visible: running

        ImageParticle {
            groups: ["stars"]
            source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'><circle cx='8' cy='8' r='6' fill='gold' opacity='0.9'/></svg>"
            alpha: 0.9
            colorVariation: 0.5
        }

        // Multiple emitters for firework bursts
        Emitter {
            id: fireworkEmitter
            anchors.fill: parent
            group: "stars"
            emitRate: 0
            lifeSpan: 2000

            velocity: AngleDirection {
                angleVariation: 360
                magnitude: 100
                magnitudeVariation: 50
            }

            acceleration: AngleDirection {
                angle: 90
                magnitude: 50
            }

            size: 8
            sizeVariation: 4
        }

        // Trigger fireworks periodically
        Timer {
            interval: 2000
            running: fireworksSystem.running
            repeat: true
            onTriggered: {
                fireworkEmitter.burst(80,
                    Math.random() * parent.width,
                    Math.random() * parent.height * 0.7);
            }
        }
    }

    // Valentine's Day hearts
    ParticleSystem {
        id: valentineSystem
        anchors.fill: parent
        running: overlayManager.activeHoliday === "valentine"
        visible: running

        ImageParticle {
            source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='32' height='32'><text x='0' y='24' font-size='24' fill='red' opacity='0.7'>❤</text></svg>"
            alpha: 0.7
            colorVariation: 0.2
        }

        Emitter {
            anchors.fill: parent
            emitRate: 15
            lifeSpan: 6000
            lifeSpanVariation: 2000

            velocity: AngleDirection {
                angle: 270
                angleVariation: 20
                magnitude: 40
                magnitudeVariation: 15
            }

            size: 20
            sizeVariation: 8
        }

        // Float upward
        Wander {
            anchors.fill: parent
            xVariance: 80
            pace: 120
        }
    }

    // St. Patrick's Day shamrocks
    ParticleSystem {
        id: stpatrickSystem
        anchors.fill: parent
        running: overlayManager.activeHoliday === "stpatrick"
        visible: running

        ImageParticle {
            source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='32' height='32'><text x='0' y='24' font-size='24' fill='green' opacity='0.7'>☘</text></svg>"
            alpha: 0.7
        }

        Emitter {
            anchors.fill: parent
            emitRate: 20
            lifeSpan: 7000
            lifeSpanVariation: 2000

            velocity: AngleDirection {
                angle: 90
                angleVariation: 30
                magnitude: 45
                magnitudeVariation: 20
            }

            size: 18
            sizeVariation: 8
        }

        Wander {
            anchors.fill: parent
            xVariance: 120
            pace: 100
        }
    }

    // Independence Day stars/sparkles
    ParticleSystem {
        id: independenceSystem
        anchors.fill: parent
        running: overlayManager.activeHoliday === "independence"
        visible: running

        ImageParticle {
            source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='24' height='24'><text x='0' y='20' font-size='20' fill='white' opacity='0.8'>✨</text></svg>"
            alpha: 0.8
            colorVariation: 0.4
        }

        Emitter {
            anchors.fill: parent
            emitRate: 25
            lifeSpan: 3000
            lifeSpanVariation: 1000

            velocity: AngleDirection {
                angleVariation: 360
                magnitude: 60
                magnitudeVariation: 30
            }

            size: 16
            sizeVariation: 8
        }
    }

    // Thanksgiving leaves
    ParticleSystem {
        id: thanksgivingSystem
        anchors.fill: parent
        running: overlayManager.activeHoliday === "thanksgiving"
        visible: running

        ImageParticle {
            source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='32' height='32'><text x='0' y='24' font-size='24' fill='orange' opacity='0.8'>🍂</text></svg>"
            alpha: 0.8
            colorVariation: 0.3
        }

        Emitter {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 50
            emitRate: 12
            lifeSpan: 10000
            lifeSpanVariation: 3000

            velocity: AngleDirection {
                angle: 90
                angleVariation: 30
                magnitude: 40
                magnitudeVariation: 20
            }

            size: 22
            sizeVariation: 10
        }

        // Drifting fall motion
        Wander {
            anchors.fill: parent
            xVariance: 150
            pace: 90
        }

        // Gentle rotation
        Turbulence {
            anchors.fill: parent
            strength: 8
        }
    }

    // Debug info
    Connections {
        target: overlayManager
        function onActiveHolidayChanged(holiday) {
            if (holiday !== "") {
                console.log("Holiday animation active:", holiday);
            }
        }
    }

    // Fade in/out for smooth transitions
    Behavior on opacity {
        NumberAnimation {
            duration: 1000
            easing.type: Easing.InOutQuad
        }
    }
}
