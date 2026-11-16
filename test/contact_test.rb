# frozen_string_literal: true

require "open3"
require_relative "test_helper"

# Email contact: reachable from the sidebar, but never written in the HTML or in the script.
class ContactTest < Minitest::Test
  include SiteHelpers

  SCRIPT = "assets/js/contact.js"
  SCRIPT_SOURCE = File.expand_path("../#{SCRIPT}", __dir__)
  EMAIL = /\A[a-z0-9._-]+@[a-z0-9-]+(\.[a-z0-9-]+)+\z/

  def setup
    @button = page("index.html").at_css(".author__urls button.js-contact")
  end

  def test_sidebar_has_an_email_button_on_every_page_with_a_sidebar
    refute_nil @button
    assert_equal "Email", @button.text.strip

    html_files.each do |file|
      doc = Nokogiri::HTML(File.read(file, encoding: "utf-8"))
      next unless doc.at_css(".author__urls")

      refute_nil doc.at_css(".author__urls button.js-contact"), "email button missing in #{file}"
    end
  end

  def test_button_carries_the_two_reversed_halves_of_a_valid_address
    refute_includes @button["data-user"], "@"
    refute_includes @button["data-domain"], "@"
    assert_match EMAIL, assembled_address
  end

  def test_no_page_contains_the_assembled_address
    html_files.each do |file|
      refute_includes File.read(file, encoding: "utf-8"), assembled_address, "plain address found in #{file}"
    end
  end

  def test_script_is_published_and_loaded
    assert File.exist?(site_path(SCRIPT)), "#{SCRIPT} not published"
    refute_nil page("index.html").at_css(%(script[src="/#{SCRIPT}"]))
  end

  def test_script_has_no_literal_address_or_mailto
    source = File.read(SCRIPT_SOURCE, encoding: "utf-8")
    refute_includes source, "mailto:"
    refute_match(/[a-z0-9._-]+@[a-z0-9-]+\.[a-z]{2,}/i, source)
  end

  def test_script_decodes_the_address
    skip "node is not installed" unless node_available?

    code = "const { decodeAddress } = require(process.argv[1]); " \
           "process.stdout.write(decodeAddress(process.argv[2], process.argv[3]));"
    output, status = Open3.capture2("node", "-e", code, SCRIPT_SOURCE, "eno.emos", "gro.elpmaxe")
    assert status.success?, "node exited with #{status.exitstatus}"
    assert_equal "some.one@example.org", output
  end

  private

  def assembled_address
    "#{@button['data-user'].reverse}@#{@button['data-domain'].reverse}"
  end

  def node_available?
    system("node", "--version", out: File::NULL, err: File::NULL)
  rescue SystemCallError
    false
  end
end
