class FeedTransaction
  TYPES_IN_PRECEDENCE = %w[refund deposit].freeze

  def initialize(row)
    @row = row
  end

  def ledger_type
    TYPES_IN_PRECEDENCE.find { |type| send(:"#{type}?") } || "purchase"
  end

  def amount
    BigDecimal(@row["amount"])
  end

  private

  def refund?
    card? && money_in?
  end

  def deposit?
    bank? && money_in?
  end

  def card?
    @row["account"] == "card"
  end

  def bank?
    @row["account"] == "bank"
  end

  def money_in?
    amount.negative?
  end
end
