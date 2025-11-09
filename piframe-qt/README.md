# PiFrame Qt - Professional Digital Photo Frame

High-quality digital photo frame for Raspberry Pi 5 with hardware-accelerated Qt/QML interface.

## Features

- **Hardware Accelerated Display**: GPU-composited slideshow with smooth transitions
- **Multi-Layer Overlays**: Clock, weather, custom messages, holiday animations
- **Zero Flicker**: Proper compositing eliminates timing issues
- **Web Control Interface**: Full-featured REST API and responsive web UI
- **Smart Storage**: USB caching with periodic Unraid sync (SD card protection)
- **Production Quality**: Video-toaster level reliability for 24/7 operation

## Architecture

- **Display Engine**: Qt 6 + QML with OpenGL ES acceleration
- **Backend**: C++ for performance-critical code, Python Flask for web API
- **Overlays**: Modular QML components with animations and effects
- **Storage**: USB thumb drive cache, tmpfs for logs
- **Sync**: rsync from Unraid photo server

## Requirements

- Raspberry Pi 5 (4GB+ recommended)
- USB thumb drive (32GB+ for photo cache)
- DietPi or Raspberry Pi OS (Bookworm)
- Qt 6.2+ with QML and Quick modules
- Python 3.11+ with Flask

## Installation

```bash
cd piframe-qt/scripts
sudo ./install.sh
```

## Quick Start

```bash
# Start the photo frame
sudo systemctl start piframe

# Enable auto-start on boot
sudo systemctl enable piframe

# Access web interface
http://192.168.68.75:5000
```

## Configuration

Edit `config.json` for:
- Photo source paths
- Brightness schedule
- Slideshow timing
- Overlay settings
- Network configuration

## Development

```bash
# Build the Qt application
qmake piframe-qt.pro
make

# Run in development mode
./piframe-qt --dev

# Run web API separately
cd web && python app.py
```

## Project Structure

```
piframe-qt/
├── src/          # C++ application code
├── qml/          # QML UI components
├── web/          # Flask API and web UI
├── scripts/      # Installation and sync scripts
├── services/     # systemd service files
└── config/       # Configuration templates
```

## Rebuilding from Legacy

This is a complete rewrite of the framebuffer-based approach. The old implementation fought against Pi 5's DRM architecture. This Qt-based solution embraces modern graphics stack for professional results.

**What's Different:**
- Single process (no FBI/clock-overlay conflicts)
- Proper GPU compositing (no white bars or artifacts)
- Hardware accelerated (60fps capable)
- Extensible overlay system (easy to add new features)
- Clean architecture (maintainable and reliable)

## License

MIT
