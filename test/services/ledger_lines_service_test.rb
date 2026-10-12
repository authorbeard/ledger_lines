require "test_helper"

class LedgerLinesServiceTest < Minitest::Test
  include FeedFixtureHelpers

  def setup
    @fixture_feed = File.read(FIXTURE_FEED)
    @lines = ledger_lines_by_id(LedgerLinesService.call(FIXTURE_FEED))
  end

  def test_matches_the_expected_output_for_the_first_15_transactions
    expected_lines = File.read(File.join(FIXTURE_FILES, "expected_first_15.csv")).lines(chomp: true)

    assert_equal expected_lines, LedgerLinesService.call(FIXTURE_FEED).lines(chomp: true).first(16)
  end

  def test_records_one_line_per_transaction_id
    assert_equal 56, @lines.size
  end

  def test_keeps_the_posted_version_of_each_re_synced_pending_transaction
    assert_equal ["2026-08-10", "purchase", "Uncategorized", "62.40", "true"], @lines["txn_1020"]
    assert_equal ["2026-08-17", "purchase", "Food & beverage", "890.00", "false"], @lines["txn_1035"]
    assert_equal ["2026-08-20", "purchase", "Food & beverage", "1755.00", "false"], @lines["txn_1041"]
    assert_equal ["2026-08-24", "purchase", "Food & beverage", "518.35", "false"], @lines["txn_1046"]
  end

  def test_both_legs_of_each_card_payment_are_transfers
    %w[txn_1016 txn_1017 txn_1051 txn_1052].each do |transaction_id|
      assert_equal ["transfer", "Transfer", "false"], @lines[transaction_id].values_at(1, 2, 4), transaction_id
    end
  end

  # Pending questions 1 and 12: savings legs never appear in the feed.
  def test_moves_to_and_from_savings_are_transfers
    assert_equal ["transfer", "Transfer", "false"], @lines["txn_1027"].values_at(1, 2, 4)
    assert_equal ["transfer", "Transfer", "false"], @lines["txn_1040"].values_at(1, 2, 4)
  end

  # Pending questions 1 and 2: a payment memo with no opposite leg.
  def test_rent_paid_by_ach_payment_is_a_purchase
    assert_equal ["purchase", "Rent", "6500.00", "false"], @lines["txn_1022"].drop(1)
  end

  def test_negative_card_amounts_that_are_not_transfers_are_refunds_in_the_purchase_category
    assert_equal ["refund", "Food & beverage", "-184.20", "false"], @lines["txn_1018"].drop(1)
    assert_equal ["refund", "Repairs & maintenance", "-59.99", "false"], @lines["txn_1024"].drop(1)
    assert_equal ["refund", "Smallwares & supplies", "-212.40", "false"], @lines["txn_1036"].drop(1)
  end

  def test_a_refund_from_an_unlisted_merchant_is_uncategorized_and_flagged
    assert_equal ["refund", "Uncategorized", "-41.99", "true"], @lines["txn_1037"].drop(1)
  end

  def test_negative_bank_amounts_that_are_not_transfers_are_deposits
    %w[txn_1002 txn_1004 txn_1019 txn_1026 txn_1034 txn_1050].each do |transaction_id|
      assert_equal "deposit", @lines[transaction_id][1], transaction_id
    end
  end

  def test_card_payment_credits_are_not_refunds
    refute_equal "refund", @lines["txn_1017"][1]
    refute_equal "refund", @lines["txn_1052"][1]
  end

  def test_money_moved_in_from_savings_is_not_a_deposit
    refute_equal "deposit", @lines["txn_1040"][1]
  end

  def test_positive_amounts_are_never_refunds_or_deposits
    positive_lines = @lines.values.reject { |line| line[3].start_with?("-") }

    assert_empty positive_lines.map { |line| line[1] } & %w[refund deposit]
  end

  def test_unlisted_merchants_are_uncategorized_and_flagged_for_review
    %w[txn_1006 txn_1020 txn_1028].each do |transaction_id|
      assert_equal ["Uncategorized", "true"], @lines[transaction_id].values_at(2, 4), transaction_id
    end
  end

  def test_running_twice_produces_identical_output
    assert_equal LedgerLinesService.call(FIXTURE_FEED), LedgerLinesService.call(FIXTURE_FEED)
  end

  def test_row_order_in_the_feed_does_not_change_the_output
    header, *rows = @fixture_feed.lines

    assert_equal LedgerLinesService.call(FIXTURE_FEED), ledger_lines_for([header, *rows.reverse].join)
  end

  def test_reads_a_feed_with_a_byte_order_mark_and_blank_lines
    assert_equal LedgerLinesService.call(FIXTURE_FEED), ledger_lines_for("\uFEFF" + @fixture_feed.gsub(/\r?\n/) { |line_end| line_end * 2 })
  end
end
