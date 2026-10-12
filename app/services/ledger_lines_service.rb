class LedgerLinesService
  def self.call(path)
    new(path).call
  end

  def initialize(path)
    @path = path
  end

  def call
    ledger = Ledger.new
    transfer_candidates = Set.new

    each_feed_row do |row|
      line = ledger.record(**LedgerLine.attributes_from_feed(row))
      transfer_candidates << line if line.transfer_memo?
    end

    transfer_candidates.select(&:transfer_memo?).group_by { |line| [line.date, line.amount.abs] }.each_value do |legs|
      pair_transfer_legs(legs)
    end

    ledger.to_csv
  end

  private

  def each_feed_row
    File.open(@path, "r:bom|utf-8") do |file|
      csv = CSV.new(file, headers: true, skip_blanks: true, strip: true)
      csv.each do |row|
        raise ArgumentError, "Missing id on line #{csv.lineno}" if row["id"].to_s.empty?

        yield row
      end
    end
  end

  # Pending question 1: assumes both legs of a transfer arrive in the same feed file.
  # A leg whose opposite is not in this file is classified by the remaining rules.
  # If legs can span files, unmatched legs would need to be persisted and matched on a later import.
  def pair_transfer_legs(legs)
    unpaired_legs = []

    legs.sort_by(&:transaction_id).each do |leg|
      opposite_leg = unpaired_legs.find { |held| held.account != leg.account && held.amount == -leg.amount }
      next unpaired_legs << leg if opposite_leg.nil?

      unpaired_legs.delete(opposite_leg)
      [opposite_leg, leg].each { |paired_leg| paired_leg.paired_transfer = true }
    end
  end
end
