# Managed Cloud Deployment Readiness

## Scope

This runbook defines the Fly.io managed-cloud baseline for the WTS Phoenix LMS pilot. It supports Core Coursework only for Student, Teacher, and Admin workflows. Fly.io is the selected pilot hosting provider; object storage and email provider decisions remain separate readiness gates.

## Provider Decision Gates

- Hosting provider selected for pilot: Fly.io. Provision Phoenix API and React web runtime as Fly apps backed by Fly Machines, with `fly.toml` definitions, managed TLS, documented VM size/count settings, release health checks, deployment evidence, rollback commands, and Fly.io provider escalation placeholders recorded before launch.
- DECISION NEEDED: email provider must be selected before production notification testing. The provider must support authenticated sending, bounce and complaint reporting, delivery event logs, suppression handling, rate controls, and FERPA-safe operational visibility.
- Managed Postgres readiness path: use Fly Postgres as the pilot candidate when it satisfies backup, point-in-time recovery, encryption, access-control, private-networking, and restore-drill requirements in `backup_restore.md`; otherwise record the exception and selected managed Postgres alternative before launch.
- DECISION NEEDED: S3-compatible object storage provider can be the same hosting provider or a separate object storage provider, but it must support private buckets, object versioning or immutable snapshots, lifecycle policy controls, server-side encryption, access logs, and restore evidence.

## Managed Cloud Requirements

- Runtime: deploy the Phoenix API and React web application as Fly.io apps with separate build and runtime stages and Fly Machines capacity settings documented per environment.
- Network: expose only public web/API entrypoints, health check endpoints, and Fly.io-managed TLS termination; restrict database, queue, and admin interfaces to Fly private networking or equivalent service identities/private access paths. Keep S3-compatible storage private through the selected storage provider controls.
- TLS: terminate TLS through Fly.io-managed certificates and automated renewal for public Fly apps.
- Capacity: define pilot capacity limits for 2-3 real courses, including concurrent users, request latency, file-transfer size, Oban queue depth, and database connection pool sizing.
- Environments: maintain separate development, staging, and production environments. Staging must be able to run restore drills without using production secrets or exposing protected student records.
- Old Canvas/archive fallback: keep the hosted Canvas or export archive read-only fallback available for affected pilot courses until the pilot success criteria are met and rollback triggers are cleared.

## Environment Configuration And Secrets

Required environment variables must be provided through Fly secrets or an equivalent managed secret store. Do not commit values, tokens, private URLs, app-private hostnames, or passwords.

| Area | Required configuration | Readiness gate |
| --- | --- | --- |
| Application | runtime environment, public base URL placeholder, release identifier, Fly app placeholder names, `fly.toml` path | Fly deployment records include version, environment, app name placeholder, Machine count/size, and release command evidence. |
| Database | Fly Postgres or selected managed Postgres connection reference, pool size, migration mode | Connection uses Fly secrets, service identity, or secret reference, not inline credentials. |
| Object storage | S3-compatible endpoint reference, bucket name placeholders, region/zone, upload size limit | Buckets are private and object recovery is tested; provider selection remains separate from Fly.io hosting. |
| Email | provider account reference, sender domain, webhook secret reference | DECISION NEEDED: email provider gate resolved before pilot email testing; store runtime references in Fly secrets or equivalent. |
| Auth | Populi SAML metadata reference, callback URL, certificate reference | Auth callback health check and auth failure metrics are visible. |
| Jobs | Oban queue names, concurrency, retry limits | Queue depth and job failure alerts are configured. |
| Logging | correlation ID header, reason-code taxonomy, log sink reference | Logs omit FERPA-sensitive content and include operational traceability. |

## Managed Postgres Readiness

- `wts-lms-api` now includes a real Ecto/Postgres Repo, so deployment readiness must validate real SQL migrations, connection pool sizing, and database health checks against managed Postgres.
- Fly Postgres is the pilot managed Postgres candidate alongside the selected Fly.io hosting path. It must support encryption at rest, encrypted connections, least-privilege service credentials, automated backups, point-in-time recovery or documented recovery equivalent, restore into a non-production environment, private-network attachment where applicable, and auditable admin access.
- Migration execution must be a controlled release step with preflight backup confirmation and post-migration health check verification.
- Database logs and query diagnostics must not expose passwords, SAML assertions, credential-bearing tokens, full submission bodies, or unnecessary grade details.

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
- API health check: confirms API process readiness, dependency status aggregation, correlation ID propagation, and Fly.io release health check compatibility.
- Database health check: confirms managed Postgres connectivity with a low-impact query through the real Ecto Repo.
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
- FERPA logging constraints from `privacy_accessibility.md`: no passwords, SAML assertions, secrets, credential-bearing tokens, full file contents, full submission bodies, or unnecessary grade details.

## Release And Rollback Gates

Before pilot launch:

1. Confirm Fly.io hosting is provisioned with safe placeholder records for app names, `fly.toml` files, Machines sizing/count, release commands, private-network dependencies, deploy evidence, rollback commands, and provider escalation contacts.
2. Confirm unresolved non-hosting provider gates, including email and S3-compatible storage, are resolved or explicitly recorded as blocking decisions.
3. Confirm current release artifact, environment variables, Fly secrets references, and secret references are recorded without secret values.
4. Confirm managed Postgres, S3-compatible storage, email, Oban, auth callback, logs, monitoring, and health check dashboards pass staging checks.
5. Confirm `backup_restore.md` restore drill has current pass evidence.
6. Confirm `incident_response.md` escalation contacts, severity levels, privacy constraints, and rollback/fallback decision steps are current.
7. Confirm hosted Canvas or export archive fallback remains available for affected pilot courses.

Rollback or fallback is triggered by any blocking migration mismatch, grade discrepancy, authorization error, missing file, broken submission workflow, failed restore rehearsal, FERPA-significant data exposure, critical accessibility violation, or inability to revoke disabled-user access.

## Fly.io Configuration Placeholders

Safe readiness records may include placeholders only, never private app names, production URLs, tokens, or secret values.

| Item | Placeholder shape | Readiness evidence |
| --- | --- | --- |
| Fly app names | `<wts-lms-api-staging>`, `<wts-lms-web-staging>`, `<wts-lms-api-production>`, `<wts-lms-web-production>` | App inventory records map placeholders to real Fly.io apps in the private operator vault. |
| `fly.toml` | app placeholder, primary region placeholder, process definitions, HTTP service health check path, release command placeholder | Reviewed config is stored without secrets and matches deployed Fly apps. |
| Fly Machines | VM size/count placeholders per environment | Capacity review records pilot limits and scale/rollback thresholds. |
| Fly secrets | names only, such as `DATABASE_URL`, `SECRET_KEY_BASE`, `S3_ENDPOINT`, `S3_BUCKET`, `EMAIL_PROVIDER_API_KEY`, `POPULI_SAML_METADATA_URL` | Secret values are set through Fly secrets or equivalent and never committed. |
| Release command | `mix ecto.migrate` or approved release task placeholder | Deploy evidence shows migration result and post-release health checks. |
| Rollback command | previous Fly release/image rollback placeholder plus database restore decision gate | Rollback evidence includes command transcript with private values redacted. |
| Provider escalation | Fly.io support plan/contact placeholder and incident severity mapping | Incident response records show who may contact Fly.io and what evidence is safe to share. |
