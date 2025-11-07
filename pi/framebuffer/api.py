#!/usr/bin/env python3
"""
PiFrame API Server
Flask API for controlling framebuffer slideshow
"""

from flask import Flask, jsonify, request
import json
import os
import subprocess

app = Flask(__name__)
CONFIG_FILE = "/etc/piframe/config.json"
STATUS_FILE = "/tmp/piframe-status.json"

def load_config():
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, 'r') as f:
            return json.load(f)
    return {}

def save_config(config):
    with open(CONFIG_FILE, 'w') as f:
        json.dump(config, f, indent=2)

@app.route('/api/status')
def get_status():
    """Get current slideshow status"""
    config = load_config()

    # Read current status from slideshow process
    status = {
        "running": True,
        "config": config
    }

    if os.path.exists(STATUS_FILE):
        with open(STATUS_FILE, 'r') as f:
            status.update(json.load(f))

    return jsonify(status)

@app.route('/api/config', methods=['GET', 'POST'])
def config():
    """Get or update configuration"""
    if request.method == 'POST':
        current_config = load_config()
        current_config.update(request.json)
        save_config(current_config)

        # Restart slideshow to apply changes
        subprocess.run(['systemctl', 'restart', 'piframe-slideshow'])

        return jsonify({'status': 'ok', 'config': current_config})

    return jsonify(load_config())

@app.route('/api/next')
def next_photo():
    """Skip to next photo (send SIGUSR1 to slideshow process)"""
    try:
        subprocess.run(['pkill', '-USR1', '-f', 'slideshow.py'])
        return jsonify({'status': 'ok'})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api/restart')
def restart():
    """Restart slideshow service"""
    try:
        subprocess.run(['systemctl', 'restart', 'piframe-slideshow'])
        return jsonify({'status': 'ok'})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
