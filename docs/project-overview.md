# PLEDGE BANK — Project overview

## Product goal
Create a clear, accessible, responsive online banking experience with a public website, authenticated customer area, and a separately maintained administrator panel.

## Current milestone
Public-facing static website and brand foundation. No banking backend is connected.

## Planned modules
1. Public site and account onboarding
2. Customer dashboard and account overview
3. Transaction history, transfers, and bills
4. Cards and account controls
5. Savings and account settings
6. Customer profile, security, and notifications
7. Statements and customer support
8. Separate admin panel with strong server-side authorization

## Non-negotiable financial safeguards
- The server and ledger are authoritative; never trust a client-supplied balance.
- Every financial mutation must be authorized, validated, idempotent, auditable, and reconciled.
- Customer access is scoped to that customer's records at the database layer.
- Administrative privileges must be checked server-side and isolated from customer roles.
- No production financial capability is considered complete without tests and verifiable evidence.
