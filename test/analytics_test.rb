# frozen_string_literal: true

require "tmpdir"
require_relative "test_helper"

# GoatCounter analytics: off while no site code is configured, on (production only) once it is set.
class AnalyticsTest < Minitest::Test
  include SiteHelpers

  ROOT = File.expand_path("..", __dir__)
  FIXTURE = "test/fixtures/goatcounter.yml"
  SELECTOR = "script[data-goatcounter]"

  def test_no_analytics_script_without_a_site_code
    html_files.each do |file|
      assert_nil Nokogiri::HTML(File.read(file, encoding: "utf-8")).at_css(SELECTOR), "unexpected analytics in #{file}"
    end
  end

  def test_analytics_script_is_added_in_production_when_a_site_code_is_set
    script = build_with_site_code("production").at_css(SELECTOR)
    refute_nil script, "analytics script missing"
    assert_equal "https://example-site.goatcounter.com/count", script["data-goatcounter"]
    assert_equal "https://gc.zgo.at/count.js", script["src"]
  end

  def test_analytics_script_is_left_out_of_development_builds
    assert_nil build_with_site_code("development").at_css(SELECTOR)
  end

  private

  # Builds the site with the GoatCounter fixture into a temporary folder and returns its home page.
  def build_with_site_code(environment)
    Dir.mktmpdir("site-analytics") do |destination|
      command = %(bundle exec jekyll build --quiet --config _config.yml,#{FIXTURE} --destination "#{destination}")
      built = system({ "JEKYLL_ENV" => environment }, command, chdir: ROOT, out: File::NULL, err: File::NULL)
      assert built, "jekyll build with #{FIXTURE} failed"
      Nokogiri::HTML(File.read(File.join(destination, "index.html"), encoding: "utf-8"))
    end
  end
end
