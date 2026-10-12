require "test_helper"

class LedgerLinesServiceEdgeCasesTest < Minitest::Test
  include FeedFixtureHelpers

  def setup
    @fixture_feed = File.read(FIXTURE_FEED)
  end

  def test_compares_sync_batches_as_base_10_integers
    feed = @fixture_feed.sub("txn_1020,1,", "txn_1020,9,").sub("txn_1020,2,", "txn_1020,010,")

    assert_equal "62.40", ledger_lines_by_id(ledger_lines_for(feed))["txn_1020"][3]
  end

  # Pending question 3: same id twice in one sync_batch.
  def test_keeps_the_first_row_when_an_id_repeats_within_one_sync_batch
    posted_row = "txn_1020,2,2026-08-10,card,SHELL OIL 57318,SHELL OIL 57318,62.40"
    feed = @fixture_feed.sub(posted_row, "#{posted_row}\r\n#{posted_row.sub('62.40', '63.00')}")

    assert_equal "62.40", ledger_lines_by_id(ledger_lines_for(feed))["txn_1020"][3]
  end

  def test_ids_that_differ_only_by_surrounding_whitespace_are_the_same_transaction
    lines = ledger_lines_by_id(ledger_lines_for(@fixture_feed.sub("txn_1020,2,", "txn_1020 ,2,")))

    assert_equal 56, lines.size
    assert_equal "62.40", lines["txn_1020"][3]
  end

  # Pending question 10: whether a malformed row should stop the import.
  def test_rejects_a_row_without_an_id
    error = assert_raises(ArgumentError) { ledger_lines_for(@fixture_feed.sub("txn_1003,", ",")) }

    assert_equal "Missing id on line 4", error.message
  end

  # Pending question 11: whether to assume or enforce US date patterns.
  def test_rejects_a_date_that_is_not_iso_8601
    assert_raises(Date::Error) { ledger_lines_for(@fixture_feed.sub("txn_1001,1,2026-08-03", "txn_1001,1,08/03/2026")) }
  end

  # Pending questions 7 and 15: rows from accounts outside the feed.
  def test_a_row_from_an_unrecognized_account_is_uncategorized_and_flagged
    lines = ledger_lines_by_id(ledger_lines_for(@fixture_feed.sub("txn_1018,1,2026-08-08,card", "txn_1018,1,2026-08-08,amex")))

    assert_equal ["purchase", "Uncategorized", "-184.20", "true"], lines["txn_1018"].drop(1)
  end

  def test_account_names_are_matched_regardless_of_case
    feed = @fixture_feed
      .sub("txn_1018,1,2026-08-08,card", "txn_1018,1,2026-08-08,Card")
      .sub("txn_1017,1,2026-08-08,card", "txn_1017,1,2026-08-08,CARD")
    lines = ledger_lines_by_id(ledger_lines_for(feed))

    assert_equal "refund", lines["txn_1018"][1]
    assert_equal %w[transfer transfer], lines.values_at("txn_1016", "txn_1017").map { |line| line[1] }
  end

  # Pending questions 1 and 14: opposite legs on the same account.
  def test_card_payment_legs_on_the_same_account_are_not_transfers
    lines = ledger_lines_by_id(ledger_lines_for(@fixture_feed.sub("txn_1016,1,2026-08-08,bank", "txn_1016,1,2026-08-08,card")))

    assert_equal %w[purchase refund], lines.values_at("txn_1016", "txn_1017").map { |line| line[1] }
  end

  def test_each_transfer_leg_pairs_with_at_most_one_opposite_leg
    feed = @fixture_feed.sub("txn_1052,2,2026-08-27,card,PAYMENT RECEIVED,ONLINE PAYMENT - THANK YOU,-6200.00",
                             "txn_1052,2,2026-08-08,card,PAYMENT RECEIVED,ONLINE PAYMENT - THANK YOU,-4850.00")
    header, *rows = feed.lines

    [feed, [header, *rows.reverse].join].each do |ordered_feed|
      lines = ledger_lines_by_id(ledger_lines_for(ordered_feed))
      assert_equal %w[transfer transfer refund], lines.values_at("txn_1016", "txn_1017", "txn_1052").map { |line| line[1] }
    end
  end
end
