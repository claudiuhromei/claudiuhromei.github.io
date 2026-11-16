# frozen_string_literal: true

require "rake/testtask"

SITE_DIR = "_site"

desc "Build the site for production into #{SITE_DIR}/"
task :build do
  sh({ "JEKYLL_ENV" => "production" }, "bundle exec jekyll build --strict_front_matter --trace")
end

desc "Serve the site locally with live reload at http://localhost:4000"
task :serve do
  sh "bundle exec jekyll serve --livereload"
end

namespace :test do
  desc "Run the tests of the Python helper scripts in tools/ (needs uv)"
  task :tools do
    sh "uv run --no-project --with pytest --with pymupdf pytest tools --quiet"
  end

  desc "Run the browser tests in browser_tests/ against the built site (needs uv and a Chromium browser)"
  task browser: :build do
    sh "uv run --no-project --with-requirements browser_tests/requirements.txt pytest browser_tests --quiet"
  end

  Rake::TestTask.new(:unit) do |t|
    t.libs << "test"
    t.test_files = FileList["test/**/*_test.rb"]
    t.warning = false
  end
  task unit: :build

  desc "Check generated HTML, images and internal links with html-proofer"
  task links: :build do
    require "html-proofer"
    HTMLProofer.check_directory(
      SITE_DIR,
      checks: %w[Links Images Scripts OpenGraph Favicon],
      disable_external: ENV["CHECK_EXTERNAL"] != "1",
      enforce_https: true,
      ignore_missing_alt: false
    ).run
  end
end

desc "Build the site and run all tests (set CHECK_EXTERNAL=1 to also check external links)"
task test: %w[test:unit test:links test:tools test:browser]

task default: :test
