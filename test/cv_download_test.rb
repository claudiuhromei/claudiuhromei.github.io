# frozen_string_literal: true

require "pdf-reader"
require_relative "test_helper"

# Downloadable CV: published, linked from the CV page and free of phone number and email address.
# The file is produced by tools/make_public_cv.py from the private CV.
class CvDownloadTest < Minitest::Test
  include SiteHelpers

  CV_PDF = "assets/files/Claudiu_Daniel_Hromei_CV.pdf"
  EMAIL = /[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}/
  PHONE = /\+\d{1,3}[\s.-]?\d{2,4}[\s.-]?\d{6,8}\b/
  PRIVATE_LINK = /\A(mailto|tel):/i

  def setup
    assert File.exist?(site_path(CV_PDF)), "#{CV_PDF} not published"
    @reader = PDF::Reader.new(site_path(CV_PDF))
  end

  def test_cv_page_links_to_the_pdf
    hrefs = page("cv/index.html").css(".page__content a").map { |a| a["href"] }
    assert_includes hrefs, "/#{CV_PDF}"
  end

  def test_pdf_is_the_curriculum
    text = @reader.pages.map(&:text).join("\n")
    assert_includes text, "Rome, Italy"
    assert_operator @reader.page_count, :>=, 2
  end

  def test_pdf_text_has_no_phone_number_or_email_address
    @reader.pages.each do |pdf_page|
      refute_match PHONE, pdf_page.text, "phone number on page #{pdf_page.number}"
      refute_match EMAIL, pdf_page.text, "email address on page #{pdf_page.number}"
    end
  end

  def test_pdf_links_do_not_expose_contact_details
    refute_empty link_targets, "expected the CV to keep its profile and project links"
    link_targets.each do |uri|
      refute_match PRIVATE_LINK, uri
      refute_match EMAIL, uri
    end
  end

  def test_pdf_metadata_has_no_contact_details
    @reader.info.each_value do |value|
      refute_match EMAIL, value.to_s
      refute_match PHONE, value.to_s
    end
  end

  private

  # URI targets of all link annotations in the document.
  def link_targets
    @link_targets ||= @reader.pages.flat_map do |pdf_page|
      annotations = @reader.objects.deref(pdf_page.attributes[:Annots]) || []
      annotations.filter_map do |reference|
        action = @reader.objects.deref(@reader.objects.deref(reference)[:A])
        action && @reader.objects.deref(action[:URI])
      end
    end
  end
end
