require "test_helper"
require "rake"

class LedgerLinesTaskTest < Minitest::Test
  def setup
    Rake.application = Rake::Application.new
    load File.expand_path("../../lib/tasks/ledger_lines.rake", __dir__)
  end

  def test_writes_the_ledger_lines_for_the_given_feed_to_stdout
    output, _errors = capture_io { Rake::Task["ledger_lines"].invoke(FIXTURE_FEED) }

    assert_equal LedgerLinesService.call(FIXTURE_FEED), output
  end

  def test_exits_with_usage_when_no_path_is_given
    _output, errors = capture_io { assert_raises(SystemExit) { Rake::Task["ledger_lines"].invoke } }

    assert_match "Usage", errors
  end
end
