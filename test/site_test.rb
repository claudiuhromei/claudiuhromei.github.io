# frozen_string_literal: true

require_relative "test_helper"

# Structure of the generated site: home page, navigation, author sidebar and metadata.
class SiteTest < Minitest::Test
  include SiteHelpers

  def setup
    @home = page("index.html")
  end

  def test_home_title_contains_full_name
    assert_includes @home.at_css("title").text, "Claudiu Daniel Hromei"
  end

  def test_home_has_meta_description
    description = @home.at_css('meta[name="description"]')
    refute_nil description, "missing <meta name=\"description\">"
    refute_empty description["content"].strip
  end

  def test_navigation_links_to_about
    nav_links = @home.css("nav.greedy-nav a").map { |a| [a.text.strip, a["href"]] }
    assert_includes nav_links, ["About", "/"]
  end

  def test_author_sidebar_shows_name_and_location
    sidebar = @home.at_css(".author__content")
    refute_nil sidebar, "author sidebar not rendered"
    assert_includes sidebar.text, "Claudiu Daniel Hromei"

    assert_includes @home.at_css(".author__urls").text, "Rome, Italy"
  end

  def test_author_sidebar_shows_the_profile_photo
    avatar = @home.at_css(".author__avatar img")
    refute_nil avatar, "profile photo not rendered"
    assert_equal "Claudiu Daniel Hromei", avatar["alt"]
    assert File.exist?(site_path(avatar["src"].delete_prefix("/"))), "profile photo not published"
  end

  def test_svg_favicon_is_linked_and_published
    icon = @home.at_css('link[rel="icon"][type="image/svg+xml"]')
    refute_nil icon, "missing SVG favicon <link>"
    assert File.exist?(site_path(icon["href"].delete_prefix("/"))), "favicon file not published"
  end

  def test_feed_and_sitemap_are_generated
    assert File.exist?(site_path("feed.xml")), "feed.xml missing"
    assert File.exist?(site_path("sitemap.xml")), "sitemap.xml missing"
  end

  def test_repo_only_files_are_not_published
    %w[CLAUDE.md roadmap.md README.md Gemfile Rakefile].each do |file|
      refute File.exist?(site_path(file)), "#{file} must not be published"
    end
    refute Dir.exist?(site_path("test")), "test/ must not be published"
    refute Dir.exist?(site_path("tools")), "tools/ must not be published"
    refute Dir.exist?(site_path("browser_tests")), "browser_tests/ must not be published"
  end
end
