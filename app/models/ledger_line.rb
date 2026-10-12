class LedgerLine
  include ActiveModel::Model
  include ActiveModel::Attributes

  CSV_HEADERS = %w[transaction_id date type category amount needs_review].freeze
  TYPE_RULES = { "transfer" => :operator_transfer?, "refund" => :card_credit?, "deposit" => :bank_credit? }.freeze
  CATEGORIES_BY_TYPE = { "transfer" => "Transfer" }.freeze
  TRANSFER_MEMO = /PAYMENT|TRANSFER/i
  OPERATOR_ACCOUNT_OUTSIDE_FEED = /SAVINGS/i
  ACCOUNTS = %w[card bank].freeze
  UNCATEGORIZED = "Uncategorized"

  attribute :transaction_id, :string
  attribute :sync_batch, :integer
  attribute :date, :date
  attribute :account, :string
  attribute :merchant, :string
  attribute :memo, :string
  attribute :amount, :decimal
  attribute :paired_transfer, :boolean, default: false

  def self.attributes_from_feed(row)
    {
      transaction_id: row["id"],
      sync_batch: Integer(row["sync_batch"], 10),
      date: Date.iso8601(row["date"].to_s),
      account: row["account"].to_s.downcase,
      merchant: row["merchant"],
      memo: row["memo"],
      amount: BigDecimal(row["amount"])
    }
  end

  def transfer_memo?
    TRANSFER_MEMO.match?(memo.to_s)
  end

  def to_csv_row
    transaction_type = TYPE_RULES.find { |_type, rule| send(rule) }&.first || "purchase"
    category = CATEGORIES_BY_TYPE.fetch(transaction_type) { (MerchantCategory.for(merchant) if ACCOUNTS.include?(account)) || UNCATEGORIZED }

    [transaction_id, date.iso8601, transaction_type, category, format("%.2f", amount), (category == UNCATEGORIZED).to_s]
  end

  private

  def operator_transfer?
    transfer_memo? && (paired_transfer || OPERATOR_ACCOUNT_OUTSIDE_FEED.match?(memo))
  end

  def card_credit?
    account == "card" && amount.negative?
  end

  def bank_credit?
    account == "bank" && amount.negative?
  end
end
