#!/usr/bin/env python3
"""
PiFrame Web UI Server
Simple Flask server to serve the control interface and proxy API requests
"""

from flask import Flask, send_from_directory, request, jsonify
from flask_cors import CORS
import requests
import os

app = Flask(__name__)
CORS(app)

# Configuration
QT_API_URL = "http://localhost:5000"  # Qt C++ API
WEB_DIR = os.path.dirname(os.path.abspath(__file__))

@app.route('/')
def index():
    """Serve the main control interface"""
    return send_from_directory(WEB_DIR, 'index.html')

@app.route('/<path:path>')
def serve_static(path):
    """Serve static files"""
    return send_from_directory(WEB_DIR, path)

# Proxy API endpoints to Qt backend
@app.route('/api/<path:endpoint>', methods=['GET', 'POST'])
def proxy_api(endpoint):
    """Proxy API requests to the Qt C++ backend"""
    try:
        url = f"{QT_API_URL}/api/{endpoint}"

        if request.method == 'POST':
            response = requests.post(url, json=request.get_json())
        else:
            response = requests.get(url)

        return jsonify(response.json()), response.status_code

    except requests.exceptions.ConnectionError:
        return jsonify({
            "success": False,
            "error": "Cannot connect to PiFrame backend. Is the service running?"
        }), 503

    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

if __name__ == '__main__':
    print("Starting PiFrame Web UI Server...")
    print(f"Access at: http://0.0.0.0:5000")
    print(f"Qt API URL: {QT_API_URL}")
    app.run(host='0.0.0.0', port=5000, debug=False)
