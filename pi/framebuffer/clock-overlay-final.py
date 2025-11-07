#!/usr/bin/env python3
"""
Framebuffer Clock Overlay - Transparent background version
Small white text at top center with transparent background
"""

import time
from datetime import datetime
from PIL import Image, ImageDraw, ImageFont

# Display settings
WIDTH = 1920
HEIGHT = 1080
FRAMEBUFFER = "/dev/fb0"

# Clock settings
FONT_SIZE = 24  # Half of 48
CLOCK_HEIGHT = 60
UPDATE_INTERVAL = 1


def get_font():
    """Get font"""
    try:
        return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", FONT_SIZE)
    except:
        return ImageFont.load_default()


def create_text_overlay(text, font):
    """Create transparent overlay with just white text"""
    # Fully transparent background
    img = Image.new('RGBA', (WIDTH, CLOCK_HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Get text size
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]

    # Center position, 10px from top
    x = (WIDTH - text_width) // 2
    y = 10

    # Draw white text only (no background, no shadow)
    draw.text((x, y), text, font=font, fill=(255, 255, 255, 255))

    return img


def main():
    """Main loop"""
    print("Starting clock overlay...")

    font = get_font()

    with open(FRAMEBUFFER, 'r+b', buffering=0) as fb:
        print("Clock running (transparent bg, white text)...")

        last_time = ""

        while True:
            now = datetime.now()
            time_str = now.strftime("%I:%M %p").lstrip('0')

            if time_str != last_time:
                # Create text overlay
                overlay = create_text_overlay(time_str, font)

                # Convert RGBA to BGRA for framebuffer
                r, g, b, a = overlay.split()
                bgra = Image.merge('RGBA', (b, g, r, a))

                # Read existing framebuffer, blend with overlay
                fb.seek(0)
                existing_data = fb.read(WIDTH * CLOCK_HEIGHT * 4)

                # Blend pixel by pixel
                overlay_bytes = bgra.tobytes()
                blended = bytearray(WIDTH * CLOCK_HEIGHT * 4)

                for i in range(0, len(blended), 4):
                    # Get overlay pixel (BGRA)
                    ob = overlay_bytes[i] if i < len(overlay_bytes) else 0
                    og = overlay_bytes[i+1] if i+1 < len(overlay_bytes) else 0
                    or_ = overlay_bytes[i+2] if i+2 < len(overlay_bytes) else 0
                    oa = overlay_bytes[i+3] if i+3 < len(overlay_bytes) else 0

                    # Get existing pixel
                    eb = existing_data[i] if i < len(existing_data) else 0
                    eg = existing_data[i+1] if i+1 < len(existing_data) else 0
                    er = existing_data[i+2] if i+2 < len(existing_data) else 0

                    # Alpha blend
                    if oa > 0:
                        alpha = oa / 255.0
                        blended[i] = int(ob * alpha + eb * (1 - alpha))
                        blended[i+1] = int(og * alpha + eg * (1 - alpha))
                        blended[i+2] = int(or_ * alpha + er * (1 - alpha))
                        blended[i+3] = 255
                    else:
                        # Keep existing
                        blended[i] = eb
                        blended[i+1] = eg
                        blended[i+2] = er
                        blended[i+3] = 255

                # Write blended result back
                fb.seek(0)
                fb.write(bytes(blended))
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
