# tasks.md

Feature: Pushover notification when daily build produces a new image
Spec: ./spec.md
Plan: ./plan.md

Summary
-------
This task list implements the minimal, independently testable feature: detect when the daily `build.yml` publishes a *new* image (digest changed) and send a concise Pushover notification. Tasks are organized by user story and numbered sequentially (T001...). Tasks marked [P] are parallelizable.

Totals
- Total tasks: 18
- Tasks by story: US1 (P1): 9 tasks, US2 (P2): 3 tasks, US3 (P3): 2 tasks, Setup/Foundational/Polish: 4 tasks
- Parallel opportunities: CI config edits, docs, and secret management tasks can be done in parallel where noted.

Phase 1 — Setup (project initialization)
----------------------------------------
T001 - [Setup] Add repository secrets for Pushover (parallel) [P]
- Action: In GitHub repo settings add two repository secrets: `PUSHOVER_TOKEN` and `PUSHOVER_USER`.
- Acceptance: Secrets present in repo settings; values masked; confirm via UI.

T002 - [Setup] Add optional debug/test secret (parallel) [P]
- Action: Add a secondary test secret (e.g., `PUSHOVER_TEST_USER`) if you want to send test messages to a different account during validation.
- Acceptance: Test secret present (optional).

T003 - [Setup] Prepare a disposable test tag and workflow_dispatch test plan [P]
- Action: Create a short test plan document in `specs/002-implement-pushover-notification/quickstart.md` (already created) and decide a disposable tag to use in test runs.
- Acceptance: `quickstart.md` reviewed and test tag chosen.

Phase 2 — Foundational tasks (blocking prerequisites)
-----------------------------------------------------
T004 - [Foundational] Backup current `build.yml` and identify insertion points (sequential)
- Action: Create a branch (already done) and copy `.github/workflows/build.yml` to a safe location or note line numbers. Identify the `Login to GitHub Container Registry` step and `Push To GHCR` step (id: `push`) — these are anchors for inserting new steps.
- Files: `.github/workflows/build.yml`
- Acceptance: Patch plan contains exact insertion points and step ids.

T005 - [Foundational] Confirm GHCR manifest access using `GITHUB_TOKEN` (sequential)
- Action: Run a quick artifact/manifest curl request or `skopeo inspect` on the runner to verify `secrets.GITHUB_TOKEN` can read manifests for the repo's GHCR package.
- If permission issues arise, document the fallback (use PAT with packages:read) in `quickstart.md`.
- Acceptance: A successful manifest HEAD returns `Docker-Content-Digest` or documented fallback is recorded.

User Story US1 (P1) — Receive notification when daily build publishes a new image
-------------------------------------------------------------------------------
User goal: Maintain a low-effort monitoring flow by getting a push when the daily workflow publishes a new image.

Independent test criteria (manual): Run the workflow on `main` with a test tag that results in a pushed digest different than the current `latest`. Observe a single Pushover notification reaching configured devices within 5 minutes.

T006 - [US1] Add pre-push digest fetch step to `build.yml` (sequential)
- Action: Insert a new step BEFORE the `Push To GHCR` step to request the manifest HEAD for the canonical tag (default `latest`) and write `prev_digest` to `$GITHUB_OUTPUT`.
- Implementation hint: use curl with Accept: manifest.v2 and `Authorization: Bearer ${{ secrets.GITHUB_TOKEN }}`. Save output as step id `prev-digest` with `prev_digest` output.
- Files: `.github/workflows/build.yml`
- Acceptance: `steps.prev-digest.outputs.prev_digest` is set after the step (value may be empty if no previous tag exists).
- Status: ✅ Implemented

T007 - [US1] Compare pushed digest to previous digest (sequential)
- Action: Insert a new step AFTER the `Push To GHCR` (`id: push`) step. This step reads `NEW_DIGEST=${{ steps.push.outputs.digest }}` and `PREV_DIGEST=${{ steps.prev-digest.outputs.prev_digest }}` and sets `is_new` output to `true` or `false`.
- Implementation hint: write outputs to `$GITHUB_OUTPUT` and exit 0 for both paths (do not fail the job on `is_new=false`).
- Files: `.github/workflows/build.yml`
- Acceptance: `steps.check-new.outputs.is_new` equals `true` when digests differ or previous digest empty; equals `false` when equal.
- Status: ✅ Implemented

T008 - [US1] Add conditional Pushover notification step (sequential)
- Action: Insert a conditional step that runs only if `steps.check-new.outputs.is_new == 'true'`. Use `umahmood/pushover-actions@main` with env `PUSHOVER_TOKEN` and `PUSHOVER_USER` (repo secrets) and with minimal payload: title, message, url.
- Files: `.github/workflows/build.yml`
- Acceptance: Notification action runs only when `is_new=true` and returns success; verify delivery on test devices.
- Status: ✅ Implemented

T009 - [US1] Add lightweight retry for notification (parallel)
- Action: Wrap the notification call in a small retry loop (2 attempts) or use the action within a try/catch style step to retry on transient failures.
- Files: `.github/workflows/build.yml`
- Acceptance: On a transient HTTP failure (simulate by temporarily breaking token), the step retries once and logs retry attempt.
-- Status: ⛔ Skipped (out of scope)

