class Ledger
  def initialize
    @lines_by_transaction_id = {}
  end

  def lines
    @lines_by_transaction_id.values
  end

  def record(transaction_id:, **attributes)
    line = @lines_by_transaction_id[transaction_id] ||= LedgerLine.new(transaction_id:)
    line.assign_attributes(attributes)
    line
  end

  def record_transaction(transaction)
    record(
      transaction_id: transaction.id,
      date: transaction.date,
      transaction_type: transaction.ledger_type,
      category: transaction.category,
      amount: transaction.amount,
      needs_review: transaction.needs_review?
    )
  end

  def to_csv
    CSV.generate do |csv|
      csv << LedgerLine::CSV_HEADERS
      lines.sort_by(&:transaction_id).each { |line| csv << line.to_csv_row }
    end
  end
end
