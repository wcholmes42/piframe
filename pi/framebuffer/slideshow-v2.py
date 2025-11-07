#!/usr/bin/env python3
"""
PiFrame Framebuffer Slideshow - v2 Robust Edition
Direct framebuffer rendering with time-based brightness control
"""

import os
import sys
import time
import json
import random
import signal
import logging
from datetime import datetime
from pathlib import Path
from PIL import Image

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler('/var/log/piframe-slideshow.log')
    ]
)
logger = logging.getLogger(__name__)

class FramebufferSlideshow:
    def __init__(self, config_path="/etc/piframe/config.json"):
        self.config_path = config_path
        self.config = self.load_config()
        self.running = True
        self.skip_to_next = False
        self.reload_config = False
        self.current_photo = None
        self.current_brightness = None

        # Setup signal handlers
        signal.signal(signal.SIGTERM, self.handle_shutdown)
        signal.signal(signal.SIGINT, self.handle_shutdown)
        signal.signal(signal.SIGUSR1, self.handle_next)
        signal.signal(signal.SIGHUP, self.handle_reload)

        # Get framebuffer info
        self.fb_device = self.config.get("framebuffer_device", "/dev/fb0")
        self.width = self.config.get("width", 1920)
        self.height = self.config.get("height", 1080)

        logger.info(f"PiFrame Slideshow starting: {self.width}x{self.height}")
        logger.info(f"Framebuffer device: {self.fb_device}")

    def load_config(self):
        """Load configuration from JSON file with fallback defaults"""
        try:
            if os.path.exists(self.config_path):
                with open(self.config_path, 'r') as f:
                    config = json.load(f)
                    logger.info(f"Loaded config from {self.config_path}")
                    return config
        except Exception as e:
            logger.error(f"Error loading config: {e}")

        # Default config
        logger.warning("Using default configuration")
        return {
            "photo_dir": "/mnt/photos",
            "interval": 10,
            "brightness_schedule": {
                "0-8": "dim",
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
        logger.warning(f"No brightness schedule match for hour {hour}, defaulting to bright")
        return "bright"

    def get_photo_list(self, brightness_folder):
        """Get list of photos from specified brightness folder"""
        base_dir = Path(self.config["photo_dir"])
        photo_dir = base_dir / brightness_folder

        if not photo_dir.exists():
            logger.error(f"Photo directory not found: {photo_dir}")
            return []

        photos = list(photo_dir.glob("*.png")) + \
                 list(photo_dir.glob("*.jpg")) + \
                 list(photo_dir.glob("*.jpeg")) + \
                 list(photo_dir.glob("*.PNG")) + \
                 list(photo_dir.glob("*.JPG")) + \
                 list(photo_dir.glob("*.JPEG"))

        if not photos:
            logger.warning(f"No photos found in {photo_dir}")
            return []

        random.shuffle(photos)
        logger.info(f"Found {len(photos)} photos in {brightness_folder}/ folder")
        return photos

    def write_to_framebuffer(self, image):
        """Write PIL Image directly to framebuffer"""
        try:
            # Ensure image is correct size
            if image.size != (self.width, self.height):
                image = image.resize((self.width, self.height), Image.LANCZOS)

            # Convert to RGB (framebuffer expects RGB)
            if image.mode != 'RGB':
                image = image.convert('RGB')

            # Write to framebuffer
            with open(self.fb_device, 'wb') as fb:
                fb.write(image.tobytes())
            return True
        except Exception as e:
            logger.error(f"Error writing to framebuffer: {e}")
            return False

    def display_photo(self, photo_path):
        """Load and display a single photo"""
        try:
            logger.info(f"Displaying: {photo_path.name}")
            img = Image.open(photo_path)

            if self.write_to_framebuffer(img):
                self.current_photo = str(photo_path)
                self.write_status()
                return True
            return False
        except Exception as e:
            logger.error(f"Error loading {photo_path}: {e}")
            return False

    def write_status(self):
        """Write current status to file for API"""
        try:
            status = {
                "current_photo": self.current_photo,
                "current_brightness": self.current_brightness,
                "timestamp": datetime.now().isoformat()
            }
            with open("/tmp/piframe-status.json", 'w') as f:
                json.dump(status, f, indent=2)
        except Exception as e:
            logger.error(f"Error writing status: {e}")

    def handle_shutdown(self, signum, frame):
        """Handle shutdown signals (SIGTERM, SIGINT)"""
        logger.info(f"Received shutdown signal {signum}")
        self.running = False

    def handle_next(self, signum, frame):
        """Handle skip to next photo (SIGUSR1)"""
        logger.info("Received skip to next photo signal")
        self.skip_to_next = True

    def handle_reload(self, signum, frame):
        """Handle config reload (SIGHUP)"""
        logger.info("Received config reload signal")
        self.reload_config = True

    def run(self):
        """Main slideshow loop"""
        photos = []
        photo_index = 0
        last_check_minute = -1

        while self.running:
            try:
                # Reload config if requested
                if self.reload_config:
                    logger.info("Reloading configuration...")
                    self.config = self.load_config()
                    self.reload_config = False

                # Check brightness folder every minute
                current_minute = datetime.now().minute
                if current_minute != last_check_minute:
                    new_brightness = self.get_brightness_folder()

                    if new_brightness != self.current_brightness:
                        logger.info(f"Switching from {self.current_brightness} to {new_brightness} brightness")
                        self.current_brightness = new_brightness
                        photos = self.get_photo_list(new_brightness)
                        photo_index = 0

                        if not photos:
                            logger.warning("No photos found after brightness switch, waiting...")
                            time.sleep(60)
                            continue

                    last_check_minute = current_minute

                # Load photos if we don't have any
                if not photos and self.current_brightness:
                    logger.info(f"Loading photos for {self.current_brightness} brightness...")
                    photos = self.get_photo_list(self.current_brightness)
                    photo_index = 0

                if not photos:
                    # First run or no photos available
                    self.current_brightness = self.get_brightness_folder()
                    photos = self.get_photo_list(self.current_brightness)

                    if not photos:
                        logger.error("No photos found in any folder, waiting 60 seconds...")
                        time.sleep(60)
                        continue

                # Display current photo
                if not self.display_photo(photos[photo_index]):
                    logger.warning(f"Failed to display photo, skipping to next")

                # Move to next photo
                if self.skip_to_next:
                    self.skip_to_next = False
                    logger.info("Skipping to next photo")

                photo_index = (photo_index + 1) % len(photos)

                # Wait for interval
                interval = self.config.get("interval", 10)
                for _ in range(interval * 10):  # Check every 100ms
                    if not self.running or self.skip_to_next:
                        break
                    time.sleep(0.1)

            except Exception as e:
                logger.error(f"Error in main loop: {e}", exc_info=True)
                time.sleep(5)  # Avoid tight loop on persistent errors

        logger.info("Slideshow stopped gracefully")

if __name__ == "__main__":
    try:
        slideshow = FramebufferSlideshow()
        slideshow.run()
    except Exception as e:
        logger.error(f"Fatal error: {e}", exc_info=True)
        sys.exit(1)
