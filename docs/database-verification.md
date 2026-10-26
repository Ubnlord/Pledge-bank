# Database authorization verification checklist

Run this checklist only after the schema has been reviewed and applied to a dedicated non-production PLEDGE BANK project.

## Schema and policies
- Confirm row-level security is enabled on `profiles`, `bank_accounts`, `bank_transactions`, and `ledger_entries`.
- Inspect all policies and confirm each customer-read policy checks `auth.uid()` against the profile or owning account.
- Confirm the private helper functions are not executable by browser roles.
- Confirm the authenticated browser role has no INSERT or UPDATE privilege on bank accounts or transactions.
- Confirm the authenticated browser role has no SELECT, INSERT, UPDATE, or DELETE privileges on ledger entries.
- Confirm anonymous users cannot read customer tables.

## Two-user isolation test
Create two test identities, User A and User B, in a non-production project. Provision test records only through a trusted test fixture.
- A can read A's profile, accounts, and transaction history.
- A cannot read B's profile, accounts, or transactions, even if A knows B's record IDs.
- B cannot read A's records.
- Neither user can insert, update, or delete bank accounts, financial transactions, or ledger entries directly through the Data API.
- A user cannot change their identity, account owner, account status, transaction status, amount, or ledger entries by modifying request payloads.
- Unauthenticated requests cannot read protected records.
- Every denied request is checked for both expected status and absence of unauthorized data.

## Financial workflow tests still required
The initial schema does not implement a posting engine or balance calculation. Before any real money operation exists, test balanced double-entry postings, transaction atomicity, idempotency under concurrent retries, reversal workflows, limits, reconciliation, audit records, and recovery from partial failures.
