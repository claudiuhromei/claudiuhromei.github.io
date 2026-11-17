# /// script
# requires-python = ">=3.10"
# dependencies = ["pymupdf>=1.24"]
# ///
"""Create the public, downloadable CV from the private one.

The private CV contains a phone number and an email address. This script removes both
(text and link targets) and writes the result to assets/files/, where the site publishes it.

Usage:
    uv run tools/make_public_cv.py "D:/path/to/HROMEI_<YYYY>_<MM>_en.pdf"
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

import pymupdf

OUTPUT = Path(__file__).resolve().parent.parent / "assets" / "files" / "Claudiu_Daniel_Hromei_CV.pdf"

PHONE = re.compile(r"\+\d{1,3}[\s.-]?\d{2,4}[\s.-]?\d{6,8}\b")
EMAIL = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}")
PRIVATE_LINK_PREFIXES = ("mailto:", "tel:")
# Replaces the source metadata, which carries identifiers of the authoring tool's document.
PUBLIC_METADATA = {
    "title": "Claudiu Daniel Hromei - Curriculum Vitae",
    "author": "Claudiu Daniel Hromei",
    "subject": "",
    "keywords": "",
    "creator": "",
    "producer": "",
}
# Icons sit right before the phone and email texts; the redaction is widened to cover them.
ICON_MARGIN = 18
UNDERLINE_MARGIN = 2
PAGE_BACKGROUND = (1, 1, 1)


def private_matches(text: str) -> list[str]:
    """Return every phone number and email address found in ``text``."""
    return PHONE.findall(text) + EMAIL.findall(text)


def is_private_link(uri: str | None) -> bool:
    """Tell whether a link target exposes contact details (``mailto:``, ``tel:`` or an address)."""
    if not uri:
        return False
    return uri.lower().startswith(PRIVATE_LINK_PREFIXES) or bool(private_matches(uri))


def redact_page(
    page: pymupdf.Page, icon_margin: float = ICON_MARGIN, background: tuple[float, ...] | None = PAGE_BACKGROUND
) -> int:
    """Remove private text and links from one page; return how many items were removed.

    ``icon_margin`` widens each redaction to the left, over the icon that precedes the text.
    With ``background`` (a plain page colour) images under the text are removed and the area is
    painted over; with ``None`` (pages drawn on pictures or gradients) only the text and the line
    art inside the area go, and the picture is kept.
    """
    removed = 0
    areas = []
    for match in set(private_matches(page.get_text())):
        for rect in page.search_for(match):
            areas.append(pymupdf.Rect(rect.x0 - icon_margin, rect.y0, rect.x1, rect.y1 + UNDERLINE_MARGIN))
            page.add_redact_annot(areas[-1], fill=background if background else False)
            removed += 1
    for link in page.get_links():
        if is_private_link(link.get("uri")):
            page.delete_link(link)
            removed += 1
    if not areas:
        return removed
    if background is None:
        page.apply_redactions(
            images=pymupdf.PDF_REDACT_IMAGE_NONE, graphics=pymupdf.PDF_REDACT_LINE_ART_REMOVE_IF_COVERED
        )
        return removed
    page.apply_redactions(images=pymupdf.PDF_REDACT_IMAGE_REMOVE)
    # Redaction removes text and images; line art such as link underlines is painted over.
    for area in areas:
        page.draw_rect(area, color=None, fill=background, overlay=True)
    return removed


def leftovers(document: pymupdf.Document) -> list[str]:
    """Return any private detail still present in the text, links or metadata of ``document``."""
    found: list[str] = []
    for page in document:
        found += private_matches(page.get_text())
        found += [link["uri"] for link in page.get_links() if is_private_link(link.get("uri"))]
    for value in (document.metadata or {}).values():
        found += private_matches(value or "")
    return found


def make_public_cv(source: Path, output: Path = OUTPUT) -> int:
    """Write the redacted copy of ``source`` to ``output``; return the number of removed items."""
    with pymupdf.open(source) as document:
        removed = sum(redact_page(page) for page in document)
        document.set_metadata(PUBLIC_METADATA)
        remaining = leftovers(document)
        if remaining:
            raise ValueError(f"private details still present after redaction: {remaining}")
        output.parent.mkdir(parents=True, exist_ok=True)
        document.save(output, garbage=4, deflate=True, clean=True)
    return removed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("source", type=Path, help="private CV (PDF)")
    parser.add_argument("--output", type=Path, default=OUTPUT, help=f"public CV (default: {OUTPUT})")
    args = parser.parse_args()

    removed = make_public_cv(args.source, args.output)
    if removed == 0:
        print("warning: nothing was removed; check that the source is the expected CV", file=sys.stderr)
    print(f"wrote {args.output} ({removed} private items removed)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
