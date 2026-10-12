require "test_helper"

class LedgerLineTest < Minitest::Test
  def test_accepts_each_ledger_transaction_type
    %w[purchase refund deposit transfer].each do |transaction_type|
      assert LedgerLine.new(transaction_id: "txn_1001", transaction_type:).valid?, "expected #{transaction_type} to be valid"
    end
  end

  def test_rejects_an_unknown_transaction_type
    line = LedgerLine.new(transaction_id: "txn_1001", transaction_type: "fee")

    refute line.valid?
    assert_includes line.errors[:transaction_type], "is not included in the list"
  end
end
