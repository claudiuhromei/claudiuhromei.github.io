# frozen_string_literal: true

require "yaml"
require_relative "test_helper"

# Home page: introduction, highlight cards, selected publications and latest news, in this order.
class HomeTest < Minitest::Test
  include SiteHelpers

  HIGHLIGHTS = YAML.load_file(File.expand_path("../_data/highlights.yml", __dir__))
  BIB_PATH = File.expand_path("../assets/bibliography/publications.bib", __dir__)

  def setup
    @content = page("index.html").at_css(".page__content")
  end

  def test_sections_come_in_the_expected_order
    assert_equal ["Highlights", "Now", "Selected publications", "News"], @content.css("h2").map { |h2| h2.text.strip }
  end

  def test_every_highlight_is_rendered_as_a_card
    cards = @content.css(".highlights__item")
    assert_equal HIGHLIGHTS.size, cards.size
    HIGHLIGHTS.zip(cards).each do |highlight, card|
      assert_equal highlight["figure"], card.at_css(".highlights__figure").text
      assert_equal highlight["title"], card.at_css(".highlights__title").text
      assert_equal highlight["text"], card.at_css(".highlights__text").text
    end
  end

  def test_highlight_cards_link_to_existing_pages
    @content.css(".highlights__link").each do |link|
      assert File.exist?(site_path(File.join(link["href"], "index.html"))), "highlight links to missing #{link['href']}"
    end
  end

  def test_highlights_are_complete
    HIGHLIGHTS.each do |highlight|
      %w[figure title text url].each { |field| refute_empty highlight[field].to_s, "highlight without #{field}" }
    end
  end

  def test_selected_publications_are_the_ones_flagged_in_the_bibliography
    selected_keys = File.read(BIB_PATH, encoding: "utf-8").scan(/^@\w+\{([^,]+),\n\s*selected\s*=\s*\{true\}/).flatten
    rendered_keys = @content.css(".publication").map do |entry|
      entry.at_css("details.publication__cite code").text[/\A\s*@\w+\{([^,]+),/, 1]
    end
    refute_empty selected_keys
    assert_equal selected_keys.sort, rendered_keys.sort
  end

  def test_selected_publications_are_not_split_by_year_and_link_to_the_full_list
    assert_empty @content.css("h2.bibliography")
    hrefs = @content.css("a").map { |a| a["href"] }
    assert_includes hrefs, "/publications/"
  end

  def test_selected_flag_is_not_part_of_the_citation
    @content.css("details.publication__cite code").each do |bibtex|
      refute_match(/^\s*selected\s*=/, bibtex.text)
    end
  end
end
