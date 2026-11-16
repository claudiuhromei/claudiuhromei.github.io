# frozen_string_literal: true

require "json"
require_relative "test_helper"

# Search engine and social preview metadata.
class SeoTest < Minitest::Test
  include SiteHelpers

  SITE_URL = "https://claudiuhromei.github.io"
  PNG_SIGNATURE = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A].pack("C*")

  def setup
    @home = page("index.html")
  end

  def test_every_page_has_an_absolute_open_graph_image_that_is_published
    html_files.each do |file|
      image = Nokogiri::HTML(File.read(file, encoding: "utf-8")).at_css('meta[property="og:image"]')
      refute_nil image, "missing og:image in #{file}"
      assert image["content"].start_with?("#{SITE_URL}/"), "og:image must be an absolute URL"
      assert File.exist?(site_path(image["content"].delete_prefix("#{SITE_URL}/"))), "og:image file not published"
    end
  end

  def test_open_graph_image_is_a_png_with_the_recommended_size
    header = File.binread(site_path("assets/images/og-image.png"), 24)
    assert_equal PNG_SIGNATURE, header[0, 8]
    assert_equal [1200, 630], header[16, 8].unpack("NN")
  end

  def test_open_graph_image_has_alternative_text
    alt = @home.at_css('meta[property="og:image:alt"]')
    refute_nil alt
    assert_includes alt["content"], "Claudiu Daniel Hromei"
  end

  def test_home_has_canonical_url
    assert_equal "#{SITE_URL}/", @home.at_css('link[rel="canonical"]')["href"]
  end

  def test_structured_data_describes_the_person_and_profiles
    data = JSON.parse(@home.at_css('script[type="application/ld+json"]').text)
    assert_equal "Person", data["@type"]
    assert_equal "Claudiu Daniel Hromei", data["name"]
    assert_includes data["sameAs"], "https://orcid.org/0009-0000-8204-5023"
    assert_includes data["sameAs"], "https://www.linkedin.com/in/cdhromei/"
  end

  def test_robots_txt_points_to_the_sitemap
    assert_includes File.read(site_path("robots.txt")), "Sitemap: #{SITE_URL}/sitemap.xml"
  end

  def test_not_found_page_is_published_but_not_in_the_sitemap
    assert_equal "Page not found", page("404.html").at_css("h1.page__title").text.strip
    refute_includes File.read(site_path("sitemap.xml")), "404"
  end
end
