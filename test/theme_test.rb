# frozen_string_literal: true

require "json"
require "open3"
require_relative "test_helper"

# Light/dark colour scheme: the dark skin is a second stylesheet gated by a media query (the OS setting
# by default), which the theme toggle overrides with the visitor's stored choice.
class ThemeTest < Minitest::Test
  include SiteHelpers

  DARK_CSS = "assets/css/main-dark.css"
  LIGHT_CSS = "assets/css/main.css"
  THEME_JS = "assets/js/theme.js"
  THEME_JS_SOURCE = File.expand_path("../#{THEME_JS}", __dir__)

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

  def test_theme_script_runs_in_the_head_right_after_the_dark_stylesheet
    head = page("index.html").at_css("head")
    script = head.at_css(%(script[src="/#{THEME_JS}"]))
    refute_nil script, "theme script not loaded in <head>"
    assert_nil script["defer"], "theme script must run before first paint"
    assert_nil script["async"], "theme script must run before first paint"
    assert_equal "dark-stylesheet", script.previous_element["id"]
    assert_equal "/#{DARK_CSS}", script.previous_element["href"]
    assert File.exist?(site_path(THEME_JS)), "#{THEME_JS} not published"
  end

  def test_every_page_has_a_theme_toggle_that_stays_hidden_without_javascript
    html_files.each do |file|
      button = Nokogiri::HTML(File.read(file, encoding: "utf-8")).at_css("button.js-theme-toggle")
      refute_nil button, "theme toggle missing in #{file}"
      refute_nil button["hidden"], "theme toggle must be hidden until the script enables it"
      refute_empty button["aria-label"].to_s
    end
  end

  def test_header_reserves_room_for_the_theme_toggle
    [LIGHT_CSS, DARK_CSS].each do |css|
      source = File.read(site_path(css), encoding: "utf-8")
      assert_match(/\.masthead__inner-wrap\{[^}]*padding-inline-end:4\.25rem/, source)
      assert_match(/\.masthead \.theme-toggle\{[^}]*position:absolute/, source)
    end
  end

  def test_theme_script_moves_the_toggle_into_the_header
    source = File.read(THEME_JS_SOURCE, encoding: "utf-8")
    assert_match(/querySelector\("\.masthead__inner-wrap"\)/, source)
    assert_includes source, "header.appendChild(button)"
  end

  def test_stored_choice_decides_when_the_dark_stylesheet_applies
    assert_equal "all", theme_js("darkStylesheetMedia", "dark")
    assert_equal "not all", theme_js("darkStylesheetMedia", "light")
    assert_equal "(prefers-color-scheme: dark)", theme_js("darkStylesheetMedia", nil)
    assert_equal "(prefers-color-scheme: dark)", theme_js("darkStylesheetMedia", "bogus")
  end

  def test_effective_theme_prefers_the_stored_choice_over_the_system_setting
    assert_equal "light", theme_js("effectiveTheme", "light", true)
    assert_equal "dark", theme_js("effectiveTheme", "dark", false)
    assert_equal "dark", theme_js("effectiveTheme", nil, true)
    assert_equal "light", theme_js("effectiveTheme", nil, false)
    assert_equal "light", theme_js("effectiveTheme", "bogus", false)
  end

  def test_toggle_switches_to_the_opposite_theme_and_says_so
    assert_equal "light", theme_js("oppositeTheme", "dark")
    assert_equal "dark", theme_js("oppositeTheme", "light")
    assert_equal "Switch to light theme", theme_js("toggleLabel", "dark")
    assert_equal "Switch to dark theme", theme_js("toggleLabel", "light")
  end

  private

  # Calls a function exported by assets/js/theme.js through Node and returns its result.
  def theme_js(function, *arguments)
    skip "node is not installed" unless node_available?

    code = "const theme = require(process.argv[1]); "            "process.stdout.write(JSON.stringify(theme[process.argv[2]](...JSON.parse(process.argv[3]))));"
    output, status = Open3.capture2("node", "-e", code, THEME_JS_SOURCE, function, JSON.generate(arguments))
    assert status.success?, "node exited with #{status.exitstatus}"
    JSON.parse(output)
  end

  def node_available?
    system("node", "--version", out: File::NULL, err: File::NULL)
  rescue SystemCallError
    false
  end

  # Background colour of the first `html{...}` rule that sets one in a compiled stylesheet.
  def page_background(css)
    File.read(site_path(css), encoding: "utf-8")[/(?:^|\})html\{[^}]*?background-color:([^;}]+)/, 1]
  end
end
