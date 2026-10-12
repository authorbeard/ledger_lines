class Ledger
  def initialize
    @lines_by_transaction_id = {}
  end

  def lines
    @lines_by_transaction_id.values
  end

  def record(transaction_id:, sync_batch:, **attributes)
    line = @lines_by_transaction_id[transaction_id] ||= LedgerLine.new(transaction_id:)
    line.assign_attributes(sync_batch:, **attributes) if line.sync_batch.nil? || sync_batch > line.sync_batch
    line
  end

  def to_csv
    CSV.generate do |csv|
      csv << LedgerLine::CSV_HEADERS
      lines.each { |line| csv << line.to_csv_row }
    end
  end
end
