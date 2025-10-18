# quickstart.md

Quickstart: enable Pushover notifications for daily image publish

1. Add repository secrets:
   - `PUSHOVER_TOKEN` — your Pushover application token
   - `PUSHOVER_USER` — your Pushover user key

2. Dispatch a test run:
   - Go to Actions > Build container image > Run workflow > `workflow_dispatch` and choose `main` branch.

3. Monitor the run:
   - If a new image was detected, you should receive a Pushover notification on registered devices.

4. Troubleshooting:
   - No notification: check `PUSHOVER_TOKEN` and `PUSHOVER_USER` values and confirm the `Check-new` step output `is_new=true`.
   - Permission errors when fetching registry manifest: ensure `GITHUB_TOKEN` has package read permissions or use a PAT with package scope for backfill.

5. Notes:
   - By default the canonical tag used for comparison is `latest`. You can change this to a different tag in the workflow if needed.