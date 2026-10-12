require "minitest/autorun"
require "tempfile"
require_relative "../config/environment"

FIXTURE_FILES = File.expand_path("fixtures/files", __dir__)
FIXTURE_FEED = File.join(FIXTURE_FILES, "transactions.csv")

module FeedFixtureHelpers
  def ledger_lines_for(feed_text)
    Tempfile.create(["transactions", ".csv"]) do |file|
      file.write(feed_text)
      file.flush
      LedgerLinesService.call(file.path)
    end
  end

  def ledger_lines_by_id(ledger_csv)
    CSV.parse(ledger_csv, headers: true).to_h { |line| [line["transaction_id"], line.fields.drop(1)] }
  end
end
