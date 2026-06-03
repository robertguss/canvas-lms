# Backup Restore Readiness

## Scope

This runbook defines Fly.io-hosted backup restore readiness for the WTS Phoenix LMS pilot. It covers Fly.io app restore coordination, managed Postgres, S3-compatible storage, email operational evidence, Oban job state, logs, monitoring evidence, and archive fallback coordination. It does not claim production readiness while real sanitized active-course samples remain unresolved blockers.

## Recovery Objectives

| Data area | Backup source | RPO target | RTO target | Notes |
| --- | --- | --- | --- | --- |
| Managed Postgres | Fly Postgres or selected managed Postgres automated backups plus point-in-time recovery or documented recovery equivalent | 15 minutes or better for pilot data | 4 hours for staging restore proof | Real Ecto/Postgres Repo exists; restore proof must validate applied SQL state. |
| S3-compatible storage | object versioning, snapshots, or immutable replicas | 15 minutes or better for pilot files | 4 hours for selected course file restore | Must include file checksum and byte-size verification. |
| Oban queues | database-backed job state and operational runbook | Same as database RPO | 1 hour to resume or safely discard retryable jobs | Jobs must be classified before replay. |
| Email evidence | Postmark delivery, bounce, complaint, suppression, and webhook event logs plus app notification records | 1 hour | 4 hours to reconstruct delivery status | Postmark selected for pilot; evidence stores sanitized identifiers only. |
| Logs and audit | centralized log sink and audit event store | 15 minutes for audit events | 4 hours for incident reconstruction | FERPA-sensitive contents must not be logged. |
| Canvas/archive fallback | hosted Canvas or export archive access | Not owned by Phoenix | Same business day access confirmation | Used when rollback/fallback triggers fire. |

## Backup Requirements

- Managed Postgres backups must be encrypted, automated, monitored, and restorable into an isolated non-production environment.
- S3-compatible storage must provide private bucket recovery through object versioning, immutable snapshots, provider snapshots, or documented equivalent controls.
- Backup jobs and retention checks must emit monitoring metrics for last success time, duration, failure count, and storage scope.
- Backup access must use least-privilege operator roles with auditable access records.
- Backup records must never contain plaintext secrets, credential-bearing tokens, SAML assertions, signing key material, or full protected student content beyond the encrypted backup payload itself.
- Backup restore evidence must be refreshed before pilot launch and after material schema, storage, or provider changes.

## Restore Drill Prerequisites

- Fly.io hosting is selected for the pilot; restore tooling must account for Fly apps, Fly Machines, `fly.toml` release configuration, Fly secrets references, private networking where applicable, and Fly.io provider escalation placeholders.
- Postmark email evidence restore prerequisites include a transactional Message Stream placeholder, API token secret reference, webhook signing secret reference, sender-domain verification evidence, and an event-retention/export path that can be reviewed without secret values or protected message contents.
- A staging environment exists with isolated secrets and no production public traffic.
- A Fly Postgres or selected managed Postgres restore target exists and can be created without overwriting production.
- An S3-compatible restore target bucket or prefix exists for non-sensitive drill artifacts.
- A representative sanitized pilot-course fixture exists. Current blocker: no real sanitized active-course sample has been committed yet, so the first drill may use sanitized contract fixtures only and must not be counted as final pilot evidence.
- A real Ecto Repo/adapter exists, so database restore steps must validate applied SQL state, migrations, and low-impact health checks against the restored target.

## Scripted Restore Drill

Record every command, timestamp, operator, source backup identifier, target Fly.io app placeholder, target environment, artifact hash, and pass/fail result in `.omo/evidence/` or the selected provider evidence store. Do not record secret values, private app names, private URLs, or production hostnames.

1. Announce the restore drill window to the incident commander, technical lead, privacy officer, and pilot lead.
2. Freeze non-essential staging writes and record the current Fly.io release identifier, Fly app placeholders, Fly Machines sizing/count, and `fly.toml` revision.
3. Select the latest Fly Postgres or selected managed Postgres backup or point-in-time restore point that satisfies the RPO target.
4. Restore managed Postgres into an isolated staging database target.
5. Apply any required application migrations to the restored database target using the same release artifact expected for pilot.
6. Select the matching S3-compatible storage snapshot, version set, or object backup for the same restore point.
7. Restore course files, submission attachments, and sentinel health check objects into the staging restore bucket or prefix.
8. Repoint staging Fly secrets or equivalent secret references to the restored managed Postgres target and restored S3-compatible storage target.
9. Deploy or start the Phoenix API, React web application, and Oban supervisors on staging Fly apps with Postmark email sending disabled, sandboxed, or limited to non-sensitive probes.
10. Run Fly.io release health checks and application probes for web, API, managed Postgres, S3, Postmark reachability or sandbox mode, Postmark webhook ingestion, Oban queues, auth callback observability, and archive fallback availability.
11. Run migration diff or contract validation against the sanitized pilot fixture, including legacy Canvas ID mappings.
12. Verify restored files by checksum, byte size, private access control, and expected course/assignment/submission association.
13. Inspect Oban queue state and classify jobs as safe to retry, safe to discard, or requiring manual reconciliation.
14. Verify email notification records and Postmark delivery, bounce, complaint, suppression, and webhook event logs can reconstruct delivery status without sending protected content.
15. Verify logs and audit events contain correlation IDs and reason codes while omitting passwords, SAML assertions, secrets, credential-bearing tokens, full file contents, full submission bodies, and unnecessary grade details.
16. Execute a rollback/fallback decision check: confirm affected courses can return to hosted Canvas or read-only archive access if the restored Phoenix environment is not accepted.
17. Record restore start time, restore finish time, data restore point timestamp, measured RPO, measured RTO, restored artifact list, and operator notes.
18. Revoke temporary drill access, destroy or lock the restored staging targets according to retention rules, and archive evidence.

