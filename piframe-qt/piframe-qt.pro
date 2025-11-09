QT += quick quickcontrols2 network
# websockets removed for local testing
CONFIG += c++17

# Deployment target for Raspberry Pi 5
TARGET = piframe-qt
TEMPLATE = app

# Enable Qt Quick Compiler for better performance
CONFIG += qtquickcompiler

# Source files
SOURCES += \
    src/main.cpp \
    src/photomodel.cpp \
    src/overlaymanager.cpp \
    src/configmanager.cpp \
    src/webapi.cpp

HEADERS += \
    src/photomodel.h \
    src/overlaymanager.h \
    src/configmanager.h \
    src/webapi.h

# QML files
RESOURCES += qml.qrc

# Default rules for deployment
target.path = /opt/piframe
INSTALLS += target

# Additional import paths
QML_IMPORT_PATH =

# Additional design paths
QML_DESIGNER_IMPORT_PATH =

# Platform-specific configurations
linux {
    # Raspberry Pi OpenGL ES configuration
    LIBS += -lGLESv2

    # Enable EGLFS platform plugin for direct framebuffer
    # Comment this out if running under X11/Wayland during development
    # QT += eglfsdeviceintegration
}

# Compiler flags for optimization
QMAKE_CXXFLAGS += -O3 -march=native

# Debug build configuration
CONFIG(debug, debug|release) {
    DEFINES += DEBUG_BUILD
    QMAKE_CXXFLAGS += -g
}

# Release build configuration
CONFIG(release, debug|release) {
    DEFINES += QT_NO_DEBUG_OUTPUT
}
