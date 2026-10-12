# ledger_lines

Turns a raw transaction feed (corporate card and bank account) into categorized ledger lines. The code is organized the way it would sit inside a Rails app (`app/models`, `app/services`, `lib/tasks`), with ActiveModel standing in for ActiveRecord so no database is needed.

## How to run it

Requires Ruby 3.4.1 (see `.ruby-version`).

```sh
bundle install
bundle exec rake "ledger_lines[<path_to_csv>]" > ledger_lines.csv
bundle exec rake test
```

The task takes the feed path as its only argument and writes the ledger lines CSV to stdout. Running it again on the same feed produces identical output.

## How it works

1. `TransactionFeedService` reads the CSV once, keeping the row from the highest `sync_batch` for each id, and wraps each surviving row as a `FeedTransaction`.
2. `TransferLegIndex` makes one pass over the transactions whose memo says PAYMENT or TRANSFER and pairs each leg with at most one opposite leg (another account, same date, equal and opposite amount) using a hash keyed by date and amount.
3. `FeedTransaction` decides the type by checking transfer, refund and deposit in that order, falling back to purchase. It gets the category from `MerchantCategory` (a case-insensitive prefix match on the merchant list).
4. `Ledger` records one `LedgerLine` per `transaction_id` (the in-memory equivalent of `find_or_initialize_by`) and writes the CSV.

## What was unclear in the story, and what I'd ask before merging

The full list, with the interim decision made for each, is in [`docs/what_i_would_ask_before_starting.md`](docs/what_i_would_ask_before_starting.md). The main ones:

- Transfers. "The memo will say PAYMENT or TRANSFER" also matches rent paid by ACH (`ACH PAYMENT MAINLINE PROPERTIES`). A transfer here requires the keyword plus an opposite leg in another account in the same file. Savings moves have no second leg in the feed, so a memo naming savings is accepted on its own. This assumes both legs of a card payment arrive in the same file and post on the same date.
- Unrecognized accounts and zero amounts have no defined treatment. Unrecognized accounts are flagged for review; zero amounts are purchases.
- Prefix matching on merchant names has no word boundary, so a merchant whose name begins with a listed name would be miscategorized.
- Malformed rows (missing id, non-ISO date, unparseable amount) stop the import with the offending line or value rather than being skipped.
- Same-id, same-batch duplicates are not covered by "keep the highest sync_batch". The first row is kept.

Follow-up work is in [`docs/what_i_would_do_next.md`](docs/what_i_would_do_next.md).

## Where I used AI and where I overrode it

I wrote the approach, rules and constraints in a prompt (included in [`docs/`](docs/)) and used Claude Code to write the tests and code under TDD: one failing test, the minimum code to pass it, one commit per step. Where a test passed against existing code, it was checked against a deliberate mutation of the code so that it was shown to catch the failure it describes. A separate Claude agent then reviewed the classifier adversarially against the story. Its findings (octal sync_batch parsing, byte order marks, non-ISO dates, a transfer leg pairing with more than one counterpart, whitespace in ids) were each reproduced as a failing test and fixed.

Where I overrode or corrected it:

- The transfer rule. My starting rule was "memo includes payment or transfer". Claude flagged that this classifies an ACH rent payment as a transfer; I decided a transfer also needs its opposite leg in another operator account. Claude proposed the interim exception for savings moves, whose other leg is never in the feed.
- Structure. Claude placed non-service classes under `app/services`; I required anything there to be named as a service, so the feed reader became `TransactionFeedService` and the leg index moved to `app/models`.
