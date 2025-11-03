from flask import Flask, render_template, jsonify, request, send_from_directory
import os
import json
import subprocess

app = Flask(__name__)

CONFIG_FILE = '/etc/piframe-config.json'
PHOTO_DIR = '/mnt/photos'

def load_config():
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, 'r') as f:
            return json.load(f)
    return {
        'delay': 10,
        'randomize': False,
        'recursive': True,
        'transition_duration': 20.0
    }

def save_config(config):
    with open(CONFIG_FILE, 'w') as f:
        json.dump(config, f, indent=2)

@app.route('/')
def index():
    config = load_config()
    return render_template('index.html', config=config)

@app.route('/slideshow')
def slideshow():
    config = load_config()
    return render_template('slideshow.html', config=config)

@app.route('/api/photos')
def get_photos():
    """Return list of photo files"""
    config = load_config()
    photos = []
    
    if config.get('recursive'):
        for root, dirs, files in os.walk(PHOTO_DIR):
            for file in files:
                if file.lower().endswith(('.jpg', '.jpeg', '.png', '.gif')):
                    rel_path = os.path.relpath(os.path.join(root, file), PHOTO_DIR)
                    photos.append(rel_path)
    else:
        if os.path.exists(PHOTO_DIR):
            for file in os.listdir(PHOTO_DIR):
                if file.lower().endswith(('.jpg', '.jpeg', '.png', '.gif')):
                    photos.append(file)
    
    return jsonify(photos)

@app.route('/photos/<path:filename>')
def serve_photo(filename):
    """Serve photo from network mount"""
    return send_from_directory(PHOTO_DIR, filename)

@app.route('/api/config', methods=['GET', 'POST'])
def config():
    if request.method == 'POST':
        config = load_config()
        config.update(request.json)
        save_config(config)
        return jsonify({'status': 'ok'})
    return jsonify(load_config())

@app.route('/api/display/<action>')
def display_action(action):
    if action == 'on':
        subprocess.run(['vcgencmd', 'display_power', '1'])
    elif action == 'off':
        subprocess.run(['vcgencmd', 'display_power', '0'])
    return jsonify({'status': 'ok'})

@app.route('/api/reoptimize')
def reoptimize():
    subprocess.run(['ssh', 'root@192.168.68.42', 'docker restart piframe-optimizer'])
    return jsonify({'status': 'ok'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
