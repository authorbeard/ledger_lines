class TransferLegIndex
  def initialize
    @paired_transaction_ids = Set.new
  end

  def index(transactions)
    unpaired_legs = Hash.new { |legs, key| legs[key] = [] }

    transactions.select(&:transfer_memo?).each do |leg|
      opposite_legs = unpaired_legs[[leg.date, -leg.amount]]
      opposite_leg = opposite_legs.find { |candidate| candidate.account != leg.account }
      next unpaired_legs[[leg.date, leg.amount]] << leg if opposite_leg.nil?

      opposite_legs.delete(opposite_leg)
      @paired_transaction_ids.merge([leg.id, opposite_leg.id])
    end
  end

  def opposite_leg_present?(transaction)
    @paired_transaction_ids.include?(transaction.id)
  end
end
