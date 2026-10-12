module TransferLegPairing
  def self.paired_ids(transactions)
    unpaired_legs = Hash.new { |legs, key| legs[key] = [] }

    transactions.select(&:transfer_memo?).each_with_object(Set.new) do |leg, paired_ids|
      opposite_legs = unpaired_legs[[leg.date, -leg.amount]]
      opposite_leg = opposite_legs.find { |candidate| candidate.account != leg.account }
      next unpaired_legs[[leg.date, leg.amount]] << leg if opposite_leg.nil?

      opposite_legs.delete(opposite_leg)
      paired_ids.merge([leg.id, opposite_leg.id])
    end
  end
end
