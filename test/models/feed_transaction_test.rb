require "test_helper"

class FeedTransactionTest < Minitest::Test
  HEADER = "id,sync_batch,date,account,merchant,memo,amount\n"

  def test_a_positive_card_charge_is_a_purchase
    feed = TransactionFeed.new(StringIO.new(HEADER + <<~CSV))
      txn_1001,1,2026-08-03,card,SYSCO PHILA 8827,SYSCO PHILA 8827,1842.17
    CSV

    assert_equal ["purchase"], feed.transactions.map(&:ledger_type)
  end
end
