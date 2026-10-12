desc "Convert a transactions feed CSV into ledger lines CSV on stdout"
task :ledger_lines, [:path] do |_task, args|
  require_relative "../../config/environment"

  abort "Usage: rake \"ledger_lines[path/to/transactions.csv]\"" if args[:path].nil?

  $stdout.write(LedgerLinesService.call(args[:path]))
end
