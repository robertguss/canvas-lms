# Incident Response Runbook

## Scope

This provider-neutral runbook defines incident response for WTS Phoenix LMS pilot operations. It covers managed-cloud availability, managed Postgres, S3-compatible storage, email, secrets, logs, monitoring, Oban queues, health check failures, backup restore failures, FERPA/privacy constraints, audit handling, and rollback/fallback coordination.

## Roles

| Role | Responsibility |
| --- | --- |
| Incident commander | Owns severity declaration, timeline, coordination, communications, and final incident closure. |
| Technical lead | Directs diagnosis and remediation for application, managed Postgres, S3-compatible storage, email, Oban, auth, or deployment failures. |
| Privacy officer | Reviews FERPA risk, protected-record exposure, audit/log access, and required notifications. |
| Pilot lead | Coordinates Student, Teacher, and Admin impact for the 2-3 pilot courses and decides instructional fallback timing with WTS leadership. |
| Communications lead | Sends approved status updates and internal notifications without exposing protected educational records. |
| Vendor liaison | Contacts the selected hosting provider or email provider after the DECISION NEEDED gates are resolved. |

DECISION NEEDED: hosting provider remains unresolved, so provider escalation paths must be filled in only after WTS approves a provider.
DECISION NEEDED: email provider remains unresolved, so delivery escalation paths must be filled in only after WTS approves a provider.

## Severity Levels

| Severity | Definition | Examples | Response target |
| --- | --- | --- | --- |
| SEV1 | Active pilot users cannot access required coursework, protected records are exposed, backup restore fails during live recovery, or rollback/fallback is required immediately. | Production outage, FERPA-significant log leak, missing submissions/files, failed restore during pilot. | Declare immediately, coordinate every 30 minutes until stable. |
| SEV2 | Major functionality is degraded or pilot launch readiness is blocked, but no active FERPA exposure or total outage is confirmed. | Managed Postgres degraded, S3 upload failures, email delivery outage, Oban queue backlog, monitoring blind spot, restore drill failure. | Triage within 1 hour, update at least every 2 hours. |
| SEV3 | Limited operational issue with workaround and no immediate pilot-blocking impact. | Single health check warning, non-critical alert noise, delayed non-essential notification, staging-only failure. | Triage same business day. |
| SEV4 | Informational issue or follow-up action. | Runbook improvement, dashboard tuning, provider documentation update. | Track in normal planning. |

## Incident Triggers

Declare an incident when any of these occur:

- Web or API health check failure affects pilot users.
- Managed Postgres connectivity, backup, point-in-time recovery, or migration execution fails.
- S3-compatible storage cannot read, write, or restore required files or submission attachments.
- Email provider delivery, event ingestion, bounce handling, or suppression handling fails for pilot notifications.
- Oban queue depth, stale job age, retry pressure, or failed jobs exceed thresholds.
- Auth callback visibility fails or disabled-user access cannot be revoked.
- Monitoring, logging, or audit event persistence is blind for a critical path.
- Restore drill or backup restore evidence fails pass criteria.
- FERPA-sensitive data appears in logs, metrics, emails, dashboards, support tickets, or evidence artifacts.
- Any rollback trigger or fallback trigger from `pilot_success_failure.md` is met.

## Response Procedure

1. Detect the alert through monitoring, health check dashboards, operator report, or pilot-user escalation.
2. Assign an incident commander and severity level.
3. Open an incident record with timestamp, correlation IDs, affected environment, release identifier, suspected service area, and current user impact.
4. Preserve evidence: logs, metrics, deployment records, Oban job state, managed Postgres status, S3 object status, email provider events, auth callback events, and backup restore records.
5. Apply FERPA handling before sharing evidence. Remove or avoid passwords, SAML assertions, secrets, access tokens, full file contents, full submission bodies, unnecessary grade details, and private URLs.
6. Decide whether immediate rollback/fallback is required using the criteria below.
7. Mitigate the incident with the least risky action: pause a queue, disable a notification path, roll back a release, restore from backup, switch affected courses to hosted Canvas/archive access, or involve the selected provider.
8. Communicate status using approved templates and avoid protected educational record details.
9. Continue monitoring until health check probes, metrics, and affected user workflows return to acceptable state.
10. Close only after root cause, corrective action, privacy review, rollback/fallback status, and follow-up owners are recorded.

