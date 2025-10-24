# research.md

Decisions for Pushover notification feature

## Decision 1: Recipient model
- Decision: Use a single Pushover application/API token (repo-level token) delivering to the user's devices registered to that Pushover account.
- Rationale: Minimizes configuration complexity and matches the user's requested preference (Q1: A). Simpler to manage as a single repository secret.
- Alternatives considered: per-user tokens or group keys. Rejected for MVP due to increased secret management complexity.

## Decision 2: Secrets storage
- Decision: Store the Pushover credentials in repository-level secrets (`PUSHOVER_TOKEN`, `PUSHOVER_USER`).
- Rationale: Matches the repository-focused workflow and the user's choice (Q2: A). Easy to manage by repository maintainers and avoids org-level admin setup for MVP.
- Alternatives considered: organization secrets or external secret manager. Rejected for MVP (added complexity).

## Decision 3: Notification payload
- Decision: Minimal payload (tag, digest, link) for push notifications.
- Rationale: Keeps messages concise and within push constraints (Q3: A). Can iterate to include additional metadata later.
- Alternatives considered: include size or changelog snippet. Defer to later iterations if needed.

## Notes
- Implementation plan will add three workflow steps to `.github/workflows/build.yml` (pre-push digest fetch, compare, conditional notification).
- Use `umahmood/pushover-actions` for sending notifications (existing marketplace action).