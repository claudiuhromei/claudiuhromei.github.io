"""Behaviour that only shows up in a real browser: layout, navigation menu, theme toggle, contact link."""

from __future__ import annotations

import pytest
from conftest import DESKTOP, PHONE, TABLET, WIDE, horizontal_overflow, page_background
from playwright.sync_api import expect

PAGES = ["/", "/experience/", "/projects/", "/publications/", "/teaching/", "/service/", "/news/", "/cv/"]
LIGHT_BACKGROUND = "rgb(255, 255, 255)"
DARK_BACKGROUND = "rgb(37, 42, 52)"


@pytest.mark.parametrize("path", PAGES)
@pytest.mark.parametrize("width", [PHONE, TABLET, DESKTOP])
def test_pages_do_not_scroll_sideways(open_page, path, width):
    assert horizontal_overflow(open_page(path, width)) == 0


def test_open_citation_does_not_widen_the_page_on_a_phone(open_page):
    page = open_page("/publications/", PHONE)
    page.locator(".publication__cite summary").first.click()
    expect(page.locator(".publication__cite pre").first).to_be_visible()
    assert horizontal_overflow(page) == 0


@pytest.mark.parametrize("width", [PHONE, DESKTOP])
def test_project_figures_fit_the_text_column_and_half_a_screen(open_page, width):
    page = open_page("/projects/", width)
    images = page.locator(".project-figure img")
    assert images.count() == 7
    paragraph = page.locator(".page__content > p").first.bounding_box()
    rem = page.evaluate("parseFloat(getComputedStyle(document.documentElement).fontSize)")
    for index in range(images.count()):
        image = images.nth(index)
        image.scroll_into_view_if_needed()
        expect(image).to_have_js_property("complete", True)
        box = image.bounding_box()
        assert box["width"] > 50, "the figure did not load"
        assert box["x"] + box["width"] <= paragraph["x"] + paragraph["width"] + 1
        assert box["height"] <= 24 * rem + 1


def test_project_figures_keep_a_white_background_in_the_dark_theme(open_page):
    page = open_page("/projects/", scheme="dark")
    background = page.evaluate("getComputedStyle(document.querySelector('.project-figure img')).backgroundColor")
    assert background == LIGHT_BACKGROUND


@pytest.mark.parametrize("width", [PHONE, DESKTOP])
def test_experience_timeline_dots_sit_on_the_line_beside_their_titles(open_page, width):
    page = open_page("/experience/", width)
    dots = page.evaluate(
        """() => [...document.querySelectorAll('.timeline > h3')].map(h3 => {
            const line = h3.parentElement.getBoundingClientRect().left + 1;  // middle of the 2px border
            const dot = getComputedStyle(h3, '::before');
            const box = h3.getBoundingClientRect();
            const centre = box.left + parseFloat(dot.left) + parseFloat(dot.width) / 2;
            return {offset: Math.abs(centre - line), top: parseFloat(dot.top), height: box.height};
        })"""
    )
    assert len(dots) == 6
    for dot in dots:
        assert dot["offset"] <= 1, "dot is not centred on the line"
        assert 0 <= dot["top"] < dot["height"]


# --- Theme -------------------------------------------------------------------------------------


@pytest.mark.parametrize(("scheme", "expected"), [("light", LIGHT_BACKGROUND), ("dark", DARK_BACKGROUND)])
def test_theme_follows_the_system_setting_by_default(open_page, scheme, expected):
    assert page_background(open_page("/", scheme=scheme)) == expected


@pytest.mark.parametrize("width", [PHONE, DESKTOP])
def test_theme_toggle_sits_in_the_header(open_page, width):
    page = open_page("/", width)
    toggle = page.locator(".masthead .js-theme-toggle")
    expect(toggle).to_be_visible()
    header = page.locator(".masthead").bounding_box()
    box = toggle.bounding_box()
    assert header["y"] <= box["y"] and box["y"] + box["height"] <= header["y"] + header["height"]


@pytest.mark.parametrize(
    ("scheme", "before", "after", "label_after"),
    [
        ("light", LIGHT_BACKGROUND, DARK_BACKGROUND, "Switch to light theme"),
        ("dark", DARK_BACKGROUND, LIGHT_BACKGROUND, "Switch to dark theme"),
    ],
)
def test_theme_toggle_switches_and_the_choice_survives_navigation(open_page, base_url, scheme, before, after, label_after):
    page = open_page("/", scheme=scheme)
    toggle = page.locator(".js-theme-toggle")
    assert page_background(page) == before

    toggle.click()
    assert page_background(page) == after
    expect(toggle).to_have_attribute("aria-label", label_after)

    page.goto(base_url + "/cv/")
    page.wait_for_load_state("networkidle")
    assert page_background(page) == after

    page.locator(".js-theme-toggle").click()
    assert page_background(page) == before


