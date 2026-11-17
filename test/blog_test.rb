# frozen_string_literal: true

require_relative "test_helper"

# The technical blog is built from _blog/ but stays hidden until the first post is ready.
# When launching it, flip these tests (see the owner's local notes).
class BlogTest < Minitest::Test
  include SiteHelpers

  def test_blog_is_not_published_yet
    refute Dir.exist?(site_path("blog")), "the blog must stay hidden"
    refute File.exist?(site_path("_blog")), "the raw posts must not be published"
  end

  def test_navigation_does_not_link_to_the_blog
    links = page("index.html").css("nav.greedy-nav a").map { |a| a["href"] }
    refute_includes links, "/blog/"
  end

  def test_post_template_is_never_published
    template = File.read(File.expand_path("../_blog/2026-11-17-post-template.md", __dir__), encoding: "utf-8")
    assert_match(/^published: false$/, template)
  end
end
