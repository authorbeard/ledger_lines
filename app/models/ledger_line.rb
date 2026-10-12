class LedgerLine
  include ActiveModel::Model
  include ActiveModel::Attributes

  TRANSACTION_TYPES = %w[purchase refund deposit transfer].freeze

  attribute :transaction_id, :string
  attribute :transaction_type, :string
  attribute :amount, :decimal

  validates :transaction_type, inclusion: { in: TRANSACTION_TYPES }
end
