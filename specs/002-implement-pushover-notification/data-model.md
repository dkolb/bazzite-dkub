# data-model.md

Entities for Pushover notification feature

## Image
- Represents a published container image.
- Fields:
  - tag: string (e.g., `latest`, `40-YYYYMMDD`)
  - digest: string (sha256 digest)
  - registry_url: string (e.g., `ghcr.io/dkolb/bazzite-dkub`)
  - published_at: timestamp (optional)

## NotificationConfig
- Repository-level notification settings.
- Fields:
  - enabled: boolean
  - recipients: list (MVP: resolved to single Pushover account; stored as app/user token in secrets)
  - priority_rules: optional (e.g., high-priority when metadata indicates)
  - throttle_minutes: integer (default 10)

## Notification
- Represents a single notification attempt.
- Fields:
  - recipient: string
  - timestamp: datetime
  - payload_summary: string
  - status: enum(sent, failed)
  - attempts: integer

# Validation rules
- digest must be a valid sha256: `sha256:[0-9a-f]{64}`
- tag must be non-empty

# Relationships
- Image -> Notification: one-to-many (multiple notifications could be sent for different recipients or retries)