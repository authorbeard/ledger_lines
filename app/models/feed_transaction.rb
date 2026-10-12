class FeedTransaction < Data.define(:row, :paired_transfer)
  TYPES_IN_PRECEDENCE = %w[transfer refund deposit].freeze
  TRANSFER_MEMO = /PAYMENT|TRANSFER/i
  OPERATOR_ACCOUNT_OUTSIDE_FEED = /SAVINGS/i
  UNCATEGORIZED = "Uncategorized"
  ACCOUNTS = %w[card bank].freeze
  CATEGORIES_BY_LEDGER_TYPE = { "transfer" => "Transfer" }.freeze

  def initialize(row:, paired_transfer: false)
    super
  end

  def ledger_type
    TYPES_IN_PRECEDENCE.find { |type| send(:"#{type}?") } || "purchase"
  end

  def category
    CATEGORIES_BY_LEDGER_TYPE.fetch(ledger_type) { (MerchantCategory.for(merchant) if known_account?) || UNCATEGORIZED }
  end

  def needs_review?
    category == UNCATEGORIZED
  end

  def id
    row["id"]
  end

  def date
    Date.iso8601(row["date"].to_s)
  end

  def account
    row["account"].to_s.downcase
  end

  def merchant
    row["merchant"]
  end

  def memo
    row["memo"]
  end

  def amount
    BigDecimal(row["amount"])
  end

  def transfer_memo?
    TRANSFER_MEMO.match?(memo.to_s)
  end

  private

  def transfer?
    transfer_memo? && (paired_transfer || OPERATOR_ACCOUNT_OUTSIDE_FEED.match?(memo.to_s))
  end

  def refund?
    card? && money_in?
  end

  def deposit?
    bank? && money_in?
  end

  def known_account?
    ACCOUNTS.include?(account)
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
