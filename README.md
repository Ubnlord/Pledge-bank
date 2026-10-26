# PLEDGE BANK — Online Banking Website

This repository contains the initial public-facing website for PLEDGE BANK.

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

## Planned next phase
Build the authenticated customer dashboard and API/database integration only after selecting the production backend and confirming the appropriate regulated service model. The separate PLEDGE BANK admin panel will be developed in its own repository and must use server-enforced administrator authorization, separate from ordinary customer access.

## Repository layout
- `public/index.html` — public landing page
- `public/assets/css/main.css` — responsive visual system
- `public/assets/js/main.js` — navigation and non-submitting demo form messaging
- `public/assets/images/logo.svg` — brand mark
- `public/pages/` — public informational and authentication preview pages
