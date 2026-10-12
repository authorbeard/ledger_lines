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
    File.open(File.join(FIXTURE_FILES, "transactions.csv")) { |file| ledger.import(TransactionFeed.new(file).transactions) }

    expected_lines = File.read(File.join(FIXTURE_FILES, "expected_first_15.csv")).lines(chomp: true)
    assert_equal expected_lines, ledger.to_csv.lines(chomp: true).first(16)
  end
end
