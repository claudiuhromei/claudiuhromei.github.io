"""Shared fixtures: a local server for the built site and browser pages at given sizes.

Run with `bundle exec rake test:browser` (builds the site first). The tests use the Chromium that
Playwright installs; on Windows they default to the installed Edge. Set BROWSER_CHANNEL to override.
"""

from __future__ import annotations

import functools
import http.server
import os
import sys
import threading
from collections.abc import Callable, Iterator
from pathlib import Path

import pytest
from playwright.sync_api import Browser, Page, sync_playwright

SITE_DIR = Path(__file__).resolve().parent.parent / "_site"
PHONE = 390
TABLET = 800
DESKTOP = 1280
WIDE = 1440


class _QuietHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args: object) -> None:  # keep the test output clean
        pass


@pytest.fixture(scope="session")
def base_url() -> Iterator[str]:
    if not (SITE_DIR / "index.html").exists():
        pytest.exit("Site not built: run `bundle exec rake build` first.", returncode=1)
    handler = functools.partial(_QuietHandler, directory=str(SITE_DIR))
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    yield f"http://127.0.0.1:{server.server_address[1]}"
    server.shutdown()


@pytest.fixture(scope="session")
def browser() -> Iterator[Browser]:
    channel = os.environ.get("BROWSER_CHANNEL") or ("msedge" if sys.platform == "win32" else None)
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(channel=channel)
        yield browser
        browser.close()


@pytest.fixture
def open_page(browser: Browser, base_url: str) -> Iterator[Callable[..., Page]]:
    """Return a function that opens a site path at a viewport width and colour scheme."""
    contexts = []

    def _open(path: str = "/", width: int = DESKTOP, scheme: str = "light") -> Page:
        context = browser.new_context(
            viewport={"width": width, "height": 800}, color_scheme=scheme, is_mobile=width < 600
        )
        contexts.append(context)
        page = context.new_page()
        page.goto(base_url + path)
        page.wait_for_load_state("networkidle")
        return page

    yield _open
    for context in contexts:
        context.close()


def horizontal_overflow(page: Page) -> int:
    """Pixels by which the document is wider than the viewport."""
    return page.evaluate("document.documentElement.scrollWidth - document.documentElement.clientWidth")


def page_background(page: Page) -> str:
    return page.evaluate("getComputedStyle(document.documentElement).backgroundColor")
