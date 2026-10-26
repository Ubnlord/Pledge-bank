# Security principles

PLEDGE BANK is currently a static website preview. It must not be used to collect real financial information or represent that live banking controls are active.

## Required before production
- Use a maintained authentication provider or rigorously reviewed authentication implementation.
- Enforce least privilege and customer-specific database authorization on every request.
- Require server-side authorization for every account and transaction operation.
- Use MFA for administrators and sensitive actions; protect login and recovery flows with rate limits.
- Keep secrets out of source control and client-side bundles.
- Maintain append-only audit records for privileged actions and financial mutations.
- Implement an authoritative double-entry ledger, idempotency, transaction limits, reconciliation, and anomaly alerts.
- Validate inputs on the server; use secure cookies, CSRF defenses where applicable, CSP, and appropriate security headers.
- Test authorization boundaries, duplicate requests, race conditions, failure recovery, and account isolation.
- Establish monitoring, backup/restore drills, incident response, and a vulnerability-reporting process.

Never claim a control is live or verified without deployment evidence and tests.
