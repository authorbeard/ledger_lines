class FeedTransaction
  TYPES_IN_PRECEDENCE = %w[transfer refund deposit].freeze

  def initialize(row, transfer_legs:)
    @row = row
    @transfer_legs = transfer_legs
  end

  def ledger_type
    TYPES_IN_PRECEDENCE.find { |type| send(:"#{type}?") } || "purchase"
  end

  def date
    @row["date"]
  end

  def account
    @row["account"]
  end

  def memo
    @row["memo"]
  end

  def amount
    BigDecimal(@row["amount"])
  end

  private

  def transfer?
    TransferLegIndex.transfer_memo?(memo) && @transfer_legs.opposite_leg_present?(date:, account:, amount:)
  end

  def refund?
    card? && money_in?
  end

  def deposit?
    bank? && money_in?
  end

  def card?
    account == "card"
  end

  def bank?
    account == "bank"
  end

  def money_in?
    amount.negative?
  end
end
