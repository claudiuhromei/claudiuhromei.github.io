# frozen_string_literal: true

require "tmpdir"
require_relative "test_helper"

# GoatCounter analytics: one cookieless script on every page of production builds,
# and nothing in development builds or when the site code is emptied.
class AnalyticsTest < Minitest::Test
  include SiteHelpers

  ROOT = File.expand_path("..", __dir__)
  DISABLED = "test/fixtures/goatcounter_off.yml"
  SELECTOR = "script[data-goatcounter]"
  ENDPOINT = "https://claudiuhromei.goatcounter.com/count"

  def test_every_page_of_the_production_site_loads_the_counter_once
    html_files.each do |file|
      scripts = Nokogiri::HTML(File.read(file, encoding: "utf-8")).css(SELECTOR)
      assert_equal 1, scripts.size, "expected one analytics script in #{file}"
      assert_equal ENDPOINT, scripts.first["data-goatcounter"]
      assert_equal "https://gc.zgo.at/count.js", scripts.first["src"]
      refute_nil scripts.first["async"], "analytics must not block rendering"
    end
  end

  def test_analytics_script_is_left_out_of_development_builds
    assert_nil build_home("development").at_css(SELECTOR)
  end

  def test_no_analytics_script_when_the_site_code_is_empty
    assert_nil build_home("production", DISABLED).at_css(SELECTOR)
  end

  private

  # Builds the site into a temporary folder (optionally with an extra config file) and returns its home page.
  def build_home(environment, extra_config = nil)
    config = ["_config.yml", extra_config].compact.join(",")
    Dir.mktmpdir("site-analytics") do |destination|
      command = %(bundle exec jekyll build --quiet --config #{config} --destination "#{destination}")
      built = system({ "JEKYLL_ENV" => environment }, command, chdir: ROOT, out: File::NULL, err: File::NULL)
      assert built, "jekyll build (#{environment}, #{config}) failed"
      Nokogiri::HTML(File.read(File.join(destination, "index.html"), encoding: "utf-8"))
    end
  end
end
