class LedgerLinesService
  def self.call(path)
    new(path).call
  end

  def initialize(path)
    @path = path
  end

  def call
    ledger = Ledger.new
    held_transfer_legs = Hash.new { |legs, key| legs[key] = [] }

    latest_rows.each do |row|
      transaction = FeedTransaction.new(row:)
      next ledger.record_transaction(transaction) unless transaction.transfer_memo?

      held_transfer_legs[[transaction.date, transaction.amount.abs]] << transaction
    end

    held_transfer_legs.each_value { |legs| record_transfer_legs(ledger, legs) }
    ledger.to_csv
  end

  private

  # Pending question 1: assumes both legs of a transfer arrive in the same feed file.
  # A leg whose opposite is not in this file is recorded by the remaining rules.
  # If legs can span files, unmatched legs would need to be persisted and matched on a later import.
  def record_transfer_legs(ledger, legs)
    unpaired_legs = []

    legs.sort_by(&:id).each do |leg|
      opposite_leg = unpaired_legs.find { |held| held.account != leg.account && held.amount == -leg.amount }
      next unpaired_legs << leg if opposite_leg.nil?

      unpaired_legs.delete(opposite_leg)
      [opposite_leg, leg].each { |paired_leg| ledger.record_transaction(paired_leg.with(paired_transfer: true)) }
    end

    unpaired_legs.each { |leg| ledger.record_transaction(leg) }
  end

  def latest_rows
    File.open(@path, "r:bom|utf-8") do |file|
      csv = CSV.new(file, headers: true, skip_blanks: true, strip: true)
      csv.each_with_object({}) do |row, latest_by_id|
        raise ArgumentError, "Missing id on line #{csv.lineno}" if row["id"].to_s.empty?

        current = latest_by_id[row["id"]]
        latest_by_id[row["id"]] = row if current.nil? || sync_batch(row) > sync_batch(current)
      end
    end.values
  end

  def sync_batch(row)
    Integer(row["sync_batch"], 10)
  end
end
