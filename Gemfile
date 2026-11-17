source "https://rubygems.org"

gem "jekyll", "~> 4.4"
# Theme pinned to an exact release; bump deliberately (see CLAUDE.md).
gem "minimal-mistakes-jekyll", "4.28.1"

group :jekyll_plugins do
  gem "jekyll-feed", "~> 0.17"
  gem "jekyll-include-cache", "~> 0.2"
  gem "jekyll-scholar", "~> 7.1"
  gem "jekyll-sitemap", "~> 1.4"
end

group :test do
  gem "html-proofer", "~> 5.0"
  gem "minitest", "~> 6.1"
  gem "nokogiri", "~> 1.16"
  gem "pdf-reader", "~> 2.12"
end

gem "rake", "~> 13.0"
gem "webrick", "~> 1.8" # `jekyll serve` on Ruby >= 3.0

# Windows and JRuby do not include zoneinfo files.
platforms :windows, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
end
gem "wdm", "~> 0.2", platforms: [:windows]
