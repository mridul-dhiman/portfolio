#!/usr/bin/env python3
"""Renders web/og.png (the 1200x630 social card) and web/favicon.png.

Both are drawn from the same tokens the Flutter app uses, in the same
monospace, so a link preview looks like the page it links to. Regenerate with:

    pip install pillow
    python3 tool/make_og_image.py

Checked-in output is what ships; this script exists so the card can be edited
rather than redrawn by hand.
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
FONTS = ROOT / "assets" / "fonts"
WEB = ROOT / "web"

# lib/theme/tokens.dart
INK = (0x0A, 0x0A, 0x0A)
PAPER = (0xFA, 0xFA, 0xF7)
ACCENT_K = (0x7A, 0x4C, 0xFA)  # light-surface Kotlin purple
DIM = tuple(round(0.58 * i + 0.42 * p) for i, p in zip(INK, PAPER))

CARD = (1200, 630)
MARGIN = 80


def font(weight: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONTS / f"JetBrainsMono-{weight}.ttf"), size)


def make_card() -> Image.Image:
    image = Image.new("RGB", CARD, PAPER)
    draw = ImageDraw.Draw(image)

    meta = font("Regular", 22)
    hero = font("Medium", 76)

    y = MARGIN
    draw.text((MARGIN, y), "// ", font=meta, fill=ACCENT_K)
    draw.text((MARGIN + draw.textlength("// ", font=meta), y), "senior android engineer", font=meta, fill=INK)

    y += 96
    draw.text((MARGIN, y), "1,150,000+ downloads", font=hero, fill=INK)
    y += 96
    line = "0.12% crash rate"
    draw.text((MARGIN, y), line, font=hero, fill=INK)

    # The blinking hero cursor, caught mid-blink: 1ch wide, solid accent.
    cursor_x = MARGIN + draw.textlength(line, font=hero)
    draw.rectangle([cursor_x, y, cursor_x + 76 * 0.6, y + 76], fill=ACCENT_K)

    # Hard 1px rule above the footer line, full bleed.
    y = CARD[1] - MARGIN - 56
    draw.rectangle([0, y, CARD[0], y], fill=INK)

    draw.text(
        (MARGIN, CARD[1] - MARGIN - 22),
        "mridul_dhiman · kotlin · flutter · gurugram, in",
        font=meta,
        fill=DIM,
    )
    return image


def make_favicon() -> Image.Image:
    """A solid accent block on paper — the hero cursor, nothing else."""
    size = 256
    image = Image.new("RGB", (size, size), PAPER)
    draw = ImageDraw.Draw(image)
    draw.rectangle([size * 0.3, size * 0.18, size * 0.7, size * 0.82], fill=ACCENT_K)
    return image


if __name__ == "__main__":
    make_card().save(WEB / "og.png", optimize=True)
    favicon = make_favicon()
    favicon.save(WEB / "favicon.png", optimize=True)
    for icon_size in (192, 512):
        resized = favicon.resize((icon_size, icon_size), Image.LANCZOS)
        resized.save(WEB / "icons" / f"Icon-{icon_size}.png", optimize=True)
        resized.save(WEB / "icons" / f"Icon-maskable-{icon_size}.png", optimize=True)
    print("wrote web/og.png, web/favicon.png and web/icons/*")
