require "test_helper"

class LedgerTest < Minitest::Test
  def test_recording_a_transaction_id_twice_updates_the_existing_line
    ledger = Ledger.new

    ledger.record(transaction_id: "txn_1020", amount: "1.00")
    ledger.record(transaction_id: "txn_1020", amount: "62.40")

    assert_equal [["txn_1020", BigDecimal("62.40")]], ledger.lines.map { |line| [line.transaction_id, line.amount] }
  end

  def test_matches_the_expected_output_for_the_first_15_transactions_of_the_feed
    ledger = Ledger.new
    File.open(File.join(FIXTURE_FILES, "transactions.csv")) { |file| ledger.import(TransactionFeedService.new(file).transactions) }

    expected_lines = File.read(File.join(FIXTURE_FILES, "expected_first_15.csv")).lines(chomp: true)
    assert_equal expected_lines, ledger.to_csv.lines(chomp: true).first(16)
  end

  def test_importing_the_same_feed_twice_leaves_the_ledger_unchanged
    ledger = Ledger.new
    File.open(File.join(FIXTURE_FILES, "transactions.csv")) { |file| ledger.import(TransactionFeedService.new(file).transactions) }
    first_import = ledger.to_csv

    File.open(File.join(FIXTURE_FILES, "transactions.csv")) { |file| ledger.import(TransactionFeedService.new(file).transactions) }

    assert_equal 56, ledger.lines.size
    assert_equal first_import, ledger.to_csv
  end

  def test_feed_row_order_does_not_change_the_ledger_lines
    header, *rows = File.read(File.join(FIXTURE_FILES, "transactions.csv")).lines
    in_order = Ledger.new
    in_order.import(TransactionFeedService.new(StringIO.new([header, *rows].join)).transactions)
    reversed = Ledger.new
    reversed.import(TransactionFeedService.new(StringIO.new([header, *rows.reverse].join)).transactions)

    assert_equal in_order.to_csv.lines.sort, reversed.to_csv.lines.sort
  end
end
