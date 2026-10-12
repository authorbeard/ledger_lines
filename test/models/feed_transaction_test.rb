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

  def test_both_legs_of_a_card_payment_are_transfers
    feed = TransactionFeed.new(StringIO.new(HEADER + <<~CSV))
      txn_1016,1,2026-08-08,bank,ONLINE PAYMENT TO CARD 4421,ONLINE PAYMENT TO CARD 4421,4850.00
      txn_1017,1,2026-08-08,card,PAYMENT RECEIVED,ONLINE PAYMENT - THANK YOU,-4850.00
    CSV

    assert_equal %w[transfer transfer], feed.transactions.map(&:ledger_type)
  end

  def test_a_payment_memo_without_an_opposite_leg_is_a_purchase
    feed = TransactionFeed.new(StringIO.new(HEADER + <<~CSV))
      txn_1022,1,2026-08-11,bank,MAINLINE PROPERTIES LLC,ACH PAYMENT MAINLINE PROPERTIES,6500.00
    CSV

    assert_equal ["purchase"], feed.transactions.map(&:ledger_type)
  end

  def test_an_opposite_leg_on_the_same_account_is_not_a_transfer
    feed = TransactionFeed.new(StringIO.new(HEADER + <<~CSV))
      txn_2001,1,2026-08-08,card,PAYMENT RECEIVED,ONLINE PAYMENT - THANK YOU,-4850.00
      txn_2002,1,2026-08-08,card,PAYMENT REVERSAL,PAYMENT REVERSAL,4850.00
    CSV

    assert_equal %w[refund purchase], feed.transactions.map(&:ledger_type)
  end

  def test_an_opposite_amount_without_a_transfer_memo_is_not_a_transfer_leg
    feed = TransactionFeed.new(StringIO.new(HEADER + <<~CSV))
      txn_2003,1,2026-08-08,bank,ONLINE PAYMENT TO CARD 4421,ONLINE PAYMENT TO CARD 4421,300.00
      txn_2004,1,2026-08-08,card,INDEED,INDEED SPONSORED JOB CREDIT,-300.00
    CSV

    assert_equal %w[purchase refund], feed.transactions.map(&:ledger_type)
  end

  def test_transfer_memos_are_matched_regardless_of_case
    feed = TransactionFeed.new(StringIO.new(HEADER + <<~CSV))
      txn_2005,1,2026-08-08,bank,Online Payment To Card 4421,Online Payment To Card 4421,4850.00
      txn_2006,1,2026-08-08,card,Payment Received,online payment - thank you,-4850.00
    CSV

    assert_equal %w[transfer transfer], feed.transactions.map(&:ledger_type)
  end

  def test_moves_to_and_from_savings_are_transfers_without_a_savings_leg_in_the_feed
    feed = TransactionFeed.new(StringIO.new(HEADER + <<~CSV))
      txn_1027,1,2026-08-13,bank,TRANSFER TO SAVINGS 8810,ONLINE TRANSFER TO SAVINGS 8810,10000.00
      txn_1040,1,2026-08-19,bank,TRANSFER FROM SAVINGS 8810,ONLINE TRANSFER FROM SAVINGS 8810,-5000.00
    CSV

    assert_equal %w[transfer transfer], feed.transactions.map(&:ledger_type)
  end

  def test_a_listed_merchant_is_categorized_and_not_flagged_for_review
    feed = TransactionFeed.new(StringIO.new(HEADER + <<~CSV))
      txn_1003,1,2026-08-03,card,HOME DEPOT #4102,HOME DEPOT #4102,146.88
    CSV

    assert_equal [["Repairs & maintenance", false]], feed.transactions.map { |transaction| [transaction.category, transaction.needs_review?] }
  end

  def test_an_unlisted_merchant_is_uncategorized_and_flagged_for_review
    feed = TransactionFeed.new(StringIO.new(HEADER + <<~CSV))
      txn_1006,1,2026-08-04,card,AMZN MKTP US*2K4X9,AMAZON MARKETPLACE,84.12
    CSV

    assert_equal [["Uncategorized", true]], feed.transactions.map { |transaction| [transaction.category, transaction.needs_review?] }
  end

  def test_transfers_are_categorized_as_transfer_and_not_flagged_for_review
    feed = TransactionFeed.new(StringIO.new(HEADER + <<~CSV))
      txn_1016,1,2026-08-08,bank,ONLINE PAYMENT TO CARD 4421,ONLINE PAYMENT TO CARD 4421,4850.00
      txn_1017,1,2026-08-08,card,PAYMENT RECEIVED,ONLINE PAYMENT - THANK YOU,-4850.00
    CSV

    assert_equal [["Transfer", false], ["Transfer", false]], feed.transactions.map { |transaction| [transaction.category, transaction.needs_review?] }
  end

  def test_a_refund_takes_the_category_its_purchase_would_get
    feed = TransactionFeed.new(StringIO.new(HEADER + <<~CSV))
      txn_1024,1,2026-08-11,card,HOME DEPOT #4102,HOME DEPOT RETURN,-59.99
    CSV

    assert_equal [["refund", "Repairs & maintenance", false]], feed.transactions.map { |transaction| [transaction.ledger_type, transaction.category, transaction.needs_review?] }
  end
end
