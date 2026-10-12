# What I Would Ask Before Starting

Open questions raised during development, with the interim decision made to avoid being blocked.

## 1. Is "keyword match + both legs present" the correct transfer check?

Question: Is a transfer correctly identified by all three of the following?

- The memo contains "payment", "transfer", or both (case-insensitive).
- The money moves between two of the operator's own accounts.
- Both legs (the account the money leaves and the account that receives it) are present in the CSV.

MVP assumption: both legs of any transfer appear in a single CSV. If legs can be split across multiple CSV files (for example, across sync windows or separate account exports), a different tracking method is needed, such as persisting unmatched legs and reconciling them on later runs.

Tests that depend on this answer and may need revision: `test_rent_paid_by_ach_payment_is_a_purchase` (a payment memo with no opposite leg), `test_moves_to_and_from_savings_are_transfers` (savings legs never appear in the feed), and `test_card_payment_legs_on_the_same_account_are_not_transfers` (the bank leg of a card payment moved onto the card account).

Follow-up: legs pair one-to-one within each group of the same date and amount, in transaction id order, after the whole file is read. When two candidate legs share a date and amount (for example, a 500.00 card payment and a 500.00 ACH rent payment on the same day as a -500.00 card credit), the one with the lower transaction id is paired. The rent payment could be recorded as the transfer. Is there a more reliable signal for pairing, such as a reference number shared by both legs or the card's last four digits in the memo?

Follow-up: the feed contains only the card and bank accounts. The savings moves (`txn_1027` TRANSFER TO SAVINGS 8810, `txn_1040` TRANSFER FROM SAVINGS 8810) have only their bank leg in the CSV, but the story says moves to and from savings are transfers. Should the savings account be treated as an operator account whose leg is not expected in the feed?

Interim decision: a row is a transfer when its memo contains "payment" or "transfer" (case-insensitive) and either a matching opposite leg is in the same file (another account, same date, equal and opposite amount, transfer memo) or the memo names an operator account the feed does not cover (for now, "savings"). This keeps the story's expected results for the savings moves while still requiring both legs for card payments. It also means legs are matched by date and amount; a card payment that posts on different dates on each side would not pair.

## 2. Should rent (and similar ACH payments to third parties) get its own type?

Context: `txn_1022` (MAINLINE PROPERTIES LLC, memo `ACH PAYMENT MAINLINE PROPERTIES`) contains "payment" but goes to a landlord, not an operator account.

Question: Should payments like this be a distinct type or category beyond "purchase"?

Interim decision: treat it as a purchase with category Rent (from the merchant list).

## 3. What should happen when the same id appears twice in the same sync_batch?

Context: the rule is "keep the version from the highest sync_batch", which does not decide between two rows that share an id and a batch number.

Question: Can the provider send this, and if so, which row is authoritative, or should the line be flagged for review?

Interim decision: keep the first row seen for that batch.

## 4. Should merchant prefix matching respect word boundaries?

Context: the story says to match when the merchant field starts with a listed name. A plain prefix match would also categorize a different merchant whose name happens to begin with a listed one (for example, "US FOODSERVICE" or "GUSTOSO CAFE" would match "US FOODS" and "GUSTO").

Question: Should a match require the listed name to be followed by a space, a non-letter character, or the end of the field?

Interim decision: plain case-insensitive prefix match, as written in the story.

## 5. Where does the merchant list live?

Question: Is there a house convention for reference data like this (a database table managed in an admin UI, a constant, a YAML file)? Who maintains the list as new merchants appear?

Interim decision: a frozen hash constant on `MerchantCategory`.

## 6. Should each row's original data be persisted with its LedgerLine?

Context: during an import, each `LedgerLine` carries the provider's account, merchant, memo and sync_batch so it can be classified, but the output keeps only the normalized fields. Once lines are persisted, those source fields would be dropped unless stored.

Question: Should each row's original data be stored alongside the LedgerLine record (for example, as a JSON column), for audit and for re-classifying lines when the rules change?

Interim decision: not persisted.

## 7. Which account values can the feed send?

Context: the rules depend on the account being card or bank. A row from any other account (a second card, a savings account added to the feed) has no defined treatment, and a negative amount there would otherwise become a negative purchase.

