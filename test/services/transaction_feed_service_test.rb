require "test_helper"

class TransactionFeedServiceTest < Minitest::Test
  HEADER = "id,sync_batch,date,account,merchant,memo,amount\n"

  def test_keeps_the_version_from_the_highest_sync_batch_when_an_id_repeats
    feed = TransactionFeedService.new(StringIO.new(HEADER + <<~CSV))
      txn_1020,1,2026-08-10,card,SHELL OIL 57318,PENDING - SHELL OIL,1.00
      txn_1020,2,2026-08-10,card,SHELL OIL 57318,SHELL OIL 57318,62.40
    CSV

    assert_equal [["txn_1020", "62.40"]], feed.latest_rows.map { |row| [row["id"], row["amount"]] }
  end

  def test_keeps_the_highest_sync_batch_when_it_arrives_before_a_lower_one
    feed = TransactionFeedService.new(StringIO.new(HEADER + <<~CSV))
      txn_1020,2,2026-08-10,card,SHELL OIL 57318,SHELL OIL 57318,62.40
      txn_1020,1,2026-08-10,card,SHELL OIL 57318,PENDING - SHELL OIL,1.00
    CSV

    assert_equal [["txn_1020", "62.40"]], feed.latest_rows.map { |row| [row["id"], row["amount"]] }
  end

  def test_compares_sync_batch_numerically
    feed = TransactionFeedService.new(StringIO.new(HEADER + <<~CSV))
      txn_1020,10,2026-08-10,card,SHELL OIL 57318,SHELL OIL 57318,62.40
      txn_1020,2,2026-08-10,card,SHELL OIL 57318,PENDING - SHELL OIL,1.00
    CSV

    assert_equal [["txn_1020", "62.40"]], feed.latest_rows.map { |row| [row["id"], row["amount"]] }
  end

  def test_keeps_one_row_per_id_across_the_full_feed
    rows = File.open(File.join(FIXTURE_FILES, "transactions.csv")) { |file| TransactionFeedService.new(file).latest_rows }

    assert_equal 56, rows.size
    assert_equal rows.map { |row| row["id"] }.uniq, rows.map { |row| row["id"] }
    assert_equal %w[2 2 2 2], rows.select { |row| %w[txn_1020 txn_1035 txn_1041 txn_1046].include?(row["id"]) }.map { |row| row["sync_batch"] }
  end

  def test_keeps_the_first_row_when_an_id_repeats_within_the_same_sync_batch
    feed = TransactionFeedService.new(StringIO.new(HEADER + <<~CSV))
      txn_1020,2,2026-08-10,card,SHELL OIL 57318,SHELL OIL 57318,62.40
      txn_1020,2,2026-08-10,card,SHELL OIL 57318,SHELL OIL 57318,63.00
    CSV

    assert_equal [["txn_1020", "62.40"]], feed.latest_rows.map { |row| [row["id"], row["amount"]] }
  end

  def test_reads_zero_padded_sync_batches_as_decimal
    feed = TransactionFeedService.new(StringIO.new(HEADER + <<~CSV))
      txn_1020,010,2026-08-10,card,SHELL OIL 57318,SHELL OIL 57318,62.40
      txn_1020,9,2026-08-10,card,SHELL OIL 57318,PENDING - SHELL OIL,1.00
    CSV

    assert_equal [["txn_1020", "62.40"]], feed.latest_rows.map { |row| [row["id"], row["amount"]] }
  end

  def test_skips_blank_lines
    feed = TransactionFeedService.new(StringIO.new(HEADER + <<~CSV))
      txn_1001,1,2026-08-03,card,SYSCO PHILA 8827,SYSCO PHILA 8827,1842.17

      txn_1003,1,2026-08-03,card,HOME DEPOT #4102,HOME DEPOT #4102,146.88

    CSV

    assert_equal %w[txn_1001 txn_1003], feed.latest_rows.map { |row| row["id"] }
  end
end
