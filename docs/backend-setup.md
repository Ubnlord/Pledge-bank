# PLEDGE BANK backend setup

## Current state
The public website is still a static preview. The SQL in `database/schema.sql` is a proposed initial data model; it has not been applied to a Supabase project. The connected Supabase accounts did not contain a project named PLEDGE BANK, so no unrelated project was modified and no new billable project was created.

## Before connecting authentication
1. Create or select a dedicated Supabase project for PLEDGE BANK (not Global-Beldex, Pledge-Invest, or the trading bot project).
2. Confirm the regulated service model, legal entity, customer eligibility, data residency, and required compliance controls.
3. Review `database/schema.sql` with the target project configuration and apply it only to a dedicated non-production environment first.
4. Verify that row-level security is enabled for every customer-facing table and that customer access policies check ownership, not only sign-in status.
5. Create two test users and prove each user can read only their own profile, accounts, and transactions. Confirm direct account writes, transaction writes, ledger reads/writes, and role escalation are denied.
6. Configure email verification, password recovery, redirect allowlists, rate limits, and MFA policies in Supabase Auth.
7. Store the Supabase project URL and publishable key in the frontend deployment environment. A publishable key may be public; never put a service-role/secret key in browser code or commit secrets.
8. Add server-side account provisioning and financial transaction workflows only after the ledger, idempotency, balanced entries, transaction authorization, and reconciliation tests are implemented.

## Data model boundaries
- `profiles`: a small set of customer profile fields; row access is limited to the matching Auth user.
- `bank_accounts`: account metadata; customers can read only their own accounts. Browser clients cannot create or update accounts.
- `bank_transactions`: transaction metadata; customers can read only transactions linked to their own accounts. Browser clients cannot create or update financial transactions.
- `ledger_entries`: accounting entries; no browser-role privileges are granted. This table is not a complete ledger implementation by itself.

## Financial safety
No balance column is stored in the browser-facing schema. A future balance must be derived from a server-controlled, reconciled ledger or a trusted banking provider. Do not add client-side balance updates, client-submitted account numbers, or direct browser writes to financial records.

## Admin panel separation
The admin panel will live in a separate repository. It must use server-enforced admin authorization and a separate role-management process. Never trust user-editable Auth metadata to decide whether someone is an administrator. Customer policies in this schema intentionally contain no admin bypass.
