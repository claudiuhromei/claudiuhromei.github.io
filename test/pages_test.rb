# frozen_string_literal: true

require_relative "test_helper"

# Content pages: each one is generated, titled, linked from the navigation and carries its key content.
class PagesTest < Minitest::Test
  include SiteHelpers

  # permalink => [navigation title, phrases the page must contain]
  PAGES = {
    "/experience/" => ["Experience", ["BIP", "University of Rome Tor Vergata", "REVEAL SRL", "Ph.D. in Artificial Intelligence"]],
    "/projects/" => ["Projects", %w[MM-IGLU ExtremITA U-DepPLLaMA GrUT HeAL9000]],
    "/publications/" => ["Publications", ["EMNLP 2025", "ACL 2025", "LREC-COLING 2024", "EVALITA 2023", "NL4AI 2022"]],
    "/teaching/" => ["Teaching & Talks", ["Corporate AI training", "CLiC-it 2023", "Thesis supervision"]],
    "/service/" => ["Service & Awards", ["Best Paper Award, EVALITA 2023", "Best Paper Award, NL4AI 2022", "NL4AI 2024"]],
    "/cv/" => ["CV", ["Technical skills", "Certifications", "Azure AI Apps & Agents Developer"]],
    "/news/" => ["News", ["Paper at EMNLP 2025", "Best Paper Award at EVALITA 2023"]]
  }.freeze

  PAGES.each do |permalink, (title, phrases)|
    slug = permalink.delete("/")

    define_method("test_#{slug}_page_has_title_and_key_content") do
      doc = page("#{slug}/index.html")
      assert_equal title, doc.at_css("h1.page__title").text.strip
      content = doc.at_css(".page__content").text
      phrases.each { |phrase| assert_includes content, phrase }
    end

    define_method("test_#{slug}_page_has_its_own_meta_description") do
      description = page("#{slug}/index.html").at_css('meta[name="description"]')["content"]
      refute_equal home_description, description
    end

    define_method("test_navigation_links_to_#{slug}") do
      assert_includes navigation_links, [title, permalink]
    end
  end

  def test_navigation_has_no_links_to_missing_pages
    navigation_links.each do |title, href|
      assert File.exist?(site_path(File.join(href, "index.html"))), "navigation entry #{title} points to missing #{href}"
    end
  end

  def test_project_pages_link_to_their_repositories
    hrefs = page("projects/index.html").css(".page__content a").map { |a| a["href"] }
    %w[GroundedSRL4HRI MM-IGLU-Dialogues ExtremITA u-deppllama grut].each do |repo|
      assert_includes hrefs, "https://github.com/crux82/#{repo}"
    end
  end

  def test_author_sidebar_links_to_confirmed_profiles
    hrefs = page("index.html").css(".author__urls a").map { |a| a["href"] }
    assert_includes hrefs, "https://www.linkedin.com/in/cdhromei/"
    assert_includes hrefs, "https://scholar.google.it/citations?user=YQRKKFoAAAAJ"
    assert_includes hrefs, "https://huggingface.co/cdh"
    assert_includes hrefs, "https://orcid.org/0009-0000-8204-5023"
    assert_includes hrefs, "https://www.semanticscholar.org/author/2148228904"
    assert_includes hrefs, "https://aclanthology.org/people/claudiu-daniel-hromei/"
  end

  private

  def home
    @home ||= page("index.html")
  end

  def home_description
    home.at_css('meta[name="description"]')["content"]
  end

  def navigation_links
    home.css("nav.greedy-nav a").map { |a| [a.text.strip, a["href"]] }
  end
end
