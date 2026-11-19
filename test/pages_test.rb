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
    "/blog/" => ["Blog", "Blog", ["why good agents ask questions"]],
    "/publications/" => ["Publications", "Publications", ["EMNLP 2025", "ACL 2025", "LREC-COLING 2024", "EVALITA 2023", "NL4AI 2022"]],
    "/teaching/" => ["Teaching & Talks", "Teaching", ["Corporate AI training", "CLiC-it 2023", "Conference presentations", "EMNLP 2025", "Thesis supervision"]],
    "/service/" => ["Awards & Service", "Awards", ["Best Paper Award, EVALITA 2023", "Best Paper Award, NL4AI 2022", "NL4AI 2024"]],
    "/cv/" => ["CV", "CV", ["Technical skills", "Certifications", "Azure AI Apps & Agents Developer"]],
    "/news/" => ["News", nil, ["New blog post: why good agents ask questions", "Paper at EMNLP 2025", "Best Paper Award at EVALITA 2023"]]
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
    assert_operator labels.size, :<=, 8
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

  # Project heading => where each of its figures comes from, in page order
  # (GrUT has no openly licensed figure).
  PROJECT_FIGURES = {
    "Situated G-SRL & synthetic data generation" => %w[https://aclanthology.org/2025.emnlp-main.1212/] * 2,
    "MM-IGLU" => %w[https://aclanthology.org/2025.findings-acl.837/],
    "ExtremITA" => %w[https://github.com/crux82/ExtremITA],
    "U-DepPLLaMA" => %w[https://aclanthology.org/2023.clicit-1.30/],
    "GrUT" => %w[/assets/files/slides/phd-defense-slides.pdf],
    "HeAL9000" => %w[https://ceur-ws.org/Vol-3060/paper-4.pdf]
  }.freeze

  def test_project_figures_are_described_sized_and_credited
    figures = page("projects/index.html").css(".page__content figure.project-figure")
    headings = figures.map { |figure| figure.xpath("preceding-sibling::h2[1]").text.strip }
    assert_equal PROJECT_FIGURES.transform_values(&:size), headings.tally
    figures.zip(headings).each do |figure, heading|
      image = figure.at_css("img")
      path = site_path(image["src"].delete_prefix("/"))

      assert File.exist?(path), "#{image['src']} not published"
      assert_operator image["alt"].length, :>=, 30, "#{heading}: the alt text must describe the figure"
      assert_equal "lazy", image["loading"]
      assert_equal image_size(path), [image["width"].to_i, image["height"].to_i], "#{heading}: wrong width/height"
      assert_includes PROJECT_FIGURES.fetch(heading), figure.at_css("figcaption a")["href"]
    end
  end

  def test_situated_project_explains_the_ambiguous_command_before_its_picture
    section = page("projects/index.html").css(".page__content > *")
                                         .drop_while { |node| node.text.strip != "Situated G-SRL & synthetic data generation" }
    explanation = section.index { |node| node.name == "p" && node.text.include?("take the phone on the bed") }
    picture = section.index { |node| node.at_css("img[src$='situated-g-srl-scene.jpg']") }
    refute_nil explanation
    refute_nil picture
    assert_operator explanation, :<, picture
  end

  def test_image_size_reads_png_and_jpeg_headers
    assert_equal [148, 149], image_size(site_path("assets/images/projects/extremita.png"))
    assert_equal [883, 624], image_size(site_path("assets/images/projects/situated-g-srl-scene.jpg"))
  end

  def test_conference_presentations_link_to_their_videos
    links = page("teaching/index.html").css(".page__content a").select { |a| a.text == "Video" }
    assert_equal %w[130964 121996 46881], links.map { |a| a["href"][%r{\Ahttps://underline\.io/(?:events/\d+/sessions/\d+/)?lecture/(\d+)-}, 1] }
  end

  def test_conference_presentations_link_to_their_slides_or_poster
    links = page("teaching/index.html").css(".page__content a").select { |a| %w[Slides Poster].include?(a.text) }
    assert_equal %w[Slides Poster Slides], links.map(&:text)
    links.each { |a| assert File.exist?(site_path(a["href"].delete_prefix("/"))), "#{a['href']} not published" }
  end

  def test_phd_defence_slides_are_linked_from_the_education_timeline
    link = page("experience/index.html").css(".timeline a").find { |a| a["href"].end_with?("phd-defense-slides.pdf") }
    refute_nil link, "defence slides not linked"
    assert File.exist?(site_path(link["href"].delete_prefix("/")))
    assert_includes link.parent.text, "supplementary slides"
  end

  def test_now_section_covers_industry_research_and_theses_and_invites_contact
    section = home.css(".page__content > *").drop_while { |node| node.text.strip != "Now" }
                  .take_while { |node| node.text.strip != "Selected publications" }
    text = section.map(&:text).join(" ")
    ["In industry.", "In research.", "Theses I supervise.", "Open to"].each { |part| assert_includes text, part }
    contact = section.flat_map { |node| node.css("a.js-contact").to_a }.first
    refute_nil contact, "the Now section must offer the obfuscated email link"
    refute_includes contact.to_html, "@"
  end

  # Every mention of the collaboration with Tor Vergata names the research group and links to it.
  def test_tor_vergata_collaboration_links_the_sag_art_group
    %w[index.html experience/index.html cv/index.html service/index.html teaching/index.html].each do |file|
      links = page(file).css(".page__content a").select { |a| a.text == "SAG ART group" }
      refute_empty links, "#{file}: no link to the SAG ART group"
      links.each { |a| assert_equal "http://sag.art.uniroma2.it/people", a["href"] }
    end
  end

  # The figure is drawn with transparent margins: on the dark theme they must stay white to be readable.
  def test_grut_figure_has_an_opaque_white_background
    png = File.binread(site_path("assets/images/projects/grut.png"))
    colour_type = png.byteslice(25).ord
    refute_includes [4, 6], colour_type, "grut.png must not have an alpha channel"
  end

  def test_reviewing_lists_venues_and_journals
    text = page("service/index.html").at_css(".page__content").text
    ["Senior Program Committee", "ACL Rolling Review", "EACL", "CLiC-it", "AIxIA", "CIKM 2026", "I-RIM 2021",
     "NL4AI", "IJCoL", "Intelligenza Artificiale"].each { |venue| assert_includes text, venue }
  end

  def test_profiles_with_a_brand_icon_use_it
    icons = page("index.html").css(".author__urls a").to_h { |a| [a["href"], a.at_css("i")&.[]("class").to_s] }
    assert_includes icons["https://huggingface.co/cdh"], "fa-hugging-face"
    assert_includes icons["https://www.linkedin.com/in/cdhromei/"], "fa-linkedin"
    assert_includes icons["https://orcid.org/0009-0000-8204-5023"], "fa-orcid"
  end

  def test_author_sidebar_links_to_confirmed_profiles
    hrefs = page("index.html").css(".author__urls a").map { |a| a["href"] }
    assert_includes hrefs, "https://www.linkedin.com/in/cdhromei/"
    assert_includes hrefs, "https://scholar.google.it/citations?user=YQRKKFoAAAAJ"
    assert_includes hrefs, "https://huggingface.co/cdh"
    assert_includes hrefs, "https://openreview.net/profile?id=%7EClaudiu_Daniel_Hromei1"
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

  # [width, height] of a PNG or JPEG file, read from its header (JPEG: the first start-of-frame segment).
  def image_size(path)
    data = File.binread(path)
    return data.unpack("@16NN") if data.start_with?("\x89PNG".b)

    offset = 2
    while offset < data.bytesize
      marker, length = data.unpack("@#{offset + 1}Cn")
      return data.unpack("@#{offset + 5}nn").reverse if (0xC0..0xCF).cover?(marker) && ![0xC4, 0xC8, 0xCC].include?(marker)

      offset += 2 + length
    end
    flunk "no image size found in #{path}"
  end

  def navigation_links
    home.css("nav.greedy-nav a").map { |a| [a.text.strip, a["href"]] }
  end
end
