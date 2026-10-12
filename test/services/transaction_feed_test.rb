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

  def test_keeps_the_highest_sync_batch_when_it_arrives_before_a_lower_one
    feed = TransactionFeed.new(StringIO.new(HEADER + <<~CSV))
      txn_1020,2,2026-08-10,card,SHELL OIL 57318,SHELL OIL 57318,62.40
      txn_1020,1,2026-08-10,card,SHELL OIL 57318,PENDING - SHELL OIL,1.00
    CSV

    assert_equal [["txn_1020", "62.40"]], feed.latest_rows.map { |row| [row["id"], row["amount"]] }
  end

  def test_compares_sync_batch_numerically
    feed = TransactionFeed.new(StringIO.new(HEADER + <<~CSV))
      txn_1020,10,2026-08-10,card,SHELL OIL 57318,SHELL OIL 57318,62.40
      txn_1020,2,2026-08-10,card,SHELL OIL 57318,PENDING - SHELL OIL,1.00
    CSV

    assert_equal [["txn_1020", "62.40"]], feed.latest_rows.map { |row| [row["id"], row["amount"]] }
  end

  def test_keeps_one_row_per_id_across_the_full_feed
    rows = File.open(File.join(FIXTURE_FILES, "transactions.csv")) { |file| TransactionFeed.new(file).latest_rows }

    assert_equal 56, rows.size
    assert_equal rows.map { |row| row["id"] }.uniq, rows.map { |row| row["id"] }
    assert_equal %w[2 2 2 2], rows.select { |row| %w[txn_1020 txn_1035 txn_1041 txn_1046].include?(row["id"]) }.map { |row| row["sync_batch"] }
  end
end
