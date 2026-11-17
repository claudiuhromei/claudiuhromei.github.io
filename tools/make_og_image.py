# /// script
# requires-python = ">=3.10"
# dependencies = ["pillow>=10.1"]
# ///
"""Create the social preview image (Open Graph) from the profile photo.

The image is what LinkedIn, WhatsApp, Slack and others show when someone shares a link to the site:
the round profile photo next to the name and headline, in the colours of the light theme.

Usage (run again whenever the photo or the headline changes):
    uv run tools/make_og_image.py
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
PHOTO = ROOT / "assets" / "images" / "profile.jpg"
OUTPUT = ROOT / "assets" / "images" / "og-image.png"

SIZE = (1200, 630)  # recommended Open Graph size
ACCENT = "#006b3f"  # $site-accent of the light theme (assets/css/main.scss)
BACKGROUND = "#ffffff"
TEXT = "#222831"
MUTED = "#5a6270"

BAR_HEIGHT = 36  # accent strip along the top, like the site header
PHOTO_DIAMETER = 340
PHOTO_RING = 8
PHOTO_LEFT = 90
TEXT_LEFT = PHOTO_LEFT + PHOTO_DIAMETER + 70
TEXT_RIGHT_MARGIN = 60

NAME = "Claudiu Daniel Hromei"
HEADLINE = "Senior AI Scientist · AI Researcher"
TOPICS = "NLP · Large Language Models · Agentic AI"
ADDRESS = "claudiuhromei.github.io"

# First font found is used; Pillow's built-in font is the last resort (e.g. on a bare CI runner).
FONTS = {
    True: ["segoeuib.ttf", "C:/Windows/Fonts/segoeuib.ttf", "DejaVuSans-Bold.ttf",
           "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"],
    False: ["segoeui.ttf", "C:/Windows/Fonts/segoeui.ttf", "DejaVuSans.ttf",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"],
}


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    for candidate in FONTS[bold]:
        try:
            return ImageFont.truetype(candidate, size)
        except OSError:
            continue
    return ImageFont.load_default(size)


def fitting_font(draw: ImageDraw.ImageDraw, text: str, size: int, width: int, bold: bool = False):
    """Largest font up to `size` whose rendering of `text` fits in `width` pixels."""
    while size > 10:
        candidate = font(size, bold)
        if draw.textlength(text, font=candidate) <= width:
            return candidate
        size -= 2
    return font(size, bold)


def round_photo(photo: Image.Image, diameter: int) -> Image.Image:
    """The photo cropped to a centred square and masked to a smooth circle."""
    side = min(photo.size)
    left, top = (photo.width - side) // 2, (photo.height - side) // 2
    square = photo.convert("RGB").crop((left, top, left + side, top + side)).resize((diameter, diameter), Image.LANCZOS)
    mask = Image.new("L", (diameter * 4, diameter * 4), 0)  # drawn large, then scaled down: anti-aliased edge
    ImageDraw.Draw(mask).ellipse((0, 0, diameter * 4 - 1, diameter * 4 - 1), fill=255)
    square.putalpha(mask.resize((diameter, diameter), Image.LANCZOS))
    return square


def make_og_image(photo_path: Path, output: Path) -> Image.Image:
    image = Image.new("RGB", SIZE, BACKGROUND)
    draw = ImageDraw.Draw(image)
    draw.rectangle((0, 0, SIZE[0], BAR_HEIGHT - 1), fill=ACCENT)

    middle = BAR_HEIGHT + (SIZE[1] - BAR_HEIGHT) // 2
    ring = PHOTO_DIAMETER + 2 * PHOTO_RING
    ring_top = middle - ring // 2
    draw.ellipse((PHOTO_LEFT - PHOTO_RING, ring_top, PHOTO_LEFT - PHOTO_RING + ring - 1, ring_top + ring - 1), fill=ACCENT)
    with Image.open(photo_path) as photo:
        circle = round_photo(photo, PHOTO_DIAMETER)
    image.paste(circle, (PHOTO_LEFT, ring_top + PHOTO_RING), circle)

    width = SIZE[0] - TEXT_LEFT - TEXT_RIGHT_MARGIN
    lines = [
        (NAME, fitting_font(draw, NAME, 64, width, bold=True), TEXT, 30),
        (HEADLINE, fitting_font(draw, HEADLINE, 36, width, bold=True), ACCENT, 22),
        (TOPICS, fitting_font(draw, TOPICS, 28, width), MUTED, 0),
    ]
    heights = [draw.textbbox((0, 0), text, font=face)[3] for text, face, _, _ in lines]
    y = middle - (sum(heights) + sum(gap for *_, gap in lines)) // 2 - 20
    for (text, face, colour, gap), height in zip(lines, heights):
        draw.text((TEXT_LEFT, y), text, font=face, fill=colour)
        y += height + gap
    draw.text((TEXT_LEFT, SIZE[1] - 80), ADDRESS, font=font(26), fill=MUTED)

    output.parent.mkdir(parents=True, exist_ok=True)
    image.save(output, optimize=True)
    return image


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--photo", type=Path, default=PHOTO)
    parser.add_argument("--output", type=Path, default=OUTPUT)
    arguments = parser.parse_args()
    make_og_image(arguments.photo, arguments.output)
    print(f"Written {arguments.output}")


if __name__ == "__main__":
    main()
