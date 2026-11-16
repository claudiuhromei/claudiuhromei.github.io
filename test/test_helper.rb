# frozen_string_literal: true

require "minitest/autorun"
require "nokogiri"

# Shared helpers for tests that inspect the generated site in `_site/`.
# Build the site first (`bundle exec rake build`); `rake test` does it for you.
module SiteHelpers
  SITE_DIR = File.expand_path("../_site", __dir__)

  def self.ensure_built!
    return if File.exist?(File.join(SITE_DIR, "index.html"))

    abort "Site not built: run `bundle exec rake build` (or `bundle exec rake test`) first."
  end

  def site_path(relative)
    File.join(SITE_DIR, relative)
  end

  def html_files
    Dir.glob(File.join(SITE_DIR, "**", "*.html"))
  end

  def page(relative)
    path = site_path(relative)
    assert File.exist?(path), "expected #{relative} to be generated"
    Nokogiri::HTML(File.read(path, encoding: "utf-8"))
  end
end

SiteHelpers.ensure_built!
