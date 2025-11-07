#!/usr/bin/env python3
"""
Framebuffer Clock Overlay - Properly centered
Only writes to the text region, not full width
"""

import time
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


def draw_text_to_framebuffer(fb, text, font):
    """Draw centered text directly to framebuffer"""
    # Create small text image
    temp = Image.new('RGBA', (500, 50), (0, 0, 0, 0))
    draw = ImageDraw.Draw(temp)

    # Get actual text size
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    # Create exact-size image for text
    text_img = Image.new('RGBA', (text_width + 4, text_height + 4), (0, 0, 0, 0))
    draw = ImageDraw.Draw(text_img)

    # Draw white text
    draw.text((2, 2), text, font=font, fill=(255, 255, 255, 255))

    # Convert to BGRA
    r, g, b, a = text_img.split()
    bgra = Image.merge('RGBA', (b, g, r, a))

    # Calculate center position
    x_pos = (WIDTH - text_width) // 2
    y_pos = 10

    # Write to framebuffer row by row
    for y in range(text_img.height):
        row_offset = (y_pos + y) * WIDTH * 4 + x_pos * 4
        fb.seek(row_offset)

        # Read existing pixels for this row
        existing = fb.read(text_img.width * 4)

        # Get overlay row
        overlay_row_start = y * text_img.width * 4
        overlay_row_end = overlay_row_start + text_img.width * 4
        overlay_row = bgra.tobytes()[overlay_row_start:overlay_row_end]

        # Blend row
        blended = bytearray(text_img.width * 4)
        for i in range(0, len(blended), 4):
            oa = overlay_row[i+3] if i+3 < len(overlay_row) else 0

            if oa > 0:
                alpha = oa / 255.0
                eb = existing[i] if i < len(existing) else 0
                eg = existing[i+1] if i+1 < len(existing) else 0
                er = existing[i+2] if i+2 < len(existing) else 0

                blended[i] = int(overlay_row[i] * alpha + eb * (1 - alpha))
                blended[i+1] = int(overlay_row[i+1] * alpha + eg * (1 - alpha))
                blended[i+2] = int(overlay_row[i+2] * alpha + er * (1 - alpha))
                blended[i+3] = 255
            else:
                if i < len(existing):
                    blended[i:i+4] = existing[i:i+4]

        # Write blended row back
        fb.seek(row_offset)
        fb.write(bytes(blended))

    fb.flush()


def main():
    """Main loop"""
    print("Starting clock overlay (centered)...")

    font = get_font()

    with open(FRAMEBUFFER, 'r+b', buffering=0) as fb:
        print("Clock running...")

        last_time = ""

        while True:
            now = datetime.now()
            time_str = now.strftime("%I:%M %p").lstrip('0')

            if time_str != last_time:
                draw_text_to_framebuffer(fb, time_str, font)
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
