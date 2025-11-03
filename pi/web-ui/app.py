#!/usr/bin/env python3
import os
import subprocess
import json
from flask import Flask, render_template, jsonify, request

app = Flask(__name__)

CONFIG_FILE = '/opt/piframe-web/config.json'
PHOTO_DIR = '/mnt/photos'
XINITRC = '/root/.xinitrc'
NIGHTMODE_FLAG = '/tmp/nightmode'

def load_config():
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE) as f:
            return json.load(f)
    return {'delay': 10, 'randomize': True, 'recursive': True}

def save_config(config):
    with open(CONFIG_FILE, 'w') as f:
        json.dump(config, f)

def update_xinitrc(config):
    delay = config.get('delay', 10)
    randomize = '--randomize' if config.get('randomize', True) else ''
    recursive = '--recursive' if config.get('recursive', True) else ''
    
    content = """#!/bin/bash
xset s off
xset -dpms
xset s noblank

while true; do
    if [ -f /tmp/nightmode ]; then
        feh --fullscreen --hide-pointer /opt/black.png
    else
        feh --fullscreen --hide-pointer --slideshow-delay """ + str(delay) + """ """ + randomize + """ """ + recursive + """ /mnt/photos
    fi
    sleep 1
done
"""
    with open(XINITRC, 'w') as f:
        f.write(content)
    os.chmod(XINITRC, 0o755)

def get_photo_stats():
    try:
        result = subprocess.run(['ls', PHOTO_DIR], capture_output=True, text=True)
        count = len([f for f in result.stdout.split('\n') if f])
        return {'count': count, 'path': PHOTO_DIR}
    except:
        return {'count': 0, 'path': PHOTO_DIR}

def get_display_status():
    return not os.path.exists(NIGHTMODE_FLAG)

def is_feh_running():
    try:
        result = subprocess.run(['pgrep', '-x', 'feh'], capture_output=True)
        return result.returncode == 0
    except:
        return False

@app.route('/')
def index():
    config = load_config()
    stats = get_photo_stats()
    display_on = get_display_status()
    feh_running = is_feh_running()
    return render_template('index.html', config=config, stats=stats, display_on=display_on, feh_running=feh_running)

@app.route('/api/reload')
def reload_photos():
    subprocess.run(['ssh', 'root@192.168.68.42', 'docker restart photo-optimizer'], stderr=subprocess.DEVNULL)
    return jsonify({'status': 'optimizer restarted - photos will refresh in ~1 minute'})

@app.route('/api/display', methods=['POST'])
def toggle_display():
    on = request.json.get('on')
    if on:
        if os.path.exists(NIGHTMODE_FLAG):
            os.remove(NIGHTMODE_FLAG)
        subprocess.run(['killall', 'feh'], stderr=subprocess.DEVNULL)
    else:
        open(NIGHTMODE_FLAG, 'a').close()
        subprocess.run(['killall', 'feh'], stderr=subprocess.DEVNULL)
    return jsonify({'status': 'ok', 'on': on})

@app.route('/api/config', methods=['POST'])
def update_config():
    config = request.json
    save_config(config)
    update_xinitrc(config)
    subprocess.run(['killall', 'feh'], stderr=subprocess.DEVNULL)
    return jsonify({'status': 'updated'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
