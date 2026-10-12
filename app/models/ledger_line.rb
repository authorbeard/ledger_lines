class LedgerLine
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :transaction_id, :string
  attribute :amount, :decimal
end
