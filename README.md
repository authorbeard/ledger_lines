# ledger_lines

Turns a raw transaction feed (corporate card and bank account) into categorized ledger lines. The code is organized the way it would sit inside a Rails app (`app/models`, `app/services`, `lib/tasks`), with ActiveModel standing in for ActiveRecord so no database is needed.

## Dependencies

- Ruby 3.4.1 (pinned in `.ruby-version`; install with rbenv, asdf, or your version manager of choice)
- Bundler 2.x (`gem install bundler`)
- Gems, installed by Bundler from the `Gemfile`: `activemodel`, `bigdecimal`, `csv`, `rake`, and `minitest` (test only)

No database or other services are required.

## How to run it

```sh
bundle install
bundle exec rake "ledger_lines[<path_to_csv>]" > ledger_lines.csv
```

The task takes the path to a transactions CSV as its only argument and writes the ledger lines CSV to stdout. Running it again on the same feed produces identical output.

Run the tests with:

```sh
bundle exec rake test
```

## How it works

```mermaid
flowchart LR
    A[transactions.csv] --> B[rake ledger_lines]
    B --> C[LedgerLinesService.call]
    C --> D[read once: keep highest<br/>sync_batch per id, sort by id]
    D --> E[TransferLegPairing<br/>pair transfer legs one-to-one]
    E --> F[FeedTransaction<br/>type, category, needs_review]
    F --> G[Ledger<br/>one LedgerLine per transaction_id]
    G --> H[ledger_lines.csv on stdout]
```

The rake task passes the CSV path to `LedgerLinesService.call`, which can equally be called from the app or a background job. The service reads the file once, keeping only the latest version of each transaction id, and sorts the survivors by id so output never depends on row order. `TransferLegPairing` matches each payment or transfer row with at most one opposite leg in the other account. Each `FeedTransaction` then determines its type (transfer, refund, deposit, otherwise purchase), its category from the merchant list, and whether it needs review. `Ledger` records one `LedgerLine` per transaction id and returns the CSV, which the task writes to stdout.

## Further documentation

- [What I would ask before starting](doc/what_i_would_ask_before_starting.md): what was unclear or wrong in the story, with the interim decision made for each.
- [What I would do next](doc/what_i_would_do_next.md): follow-up work left out of this version.
- [What I did](doc/what_i_did.md): my part of the work, including where I directed and overrode the AI-generated code.
- [Original prompt](doc/ledger_lines_original_prompt.md): the prompt Claude Code worked from.

## Where I used AI

Claude Code wrote the tests and code test-first from my prompt, one commit per passing test. A separate Claude agent reviewed the classifier adversarially, and each of its findings was reproduced as a failing test before being fixed. Where I overrode or corrected it is in [What I did](doc/what_i_did.md).
