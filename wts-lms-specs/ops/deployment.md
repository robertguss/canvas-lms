# Managed Cloud Deployment Readiness

## Scope

This runbook defines the provider-neutral managed-cloud baseline for the WTS Phoenix LMS pilot. It supports Core Coursework only for Student, Teacher, and Admin workflows. It does not select a hosting vendor, managed Postgres vendor, object storage vendor, or email vendor.

## Provider Decision Gates

- DECISION NEEDED: hosting provider must be selected before production provisioning. The provider must support managed application hosting, managed Postgres, private networking or equivalent service isolation, managed TLS, autoscaling or documented capacity controls, centralized logs, metrics, alerting, and restore access.
- DECISION NEEDED: email provider must be selected before production notification testing. The provider must support authenticated sending, bounce and complaint reporting, delivery event logs, suppression handling, rate controls, and FERPA-safe operational visibility.
- DECISION NEEDED: managed Postgres provider can be the same hosting provider or a separate managed database provider, but it must meet the backup, point-in-time recovery, encryption, access-control, and restore-drill requirements in `backup_restore.md`.
- DECISION NEEDED: S3-compatible object storage provider can be the same hosting provider or a separate object storage provider, but it must support private buckets, object versioning or immutable snapshots, lifecycle policy controls, server-side encryption, access logs, and restore evidence.

## Managed Cloud Requirements

- Runtime: deploy the Phoenix API and React web application as managed services with separate build and runtime stages.
- Network: expose only public web/API entrypoints, health check endpoints, and provider-required TLS termination; restrict database, object storage, queue, and admin interfaces to service identities or private access paths.
- TLS: terminate TLS through the selected provider using managed certificates and automated renewal.
- Capacity: define pilot capacity limits for 2-3 real courses, including concurrent users, request latency, file-transfer size, Oban queue depth, and database connection pool sizing.
- Environments: maintain separate development, staging, and production environments. Staging must be able to run restore drills without using production secrets or exposing protected student records.
- Old Canvas/archive fallback: keep the hosted Canvas or export archive read-only fallback available for affected pilot courses until the pilot success criteria are met and rollback triggers are cleared.

## Environment Configuration And Secrets

Required environment variables must be provided by the selected provider secret manager or an equivalent managed secret store. Do not commit values, tokens, private URLs, or passwords.

| Area | Required configuration | Readiness gate |
| --- | --- | --- |
| Application | runtime environment, public base URL, release identifier | Deployment records include version and environment. |
| Database | managed Postgres connection reference, pool size, migration mode | Connection uses service identity or secret reference, not inline credentials. |
| Object storage | S3-compatible endpoint reference, bucket names, region/zone, upload size limit | Buckets are private and object recovery is tested. |
| Email | provider account reference, sender domain, webhook secret reference | DECISION NEEDED: email provider gate resolved before pilot email testing. |
| Auth | Populi SAML metadata reference, callback URL, certificate reference | Auth callback health check and auth failure metrics are visible. |
| Jobs | Oban queue names, concurrency, retry limits | Queue depth and job failure alerts are configured. |
| Logging | correlation ID header, reason-code taxonomy, log sink reference | Logs omit FERPA-sensitive content and include operational traceability. |

## Managed Postgres Readiness

- Managed Postgres is a future required deployment dependency because `wts-lms-api` currently has no real Ecto Repo or SQL adapter.
- The selected provider must support encryption at rest, encrypted connections, least-privilege service credentials, automated backups, point-in-time recovery, restore into a non-production environment, and auditable admin access.
- Migration execution must be a controlled release step with preflight backup confirmation and post-migration health check verification.
- Database logs and query diagnostics must not expose passwords, SAML assertions, access tokens, full submission bodies, or unnecessary grade details.

## S3-Compatible Storage Readiness

- Store course files, submission attachments, and imported Canvas file payloads in private S3-compatible storage.
- Use path conventions that preserve legacy Canvas ID mappings without exposing identities in public URLs.
- Require server-side encryption, bucket access logging, object versioning or immutable snapshots, and documented lifecycle retention.
- File retrieval and upload paths must emit correlation IDs and reason codes without logging full file contents.
- Migration readiness is not complete until real sanitized active-course samples prove file byte acquisition and checksum validation.

