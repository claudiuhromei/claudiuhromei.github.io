# frozen_string_literal: true

require_relative "test_helper"

# Vertical timeline on the Experience page: both sections are timelines, every role and degree is an
# entry of one of them, most recent first, and the stylesheets draw the line and the dots.
class TimelineTest < Minitest::Test
  include SiteHelpers

  SECTIONS = {
    "Professional experience" => ["Senior AI Scientist (Finance)", "Postdoc Volunteer Researcher", "R&D Researcher (NLU & HRI)"],
    "Education" => ["Ph.D. in Artificial Intelligence", "M.Sc. in Computer Science (Artificial Intelligence)"]
  }.freeze

  def test_each_section_is_a_timeline_of_its_entries_most_recent_first
    content = page("experience/index.html").at_css(".page__content")
    timelines = content.css("div.timeline")
    assert_equal SECTIONS.size, timelines.size
    SECTIONS.each_with_index do |(heading, entries), index|
      timeline = timelines[index]
      assert_equal heading, timeline.xpath("preceding-sibling::h2[1]").text.strip
      titles = timeline.css("> h3").map { |h3| h3.text.strip }
      assert_equal entries.size, titles.size
      entries.zip(titles).each { |entry, title| assert title.start_with?(entry), "#{title} out of place" }
    end
    assert_empty content.css("> h3"), "every entry must be inside a timeline"
  end

  def test_entries_keep_their_text_rendered_as_markdown
    timeline = page("experience/index.html").at_css(".page__content div.timeline")
    assert_operator timeline.css("> p").size, :>=, 2
    refute_includes timeline.inner_html, "###", "Markdown inside the timeline was not converted"
  end

  def test_stylesheets_draw_the_line_and_a_dot_per_entry
    %w[assets/css/main.css assets/css/main-dark.css].each do |css|
      source = File.read(site_path(css), encoding: "utf-8")
      assert_match(/\.timeline\{[^}]*border-left:2px solid/, source)
      assert_match(/\.timeline>h3::before\{[^}]*border-radius:50%/, source)
      assert_match(/\.timeline>p,\.timeline>ul\{max-width:37em\}/, source)
    end
  end
end
