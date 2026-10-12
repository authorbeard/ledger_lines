# What I Did

My part of the work, as distinct from what Claude Code generated.

## Setup

- Created the project directory and the `ledger_lines` repository.
- Downloaded the take-home materials: the project description, `transactions.csv`, `expected_first_15.csv`, and the merchant list screenshot.
- Wrote the prompt that set the approach and constraints: a Rails-shaped rake task without a database, test-first, idempotency before categorization, the initial type rules, a commit per passing test, and the two running lists (questions to ask, work to do next). The prompt and my notes are in [`20261012_exponent_takehome_notes.txt`](20261012_exponent_takehome_notes.txt).

## Decisions during development

- Refined the transfer rule: a transfer must include "payment" or "transfer" and have a corresponding leg in another operator account, with both legs assumed to be in a single CSV for the MVP. Rent goes to a third party, so it is a purchase.
- Added storing the original CSVs (S3 or a data warehouse) to the follow-up work, and asked whether each row's original data should be persisted with its ledger line.
- Required anything under `app/services` to be named as a service.
- Ordered an adversarial review of the classifier, then a second round focused on over-engineering.
- Asked whether US date patterns should be assumed or enforced.
- Moved the work onto a branch for review and kept all agent configuration out of the repository.

## PR review

Reviewed the pull request once all the commits were in and left these comments:

- Tests generate their own CSV rows instead of using the given fixture and expected-output files, which are the known-good references. Use those throughout, in both `feed_transaction_test.rb` and `transaction_feed_service_test.rb`.
- Now that everything is built, run the service once and assert against its real output, compared to `expected_first_15.csv`, rather than against generated lines that have not been vouched for.
- Add negative cases, drawn from the fixtures, asserting that transactions are not mischaracterized as deposits or refunds.
- The test for transfer-like rows missing a leg needs verification and may be revised depending on the answers to the transfer questions. `txn_2001` should have a corresponding bank leg; this is pending the same answer.
- The savings transfer case is a specific question: what to do when a row looks like a transfer but involves an account type we don't receive CSVs for, whether to keep a static list of external accounts, and whether savings transactions could appear in the future.
- The refund-category rule needs confirmation.
- A row from an unrecognized account should also be Uncategorized, with test coverage.
- Same-account opposite legs should be pulled out for verification: do they need another ledger type, and an ActiveRecord scope to return them for review?
- How to handle a transaction whose type cannot be determined: leave it blank and flag it `needs_review`, which may mean a nullable enum.
- The full-feed test in `ledger_test.rb` only exercises the fixture file and preserves a transient test artifact. Use the fixtures and the expected first 15 instead, so the tests document what specifically is being tested.
- `TransactionFeedService#transactions` is hard to read; use `do ... end`.
- The rake task should not assemble the pieces itself. The service should orchestrate: take the file path and return the ledger's CSV, callable as-is from the app or a Sidekiq job.
- `TransactionFeedService` adds at least one full iteration over the source before further processing. Justify it or refactor; the class may be unnecessary.
