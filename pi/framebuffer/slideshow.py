#!/usr/bin/env python3
"""
PiFrame Framebuffer Slideshow
Direct framebuffer rendering with time-based brightness control
"""

import os
import sys
import time
import json
import random
import signal
from datetime import datetime
from pathlib import Path
from PIL import Image

class FramebufferSlideshow:
    def __init__(self, config_path="/etc/piframe/config.json"):
        self.config = self.load_config(config_path)
        self.running = True
        self.current_photo = None

        # Setup signal handlers for graceful shutdown
        signal.signal(signal.SIGTERM, self.handle_signal)
        signal.signal(signal.SIGINT, self.handle_signal)

        # Get framebuffer info
        self.fb_device = self.config.get("framebuffer_device", "/dev/fb0")
        self.width = self.config.get("width", 1920)
        self.height = self.config.get("height", 1080)

        print(f"PiFrame Slideshow starting: {self.width}x{self.height}")

    def load_config(self, config_path):
        """Load configuration from JSON file"""
        if os.path.exists(config_path):
            with open(config_path, 'r') as f:
                return json.load(f)

        # Default config
        return {
            "photo_dir": "/mnt/photos",
            "interval": 10,
            "brightness_schedule": {
                "8-17": "bright",
                "17-19": "medium",
                "19-24": "dim"
            },
            "width": 1920,
            "height": 1080,
            "framebuffer_device": "/dev/fb0"
        }

    def get_brightness_folder(self):
        """Determine which brightness folder to use based on time"""
        hour = datetime.now().hour
        schedule = self.config.get("brightness_schedule", {})

        for time_range, folder in schedule.items():
            start, end = map(int, time_range.split('-'))
            if start <= hour < end:
                return folder

        # Default to bright if no match
        return "bright"

    def get_photo_list(self):
        """Get list of photos from current brightness folder"""
        base_dir = Path(self.config["photo_dir"])
        brightness = self.get_brightness_folder()
        photo_dir = base_dir / brightness

        if not photo_dir.exists():
            print(f"ERROR: Photo directory not found: {photo_dir}")
            return []

        photos = list(photo_dir.glob("*.png")) + \
                 list(photo_dir.glob("*.jpg")) + \
                 list(photo_dir.glob("*.jpeg"))

        random.shuffle(photos)
        print(f"Found {len(photos)} photos in {brightness}/ folder")
        return photos

    def write_to_framebuffer(self, image):
        """Write PIL Image directly to framebuffer"""
        # Ensure image is correct size and mode
        if image.size != (self.width, self.height):
            image = image.resize((self.width, self.height), Image.LANCZOS)

        # Convert to RGB (framebuffer expects RGB)
        if image.mode != 'RGB':
            image = image.convert('RGB')

        # Write to framebuffer
        try:
            with open(self.fb_device, 'wb') as fb:
                fb.write(image.tobytes())
        except Exception as e:
            print(f"ERROR writing to framebuffer: {e}")

    def display_photo(self, photo_path):
        """Load and display a single photo"""
        try:
            print(f"Displaying: {photo_path.name}")
            img = Image.open(photo_path)
            self.write_to_framebuffer(img)
            self.current_photo = str(photo_path)
            return True
        except Exception as e:
            print(f"ERROR loading {photo_path}: {e}")
            return False

    def handle_signal(self, signum, frame):
        """Handle shutdown signals"""
        print(f"\nReceived signal {signum}, shutting down...")
        self.running = False

    def run(self):
        """Main slideshow loop"""
        last_brightness = None
        photos = []
        photo_index = 0

        while self.running:
            # Check if we need to switch brightness folders
            current_brightness = self.get_brightness_folder()
            if current_brightness != last_brightness:
                print(f"Switching to {current_brightness} brightness")
                photos = self.get_photo_list()
                photo_index = 0
                last_brightness = current_brightness

                if not photos:
                    print("No photos found, waiting...")
                    time.sleep(60)
                    continue

            # Display next photo
            if photos:
                self.display_photo(photos[photo_index])
                photo_index = (photo_index + 1) % len(photos)

            # Wait for interval
            interval = self.config.get("interval", 10)
            for _ in range(interval):
                if not self.running:
                    break
                time.sleep(1)

        print("Slideshow stopped")

if __name__ == "__main__":
    slideshow = FramebufferSlideshow()
    slideshow.run()