Question: What is the full set of account values, and are they stable identifiers or display names? A leg on an unrecognized account that pairs with a card or bank leg is currently recorded as a Transfer and not flagged; should it be flagged for review instead?

Interim decision: account names are compared case-insensitively. A row from an account other than card or bank can never be a refund or deposit, so it is typed as a purchase (or a transfer, if it pairs), categorized Uncategorized, and flagged for review.

## 8. How should zero-amount transactions be treated?

Context: a zero amount is neither money in nor money out, so it falls through to purchase. Pending authorizations sometimes arrive this way.

Question: Should zero-amount rows be recorded, skipped, or flagged? Two zero-amount rows with transfer memos on different accounts on the same day currently pair as a transfer.

Interim decision: recorded as a purchase.

## 9. Can the two legs of a card payment post on different dates?

Context: transfer legs are paired by date and opposite amount. If the bank debit and the card credit post a day apart, neither leg would pair and both would be classified by the other rules (a purchase on the bank side, a refund on the card side).

Question: How far apart can the posting dates of the two legs be?

Interim decision: same-date matching only.

## 10. Should a malformed row stop the whole import?

Context: a row with a missing id, a non-ISO date, or an amount the parser cannot read (`1,842.17`, `$5.00`, `(5.00)`) cannot be classified reliably.

Question: Should one bad row fail the whole import, or be skipped (or recorded and flagged) while the rest of the feed goes through? Can the provider send amounts with thousands separators, currency symbols, or more than two decimal places? Are the header names fixed, including their case?

Interim decision: fail the import, so nothing is recorded from a feed that was only partly understood. A missing id reports its line number; other malformed values raise the parser's own error (for example, "invalid date"), which does not yet name the row.

## 11. Should we assume or enforce US date patterns?

Context: the fixture feed uses ISO 8601 dates (`2026-08-03`). A US-style date such as `08/03/2026` would otherwise be parsed day-first and recorded as March 8 without any error.

Question: Should we assume or enforce US date patterns (`MM/DD/YYYY`) for provider feeds, or does every provider send ISO 8601?

Interim decision: only ISO 8601 dates are accepted; any other format stops the import.

## 12. What do we do with a transfer to or from an account type we don't receive CSVs for?

Context: savings moves look like transfers, but the savings account is not in the feed, so only one leg is ever visible. This is related to question 1 (missing legs) but distinct: here the second leg cannot appear in any feed we receive.

Questions: Should there be a static list of the operator's external accounts to check against before confirming a transfer? Could savings transactions be added to the feed in the future, which would change how these are paired?

Interim decision: a transfer memo naming savings is accepted as a transfer without a second leg.

## 13. Does a refund always take the category its purchase would get?

Context: the story says a refund gets the same category the purchase would. A return to a listed merchant (`txn_1024`, HOME DEPOT RETURN) is categorized Repairs & maintenance.

Question: Confirm this rule, including for refunds from unlisted merchants (currently Uncategorized and flagged for review).

Interim decision: refunds use the merchant lookup, as purchases do.

## 14. Do same-account opposite legs need their own type or a review scope?

Context: a payment and its reversal on the same account (`PAYMENT RECEIVED` -500.00 and `PAYMENT REVERSAL` 500.00 on the card) look like transfer legs but are not a transfer. They are classified as a refund and a purchase.

Questions: Do we need another ledger type for these? Will we need an ActiveRecord scope that returns them for review?

Interim decision: classified by the standard rules (refund and purchase).

## 15. How should a transaction whose type cannot be determined be recorded?

Context: every row falls through to purchase when no other rule matches, so the type is never unknown. Rows from unrecognized accounts are typed by the standard rules, categorized Uncategorized, and flagged for review.

Question: Should an unclassifiable row leave its type blank and be flagged `needs_review`? That would make the `transaction_type` enum nullable.

Interim decision: fall through to purchase and flag for review where the account is unrecognized.

## 16. What order should ledger lines be output in?

Context: lines are written in the order their transaction ids first appear in the feed. Sorting them (by id or date) would make the output order independent of the feed's row order, but adds an O(u log u) step to an otherwise linear import.

Question: Does anything downstream depend on line order, or will order come from the database once lines are persisted?

Interim decision: first-appearance order, with no sort.
