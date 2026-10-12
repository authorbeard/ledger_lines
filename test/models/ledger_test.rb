require "test_helper"

class LedgerTest < Minitest::Test
  def test_a_later_sync_batch_updates_the_existing_line
    ledger = Ledger.new

    ledger.record(transaction_id: "txn_1020", sync_batch: 1, amount: "1.00")
    ledger.record(transaction_id: "txn_1020", sync_batch: 2, amount: "62.40")

    assert_equal [["txn_1020", BigDecimal("62.40")]], ledger.lines.map { |line| [line.transaction_id, line.amount] }
  end

  def test_an_earlier_sync_batch_does_not_replace_a_later_one
    ledger = Ledger.new

    ledger.record(transaction_id: "txn_1020", sync_batch: 2, amount: "62.40")
    ledger.record(transaction_id: "txn_1020", sync_batch: 1, amount: "1.00")

    assert_equal [["txn_1020", BigDecimal("62.40")]], ledger.lines.map { |line| [line.transaction_id, line.amount] }
  end
end
