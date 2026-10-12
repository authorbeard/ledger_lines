class FeedTransaction
  TYPES_IN_PRECEDENCE = %w[transfer refund deposit].freeze
  OPERATOR_ACCOUNT_OUTSIDE_FEED = /SAVINGS/i
  UNCATEGORIZED = "Uncategorized"

  def initialize(row, transfer_legs:)
    @row = row
    @transfer_legs = transfer_legs
  end

  def ledger_type
    TYPES_IN_PRECEDENCE.find { |type| send(:"#{type}?") } || "purchase"
  end

  def category
    MerchantCategory.for(merchant) || UNCATEGORIZED
  end

  def needs_review?
    category == UNCATEGORIZED
  end

  def date
    @row["date"]
  end

  def account
    @row["account"]
  end

  def merchant
    @row["merchant"]
  end

  def memo
    @row["memo"]
  end

  def amount
    BigDecimal(@row["amount"])
  end

  private

  def transfer?
    TransferLegIndex.transfer_memo?(memo) && counterpart_is_operator_account?
  end

  def counterpart_is_operator_account?
    OPERATOR_ACCOUNT_OUTSIDE_FEED.match?(memo.to_s) || @transfer_legs.opposite_leg_present?(date:, account:, amount:)
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
