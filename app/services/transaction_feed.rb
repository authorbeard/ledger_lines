class TransactionFeed
  def initialize(source)
    @source = source
  end

  def latest_rows
    CSV.new(@source, headers: true).each_with_object({}) do |row, latest_by_id|
      latest_by_id[row["id"]] = row
    end.values
  end
end