## Email Provider Readiness

- DECISION NEEDED: email provider must remain unresolved until WTS approves a provider.
- The selected provider must support transactional notification delivery, delivery event logs, bounce and complaint handling, suppression list review, SPF/DKIM/DMARC alignment, and rate limits suitable for the pilot.
- Email health check coverage must verify provider reachability and delivery-event ingestion without sending protected educational records in test messages.
- Operational logs may record recipient identifiers only when necessary for support and must avoid full message bodies, grade details, submission text, or secret tokens.

## Oban Queue Readiness

| Queue | Purpose | Required monitoring | Failure action |
| --- | --- | --- | --- |
| `migration` | import and diff pilot course data | queue depth, job age, retry count, failed jobs | stop launch if required records or files are missing |
| `notifications` | email and in-app notification delivery | provider response, bounce event lag, retry count | pause sends and escalate if email provider health fails |
| `sis_sync` | SIS/Registrar mirror updates | sync duration, add/drop propagation lag, conflicts | block launch if unresolved session/SIS decisions affect access |
| `audit` | audit event persistence and export | write failures, lag, dropped events | treat dropped FERPA audit events as incident response input |
| `maintenance` | backups, retention checks, health probes | last successful run, duration, failure count | escalate if backup restore evidence becomes stale |

## Health Check Requirements

Each health check must be safe to expose to authenticated operators or provider probes and must not leak protected records.

- Web health check: confirms static assets and runtime release identifier are available.
- API health check: confirms API process readiness, dependency status aggregation, and correlation ID propagation.
- Database health check: confirms managed Postgres connectivity with a low-impact query after real Repo/adapter implementation exists.
- S3 health check: confirms S3-compatible storage list/read/write probe against a non-sensitive sentinel object.
- Email health check: confirms provider API reachability and event webhook processing with non-sensitive test identifiers.
- Oban health check: confirms queue supervision, queue depth thresholds, retry pressure, and stale job detection.
- Auth callback health check: confirms Populi SAML metadata availability and callback route observability without accepting fake assertions as real login.
- Archive fallback health check: confirms hosted Canvas or export archive access path remains available for rollback/fallback coordination.

## Logging And Monitoring

Monitoring must cover availability, error rate, latency, managed Postgres health, S3-compatible storage failures, email failures, Oban queue failures, auth callback failures, backup freshness, and restore drill freshness.

Required logs and metrics:

- Correlation ID for every external request, background job, storage action, email action, auth callback, and migration import batch.
- Operational reason codes for admin access, migration changes, grade changes, enrollment changes, file access, and incident response actions.
- Availability and latency SLO dashboards for web, API, database, storage, email, auth, and Oban queues.
- Alerts for elevated error rate, failed auth callbacks, email delivery failures, storage read/write failures, backup failures, restore drill overdue, queue depth threshold breach, and audit event write failures.
- FERPA logging constraints from `privacy_accessibility.md`: no passwords, SAML assertions, secrets, access tokens, full file contents, full submission bodies, or unnecessary grade details.

## Release And Rollback Gates

Before pilot launch:

1. Confirm provider gates are resolved or explicitly recorded as blocking decisions.
2. Confirm current release artifact, environment variables, and secret references are recorded without secret values.
3. Confirm managed Postgres, S3-compatible storage, email, Oban, auth callback, logs, monitoring, and health check dashboards pass staging checks.
4. Confirm `backup_restore.md` restore drill has current pass evidence.
5. Confirm `incident_response.md` escalation contacts, severity levels, privacy constraints, and rollback/fallback decision steps are current.
6. Confirm hosted Canvas or export archive fallback remains available for affected pilot courses.

Rollback or fallback is triggered by any blocking migration mismatch, grade discrepancy, authorization error, missing file, broken submission workflow, failed restore rehearsal, FERPA-significant data exposure, critical accessibility violation, or inability to revoke disabled-user access.
