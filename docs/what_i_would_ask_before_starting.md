# What I Would Ask Before Starting

Open questions raised during development, with the interim decision made to avoid being blocked.

## 1. Is "keyword match + both legs present" the correct transfer check?

Question: Is a transfer correctly identified by all three of the following?

- The memo contains "payment", "transfer", or both (case-insensitive).
- The money moves between two of the operator's own accounts.
- Both legs (the account the money leaves and the account that receives it) are present in the CSV.

MVP assumption: both legs of any transfer appear in a single CSV. If legs can be split across multiple CSV files (for example, across sync windows or separate account exports), a different tracking method is needed, such as persisting unmatched legs and reconciling them on later runs.

Follow-up: legs pair one-to-one, in feed order. When two candidate legs share a date and amount (for example, a 500.00 card payment and a 500.00 ACH rent payment on the same day as a -500.00 card credit), the one that appears first in the file is paired. The rent payment could be recorded as the transfer. Is there a more reliable signal for pairing, such as a reference number shared by both legs or the card's last four digits in the memo?

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

Context: a ledger line keeps only the normalized fields. The provider's memo, merchant string, account, and sync_batch are dropped after classification.

Question: Should each row's original data be stored alongside the LedgerLine record (for example, as a JSON column), for audit and for re-classifying lines when the rules change?

Interim decision: not persisted.

## 7. Which account values can the feed send?

Context: the rules depend on the account being card or bank. A row from any other account (a second card, a savings account added to the feed) has no defined treatment, and a negative amount there would otherwise become a negative purchase.

Question: What is the full set of account values, and are they stable identifiers or display names?

Interim decision: account names are compared case-insensitively. Rows from an account other than card or bank are classified by the same rules but flagged for review.

## 8. How should zero-amount transactions be treated?

Context: a zero amount is neither money in nor money out, so it falls through to purchase. Pending authorizations sometimes arrive this way.

Question: Should zero-amount rows be recorded, skipped, or flagged?

Interim decision: recorded as a purchase.

## 9. Can the two legs of a card payment post on different dates?

Context: transfer legs are paired by date and opposite amount. If the bank debit and the card credit post a day apart, neither leg would pair and both would be classified by the other rules (a purchase on the bank side, a refund on the card side).

Question: How far apart can the posting dates of the two legs be?

Interim decision: same-date matching only.

## 10. Should a malformed row stop the whole import?

Context: a row with a missing id, a non-ISO date, or an amount the parser cannot read (`1,842.17`, `$5.00`, `(5.00)`) cannot be classified reliably.

Question: Should one bad row fail the whole import, or be skipped (or recorded and flagged) while the rest of the feed goes through? Can the provider send amounts with thousands separators, currency symbols, or more than two decimal places? Are the header names fixed, including their case?

Interim decision: fail the import with the line number or the offending value, so nothing is recorded from a feed that was only partly understood.
