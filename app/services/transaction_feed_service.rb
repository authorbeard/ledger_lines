class TransactionFeedService
  def initialize(source)
    @source = source
  end

  def transactions
    transfer_legs = TransferLegIndex.new
    latest_rows.map { |row| FeedTransaction.new(row, transfer_legs:) }.tap { |transactions| transfer_legs.index(transactions) }
  end

  def latest_rows
    csv = CSV.new(@source, headers: true, skip_blanks: true, strip: true)
    csv.each_with_object({}) do |row, latest_by_id|
      raise ArgumentError, "Missing id on line #{csv.lineno}" if row["id"].to_s.strip.empty?

      current = latest_by_id[row["id"]]
      latest_by_id[row["id"]] = row if current.nil? || sync_batch(row) > sync_batch(current)
    end.values
  end

  private

  def sync_batch(row)
    Integer(row["sync_batch"], 10)
  end
end
