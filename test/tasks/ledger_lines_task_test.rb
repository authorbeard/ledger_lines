require "test_helper"
require "rake"

class LedgerLinesTaskTest < Minitest::Test
  def setup
    Rake.application = Rake::Application.new
    load File.expand_path("../../lib/tasks/ledger_lines.rake", __dir__)
  end

  def test_writes_one_ledger_line_per_transaction_to_stdout
    output, _errors = capture_io { Rake::Task["ledger_lines"].invoke(File.join(FIXTURE_FILES, "transactions.csv")) }

    assert_equal "transaction_id,date,type,category,amount,needs_review", output.lines.first.chomp
    assert_equal 56, output.lines.size - 1
  end

  def test_running_twice_on_the_same_feed_produces_identical_output
    feed_path = File.join(FIXTURE_FILES, "transactions.csv")
    first_run, _errors = capture_io { Rake::Task["ledger_lines"].invoke(feed_path) }
    Rake::Task["ledger_lines"].reenable
    second_run, _errors = capture_io { Rake::Task["ledger_lines"].invoke(feed_path) }

    assert_equal first_run, second_run
  end

  def test_exits_with_usage_when_no_path_is_given
    _output, errors = capture_io { assert_raises(SystemExit) { Rake::Task["ledger_lines"].invoke } }

    assert_match "Usage", errors
  end
end
