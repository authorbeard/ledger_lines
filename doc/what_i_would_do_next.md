# What I Would Do Next

Follow-up work deliberately left out of this demonstration.

## Persistence

- Replace the ActiveModel stand-ins with ActiveRecord models and migrations: `ledgers` (operator, source file, import metadata) and `ledger_lines` belonging to a ledger.
- Declare `enum :transaction_type, { purchase: 0, refund: 1, deposit: 2, transfer: 3 }` on `LedgerLine` in place of the inclusion validation.
- Add a unique index on `ledger_lines (ledger_id, transaction_id)` so the database enforces one line per transaction, not only the application code.
- Swap the in-memory `Ledger#record` for `ledger_lines.find_or_initialize_by(transaction_id:)`, or `upsert_all` keyed on that unique index once feeds are large enough that per-row queries matter.

## Source data

- Determine what to do with the original CSVs. Keep a record of each source document somewhere durable, such as an S3 bucket or a data warehouse/lake, so any ledger line can be traced back to the file it came from.

## Tests

- Add FactoryBot with a `ledger_line` factory and a trait for each transaction type (purchase, refund, deposit, transfer), plus a `needs_review` trait.

## Merchant matching

- Build up an association between the merchant-string variants seen in feeds (`SYSCO PHILA 8827`, `Sysco Phila`) and the canonical merchant, so repeat merchants resolve with a direct lookup instead of scanning the prefix list every time.

## Scale

- The import reads the feed in a single pass and holds one row per unique id in memory until classification. For feeds too large for that, process in batches keyed by id range or date window, or stage rows in a database table and let a unique index on the transaction id resolve re-syncs.
- Reduce the time complexity from O(n + u log u + u * m) toward O(n):
  - Drop the in-memory sort. It exists only to make output and pairing independent of row order. Once lines are persisted, output order comes from an indexed `ORDER BY` in the database. Pairing only needs a deterministic order within each date-and-amount bucket of transfer-memo rows, which is a small fraction of the feed.
  - Make the merchant lookup constant-time. Key merchants by their normalized first word (or cache each merchant string variant once resolved, as noted under Merchant matching) instead of scanning the whole list for every row.
  - Compute each transaction's type once. `category` and `needs_review?` currently recompute `ledger_type`, roughly tripling the classification work per row.
- Run the import as a background job per operator feed rather than a rake task, with the rake task kept as a manual entry point.

## Hardening

- Format amounts without going through Float. `format("%.2f")` is exact for two-decimal amounts of realistic size, but rounds inconsistently for amounts with more than two decimal places and loses precision above roughly 15 significant digits.
- Validate the header row up front and fail with a clear message when an expected column is missing or differently named.
- Add RuboCop with the house configuration and run the suite and linter in CI.
