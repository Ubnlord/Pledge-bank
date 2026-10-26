# PLEDGE BANK — Online Banking Website

This repository contains the public-facing PLEDGE BANK website preview. The intended account currencies are USD and EUR only; local-currency wallets are not offered. A Buy Bitcoin entry point is included as a preview, but Bitcoin purchases are not connected or enabled.

## Included
- Responsive landing page and brand styling
- Mobile-friendly navigation
- Public about, services, and contact pages
- Login, registration, and password-recovery preview screens
- Initial privacy and website-terms notices
- SVG brand mark and accessible, reduced-motion-aware styling

## Run locally
The current site is static HTML, CSS, and JavaScript. Open `public/index.html` in a browser or serve the `public/` directory with any static HTTP server.

## Important security and launch status
**This is a front-end preview, not a functioning bank.** Login, account creation, password recovery, payments, balances, transfers, cards, and support submissions are not connected to a backend. Forms explicitly show a preview notice and do not transmit or persist submitted data. Numbers and card details on the landing page are illustrative only.

Do not collect real customer information until a production backend and security controls are implemented and independently tested. Before enabling banking services, implement and verify:
- A trusted, appropriately licensed banking/payment partner and legal/compliance disclosures
- Server-side authentication, secure session lifecycle, MFA, account recovery, and rate limiting
- Database access controls and row-level authorization
- Server-authoritative ledger and double-entry accounting; never trust client-side balance values
- Idempotent transaction processing, reconciliation, immutable audit events, limits, and fraud monitoring
- Encryption in transit and at rest, secret management, backups, monitoring, and incident response
- Automated tests, accessibility checks, and security review

## Backend foundation
- `database/schema.sql` — schema source for customer profiles, account metadata, transaction metadata, and restricted ledger entries.
- `database/seed-data.sql` — no fabricated customer or financial data.
- `docs/database-verification.md` — row-level authorization and database privilege test checklist.
- `docs/backend-setup.md` — staged setup and verification notes.
- `backend/config.env.example` — environment-variable names only; no credentials.

**Supabase schema deployed:** the initial migration was applied to the dedicated PLEDGE BANK project on 2026-10-26 and verified by listing the four tables, their columns, RLS status, and the migration record. A foreign-key performance index was added in a follow-up migration. The two-user isolation tests have not yet been run. Supabase Auth is not yet wired to the website, and no financial operations are enabled.

## Next implementation phase
Configure Auth settings and email redirects, wire registration/login/password recovery to Supabase Auth, and pass the two-user isolation tests in `docs/database-verification.md`. Then implement an authenticated customer dashboard. Server-side financial workflows must be separately designed and tested before any deposits, transfers, or balance displays become live. The separate PLEDGE BANK admin panel will be developed in its own repository and must use server-enforced administrator authorization, separate from ordinary customer access.

## Repository layout
- `public/index.html` — public landing page
- `public/assets/css/main.css` — responsive visual system
- `public/assets/js/main.js` — navigation and non-submitting demo form messaging
- `public/assets/images/logo.svg` — brand mark
- `public/pages/` — public informational and authentication preview pages

## Publish on GitHub Pages

The repository includes a GitHub Actions workflow at `.github/workflows/deploy-pages.yml` that publishes the contents of `public/` whenever files in that folder change on `main`, and supports manual runs.

- Expected website URL: https://ubnlord.github.io/Pledge-bank/
- In GitHub, open **Settings → Pages** and set **Build and deployment → Source** to **GitHub Actions** if it is not already selected.
- Then open **Actions → Deploy PLEDGE BANK to GitHub Pages** to check the deployment result. The first deployment may take a few minutes.

The hosted site remains a non-functional visual preview; authentication and banking operations are not enabled. See the security and launch notes above before sharing it with customers.


## Customer dashboard integration

The customer sign-in, registration, password recovery, and dashboard pages now use the dedicated PLEDGE BANK Supabase project. The browser uses only the project's publishable key; row-level security limits account and transaction reads to the signed-in customer. Dashboard balances come from `get_my_account_balances()` and include only ledger entries attached to posted transactions. The dashboard never invents sample balances.

**Important:** this is a real authenticated account-data dashboard, not a complete operational bank. New logins do not automatically receive accounts. Account provisioning and all money movement must remain in trusted, audited server-side workflows. Transfers, deposits, withdrawals, and Bitcoin orders are not enabled. Configure Supabase Auth site URL, allowed redirect URLs, email confirmation, and password recovery redirects before inviting customers. Do not enable live banking based on the dashboard alone.
