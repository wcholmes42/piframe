#!/usr/bin/env python3
"""
Framebuffer Clock Overlay
Draws time at top center of display over FBI slideshow
"""

import os
import time
import mmap
from datetime import datetime
from PIL import Image, ImageDraw, ImageFont

# Display settings
WIDTH = 1920
HEIGHT = 1080
BPP = 4  # 32-bit RGBA
FRAMEBUFFER = "/dev/fb0"

# Clock settings
FONT_SIZE = 72
CLOCK_Y = 20  # Distance from top
UPDATE_INTERVAL = 30  # Update every 30 seconds

# Colors (BGRA format for framebuffer)
TEXT_COLOR = (255, 255, 255, 255)  # White
SHADOW_COLOR = (0, 0, 0, 180)  # Black with alpha
BG_COLOR = (0, 0, 0, 140)  # Semi-transparent black background


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

    # Fallback to default font
    return ImageFont.load_default()


def create_clock_overlay(text, font):
    """Create semi-transparent overlay with clock text"""
    # Create RGBA image for overlay
    overlay = Image.new('RGBA', (WIDTH, 120), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # Get text size
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    # Center position
    x = (WIDTH - text_width) // 2
    y = CLOCK_Y

    # Draw background rectangle
    padding = 20
    draw.rectangle(
        [x - padding, y - padding, x + text_width + padding, y + text_height + padding],
        fill=BG_COLOR
    )

    # Draw shadow
    shadow_offset = 3
    draw.text((x + shadow_offset, y + shadow_offset), text, font=font, fill=SHADOW_COLOR)

    # Draw main text
    draw.text((x, y), text, font=font, fill=TEXT_COLOR)

    return overlay


def write_overlay_to_framebuffer(overlay, fb_mem):
    """Write overlay to framebuffer at top of screen"""
    # Convert RGBA to BGRA for framebuffer
    overlay_bgra = Image.new('RGBA', overlay.size)
    r, g, b, a = overlay.split()
    overlay_bgra = Image.merge('RGBA', (b, g, r, a))

    # Write only the overlay region (top 120 lines)
    overlay_bytes = overlay_bgra.tobytes()

    for row in range(overlay.size[1]):
        offset = row * WIDTH * BPP
        row_start = row * overlay.size[0] * BPP
        row_end = row_start + (overlay.size[0] * BPP)

        # Blend with existing framebuffer content
        existing = fb_mem[offset:offset + (overlay.size[0] * BPP)]
        new_row = overlay_bytes[row_start:row_end]

        # Simple alpha blend (could be optimized)
        blended = bytearray(len(existing))
        for i in range(0, len(existing), 4):
            alpha = new_row[i + 3] / 255.0
            blended[i] = int(new_row[i] * alpha + existing[i] * (1 - alpha))  # B
            blended[i + 1] = int(new_row[i + 1] * alpha + existing[i + 1] * (1 - alpha))  # G
            blended[i + 2] = int(new_row[i + 2] * alpha + existing[i + 2] * (1 - alpha))  # R
            blended[i + 3] = 255  # A

        fb_mem[offset:offset + len(blended)] = bytes(blended)


def main():
    """Main clock overlay loop"""
    print("Starting framebuffer clock overlay...")

    font = get_font()
    print(f"Using font size: {FONT_SIZE}")

    # Open framebuffer
    try:
        with open(FRAMEBUFFER, 'r+b') as fb:
            fb_mem = mmap.mmap(fb.fileno(), WIDTH * HEIGHT * BPP)

            print(f"Framebuffer mapped: {WIDTH}x{HEIGHT}x{BPP}")
            print(f"Updating every {UPDATE_INTERVAL} seconds")
            print("Press Ctrl+C to stop")

            last_time_str = ""

            while True:
                # Get current time
                now = datetime.now()
                time_str = now.strftime("%I:%M %p").lstrip('0')  # Remove leading zero

                # Only update if time changed
                if time_str != last_time_str:
                    overlay = create_clock_overlay(time_str, font)
                    write_overlay_to_framebuffer(overlay, fb_mem)
                    last_time_str = time_str
                    print(f"Updated: {time_str}", flush=True)

                time.sleep(UPDATE_INTERVAL)

    except FileNotFoundError:
        print(f"ERROR: Framebuffer {FRAMEBUFFER} not found")
        return 1
    except PermissionError:
        print(f"ERROR: Permission denied accessing {FRAMEBUFFER}")
        print("Run as root: sudo python3 clock-overlay.py")
        return 1
    except KeyboardInterrupt:
        print("\nClock overlay stopped")
        return 0
    except Exception as e:
        print(f"ERROR: {e}")
        return 1


if __name__ == "__main__":
    exit(main())