## Privacy And Audit Constraints

- Treat grades, submissions, comments, enrollment status, course membership, identity mappings, files, and audit trails as protected educational records.
- Logs must not include passwords, SAML assertions, secrets, access tokens, full file contents, full submission bodies, or unnecessary grade details.
- Audit events must identify who accessed or changed protected records, when, from where, and why, using correlation IDs and reason codes.
- Incident evidence must be stored in the approved evidence location with least-privilege access.
- Operator access during incidents must be time-limited, reason-coded, and reviewed by the privacy officer when protected records may be involved.
- Communications must describe impact and actions without naming students, grades, submission content, or private course details unless explicitly approved through WTS privacy channels.

## Rollback And Fallback Coordination

Rollback or fallback is required when any condition is true:

- A blocking migration mismatch, grade discrepancy, authorization error, missing file, or broken submission workflow is confirmed.
- A restore rehearsal fails and pilot launch has not yet occurred.
- A backup restore fails during pilot recovery.
- A FERPA-significant data exposure is suspected or confirmed.
- A critical accessibility violation blocks a pilot workflow.
- Disabled-user access cannot be revoked promptly.
- Phoenix is unavailable and expected recovery misses the incident commander threshold for affected coursework.

Rollback/fallback steps:

1. Incident commander confirms affected courses, users, and workflows with the pilot lead.
2. Technical lead identifies the safest rollback point: previous release, restored managed Postgres point, restored S3-compatible object state, paused Oban queue, or disabled email path.
3. Privacy officer reviews whether rollback/fallback evidence contains protected records.
4. Pilot lead coordinates instructor and student communication for hosted Canvas or read-only archive fallback.
5. Technical lead executes rollback or restore and runs health check probes for web, API, managed Postgres, S3, email, Oban, auth callback, monitoring, and archive fallback.
6. Communications lead sends status update and expected next update time.
7. Incident commander records whether Phoenix remains paused, partially available, or fully restored.

## Communications Templates

Internal initial notice:

```
Severity: <SEV1|SEV2|SEV3|SEV4>
Impact: <course/workflow impact without protected educational record details>
Detected: <timestamp>
Current action: <mitigation or investigation step>
Fallback status: <hosted Canvas/archive available, pending, or not needed>
Next update: <timestamp>
```

Pilot-user notice:

```
We are investigating an LMS issue affecting <workflow>. Please use the instructed fallback path for affected coursework if your instructor or administrator directs you to do so. Do not resubmit work unless your instructor confirms it is needed. Next update: <timestamp>.
```

Closure notice:

```
The LMS incident affecting <workflow> is resolved. We verified health checks, monitoring, and required course workflows. Any affected fallback instructions are now <ended|continuing for listed course workflow>. Contact the pilot support channel if you still see issues.
```

## Post-Incident Review

Complete within five business days for SEV1/SEV2 and same planning cycle for SEV3/SEV4:

- Timeline from detection through closure.
- Root cause and contributing factors.
- Affected managed-cloud components: hosting, managed Postgres, S3-compatible storage, email, secrets, logs, monitoring, Oban queues, health checks, backup restore, auth callback, or archive fallback.
- FERPA/privacy assessment and audit/log handling review.
- Rollback/fallback decision and outcome.
- Corrective actions with owners and due dates.
- Runbook updates and monitoring threshold changes.
- Restore drill or tabletop follow-up if backup restore, object recovery, or incident coordination failed.
