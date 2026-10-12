class LedgerLine
  include ActiveModel::Model
  include ActiveModel::Attributes

  TRANSACTION_TYPES = %w[purchase refund deposit transfer].freeze
  CSV_HEADERS = %w[transaction_id date type category amount needs_review].freeze

  attribute :transaction_id, :string
  attribute :date, :date
  attribute :transaction_type, :string
  attribute :category, :string
  attribute :amount, :decimal
  attribute :needs_review, :boolean

  validates :transaction_type, inclusion: { in: TRANSACTION_TYPES }

  def to_csv_row
    [transaction_id, date.iso8601, transaction_type, category, format("%.2f", amount), needs_review.to_s]
  end
end
