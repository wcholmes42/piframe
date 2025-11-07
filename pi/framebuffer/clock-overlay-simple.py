#!/usr/bin/env python3
"""
Simple Framebuffer Clock Overlay
Draws live time over FBI slideshow without mmap
"""

import os
import time
from datetime import datetime
from PIL import Image, ImageDraw, ImageFont

# Display settings
WIDTH = 1920
HEIGHT = 1080
BPP = 4  # 32-bit BGRA
FRAMEBUFFER = "/dev/fb0"

# Clock settings
FONT_SIZE = 72
CLOCK_Y = 20
UPDATE_INTERVAL = 1  # Update every second

# Colors (BGRA format)
TEXT_COLOR = (255, 255, 255, 255)  # White
SHADOW_COLOR = (0, 0, 0, 180)  # Black shadow
BG_COLOR = (0, 0, 0, 140)  # Semi-transparent black


def get_font():
    """Find best available font"""
    font_paths = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
        "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf",
    ]

    for path in font_paths:
        if os.path.exists(path):
            return ImageFont.truetype(path, FONT_SIZE)

    return ImageFont.load_default()


def create_clock_image(text, font):
    """Create clock overlay image"""
    # Create transparent RGBA image
    img = Image.new('RGBA', (WIDTH, 150), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Get text size
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    # Center position
    x = (WIDTH - text_width) // 2
    y = CLOCK_Y

    # Draw background
    padding = 20
    draw.rectangle(
        [x - padding, y - padding, x + text_width + padding, y + text_height + padding],
        fill=BG_COLOR
    )

    # Draw shadow
    draw.text((x + 3, y + 3), text, font=font, fill=SHADOW_COLOR)

    # Draw text
    draw.text((x, y), text, font=font, fill=TEXT_COLOR)

    return img


def write_to_framebuffer(img, fb_file):
    """Write image to framebuffer top region"""
    # Convert RGBA to BGRA
    r, g, b, a = img.split()
    img_bgra = Image.merge('RGBA', (b, g, r, a))

    # Write each row
    for row in range(img.size[1]):
        offset = row * WIDTH * BPP
        fb_file.seek(offset)

        # Get row data
        row_start = row * WIDTH * BPP
        row_end = row_start + WIDTH * BPP
        row_data = img_bgra.tobytes()[row_start:row_end]

        fb_file.write(row_data)

    fb_file.flush()


def main():
    """Main loop"""
    print("Starting framebuffer clock overlay...")

    font = get_font()
    print(f"Font loaded, size: {FONT_SIZE}")

    try:
        with open(FRAMEBUFFER, 'r+b', buffering=0) as fb:
            print(f"Framebuffer opened: {FRAMEBUFFER}")
            print("Drawing clock every second...")

            last_time_str = ""

            while True:
                now = datetime.now()
                time_str = now.strftime("%I:%M:%S %p").lstrip('0')

                # Only redraw if time changed
                if time_str != last_time_str:
                    img = create_clock_image(time_str, font)
                    write_to_framebuffer(img, fb)
                    last_time_str = time_str
                    print(f"\r{time_str}", end='', flush=True)

                time.sleep(UPDATE_INTERVAL)

    except FileNotFoundError:
        print(f"ERROR: {FRAMEBUFFER} not found")
        return 1
    except PermissionError:
        print(f"ERROR: Permission denied. Run as root.")
        return 1
    except KeyboardInterrupt:
        print("\nStopped")
        return 0
    except Exception as e:
        print(f"ERROR: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    exit(main())
