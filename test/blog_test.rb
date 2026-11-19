# frozen_string_literal: true

require_relative "test_helper"

# The technical blog: posts in _blog/, listed at /blog/, linked from the navigation.
class BlogTest < Minitest::Test
  include SiteHelpers

  FIRST_POST = "blog/2026/11/why-good-agents-ask-questions/index.html"

  def test_blog_index_lists_the_posts
    doc = page("blog/index.html")
    assert_equal "Blog", doc.at_css("h1.page__title").text.strip
    hrefs = doc.css(".page__content a").map { |a| a["href"] }
    assert_includes hrefs, "/#{File.dirname(FIRST_POST)}/"
  end

  def test_raw_posts_are_not_published
    refute File.exist?(site_path("_blog")), "the raw posts must not be published"
  end

  def test_first_post_is_published_with_table_of_contents_and_figures
    doc = page(FIRST_POST)
    assert_match(/why good agents ask questions/, doc.at_css("h1.page__title").text)
    refute_nil doc.at_css(".sidebar__right .toc"), "the post must have its table of contents"
    images = doc.css(".page__content img").map { |img| img["src"] }
    assert_operator images.size, :>=, 5
    content = doc.at_css(".page__content").text
    refute_match(/\{%|\{\{/, content, "unrendered Liquid in the post")
  end

  def test_drafts_are_not_published
    Dir[File.expand_path("../_blog/*.md", __dir__)].each do |path|
      next unless File.read(path, encoding: "utf-8").match?(/^published: false$/)

      slug = File.basename(path, ".md").sub(/\A\d{4}-\d{2}-\d{2}-/, "")
      assert_empty Dir[site_path("blog/*/*/#{slug}")], "draft #{slug} must not be published"
    end
  end

  def test_posts_have_title_date_and_excerpt
    Dir[File.expand_path("../_blog/*.md", __dir__)].each do |path|
      front_matter = File.read(path, encoding: "utf-8")[/\A---\n(.*?)\n---\n/m, 1]
      refute_nil front_matter, "#{File.basename(path)} has no front matter"
      %w[title date excerpt].each do |key|
        assert_match(/^#{key}: \S/, front_matter, "#{File.basename(path)} has no #{key}")
      end
    end
  end

  # Drafts are not built, so check figures on disk: every project-figure include must point to an
  # existing image (dir defaults to "projects").
  def test_post_figures_exist
    Dir[File.expand_path("../_blog/*.md", __dir__)].each do |path|
      File.read(path, encoding: "utf-8").scan(/\{%\s*include project-figure\.html(.*?)%\}/m).each do |(args)|
        dir = args[/\bdir="([^"]+)"/, 1] || "projects"
        image = args[/\bimage="([^"]+)"/, 1]
        refute_nil image, "#{File.basename(path)}: figure without image"
        file = File.expand_path("../assets/images/#{dir}/#{image}", __dir__)
        assert File.exist?(file), "#{File.basename(path)}: missing figure #{dir}/#{image}"
      end
    end
  end

  def test_post_template_is_never_published
    template = File.read(File.expand_path("../_blog/2026-11-17-post-template.md", __dir__), encoding: "utf-8")
    assert_match(/^published: false$/, template)
  end
end
