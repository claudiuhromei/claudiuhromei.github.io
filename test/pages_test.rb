# frozen_string_literal: true

require_relative "test_helper"

# Content pages: each one is generated, titled, linked from the navigation and carries its key content.
class PagesTest < Minitest::Test
  include SiteHelpers

  # permalink => [page title, navigation label (nil when the page is not in the navigation),
  #               phrases the page must contain]
  PAGES = {
    "/experience/" => ["Experience", "Experience", ["BIP", "REVEAL SRL", "Ph.D. in Artificial Intelligence", "2018 – 2021 · University of Rome Tor Vergata"]],
    "/projects/" => ["Projects", "Projects", %w[MM-IGLU ExtremITA U-DepPLLaMA GrUT HeAL9000]],
    "/publications/" => ["Publications", "Publications", ["EMNLP 2025", "ACL 2025", "LREC-COLING 2024", "EVALITA 2023", "NL4AI 2022"]],
    "/teaching/" => ["Teaching & Talks", "Teaching", ["Corporate AI training", "CLiC-it 2023", "Thesis supervision"]],
    "/service/" => ["Awards & Service", "Awards", ["Best Paper Award, EVALITA 2023", "Best Paper Award, NL4AI 2022", "NL4AI 2024"]],
    "/cv/" => ["CV", "CV", ["Technical skills", "Certifications", "Azure AI Apps & Agents Developer"]],
    "/news/" => ["News", nil, ["Paper at EMNLP 2025", "Best Paper Award at EVALITA 2023"]]
  }.freeze

  PAGES.each do |permalink, (title, navigation_label, phrases)|
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

    define_method("test_navigation_for_#{slug}") do
      if navigation_label
        assert_includes navigation_links, [navigation_label, permalink]
      else
        refute_includes navigation_links.map(&:last), permalink
      end
    end
  end

  # Short labels keep every entry visible in the header instead of folding some into the menu.
  def test_navigation_is_short_enough_to_fit_the_header
    labels = home.css("nav.greedy-nav .visible-links a").map { |a| a.text.strip }
    assert_operator labels.size, :<=, 7
    assert_operator labels.sum(&:length), :<=, 55
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
    assert_includes hrefs, "https://dblp.org/pid/309/5387.html"
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
