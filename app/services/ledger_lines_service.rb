class LedgerLinesService
  def self.call(path)
    new(path).call
  end

  def initialize(path)
    @path = path
  end

  def call
    ledger = Ledger.new
    ledger.import(transactions)
    ledger.to_csv
  end

  private

  def transactions
    unpaired = latest_rows.map { |row| FeedTransaction.new(row:) }
    paired_ids = TransferLegPairing.paired_ids(unpaired)

    unpaired.map do |transaction|
      transaction.with(paired_transfer: paired_ids.include?(transaction.id))
    end
  end

  def latest_rows
    File.open(@path, "r:bom|utf-8") do |file|
      csv = CSV.new(file, headers: true, skip_blanks: true, strip: true)
      csv.each_with_object({}) do |row, latest_by_id|
        raise ArgumentError, "Missing id on line #{csv.lineno}" if row["id"].to_s.empty?

        current = latest_by_id[row["id"]]
        latest_by_id[row["id"]] = row if current.nil? || sync_batch(row) > sync_batch(current)
      end
    end.values.sort_by { |row| row["id"] }
  end

  def sync_batch(row)
    Integer(row["sync_batch"], 10)
  end
end
