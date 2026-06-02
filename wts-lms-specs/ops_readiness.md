# Operations Readiness Spec

## Scope

Operations readiness defines the managed-cloud baseline required before pilot launch. Task 13 will expand this into runbooks under `wts-lms-specs/ops/`, but Task 1 freezes the required operational surface.

## Required Readiness Areas

| Area | Decision | Requirement |
| --- | --- | --- |
| Hosting | Simplify | Use managed cloud rather than self-hosted Canvas operational parity. |
| Health checks | Preserve | API, web, database, object storage, email, background jobs, and auth callback health must be observable. |
| Backups | Preserve | Database backups and S3-compatible object snapshots must support point-in-time recovery expectations for pilot data. |
| Restore drill | Preserve | A restore drill must be executed before pilot launch and recorded as evidence. |
| Monitoring | Preserve | Metrics and alerts must cover availability, error rate, latency, job failures, auth failures, storage failures, and email failures. |
| Logs | Preserve | Logs must include correlation IDs and operational reason codes without exposing FERPA-sensitive content. |
| Incident process | Preserve | Operators must have severity levels, escalation contacts, communication templates, and rollback/fallback decision steps. |
| Old Canvas/export archive | Preserve | Historical read-only access strategy must be available while Phoenix handles active Core Coursework. |
| Canvas ops parity | Exclude | Do not recreate Canvas deployment, plugin, or multi-tenant operational internals. |

## Pilot Gate

Pilot readiness fails if backup restore, monitoring, incident response, log privacy, S3 object recovery, email delivery, auth callback visibility, or archive fallback is unproven.
