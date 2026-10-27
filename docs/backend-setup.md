# PLEDGE BANK backend setup

## Current state
The dedicated Supabase project is `iilxerppufschjdcsayn` (`https://iilxerppufschjdcsayn.supabase.co`). The initial schema migration `pledge_bank_initial_schema` was applied on 2026-10-26, and the four core tables were verified through the Supabase project tools. A follow-up migration added an index for `bank_transactions.initiated_by`.

The customer website now uses Supabase Auth for sign-in, registration, password recovery, and authenticated dashboard reads. The Supabase Auth site URL/redirect allowlist and end-to-end auth flows still require deployment-specific configuration and testing. Two-user isolation tests remain outstanding, and no financial operations are enabled. Do not represent the site as a functioning bank.

## Before enabling authentication
1. Configure Supabase Auth email confirmation, password recovery, allowed redirect URLs, rate limits, and any required MFA policy.
2. Use only the project URL and a publishable key in public frontend code. Never place a service-role/secret key in browser code or commit secrets.
3. Run the two-user isolation tests in `docs/database-verification.md` using test accounts and test-only records.
4. Confirm authenticated browser users cannot create/update bank accounts or transactions, cannot read/write ledger entries, and cannot read other users' records.
5. Check Supabase security and performance advisors. The ledger table intentionally has RLS enabled and no browser policies because browser roles are denied all privileges; treat this as deliberate defense in depth.
6. Configure Auth Site URL and allowed Redirect URLs for the deployed website, including `pages/dashboard.html` and `pages/reset-password.html`; then test sign-in, email confirmation, and recovery end to end.
7. Add server-side account provisioning and financial transaction workflows only after ledger balancing, idempotency, transaction authorization, limits, reconciliation, and audit tests exist.

## Data model boundaries
- `profiles`: minimal profile fields; row access is limited to the matching Auth user.
- `bank_accounts`: account metadata; customers can read only their own accounts. Browser clients cannot create or update accounts.
- `bank_transactions`: transaction metadata; customers can read only transactions linked to their own accounts. Browser clients cannot create or update financial transactions.
- `ledger_entries`: accounting entries; no browser-role privileges are granted. This table is not a complete ledger/posting implementation by itself.

## Financial safety
No balance column is stored in the browser-facing schema. A future balance must be derived from a server-controlled, reconciled ledger or a trusted banking provider. Do not add client-side balance updates, client-submitted account numbers, or direct browser writes to financial records.

## Admin panel separation
The admin panel will live in a separate repository. It must use server-enforced admin authorization and a separate role-management process. Never trust user-editable Auth metadata to decide whether someone is an administrator. Customer policies in this schema intentionally contain no admin bypass.


## Customer dashboard integration (2026-10-26)

- Website pages `public/pages/login.html`, `register.html`, `forgot-password.html`, `reset-password.html`, and `dashboard.html` use Supabase Auth and the dedicated project publishable key.
- Dashboard reads profile/account/transaction rows using existing RLS policies and calls `get_my_account_balances()`, which sums only ledger entries belonging to posted transactions. It displays no fabricated balances.
- Migration `20261026_usd_eur_dashboard_balances` was applied to production: currency fields now default to USD and database constraints permit only USD/EUR. The RPC returns only balances for accounts owned by `auth.uid()`; execute is granted only to authenticated users.
- Before customer rollout, configure Auth Site URL and Redirect URLs for the deployed origin and its dashboard/reset-password pages; confirm email delivery, password recovery, and row isolation with two separate test users.
- No account provisioning, transfers, deposits, withdrawals, card services, or Bitcoin purchases are enabled. No client can write account, transaction, or ledger rows. A ledger-backed dashboard is not proof of a complete or regulated banking service.


## Explicit customer table grants

A final least-privilege migration explicitly revokes all table-level privileges from `public`, `anon`, and `authenticated` on profiles, bank accounts, bank transactions, and ledger entries, then grants back only the intended profile select/column update and account/transaction select permissions. Database privilege checks confirmed customers cannot insert or update account/transaction rows and cannot read ledger entries. RLS still limits visible profile/account/transaction rows to the authenticated owner.


## Customer dashboard settings, notifications, and support

Migration `20261027_customer_dashboard_settings_notifications_support.sql` creates `customer_settings`, `support_requests`, and `customer_notifications` with row-level security. Customers can edit only their own preferences, create and read their own support requests, and read their own notifications while updating only the notification `read_at` field. Notification records must be created by a trusted server/admin workflow; the customer browser cannot fabricate them. Support requests are stored in Supabase but an admin response/handling console is not implemented here. Verify the three features using an authenticated test account before production rollout.
