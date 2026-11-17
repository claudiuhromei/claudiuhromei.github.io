# frozen_string_literal: true

require "yaml"
require_relative "test_helper"

# Experience timeline: one row per entry of _data/timeline.yml, readable as text, with bars that stay
# inside the axis and ongoing roles reaching its right end (today).
class TimelineTest < Minitest::Test
  include SiteHelpers

  ENTRIES = YAML.load_file(File.expand_path("../_data/timeline.yml", __dir__))
  KINDS = %w[work research education].freeze

  def test_every_entry_has_a_row_with_its_title_place_and_period
    rows = timeline.css(".timeline__rows > li")
    assert_equal ENTRIES.size, rows.size
    ENTRIES.zip(rows).each do |entry, row|
      text = row.at_css(".timeline__label").text.gsub(/\s+/, " ")
      [entry["title"], entry["place"], entry["period"]].each { |part| assert_includes text, part }
      assert_includes row["class"], "timeline__row--#{entry['kind']}"
    end
  end

  def test_entries_are_valid_and_oldest_first
    ENTRIES.each do |entry|
      assert_includes KINDS, entry["kind"]
      assert_match(/\A\d{4}-(0[1-9]|1[0-2])\z/, entry["start"])
      assert_operator entry["end"], :>, entry["start"] if entry["end"]
    end
    assert_equal ENTRIES.map { |entry| entry["start"] }.sort, ENTRIES.map { |entry| entry["start"] }
  end

  def test_bars_stay_on_the_axis_and_ongoing_ones_reach_today
    timeline.css(".timeline__bar").zip(ENTRIES).each do |bar, entry|
      left, width = bar["style"].scan(/[\d.]+(?=%)/).map(&:to_f)
      assert_operator left, :>=, 0
      assert_operator width, :>, 0
      assert_operator left + width, :<=, 100.01
      if entry["end"]
        assert_operator left + width, :<, 100, "#{entry['title']} ended, its bar must stop before today"
      else
        assert_in_delta 100, left + width, 0.02, "#{entry['title']} is ongoing, its bar must reach today"
        assert_includes bar["class"], "timeline__bar--ongoing"
      end
    end
  end

  def test_axis_has_one_tick_per_year_up_to_the_current_one
    years = timeline.css(".timeline__tick").map { |tick| tick.text.to_i }
    first = ENTRIES.first["start"][0, 4].to_i
    assert_equal (first..Time.now.year).to_a, years
  end

  def test_bars_and_axis_are_hidden_from_screen_readers
    assert(timeline.css(".timeline__track").all? { |track| track.ancestors.any? { |node| node["aria-hidden"] == "true" } || track["aria-hidden"] == "true" })
  end

  private

  def timeline
    @timeline ||= page("experience/index.html").at_css(".page__content .timeline")
  end
end