## Postmark Email Evidence Restore

Postmark evidence supports notification reconstruction only; it is not a backup location for protected educational content. Restore drills must prove the application can reconcile restored notification records with Postmark event exports or dashboard evidence while preserving FERPA-safe evidence rules.

- Capture sanitized Postmark delivery event samples with event type, timestamp, Message Stream placeholder, correlation ID, and internal notification ID.
- Capture bounce, complaint, suppression, and webhook ingestion evidence using sanitized recipient references only; do not store real recipient addresses in committed evidence.
- Confirm restored app records can show whether a notification was accepted, delivered, bounced, complained, suppressed, retried, or paused without relying on full message bodies.
- Confirm suppression review after restore uses least-privilege operator access and records only the reason code, reviewer, timestamp, sanitized recipient reference, and outcome.
- Confirm rate-control state after restore keeps notification jobs paused until Postmark reachability, webhook ingestion, and delivery log reconciliation pass.
- Evidence must omit API tokens, webhook secret values, Postmark account identifiers, private URLs, full message bodies, grade details, submission text, and other protected records.

## Expected Restore Artifacts

- Restore drill report with operator, date, source restore point, target environment, release identifier, and measured RPO/RTO.
- Fly Postgres or selected managed Postgres restore evidence showing successful target creation, private-network or service attachment where applicable, and application health check.
- S3-compatible storage restore evidence showing restored object list, byte sizes, checksums, and private ACL or equivalent access control.
- Oban queue inspection output showing queue depth, failed jobs, stale jobs, and replay/discard decisions.
- Monitoring dashboard screenshot or exported report showing green Fly.io release checks plus health check probes for web, API, managed Postgres, S3, Postmark delivery/webhook ingestion, Oban, auth callback, and archive fallback.
- Log and audit sampling report showing correlation IDs and reason codes with no FERPA-sensitive leakage.
- Rollback/fallback checklist showing whether hosted Canvas/archive access was verified.

## Pass Criteria

The restore drill passes only when all criteria are true:

- Measured RPO is within the target for managed Postgres, S3-compatible storage, audit events, and Postmark email evidence.
- Measured RTO is within the target for managed Postgres restore, S3 object restore, application health check recovery, and incident reconstruction.
- Web, API, managed Postgres, S3, Postmark, Oban, auth callback, monitoring, and archive fallback health check probes pass in the restored staging environment.
- Restored course records, legacy Canvas ID mappings, required files, submission attachments, comments, grades, and notification records match the sanitized fixture expectations.
- No protected educational records appear in logs beyond approved identifiers, correlation IDs, and reason codes.
- Oban jobs are either safely replayed, safely discarded, or documented for manual reconciliation.
- Rollback/fallback coordination confirms affected pilot users can return to hosted Canvas or read-only archive access if needed.

## Fail Criteria And Escalation

The restore drill fails if any criterion is true:

- RPO or RTO misses the target without an approved exception.
- Fly Postgres or selected managed Postgres cannot be restored into an isolated target.
- S3-compatible storage objects cannot be restored with matching checksums and byte sizes.
- Health check probes fail for web, API, database, object storage, Postmark delivery/webhook ingestion, Oban, auth callback, monitoring, or archive fallback.
- Logs expose passwords, SAML assertions, secrets, credential-bearing tokens, full file contents, full submission bodies, or unnecessary grade details.
- Oban job state cannot be classified for replay, discard, or manual reconciliation.
- Hosted Canvas/archive fallback cannot be confirmed for affected pilot courses.

Failure escalation:

1. Open a severity 2 incident if the failure affects only staging readiness; open severity 1 if the failure affects live pilot data or blocks access during pilot.
2. Assign a technical lead for database/storage recovery, an incident commander for coordination, and a privacy officer for FERPA review.
3. Pause pilot launch or initiate Fly.io rollback/fallback for affected courses until restore evidence passes.
4. Record the failure, root cause, corrective action, owner, and next drill date in the readiness evidence store and notepad problems log.
