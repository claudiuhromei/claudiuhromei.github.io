"""Tests for make_public_cv.py. Run with: bundle exec rake test:tools"""

from __future__ import annotations

from pathlib import Path

import pymupdf
import pytest

from make_public_cv import is_private_link, leftovers, make_public_cv, private_matches

PHONE = "+39 3330000000"
EMAIL = "some.one@example.org"


@pytest.fixture
def private_cv(tmp_path: Path) -> Path:
    """A two-page PDF with a contact line (text and links) on the first page."""
    path = tmp_path / "private.pdf"
    document = pymupdf.open()
    first = document.new_page()
    first.insert_text((40, 60), "Jane Doe, PhD")
    first.insert_text((40, 90), "Rome, Italy")
    first.insert_text((140, 90), PHONE)
    first.insert_text((300, 90), EMAIL)
    first.insert_link({"kind": pymupdf.LINK_URI, "from": pymupdf.Rect(300, 78, 430, 94), "uri": f"mailto:{EMAIL}"})
    first.insert_link({"kind": pymupdf.LINK_URI, "from": pymupdf.Rect(40, 110, 200, 126), "uri": "https://example.org/"})
    document.new_page().insert_text((40, 60), "Publications")
    document.set_metadata({"keywords": "internal-id", "creator": "Some Tool"})
    document.save(path)
    document.close()
    return path


@pytest.mark.parametrize(
    ("text", "expected"),
    [
        (f"Rome, Italy {PHONE} {EMAIL}", [PHONE, EMAIL]),
        ("+391234567890", ["+391234567890"]),
        ("EMNLP 2025, pages 23747-23770, 110/110 cum laude", []),
    ],
)
def test_private_matches(text: str, expected: list[str]) -> None:
    assert private_matches(text) == expected


@pytest.mark.parametrize(
    ("uri", "expected"),
    [
        (f"mailto:{EMAIL}", True),
        ("MAILTO:someone", True),
        ("tel:+393330000000", True),
        (f"https://example.org/contact?to={EMAIL}", True),
        ("https://github.com/crux82/grut", False),
        (None, False),
    ],
)
def test_is_private_link(uri: str | None, expected: bool) -> None:
    assert is_private_link(uri) is expected


def test_public_cv_has_no_contact_details_but_keeps_the_rest(private_cv: Path, tmp_path: Path) -> None:
    output = tmp_path / "out" / "public.pdf"

    removed = make_public_cv(private_cv, output)

    assert removed == 3  # phone text, email text, mailto link
    with pymupdf.open(output) as document:
        assert leftovers(document) == []
        assert len(document) == 2
        first_page = document[0].get_text()
        assert "Jane Doe, PhD" in first_page
        assert "Rome, Italy" in first_page
        assert [link["uri"] for link in document[0].get_links()] == ["https://example.org/"]
        assert "Publications" in document[1].get_text()


def test_public_cv_drops_the_source_metadata(private_cv: Path, tmp_path: Path) -> None:
    output = tmp_path / "public.pdf"

    make_public_cv(private_cv, output)

    with pymupdf.open(output) as document:
        assert document.metadata["keywords"] == ""
        assert document.metadata["creator"] == ""
        assert document.metadata["author"] == "Claudiu Daniel Hromei"


def test_source_file_is_left_untouched(private_cv: Path, tmp_path: Path) -> None:
    before = private_cv.read_bytes()

    make_public_cv(private_cv, tmp_path / "public.pdf")

    assert private_cv.read_bytes() == before
