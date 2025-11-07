#!/usr/bin/env python3
"""
Framebuffer Clock Overlay - Simple Version
Small clock at top center, no alpha blending
"""

import time
from datetime import datetime
from PIL import Image, ImageDraw, ImageFont

# Display settings
WIDTH = 1920
HEIGHT = 1080
FRAMEBUFFER = "/dev/fb0"

# Clock settings
FONT_SIZE = 42
UPDATE_INTERVAL = 1


def get_font():
    """Get font"""
    try:
        return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", FONT_SIZE)
    except:
        return ImageFont.load_default()


def create_clock_bar(text, font):
    """Create small clock bar for top of screen"""
    # Create RGBA image
    img = Image.new('RGBA', (WIDTH, 80), (0, 0, 0, 255))  # Opaque black background
    draw = ImageDraw.Draw(img)

    # Get text size
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]

    # Center position
    x = (WIDTH - text_width) // 2
    y = 15

    # Draw shadow
    draw.text((x + 2, y + 2), text, font=font, fill=(50, 50, 50, 255))

    # Draw white text
    draw.text((x, y), text, font=font, fill=(255, 255, 255, 255))

    return img


def main():
    """Main loop"""
    print("Starting clock overlay...")

    font = get_font()

    with open(FRAMEBUFFER, 'r+b', buffering=0) as fb:
        print("Clock running...")

        last_time = ""

        while True:
            now = datetime.now()
            time_str = now.strftime("%I:%M %p").lstrip('0')

            if time_str != last_time:
                # Create clock bar
                clock_img = create_clock_bar(time_str, font)

                # Convert RGBA to BGRA for framebuffer
                r, g, b, a = clock_img.split()
                bgra = Image.merge('RGBA', (b, g, r, a))

                # Write top 80 rows to framebuffer
                data = bgra.tobytes()
                fb.seek(0)
                fb.write(data)
                fb.flush()

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
