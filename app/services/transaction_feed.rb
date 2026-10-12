class TransactionFeed
  def initialize(source)
    @source = source
  end

  def transactions
    latest_rows.map { |row| FeedTransaction.new(row) }
  end

  def latest_rows
    CSV.new(@source, headers: true).each_with_object({}) do |row, latest_by_id|
      current = latest_by_id[row["id"]]
      latest_by_id[row["id"]] = row if current.nil? || sync_batch(row) > sync_batch(current)
    end.values
  end

  private

  def sync_batch(row)
    Integer(row["sync_batch"])
  end
end
