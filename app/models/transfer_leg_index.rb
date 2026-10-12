class TransferLegIndex
  TRANSFER_MEMO = /PAYMENT|TRANSFER/i

  def self.transfer_memo?(memo)
    TRANSFER_MEMO.match?(memo.to_s)
  end

  def initialize(rows)
    @accounts_by_date_and_amount = Hash.new { |index, key| index[key] = Set.new }
    rows.select { |row| self.class.transfer_memo?(row["memo"]) }.each do |row|
      @accounts_by_date_and_amount[[row["date"], BigDecimal(row["amount"])]] << row["account"]
    end
  end

  def opposite_leg_present?(date:, account:, amount:)
    @accounts_by_date_and_amount.fetch([date, -amount], Set.new).any? { |other_account| other_account != account }
  end
end