T010 - [US1] Add logging and human-readable failure messages (parallel)
- Action: Ensure the compare step logs both digests and, on notification failure, prints a concise reason (do not leak secrets). Update quickstart troubleshooting notes.
- Acceptance: Logs contain `prev_digest=...` and `new_digest=...` and a readable failure note if notification fails.
- Status: ✅ Implemented

T011 - [US1] Add throttle safeguard (parallel)
- Action: Add a simple throttling policy (MVP: rely on Pushover limits and do not send duplicate notifications within X minutes) — for now, document throttle policy in `quickstart.md` and, optionally, add a short check that prevents notification if a recent notification is recorded in Actions artifacts (optional enhancement).
- Acceptance: Throttle policy documented in `quickstart.md` (optional runtime implementation deferred)
-- Status: ⛔ Skipped (out of scope)

User Story US2 (P2) — Configure notification recipients and opt-in
-------------------------------------------------------------
User goal: Allow maintainers to enable/disable notifications and avoid noise.

Independent test criteria: Disable notifications via config, run a publish that would otherwise trigger notification, confirm no notification is sent.

T012 - [US2] Add repository-level enable/disable flag documentation & default behavior (parallel) [P]
- Action: Document in `quickstart.md` how to disable notifications (MVP: remove secrets or set a repo secret `PUSHOVER_ENABLED=false`), and the default state (enabled if secrets exist).
- Files: `specs/002-implement-pushover-notification/quickstart.md`
- Acceptance: Docs updated; test procedure described.

T013 - [US2] Implement conditional guard for notifications based on secret or env var (sequential)
- Action: Modify the conditional on the notification step to also require `env.PUSHOVER_ENABLED != 'false'` or presence of secrets. If `PUSHOVER_ENABLED` is explicitly `false`, skip notification.
- Files: `.github/workflows/build.yml`
- Acceptance: Setting `PUSHOVER_ENABLED=false` prevents the notification step from running even when `is_new=true`.

T014 - [US2] Document recipient management (parallel) [P]
- Action: In `quickstart.md` and README/AGENTS.md explain that recipients are managed inside the Pushover account (devices registered to the app/user key) and that repository stores only the app/user token.
- Files: `quickstart.md`, `README.md`, `AGENTS.md`
- Acceptance: Documentation updated with instructions and link to Pushover account management.

User Story US3 (P3) — Notification content and severity
-----------------------------------------------------
User goal: Provide concise, actionable content in notifications and make high-severity changes triaged.

Independent test criteria: For a designated high-severity change, the notification payload indicates high priority and includes link; for normal publishes, minimal payload is used.

T015 - [US3] Use minimal payload: title, digest, link (sequential)
- Action: Ensure the notification `message` contains only the tag and digest and `url` points to relevant metadata. Use `title` like "New image published: <tag>".
- Files: `.github/workflows/build.yml`
-- Acceptance: Notification content exactly matches contract `contracts/notification.json`.
-- Status: ✅ Implemented

T016 - [US3] Add high-priority flag support (parallel)
- Action: Provide a mechanism (optional parameter or metadata rule) to mark a publish as high priority (e.g., environment variable or a tag pattern). If detected, set `priority` input to the pushover action.
- Files: `.github/workflows/build.yml`
-- Acceptance: Simulate a high-priority condition and observe the notification's priority flag.
-- Status: ✅ Implemented

Final Phase — Polish & Cross-Cutting Concerns
---------------------------------------------
T017 - [Polish] Update README and AGENTS.md with instructions and change log (parallel) [P]
- Action: Add a short section documenting the notification feature, secrets, and testing steps.
- Files: `README.md`, `AGENTS.md`
- Acceptance: Documentation updated and reviewed.

T018 - [Polish] Validate CI YAML and run one full test via `workflow_dispatch` (sequential)
- Action: Commit the workflow changes to `002-implement-pushover-notification`, push branch, run `workflow_dispatch` with a test tag, and verify behavior end-to-end.
- Acceptance: Workflow completes; notifications delivered when expected; check logs for clarity.

Dependencies & Execution Order (graph)
-------------------------------------
- Setup tasks (T001-T003) can run in parallel. Foundational tasks (T004-T005) must complete before US1 tasks execute.
- T004 -> T005 -> {T006, T007, T008, T009, T010, T011} -> T018
- US2 tasks depend on either T006/T007 outcome for testing but can be prepared in parallel (T012, T014). T013 (guard) is sequential with US1 implementation.
- US3 tasks (T015, T016) depend on US1 implementation but can be tested independently after T008.

Parallel execution examples
---------------------------
- Example A (fast path): T001, T002, T003, T012, T014 run in parallel. While those run, a single engineer completes T004 and T005. Once T004/T005 done, T006->T007->T008 run to validate behavior.
- Example B (two-person): Person A implements the pre-push and compare steps (T006, T007). Person B implements the notification step and retry (T008, T009). Both coordinate on insertion points (T004) and then run T018.

Implementation strategy
-----------------------
- MVP first: Implement US1 fully (T006-T011) and ensure independent test passes. Then add US2 opt-in/guard (T012-T014) and finally US3 enhancements (T015-T016). Polish docs and tests last (T017-T018).

Notes
-----
- Tests: The spec defined acceptance scenarios; we included independent test criteria but did not enforce TDD. If you want TDD, I will add pre-implementation test tasks.
- Files to be edited: `.github/workflows/build.yml`, `README.md`, `AGENTS.md`, `specs/.../quickstart.md` (already present), and `specs/.../contracts/notification.json` (already present).
