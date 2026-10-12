require "test_helper"

class TransactionFeedTest < Minitest::Test
  HEADER = "id,sync_batch,date,account,merchant,memo,amount\n"

  def test_keeps_the_version_from_the_highest_sync_batch_when_an_id_repeats
    feed = TransactionFeed.new(StringIO.new(HEADER + <<~CSV))
      txn_1020,1,2026-08-10,card,SHELL OIL 57318,PENDING - SHELL OIL,1.00
      txn_1020,2,2026-08-10,card,SHELL OIL 57318,SHELL OIL 57318,62.40
    CSV

    assert_equal [["txn_1020", "62.40"]], feed.latest_rows.map { |row| [row["id"], row["amount"]] }
  end
end
