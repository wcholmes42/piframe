#!/usr/bin/env python3
"""
Framebuffer Clock Overlay - Fixed
Small clock at top center over slideshow
"""

import time
from datetime import datetime
from PIL import Image, ImageDraw, ImageFont

# Display settings
WIDTH = 1920
HEIGHT = 1080
FRAMEBUFFER = "/dev/fb0"

# Clock settings
FONT_SIZE = 48
CLOCK_HEIGHT = 100
UPDATE_INTERVAL = 1

# Colors (RGBA)
TEXT_COLOR = (255, 255, 255, 255)  # White
SHADOW_COLOR = (0, 0, 0, 200)  # Black shadow
BG_COLOR = (0, 0, 0, 120)  # Semi-transparent black


def get_font():
    """Get font"""
    try:
        return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", FONT_SIZE)
    except:
        return ImageFont.load_default()


def create_clock_overlay(text, font):
    """Create small centered clock overlay"""
    # Create full-width transparent image
    img = Image.new('RGBA', (WIDTH, CLOCK_HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Get text size
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    # Center horizontally, 10px from top
    x = (WIDTH - text_width) // 2
    y = 10

    # Draw background box
    pad = 15
    draw.rectangle(
        [x - pad, y - pad, x + text_width + pad, y + text_height + pad],
        fill=BG_COLOR
    )

    # Draw shadow
    draw.text((x + 2, y + 2), text, font=font, fill=SHADOW_COLOR)

    # Draw text
    draw.text((x, y), text, font=font, fill=TEXT_COLOR)

    return img


def main():
    """Main loop"""
    print("Starting clock overlay...")

    font = get_font()

    with open(FRAMEBUFFER, 'r+b', buffering=0) as fb:
        print("Drawing clock...")

        last_time = ""

        while True:
            now = datetime.now()
            time_str = now.strftime("%I:%M %p").lstrip('0')

            if time_str != last_time:
                # Create overlay
                overlay = create_clock_overlay(time_str, font)

                # Convert to BGRA for framebuffer
                r, g, b, a = overlay.split()
                bgra = Image.merge('RGBA', (b, g, r, a))

                # Write to framebuffer top rows only (alpha blend manually)
                # Read existing framebuffer, blend, write back
                pixels = bgra.load()

                for y in range(CLOCK_HEIGHT):
                    fb.seek(y * WIDTH * 4)  # 4 bytes per pixel (BGRA)
                    row_data = fb.read(WIDTH * 4)

                    # Create blended row
                    blended = bytearray(WIDTH * 4)
                    for x in range(WIDTH):
                        px_offset = x * 4
                        overlay_px = (
                            pixels[x, y][0],  # B
                            pixels[x, y][1],  # G
                            pixels[x, y][2],  # R
                            pixels[x, y][3],  # A
                        )

                        if overlay_px[3] > 0:  # Has alpha
                            alpha = overlay_px[3] / 255.0
                            existing = (
                                row_data[px_offset] if px_offset < len(row_data) else 0,
                                row_data[px_offset + 1] if px_offset + 1 < len(row_data) else 0,
                                row_data[px_offset + 2] if px_offset + 2 < len(row_data) else 0,
                                255
                            )

                            # Alpha blend
                            blended[px_offset] = int(overlay_px[0] * alpha + existing[0] * (1 - alpha))
                            blended[px_offset + 1] = int(overlay_px[1] * alpha + existing[1] * (1 - alpha))
                            blended[px_offset + 2] = int(overlay_px[2] * alpha + existing[2] * (1 - alpha))
                            blended[px_offset + 3] = 255
                        else:
                            # Copy existing
                            if px_offset < len(row_data):
                                blended[px_offset:px_offset + 4] = row_data[px_offset:px_offset + 4]

                    # Write blended row back
                    fb.seek(y * WIDTH * 4)
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
