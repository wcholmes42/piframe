#!/usr/bin/env python3
"""
Framebuffer Clock Overlay - RGB565 Format
Correct format for Pi framebuffer
"""

import time
import struct
from datetime import datetime
from PIL import Image, ImageDraw, ImageFont

# Display settings
WIDTH = 1920
HEIGHT = 1080
FRAMEBUFFER = "/dev/fb0"

# Clock settings
FONT_SIZE = 24
UPDATE_INTERVAL = 1


def get_font():
    """Get font"""
    try:
        return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", FONT_SIZE)
    except:
        return ImageFont.load_default()


def rgb888_to_rgb565(r, g, b):
    """Convert 24-bit RGB to 16-bit RGB565"""
    r5 = (r >> 3) & 0x1F
    g6 = (g >> 2) & 0x3F
    b5 = (b >> 3) & 0x1F
    return (r5 << 11) | (g6 << 5) | b5


def draw_text_centered(fb, text, font):
    """Draw centered text to RGB565 framebuffer"""
    # Create text image in RGB mode
    temp = Image.new('RGB', (400, 50), (0, 0, 0))
    draw = ImageDraw.Draw(temp)

    # Measure text
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    # Create exact-size image
    text_img = Image.new('RGB', (text_width, text_height), (0, 0, 0))
    draw = ImageDraw.Draw(text_img)

    # Draw white text
    draw.text((0, 0), text, font=font, fill=(255, 255, 255))

    # Calculate center position
    x_pos = (WIDTH - text_width) // 2
    y_pos = 10

    # Convert to RGB565 and write
    pixels = text_img.load()

    for y in range(text_img.height):
        fb_row_offset = (y_pos + y) * WIDTH * 2  # 2 bytes per pixel
        fb.seek(fb_row_offset + x_pos * 2)

        # Read existing row segment
        existing = fb.read(text_width * 2)

        # Create new row
        row_data = bytearray()
        for x in range(text_width):
            r, g, b = pixels[x, y]

            # If pixel is white (text), use it; otherwise use existing
            if r > 200 and g > 200 and b > 200:  # White text
                rgb565 = rgb888_to_rgb565(r, g, b)
            else:
                # Use existing pixel
                if x * 2 + 1 < len(existing):
                    rgb565 = struct.unpack('<H', existing[x*2:x*2+2])[0]
                else:
                    rgb565 = 0

            row_data.extend(struct.pack('<H', rgb565))

        # Write row back
        fb.seek(fb_row_offset + x_pos * 2)
        fb.write(bytes(row_data))

    fb.flush()


def main():
    """Main loop"""
    print("Starting clock overlay (RGB565)...")

    font = get_font()

    with open(FRAMEBUFFER, 'r+b', buffering=0) as fb:
        print("Clock running...")

        last_time = ""

        while True:
            now = datetime.now()
            time_str = now.strftime("%I:%M %p").lstrip('0')

            if time_str != last_time:
                draw_text_centered(fb, time_str, font)
                last_time = time_str
                print(f"\r{time_str}", end='', flush=True)

            time.sleep(UPDATE_INTERVAL)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nStopped")
    except Exception as e:
        print(f"ERROR: {e}")
        import traceback
        traceback.print_exc()
