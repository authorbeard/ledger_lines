class FeedTransaction
  def initialize(row)
    @row = row
  end

  def ledger_type
    "purchase"
  end
end
