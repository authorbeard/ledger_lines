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
end
