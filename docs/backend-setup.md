# PLEDGE BANK backend setup

## Current state
The dedicated Supabase project is `iilxerppufschjdcsayn` (`https://iilxerppufschjdcsayn.supabase.co`). The initial schema migration `pledge_bank_initial_schema` was applied on 2026-10-26, and the four core tables were verified through the Supabase project tools. A follow-up migration added an index for `bank_transactions.initiated_by`.

The public website remains a static preview. Supabase Auth has not been connected to the website, the two-user isolation tests are still outstanding, and no financial operations are enabled. Do not represent the site as a functioning bank.

## Before enabling authentication
1. Configure Supabase Auth email confirmation, password recovery, allowed redirect URLs, rate limits, and any required MFA policy.
2. Use only the project URL and a publishable key in public frontend code. Never place a service-role/secret key in browser code or commit secrets.
3. Run the two-user isolation tests in `docs/database-verification.md` using test accounts and test-only records.
4. Confirm authenticated browser users cannot create/update bank accounts or transactions, cannot read/write ledger entries, and cannot read other users' records.
5. Check Supabase security and performance advisors. The ledger table intentionally has RLS enabled and no browser policies because browser roles are denied all privileges; treat this as deliberate defense in depth.
6. Connect the login, registration, and recovery screens to Supabase Auth only after redirect configuration and test identities are ready.
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
