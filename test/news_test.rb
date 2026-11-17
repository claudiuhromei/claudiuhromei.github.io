# frozen_string_literal: true

require_relative "test_helper"

# News: dated posts, the latest ones on the home page and the full archive on /news/.
class NewsTest < Minitest::Test
  include SiteHelpers

  POSTS_DIR = File.expand_path("../_posts", __dir__)
  HOME_LIMIT = 5

  def setup
    @home_items = news_items(page("index.html"))
    @archive = page("news/index.html")
    @archive_items = news_items(@archive)
  end

  def test_archive_lists_every_post
    assert_equal post_files.size, @archive_items.size
    refute_empty @archive_items
  end

  def test_home_shows_only_the_latest_posts
    assert_equal [HOME_LIMIT, post_files.size].min, @home_items.size
    assert_equal @archive_items.first(HOME_LIMIT), @home_items
  end

  # Career milestones carry their exact date in the file name (the date of the post).
  def test_milestones_are_dated_on_the_day_they_happened
    { "joined-bip" => "2025-05-05", "phd-completed" => "2025-06-03" }.each do |slug, date|
      assert_equal ["#{date}-#{slug}.md"], post_files.map { |f| File.basename(f) }.grep(/-#{slug}\.md\z/)
    end
  end

  def test_home_links_to_the_archive
    hrefs = page("index.html").css(".page__content a").map { |a| a["href"] }
    assert_includes hrefs, "/news/"
  end

  def test_archive_is_sorted_most_recent_first
    months = @archive_items.map { |item| item[:month] }
    assert_equal months.sort.reverse, months
  end

  def test_archive_is_grouped_by_year
    years = @archive.css(".page__content h2").map { |heading| heading.text.to_i }
    assert_equal years.sort.reverse, years
    assert_equal years.uniq, years
    assert_equal @archive_items.map { |item| item[:month][0, 4].to_i }.uniq, years
  end

  def test_every_news_item_links_to_a_generated_post_page
    @archive_items.each do |item|
      assert item[:href].start_with?("/news/"), "unexpected post URL #{item[:href]}"
      post = page(File.join(item[:href], "index.html"))
      assert_equal item[:title], post.at_css("h1.page__title").text.strip
    end
  end

  def test_post_pages_do_not_show_a_day_level_date
    @archive_items.each do |item|
      assert_nil page(File.join(item[:href], "index.html")).at_css(".page__meta-date")
    end
  end

  private

  def post_files
    Dir.glob(File.join(POSTS_DIR, "*.md"))
  end

  def news_items(doc)
    doc.css(".news-list li").map do |li|
      link = li.at_css("a")
      { month: li.at_css("time")["datetime"], title: link.text.strip, href: link["href"] }
    end
  end
end
