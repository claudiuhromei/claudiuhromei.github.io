# /// script
# requires-python = ">=3.10"
# dependencies = ["pymupdf>=1.24"]
# ///
"""Create a public, downloadable copy of a slide deck or poster.

The copy has no email addresses (text and link targets), none of the pages listed with --drop-pages
(for example a page of reviewer comments exported by PowerPoint) and clean metadata. It is written to
assets/files/slides/, where the site publishes it.

Usage:
    uv run tools/make_public_slides.py "<deck>.pdf" <output-name>.pdf --title "<talk title>" [--drop-pages 8]
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import pymupdf

from make_public_cv import leftovers, redact_page

OUTPUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "files" / "slides"
AUTHOR = "Claudiu Daniel Hromei"
# Slides have no contact icons next to the addresses: the redaction covers the text plus one point, so
# that it also covers the link underline (which starts slightly before the text). It keeps the pictures
# and gradients that slides are drawn on.
ICON_MARGIN = 1


def make_public_slides(source: Path, output: Path, title: str, drop_pages: list[int] | None = None) -> int:
    """Write the public copy of ``source`` to ``output``; return the number of removed items.

    ``drop_pages`` are 1-based page numbers of ``source``.
    """
    with pymupdf.open(source) as document:
        drop = sorted({page - 1 for page in drop_pages or []})
        if any(page < 0 or page >= document.page_count for page in drop):
            raise ValueError(f"pages to drop must be between 1 and {document.page_count}: {drop_pages}")
        if drop:
            document.delete_pages(drop)
        removed = sum(redact_page(page, icon_margin=ICON_MARGIN, background=None) for page in document)
        document.set_metadata(
            {"title": title, "author": AUTHOR, "subject": "", "keywords": "", "creator": "", "producer": ""}
        )
        remaining = leftovers(document)
        if remaining:
            raise ValueError(f"private details still present after redaction: {remaining}")
        output.parent.mkdir(parents=True, exist_ok=True)
        document.save(output, garbage=4, deflate=True, clean=True)
    return removed + len(drop)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("source", type=Path, help="slide deck or poster (PDF)")
    parser.add_argument("name", help=f"file name of the public copy, written to {OUTPUT_DIR}")
    parser.add_argument("--title", required=True, help="title stored in the PDF metadata")
    parser.add_argument("--drop-pages", type=int, nargs="*", default=[], help="1-based pages to leave out")
    args = parser.parse_args()

    output = OUTPUT_DIR / args.name
    removed = make_public_slides(args.source, output, args.title, args.drop_pages)
    print(f"wrote {output} ({output.stat().st_size // 1024} KiB, {removed} items removed)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
