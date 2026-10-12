# What I Did

My part of the work, as distinct from what Claude Code generated.

## Setup

- Created the project directory and the `ledger_lines` repository.
- Downloaded the take-home materials: the project description, `transactions.csv`, `expected_first_15.csv`, and the merchant list screenshot.
- Wrote the prompt that set the approach and constraints: a Rails-shaped rake task without a database, test-first, idempotency before categorization, the initial type rules, a commit per passing test, and the two running lists (questions to ask, work to do next). The prompt is in [`ledger_lines_original_prompt.md`](ledger_lines_original_prompt.md).

## Tools I used

- Claude Code, for writing the tests and code, and for running the adversarial reviews as separate agents.
- [Ponytail](https://github.com/DietrichGebert/ponytail) (MIT), adapted as a rule and a set of review skills that push back on over-engineering. Its whole-repo audit drove the second review round.
- A group of agent settings, rules and skills I developed for use at my current company. Some are part of the team's shared setup (testing, code design, Ruby style, and commit conventions, plus the bootstrap that installs them); others are my individual settings and preferences (writing style, interaction terms, and ticket and documentation conventions). They were applied locally and kept out of this repository.

## Decisions during development

- Refined the transfer rule: a transfer must include "payment" or "transfer" and have a corresponding leg in another operator account, with both legs assumed to be in a single CSV for the MVP. Rent goes to a third party, so it is a purchase.
- Added storing the original CSVs (S3 or a data warehouse) to the follow-up work, and asked whether each row's original data should be persisted with its ledger line.
- Required anything under `app/services` to be named as a service.
- Ordered three rounds of adversarial review: the classifier's edge cases, over-engineering (using Ponytail), and regressions from the single-pass refactor.
- Asked whether US date patterns should be assumed or enforced.
- After the over-engineering review, chose a middle-ground refactor over collapsing everything into a single service: a service that takes the file path and returns the ledger CSV, while keeping the `Ledger`, `LedgerLine` and `FeedTransaction` shapes (`FeedTransaction` was later merged into `LedgerLine`; see Second review round). This was in part because we don't yet know enough to begin implementing the `Ledger` class, or some of the others, so they stay minimal rather than being either removed or built out.
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

## Second review round

After the first refactor, I left one more PR comment and followed up with three prompts.

PR comment, on `app/services/ledger_lines_service.rb`:

> This still entails a second pass over almost the entire set of transactions. Instead, a transaction that looks like a transfer should be held until or unless its other leg is found. If it is, then the transfer can be recorded for both accounts, and if it's not, then it can be categorized later. Mark this code as pending answers on whether transfer legs will always be present in the same transactions file.

Prompts:

> It looks like you've kept some classes that the adversarial review recommended dropping. Check that and also address my most recent comment.

> Also, I'm not sure FeedTransaction and LedgerLine need to be two different classes here. A lot of the getter methods in FeedTransaction are overkill at this point and just add padding and cruft.

> The current time complexity is far too high.

Outcome:

- Classes: of the five the over-engineering review recommended dropping, `TransactionFeedService`, the transfer leg index, and `FeedTransaction` were removed. `Ledger` and `LedgerLine` remain, per the middle-ground decision. The code is now four files: `LedgerLinesService`, `Ledger`, `LedgerLine`, and `MerchantCategory`.
- Transfers: rows with a PAYMENT or TRANSFER memo are held while the file is read, then paired one-to-one within groups of the same date and amount; a leg without an opposite is classified by the remaining rules. The code is marked as pending the answer on whether both legs always arrive in the same file. Legs are matched at the end of the read rather than the moment the second arrives, because matching on arrival would make the result depend on row order whenever three or more legs share a date and amount.
- Classes merged: each feed row becomes a `LedgerLine` with ActiveModel attributes, replacing `FeedTransaction` and its getter methods. The type rules are named for what they check (`card_credit?`, `bank_credit?`, `operator_transfer?`) so they will not collide with an ActiveRecord enum's predicates. The `transaction_type` validation was dropped, since the type is computed and cannot be invalid.
- Time complexity: from O(n + u log u + u * m) to O(n). `Ledger#record` keeps the highest `sync_batch` per id during the read, so deduplication is no longer a separate step. Type, category and review status are computed once per line when the CSV is written. Merchant lookups are cached per distinct merchant string. The output sort was removed, so lines follow the order ids first appear in the feed; output order became open question 16.
- Verification: the suite passes, the first 15 lines still match `expected_first_15.csv`, and each design change was checked by deliberately breaking it (8 targeted mutations, all caught).

