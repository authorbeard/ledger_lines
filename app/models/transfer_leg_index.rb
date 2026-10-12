class TransferLegIndex
  def initialize
    @accounts_by_date_and_amount = Hash.new { |index, key| index[key] = Set.new }
  end

  def index(transactions)
    transactions.select(&:transfer_memo?).each do |transaction|
      @accounts_by_date_and_amount[[transaction.date, transaction.amount]] << transaction.account
    end
  end

  def opposite_leg_present?(transaction)
    @accounts_by_date_and_amount.fetch([transaction.date, -transaction.amount], Set.new).any? { |account| account != transaction.account }
  end
end
