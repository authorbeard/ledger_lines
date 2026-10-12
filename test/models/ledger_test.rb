require "test_helper"

class LedgerTest < Minitest::Test
  def test_recording_a_transaction_id_twice_updates_the_existing_line
    ledger = Ledger.new

    ledger.record(transaction_id: "txn_1020", amount: "1.00")
    ledger.record(transaction_id: "txn_1020", amount: "62.40")

    assert_equal [["txn_1020", BigDecimal("62.40")]], ledger.lines.map { |line| [line.transaction_id, line.amount] }
  end
end
