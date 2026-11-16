# frozen_string_literal: true

require_relative "test_helper"

# Automatic light/dark colour scheme: the dark skin is a second stylesheet gated by a media query.
class ThemeTest < Minitest::Test
  include SiteHelpers

  DARK_CSS = "assets/css/main-dark.css"
  LIGHT_CSS = "assets/css/main.css"

  def test_dark_stylesheet_is_loaded_only_for_dark_colour_schemes_on_every_page
    html_files.each do |file|
      doc = Nokogiri::HTML(File.read(file, encoding: "utf-8"))
      link = doc.at_css(%(link[rel="stylesheet"][href="/#{DARK_CSS}"]))
      refute_nil link, "dark stylesheet not linked in #{file}"
      assert_equal "(prefers-color-scheme: dark)", link["media"]
    end
  end

  def test_dark_stylesheet_comes_after_the_light_one
    hrefs = page("index.html").css('link[rel="stylesheet"]').map { |link| link["href"] }
    assert_operator hrefs.index("/#{LIGHT_CSS}"), :<, hrefs.index("/#{DARK_CSS}")
  end

  def test_light_stylesheet_has_no_media_restriction
    link = page("index.html").at_css(%(link[rel="stylesheet"][href="/#{LIGHT_CSS}"]))
    assert_nil link["media"]
  end

  def test_light_and_dark_stylesheets_use_different_page_backgrounds
    light = page_background(LIGHT_CSS)
    dark = page_background(DARK_CSS)
    refute_nil light
    refute_nil dark
    refute_equal light, dark
  end

  def test_both_stylesheets_include_the_site_styles
    [LIGHT_CSS, DARK_CSS].each do |css|
      assert_includes File.read(site_path(css), encoding: "utf-8"), ".publication__award"
    end
  end

  def test_page_declares_support_for_both_colour_schemes
    meta = page("index.html").at_css('meta[name="color-scheme"]')
    refute_nil meta
    assert_equal "light dark", meta["content"]
  end

  private

  # Background colour of the first `html{...}` rule that sets one in a compiled stylesheet.
  def page_background(css)
    File.read(site_path(css), encoding: "utf-8")[/(?:^|\})html\{[^}]*?background-color:([^;}]+)/, 1]
  end
end
