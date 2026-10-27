# PLEDGE BANK dashboard end-to-end checklist

## Test environment

Use two dedicated test accounts (Customer A and Customer B) in the PLEDGE BANK Supabase project. Do not use production customer data or real payment details. Do not manually insert sample balances into a customer-facing environment.

## Authentication and dashboard

- [ ] Register Customer A with a test mailbox; confirm verification email is received and the link returns to the expected site.
- [ ] Sign in; verify the dashboard loads without console/network errors.
- [ ] Open dashboard directly in a private/anonymous browser; verify redirect to login.
- [ ] Refresh the authenticated dashboard; verify session persists and data reloads.
- [ ] Sign out; use browser back and direct URL to confirm protected page does not reveal cached customer data.
- [ ] Verify an account-less user sees an empty state, not a fabricated balance.
- [ ] Verify USD/EUR balances match posted ledger entries; pending/failed transactions do not affect balances.
- [ ] Verify account and transaction reads for Customer A do not reveal Customer B records.

## Settings

- [ ] Save Customer A's display name and phone; reload and verify persistence.
- [ ] Toggle email notifications, security alerts, and marketing preference; reload and verify persistence.
- [ ] Verify invalid/oversized fields are rejected and save errors are visible.

## Notifications

- [ ] Customer A sees only A's notifications.
- [ ] Mark a notification read; verify only `read_at` changes.
- [ ] Confirm customer API calls cannot insert notifications or edit title/body/category/user_id.
- [ ] Create a test notification through the trusted admin Edge Function after an administrator has been securely provisioned; verify it appears for the intended customer only.

## Support

- [ ] Submit a support request as Customer A; verify it appears in A's history.
- [ ] Confirm Customer B cannot read A's request or replies.
- [ ] With a trusted administrator session, list the queue, reply, and resolve through the `pledge-bank-admin` Edge Function.
- [ ] Verify the customer receives a notification after admin reply/resolution.
- [ ] Verify the customer sees replies and can add a reply only while the request is open/in progress.
- [ ] Verify a resolved/closed request rejects further customer replies.

## Responsive and accessibility

- [ ] Check 320px, 375px, and 430px mobile widths; ensure no horizontal overflow.
- [ ] Check tablet and desktop layouts.
- [ ] Test keyboard focus, Escape-to-close modal, required fields, and visible success/error messages.

## Money movement guardrails

Transfers, deposits, withdrawals, card payments, bill payments, crypto purchases, loans, and investment orders must remain disabled until licensed provider integrations, server-side authorization, idempotency, ledger posting, reconciliation, limits, audit trails, fraud controls, and independent security tests are implemented.

## Current verification boundary

Database privilege checks have been run for settings, support requests, support replies, and notifications. The `pledge-bank-admin` Edge Function is deployed with JWT verification. A live browser-based end-to-end run with dedicated test users and an administrator has **not** yet been completed.