# --- Header and navigation -----------------------------------------------------------------------


@pytest.mark.parametrize("width", [DESKTOP, WIDE])
def test_every_navigation_entry_is_visible_on_desktop(open_page, width):
    page = open_page("/", width)
    assert page.locator(".hidden-links li").count() == 0
    assert page.locator(".visible-links li").count() == 7
    expect(page.locator(".greedy-nav__toggle")).to_be_hidden()


@pytest.mark.parametrize("width", [DESKTOP, WIDE])
def test_navigation_and_content_share_their_left_edge(open_page, width):
    page = open_page("/", width)
    first_link = page.locator(".visible-links li:first-child a").bounding_box()
    content = page.locator(".page__content").bounding_box()
    assert abs(first_link["x"] - content["x"]) <= 2


@pytest.mark.parametrize("scheme", ["light", "dark"])
def test_open_phone_menu_covers_the_follow_button_and_keeps_the_header_solid(open_page, scheme):
    page = open_page("/", PHONE, scheme)
    header_colour = page.evaluate("getComputedStyle(document.querySelector('.masthead')).backgroundColor")
    follow = page.locator(".author__urls-wrapper button").bounding_box()
    centre = [follow["x"] + follow["width"] / 2, follow["y"] + follow["height"] / 2]

    page.locator(".greedy-nav__toggle").click()
    expect(page.locator(".hidden-links")).to_be_visible()

    # Whatever is on top there (the menu or the veil that dims the page) belongs to the header.
    covered = page.evaluate("([x, y]) => !!document.elementFromPoint(x, y).closest('.masthead')", centre)
    assert covered, "the Follow button shows through the open menu"
    strip = page.evaluate("getComputedStyle(document.querySelector('.masthead'), '::after').backgroundColor")
    assert strip == header_colour


def test_phone_menu_closes_on_a_click_outside_and_its_entries_navigate(open_page, base_url):
    page = open_page("/", PHONE)
    toggle = page.locator(".greedy-nav__toggle")

    toggle.click()
    page.mouse.click(100, 600)
    expect(page.locator(".hidden-links")).to_be_hidden()

    toggle.click()
    page.locator(".hidden-links a", has_text="Projects").click()
    page.wait_for_url(base_url + "/projects/")


# --- Author sidebar ------------------------------------------------------------------------------


def test_email_link_is_visible_on_desktop_and_reveals_the_address_on_click(open_page):
    page = open_page("/")
    link = page.locator(".author__urls .js-contact")
    expect(link).to_be_visible()
    assert "@" not in page.locator(".author__urls").text_content()

    link.click()
    expect(link.locator(".label")).to_contain_text("@")


def test_follow_button_opens_the_profile_links_on_a_phone(open_page):
    page = open_page("/", PHONE)
    expect(page.locator(".author__urls")).to_be_hidden()
    page.locator(".author__urls-wrapper button").click()
    expect(page.locator(".author__urls")).to_be_visible()


# --- Printing ------------------------------------------------------------------------------------


@pytest.mark.parametrize("scheme", ["light", "dark"])
def test_printed_cv_shows_only_the_content_in_black_on_white(open_page, scheme):
    page = open_page("/cv/", scheme=scheme)
    page.emulate_media(media="print")
    page.wait_for_timeout(500)  # let any colour transition of the screen styles finish

    for selector in (".masthead", ".sidebar", ".page__footer", ".js-theme-toggle", ".page__content .btn"):
        expect(page.locator(selector).first).to_be_hidden()
    expect(page.locator("h1.page__title")).to_be_visible()
    expect(page.locator(".page__content table").first).to_be_visible()

    assert page_background(page) == LIGHT_BACKGROUND
    for selector in ("h1.page__title a", ".page__content p"):
        channels = page.evaluate(
            "(s) => getComputedStyle(document.querySelector(s)).color.match(/\d+/g).map(Number)", selector
        )
        assert max(channels[:3]) < 40, f"{selector} is not printed in (near) black: {channels}"
    title_suffix = page.evaluate("getComputedStyle(document.querySelector('h1.page__title a'), '::after').content")
    assert title_suffix in ("none", "normal"), "the page title must not print its own address"

    viewport = page.viewport_size["width"]
    content = page.locator(".page__content").bounding_box()
    assert content["x"] < 40 and content["width"] > viewport - 80, "printed content must use the full width"


def test_icon_font_passes_its_integrity_check_and_draws_the_icons(open_page):
    # A wrong Subresource Integrity hash makes the browser drop the stylesheet: icons would vanish.
    page = open_page("/", DESKTOP)
    page.wait_for_function(
        "[...document.styleSheets].some(sheet => (sheet.href || '').includes('fontawesome-free'))"
    )
    content = page.evaluate(
        "getComputedStyle(document.querySelector('.author__urls .fa-envelope'), '::before').content"
    )
    assert content not in ("none", "normal", "")
