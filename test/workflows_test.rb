# frozen_string_literal: true

require "yaml"
require_relative "test_helper"

# Continuous integration set-up: what runs on pull requests and what runs on a schedule.
class WorkflowsTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def test_weekly_link_check_runs_on_a_schedule_and_on_demand
    triggers = workflow("links.yml").fetch(true) # YAML reads the key `on` as true
    assert_match(/\A\d+ \d+ \* \* [0-6]\z/, triggers.fetch("schedule").first.fetch("cron"), "expected a weekly cron")
    assert triggers.key?("workflow_dispatch")
    refute triggers.key?("pull_request"), "external links must not block pull requests"
  end

  def test_weekly_link_check_checks_external_links_and_can_open_issues
    links = workflow("links.yml")
    assert_equal "write", links.fetch("permissions").fetch("issues")
    steps = links.fetch("jobs").fetch("check-links").fetch("steps")
    check = steps.find { |step| step["id"] == "check" }
    assert_equal "1", check.fetch("env").fetch("CHECK_EXTERNAL")
    assert_includes check.fetch("run"), "rake test:links"
    assert_includes check.fetch("run"), "pipefail", "a failing check must fail the step despite the pipe"
    report = steps.last
    assert_includes report.fetch("if"), "failure()"
    assert_includes report.fetch("run"), "gh issue"
  end

  def test_site_workflow_tests_every_pull_request_before_deploying
    site = workflow("site.yml")
    assert site.fetch(true).key?("pull_request")
    assert_equal "build-test", site.fetch("jobs").fetch("deploy").fetch("needs")
    run_steps = site.fetch("jobs").fetch("build-test").fetch("steps").filter_map { |step| step["run"] }
    assert_includes run_steps, "bundle exec rake test"
  end

  def test_link_checker_tolerates_sites_that_block_automated_clients
    rakefile = File.read(File.join(ROOT, "Rakefile"), encoding: "utf-8")
    assert_match(/BOT_BLOCKED_STATUS_CODES = \[403, 429, 999\]/, rakefile)
    assert_includes rakefile, "ignore_status_codes: BOT_BLOCKED_STATUS_CODES"
  end

  private

  def workflow(name)
    YAML.load_file(File.join(ROOT, ".github", "workflows", name))
  end
end
