# frozen_string_literal: true

require_relative "test_helper"

# Guards against publishing contact details in plain text (scrapers harvest them).
# The email must only ever appear obfuscated, and the phone number never.
class PrivacyTest < Minitest::Test
  include SiteHelpers

  EMAIL = /[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}/
  # International phone number, e.g. "+39 123 4567890" or "+391234567890".
  PHONE = /\+\d{1,3}[\s.-]?\d{2,4}[\s.-]?\d{6,8}\b/

  def test_html_files_exist
    refute_empty html_files
  end

  def test_no_plain_text_email_addresses
    offenders = scan_html_for(EMAIL)
    assert_empty offenders, "plain-text email found: #{offenders.inspect}"
  end

  def test_no_mailto_links
    offenders = html_files.select { |file| File.read(file, encoding: "utf-8").include?("mailto:") }
    assert_empty offenders, "mailto: link found in: #{offenders.inspect}"
  end

  def test_no_phone_numbers
    offenders = scan_html_for(PHONE)
    assert_empty offenders, "phone number found: #{offenders.inspect}"
  end

  private

  # Returns "file: match" pairs for every match of +pattern+ in the visible text of the site.
  def scan_html_for(pattern)
    html_files.flat_map do |file|
      text = Nokogiri::HTML(File.read(file, encoding: "utf-8")).text
      text.scan(pattern).map { |match| "#{relative(file)}: #{match}" }
    end
  end

  def relative(file)
    file.delete_prefix("#{SITE_DIR}/")
  end
end
