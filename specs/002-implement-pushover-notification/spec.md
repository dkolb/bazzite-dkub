# Feature Specification: Pushover notification when daily build produces a new image

**Feature Branch**: `002-implement-pushover-notification`  
**Created**: 2025-10-18  
**Status**: Draft  
**Input**: User description: "Implement pushover notification when daily build workflow produces a new image"

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.
  
  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Deployed independently
  - Demonstrated to users independently
-->

### User Story 1 - Receive notification when daily build publishes a new image (Priority: P1)

As a repository maintainer I want to receive a short, actionable push notification when the daily image build publishes a new image so I don't need to check CI logs or the registry manually.

**Why this priority**: This dramatically reduces manual monitoring effort and lets maintainers react quickly to unexpected changes in published images.

**Independent Test**: Run the daily build workflow in two variants (one that results in a new image and one that does not). Observe whether a push notification is delivered only for the run that created a new image.

**Acceptance Scenarios**:

1. **Given** the daily build workflow completes and produces an image that did not exist previously, **When** the workflow finishes publishing the image, **Then** a push notification is sent to configured recipients containing the image tag, digest, and a link to the image metadata.
2. **Given** the daily build workflow completes but the published image already matches the previous latest (no new image), **When** the workflow finishes, **Then** no push notification is sent.
3. **Given** the notification service is unreachable or returns an error, **When** the workflow attempts to send a notification, **Then** the workflow records a clear, human-readable failure message in its logs and retries the notification at least once.

---

### User Story 2 - Configure notification recipients and opt-in (Priority: P2)

As a maintainer or project owner I want to control who receives notifications and to be able to enable or disable notifications so noise is limited to interested parties.

**Why this priority**: Prevents notification fatigue and makes the feature safe for projects with multiple maintainers.

**Independent Test**: Change the notification configuration to disable notifications, run the daily build that produces a new image, and confirm no notification is delivered. Then enable for a specific recipient and confirm delivery.

**Acceptance Scenarios**:

1. **Given** notifications are disabled in the repository's notification settings, **When** the daily workflow publishes a new image, **Then** no notification is sent.
2. **Given** notifications are enabled for a recipient, **When** the daily workflow publishes a new image, **Then** the recipient receives a single notification for that new image.

---

### User Story 3 - Notification content and severity (Priority: P3)

As a recipient I want the notification to include enough context to decide whether to investigate immediately (e.g., tag, short changelog or indicator, and link), and to mark high-risk changes with higher priority so I can triage quickly.

**Why this priority**: Improves signal-to-noise and enables faster triage when a break appears.

**Independent Test**: For an intentionally modified build that should be treated as high-priority (for example, a non-empty change in the build metadata), verify the notification includes a clear priority flag and the message content described in requirements.

**Acceptance Scenarios**:

1. **Given** a normal daily image publish, **When** a notification is sent, **Then** it contains image tag, short descriptor (e.g., "daily"), digest, and a link.
2. **Given** a publish that matches a configured high-severity condition, **When** a notification is sent, **Then** it is marked with a higher priority flag in the notification payload.

---

### Edge Cases

- Duplicate publishes (registry reports identical digest for multiple tags): system should treat identical digest as "no new image".
- Notification rate limiting by provider: system should avoid spamming notifications if multiple images publish in rapid succession (throttle to 1 notification per 10 minutes by default).
- Missing or invalid notification credentials: workflow should fail the notification step with clear guidance and not expose secrets in logs.
- Large payloads or very long messages: notifications should be truncated to a concise summary with a link to full details.

## Requirements *(mandatory)*

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right functional requirements.
-->


### Functional Requirements

- **FR-001**: The system MUST detect whether a completed daily build workflow produced a new image that was not previously published under the same repository/latest reference.
- **FR-002**: When a new image is detected, the system MUST send a single push notification to the configured recipients containing: image tag, short descriptor (e.g., "daily"), image digest, and a link to image metadata or release notes.
- **FR-003**: The system MUST NOT send a notification if the completed build published an image identical to the previously published image (same digest).
- **FR-004**: The system MUST record a succinct, human-readable log entry for the notification attempt including success/failure and the notification recipient(s) (without exposing sensitive credentials).
- **FR-005**: The system MUST allow notifications to be enabled or disabled at the repository level and allow recipient configuration.
- **FR-006**: The system MUST handle transient notification failures by retrying at least once and surfacing a clear error to maintainers if retries fail.


*Clarifications applied (per user choices):*

- **FR-CLAR-01 (Recipient model)**: Use a single Application/API token (a single Pushover application token) to deliver notifications to the user's configured devices. Implication: a single repo-level token is sufficient; recipients are the devices/users registered in that Pushover account.
- **FR-CLAR-02 (Secrets storage)**: Store the notification credentials in repository-level secrets (e.g., `PUSHOVER_API_TOKEN` in the repository's secrets). Implication: maintainers manage the token in repo settings; no org-level or external secret integrations are required for MVP.
- **FR-CLAR-03 (Notification content)**: Use the minimal payload for now: image tag, digest, and a link to image metadata. Implication: messages are concise and fit push limitations; we can iterate later to include size or changelog snippets if needed.

### Key Entities *(include if feature involves data)*

- **Image**: Represents a published container image. Key attributes: tag, digest, size (optional), published_at timestamp, registry URL.
- **NotificationConfig**: Represents repository-level configuration for notifications. Key attributes: enabled (bool), recipients (list), priority rules (optional), throttling policy.
- **Notification**: Represents a single notification attempt. Key attributes: recipient, timestamp, payload_summary, status (sent/failed), attempts.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Notifications for new images are delivered to configured recipients within 5 minutes of the workflow completing in at least 95% of successful publish events (measured over a 14-day rolling window).
- **SC-002**: No notifications are sent for non-new images (false positives = 0 in acceptance tests and <1% in production over a 30-day period).
- **SC-003**: When notification credentials are missing or invalid, the workflow reports a clear, human-readable error and does not expose secret values in logs; incidents are surfaced to maintainers.
- **SC-004**: Repository-level opt-out works: if notifications are disabled, zero notifications are delivered for new image publishes in that repository.

## Assumptions

- The "daily" workflow already publishes images and exposes enough metadata (tag and digest) for a post-run check.
- Recipients can be represented as a manageable identifier (token/user key) compatible with the chosen push service.
- Secrets used for notification are available via a secure secret store accessible to the workflow runner.

## Security and Privacy Considerations

- Notification credentials MUST never be logged or printed in plain text.
- Notification messages should avoid including sensitive details (use short summaries and links to secured pages when needed).
- Access to configure recipients or enable/disable notifications should be limited to repository maintainers or owners.

## Next Steps

1. Confirm answers to the three clarification questions below (recipients model, secrets storage, notification content details).
2. Implement a minimal workflow step that checks whether the published image digest differs from the previous published digest and emits a single notification when a new digest is found.
3. Add repository-level configuration (enable/disable + recipients) and tests that simulate publish and no-publish scenarios.
