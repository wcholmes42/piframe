#!/usr/bin/env python3
"""
Framebuffer Clock Overlay - Simple RGB565
Only updates when minute changes, lets FBI handle photo updates
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
UPDATE_INTERVAL = 5  # Check every 5 seconds


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


def draw_text(fb, text, font):
    """Draw text to framebuffer, only in text region"""
    # Create text image
    temp = Image.new('RGB', (400, 50), (0, 0, 0))
    draw = ImageDraw.Draw(temp)

    # Measure text
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    # Create exact-size text image
    text_img = Image.new('RGB', (text_width, text_height), (0, 0, 0))
    draw = ImageDraw.Draw(text_img)
    draw.text((0, 0), text, font=font, fill=(255, 255, 255))

    # Center position
    x_pos = (WIDTH - text_width) // 2
    y_pos = 10

    # Write to framebuffer
    pixels = text_img.load()

    for y in range(text_img.height):
        row_offset = (y_pos + y) * WIDTH * 2 + x_pos * 2
        fb.seek(row_offset)

        # Convert row to RGB565
        row_data = bytearray()
        for x in range(text_img.width):
            r, g, b = pixels[x, y]
            rgb565 = rgb888_to_rgb565(r, g, b)
            row_data.extend(struct.pack('<H', rgb565))

        fb.write(bytes(row_data))

    # Clear white bar at row 1060 (FBI artifact workaround)
    fb.seek(1060 * WIDTH * 2)
    fb.write(b'\x00' * (WIDTH * 2))

    fb.flush()


def main():
    """Main loop"""
    print("Starting clock overlay...")

    font = get_font()

    with open(FRAMEBUFFER, 'r+b', buffering=0) as fb:
        print("Clock running (updates on minute change)...")

        last_time = ""

        while True:
            now = datetime.now()
            time_str = now.strftime("%I:%M %p").lstrip('0')

            # Redraw every cycle to prevent FBI from overwriting
            draw_text(fb, time_str, font)

            # Print only when time changes
            if time_str != last_time:
                last_time = time_str
                print(f"{time_str}")

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
