require "test_helper"

class FeedTransactionTest < Minitest::Test
  HEADER = "id,sync_batch,date,account,merchant,memo,amount\n"

  def test_a_positive_card_charge_is_a_purchase
    feed = TransactionFeed.new(StringIO.new(HEADER + <<~CSV))
      txn_1001,1,2026-08-03,card,SYSCO PHILA 8827,SYSCO PHILA 8827,1842.17
    CSV

    assert_equal ["purchase"], feed.transactions.map(&:ledger_type)
  end

  def test_a_negative_card_amount_is_a_refund
    feed = TransactionFeed.new(StringIO.new(HEADER + <<~CSV))
      txn_1018,1,2026-08-08,card,SYSCO PHILA 8827,SYSCO CREDIT SHORTED DELIVERY,-184.20
    CSV

    assert_equal ["refund"], feed.transactions.map(&:ledger_type)
  end

  def test_a_negative_bank_amount_is_a_deposit
    feed = TransactionFeed.new(StringIO.new(HEADER + <<~CSV))
      txn_1002,1,2026-08-03,bank,DOORDASH PAYOUT,DOORDASH INC PAYOUT,-2210.45
    CSV

    assert_equal ["deposit"], feed.transactions.map(&:ledger_type)
  end

  def test_a_positive_bank_amount_is_a_purchase
    feed = TransactionFeed.new(StringIO.new(HEADER + <<~CSV))
      txn_1007,1,2026-08-05,bank,METRO GAS & ELECTRIC,AUTOPAY METRO GAS & ELECTRIC,1288.40
    CSV

    assert_equal ["purchase"], feed.transactions.map(&:ledger_type)
  end
end
