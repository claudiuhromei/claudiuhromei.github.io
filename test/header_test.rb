# frozen_string_literal: true

require_relative "test_helper"

# Coloured header: green in the light theme, terracotta in the dark one, readable in both,
# and stacked above the author sidebar so the open navigation menu covers the "Follow" button.
class HeaderTest < Minitest::Test
  include SiteHelpers

  STYLESHEETS = {
    "assets/css/main.css" => "#006b3f",
    "assets/css/main-dark.css" => "#bf5445"
  }.freeze
  MINIMUM_CONTRAST = 4.5 # WCAG AA for normal text

  STYLESHEETS.each do |path, accent|
    name = File.basename(path, ".css").tr("-", "_")

    define_method("test_#{name}_header_uses_the_accent_colour") do
      assert_equal accent, declaration(path, ".masthead", "background-color")
      # Strip painted above the veil that dims the page while the navigation menu is open.
      assert_equal accent, declaration(path, ".masthead::after", "background-color")
    end

    define_method("test_#{name}_header_text_is_readable_on_the_accent_colour") do
      text = declaration(path, ".masthead .site-title,.masthead .visible-links a", "color")
      refute_nil text, "header text colour not found in #{path}"
      assert_operator contrast(text, accent), :>=, MINIMUM_CONTRAST
    end

    define_method("test_#{name}_header_is_stacked_above_the_author_sidebar") do
      masthead = declaration(path, ".masthead", "z-index").to_i
      sidebar = declaration(path, ".author__urls-wrapper", "z-index").to_i
      assert_operator masthead, :>, sidebar
    end

    # On wide screens the navigation starts where the page content starts and the content
    # runs up to the header's right edge (no empty right-hand column).
    define_method("test_#{name}_header_and_page_content_share_their_edges") do
      css = File.read(site_path(path), encoding: "utf-8")
      assert_equal "flex-start", declaration(path, ".masthead .visible-links", "justify-content")
      # Links have a 0.5rem margin on each side; the title is the sidebar minus 1rem minus that margin.
      assert_equal ".5rem", declaration(path, ".masthead .visible-links a", "margin-inline")
      assert_includes css, ".masthead .site-title{min-width:calc(240px - 1.5rem)}"
      assert_includes css, ".masthead .site-title{min-width:calc(300px - 1.5rem)}"
      assert_includes css, "width:calc(100% - 240px)", "sidebar column must fit the site title"
      assert_equal "0", declaration(path, ".page", "padding-inline-end")
    end

    # Running text is capped at a readable measure; headings, tables and card grids are not.
    define_method("test_#{name}_running_text_has_a_readable_line_length") do
      css = File.read(site_path(path), encoding: "utf-8")
      rule = css[/\.page__content>p,[^{]*\{max-width:([^;}]+)\}/, 1]
      assert_equal "37em", rule
      selectors = css[/(\.page__content>p,[^{]*)\{max-width:37em\}/, 1]
      assert_includes selectors, ".page__content>ul:not(.highlights)"
      assert_includes selectors, ".page__content .publication"
      refute_includes selectors, "table"
      refute_includes selectors, "h2"
    end

    define_method("test_#{name}_primary_buttons_are_readable") do
      text = declaration(path, ".btn--primary,.btn--primary:visited,.btn--primary:hover", "color")
      background = declaration(path, ".btn--primary", "background-color")
      assert_equal accent, background
      assert_operator contrast(text, background), :>=, MINIMUM_CONTRAST
    end
  end

  def test_contrast_helper_matches_known_values
    assert_in_delta 21.0, contrast("#000", "#ffffff"), 0.01
    assert_in_delta 1.0, contrast("#fff", "#fff"), 0.01
  end

  private

  # Last value of +property+ declared for exactly +selector+ in a compiled (compressed) stylesheet.
  def declaration(path, selector, property)
    css = File.read(site_path(path), encoding: "utf-8")
    rules = css.scan(/(?:^|\})#{Regexp.escape(selector)}\{([^}]*)\}/).flatten
    rules.filter_map { |body| body[/(?:^|;)#{Regexp.escape(property)}:([^;]+)/, 1] }.last
  end

  # WCAG contrast ratio between two hex colours.
  def contrast(first, second)
    lighter, darker = [luminance(first), luminance(second)].sort.reverse
    (lighter + 0.05) / (darker + 0.05)
  end

  def luminance(hex)
    digits = hex.delete_prefix("#")
    digits = digits.chars.map { |char| char * 2 }.join if digits.length == 3
    red, green, blue = digits.scan(/../).map do |pair|
      channel = pair.to_i(16) / 255.0
      channel <= 0.03928 ? channel / 12.92 : ((channel + 0.055) / 1.055)**2.4
    end
    (0.2126 * red) + (0.7152 * green) + (0.0722 * blue)
  end
end
