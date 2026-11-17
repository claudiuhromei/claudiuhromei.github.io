"""Tests for make_public_slides.py. Run with: bundle exec rake test:tools"""

from __future__ import annotations

from pathlib import Path

import pymupdf
import pytest

from make_public_slides import AUTHOR, make_public_slides

EMAIL = "some.one@example.org"
BACKGROUND = (0.4, 0.2, 0.8)


@pytest.fixture
def deck(tmp_path: Path) -> Path:
    """Three slides on a coloured background: an email on the last one, comments on the second."""
    path = tmp_path / "deck.pdf"
    document = pymupdf.open()
    for text in ("Title slide", "Comments: merge with the previous slide", "Thank you!"):
        page = document.new_page(width=800, height=450)
        page.draw_rect(page.rect, color=None, fill=BACKGROUND)
        page.insert_text((40, 60), text)
    last = document[-1]
    last.insert_text((40, 120), EMAIL)
    last.insert_link({"kind": pymupdf.LINK_URI, "from": pymupdf.Rect(40, 108, 200, 124), "uri": f"mailto:{EMAIL}"})
    document.set_metadata({"author": "Someone Else", "creator": "Some Tool", "title": "draft v1.2"})
    document.save(path)
    document.close()
    return path


def test_removes_emails_and_the_listed_pages(tmp_path: Path, deck: Path):
    output = tmp_path / "out" / "public.pdf"
    removed = make_public_slides(deck, output, "My talk", drop_pages=[2])
    assert removed == 3  # the email text, its mailto link and one page
    with pymupdf.open(output) as public:
        assert public.page_count == 2
        text = "".join(page.get_text() for page in public)
        assert EMAIL not in text and "Comments" not in text
        assert "Title slide" in text and "Thank you!" in text
        assert not public[-1].get_links()


def test_keeps_the_slide_background_under_the_removed_email(tmp_path: Path, deck: Path):
    output = tmp_path / "public.pdf"
    make_public_slides(deck, output, "My talk")
    with pymupdf.open(output) as public:
        pixel = public[-1].get_pixmap().pixel(60, 116)
    assert all(abs(channel - round(value * 255)) <= 2 for channel, value in zip(pixel, BACKGROUND))


def test_replaces_the_metadata(tmp_path: Path, deck: Path):
    output = tmp_path / "public.pdf"
    make_public_slides(deck, output, "My talk")
    with pymupdf.open(output) as public:
        assert public.metadata["title"] == "My talk"
        assert public.metadata["author"] == AUTHOR
        assert public.metadata["creator"] == ""


def test_rejects_pages_outside_the_deck(tmp_path: Path, deck: Path):
    with pytest.raises(ValueError):
        make_public_slides(deck, tmp_path / "public.pdf", "My talk", drop_pages=[4])
