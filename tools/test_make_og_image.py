"""Tests for make_og_image.py. Run with: bundle exec rake test:tools"""

from __future__ import annotations

from pathlib import Path

import pytest
from PIL import Image, ImageColor

import make_og_image as og

RED = (200, 30, 30)


@pytest.fixture
def preview(tmp_path: Path) -> Image.Image:
    """Preview built from a plain red, non-square "photo"."""
    photo = tmp_path / "photo.jpg"
    Image.new("RGB", (600, 400), RED).save(photo, quality=95)
    return og.make_og_image(photo, tmp_path / "out" / "og.png")


def close(pixel, colour, tolerance=12) -> bool:
    return all(abs(a - b) <= tolerance for a, b in zip(pixel, colour))


def photo_centre() -> tuple[int, int]:
    middle = og.BAR_HEIGHT + (og.SIZE[1] - og.BAR_HEIGHT) // 2
    return og.PHOTO_LEFT + og.PHOTO_DIAMETER // 2, middle


def test_image_has_the_open_graph_size_and_is_written(tmp_path: Path, preview: Image.Image):
    assert preview.size == (1200, 630)
    with Image.open(tmp_path / "out" / "og.png") as saved:
        assert saved.size == (1200, 630)


def test_top_bar_uses_the_site_accent(preview: Image.Image):
    accent = ImageColor.getrgb(og.ACCENT)
    assert all(close(preview.getpixel((x, 10)), accent, 0) for x in (0, 600, 1199))
    assert close(preview.getpixel((600, og.BAR_HEIGHT + 5)), (255, 255, 255), 0)


def test_photo_is_round_with_an_accent_ring(preview: Image.Image):
    x, y = photo_centre()
    radius = og.PHOTO_DIAMETER // 2
    assert close(preview.getpixel((x, y)), RED)
    assert close(preview.getpixel((x, y - radius - og.PHOTO_RING // 2)), ImageColor.getrgb(og.ACCENT))
    # The corners of the photo's square stay background: the photo is a circle.
    corner = (og.PHOTO_LEFT + 5, y - radius + 5)
    assert close(preview.getpixel(corner), (255, 255, 255), 0)


def test_text_is_drawn_to_the_right_of_the_photo_and_fits(preview: Image.Image):
    # getextrema() gives (darkest, lightest) per channel of a region.
    text_area = preview.crop((og.TEXT_LEFT, og.BAR_HEIGHT, og.SIZE[0], og.SIZE[1]))
    assert min(low for low, _ in text_area.getextrema()) < 100, "no text drawn"
    margin = preview.crop((og.SIZE[0] - og.TEXT_RIGHT_MARGIN + 10, og.BAR_HEIGHT, og.SIZE[0], og.SIZE[1]))
    assert all(low == 255 for low, _ in margin.getextrema()), "text runs into the right margin"


def test_round_photo_is_a_centred_square_with_transparent_corners():
    photo = Image.new("RGB", (300, 100), (0, 0, 255))
    photo.paste((0, 255, 0), (100, 0, 200, 100))  # the centred square is green
    circle = og.round_photo(photo, 80)
    assert circle.size == (80, 80)
    assert circle.getpixel((40, 40))[:3] == (0, 255, 0)
    assert circle.getpixel((0, 0))[3] == 0
    assert circle.getpixel((40, 40))[3] == 255
