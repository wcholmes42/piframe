#!/usr/bin/env python3
"""
PiFrame API Server - v2 Robust Edition
Flask API for controlling framebuffer slideshow
"""

from flask import Flask, jsonify, request
import json
import os
import subprocess
import logging

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CONFIG_FILE = "/etc/piframe/config.json"
STATUS_FILE = "/tmp/piframe-status.json"

def load_config():
    """Load configuration with error handling"""
    try:
        if os.path.exists(CONFIG_FILE):
            with open(CONFIG_FILE, 'r') as f:
                return json.load(f)
    except Exception as e:
        logger.error(f"Error loading config: {e}")
    return {}

def save_config(config):
    """Save configuration with error handling"""
    try:
        with open(CONFIG_FILE, 'w') as f:
            json.dump(config, f, indent=2)
        return True
    except Exception as e:
        logger.error(f"Error saving config: {e}")
        return False

@app.route('/api/status')
def get_status():
    """Get current slideshow status"""
    config = load_config()
    status = {
        "running": is_service_running('piframe-slideshow'),
        "config": config
    }

    # Read slideshow status
    try:
        if os.path.exists(STATUS_FILE):
            with open(STATUS_FILE, 'r') as f:
                status.update(json.load(f))
    except Exception as e:
        logger.error(f"Error reading status file: {e}")

    return jsonify(status)

@app.route('/api/config', methods=['GET', 'POST'])
def config():
    """Get or update configuration"""
    if request.method == 'POST':
        try:
            current_config = load_config()
            current_config.update(request.json)

            if not save_config(current_config):
                return jsonify({'status': 'error', 'message': 'Failed to save config'}), 500

            # Send SIGHUP to reload config
            result = subprocess.run(['pkill', '-HUP', '-f', 'slideshow'],
                                    capture_output=True, text=True)

            if result.returncode != 0:
                logger.warning("Failed to send reload signal, restarting service instead")
                subprocess.run(['systemctl', 'restart', 'piframe-slideshow'])

            return jsonify({'status': 'ok', 'config': current_config})
        except Exception as e:
            logger.error(f"Error updating config: {e}")
            return jsonify({'status': 'error', 'message': str(e)}), 500

    return jsonify(load_config())

@app.route('/api/next')
def next_photo():
    """Skip to next photo"""
    try:
        result = subprocess.run(['pkill', '-USR1', '-f', 'slideshow'],
                                capture_output=True, text=True)

        if result.returncode == 0:
            return jsonify({'status': 'ok'})
        else:
            return jsonify({'status': 'error', 'message': 'Slideshow not running'}), 404
    except Exception as e:
        logger.error(f"Error sending next signal: {e}")
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api/restart')
def restart():
    """Restart slideshow service"""
    try:
        result = subprocess.run(['systemctl', 'restart', 'piframe-slideshow'],
                                capture_output=True, text=True)

        if result.returncode == 0:
            return jsonify({'status': 'ok'})
        else:
            return jsonify({'status': 'error', 'message': result.stderr}), 500
    except Exception as e:
        logger.error(f"Error restarting service: {e}")
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api/stop')
def stop():
    """Stop slideshow service"""
    try:
        result = subprocess.run(['systemctl', 'stop', 'piframe-slideshow'],
                                capture_output=True, text=True)

        if result.returncode == 0:
            return jsonify({'status': 'ok'})
        else:
            return jsonify({'status': 'error', 'message': result.stderr}), 500
    except Exception as e:
        logger.error(f"Error stopping service: {e}")
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api/start')
def start():
    """Start slideshow service"""
    try:
        result = subprocess.run(['systemctl', 'start', 'piframe-slideshow'],
                                capture_output=True, text=True)

        if result.returncode == 0:
            return jsonify({'status': 'ok'})
        else:
            return jsonify({'status': 'error', 'message': result.stderr}), 500
    except Exception as e:
        logger.error(f"Error starting service: {e}")
        return jsonify({'status': 'error', 'message': str(e)}), 500

def is_service_running(service_name):
    """Check if systemd service is running"""
    try:
        result = subprocess.run(['systemctl', 'is-active', service_name],
                                capture_output=True, text=True)
        return result.stdout.strip() == 'active'
    except:
        return False

if __name__ == '__main__':
    logger.info("Starting PiFrame API server on port 5000")
    app.run(host='0.0.0.0', port=5000)
