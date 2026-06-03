# Operations Readiness Spec

## Scope

Operations readiness defines the managed-cloud baseline required before pilot launch. Task 13 will expand this into runbooks under `wts-lms-specs/ops/`, but Task 1 freezes the required operational surface.

## Required Readiness Areas

| Area | Decision | Requirement |
| --- | --- | --- |
| Hosting | Simplify | Use managed cloud rather than self-hosted Canvas operational parity. |
| Health checks | Preserve | API, web, database, object storage, Postmark email, background jobs, and auth callback health must be observable. |
| Backups | Preserve | Database backups and S3-compatible object snapshots must support point-in-time recovery expectations for pilot data. |
| Restore drill | Preserve | A restore drill must be executed before pilot launch and recorded as evidence. |
| Monitoring | Preserve | Metrics and alerts must cover availability, error rate, latency, job failures, auth failures, storage failures, Postmark delivery failures, bounce/complaint events, suppression review, webhook ingestion, and email rate controls. |
| Logs | Preserve | Logs must include correlation IDs and operational reason codes without exposing FERPA-sensitive content. |
| Incident process | Preserve | Operators must have severity levels, escalation contacts, communication templates, and rollback/fallback decision steps. |
| Old Canvas/export archive | Preserve | Historical read-only access strategy must be available while Phoenix handles active Core Coursework. |
| Canvas ops parity | Exclude | Do not recreate Canvas deployment, plugin, or multi-tenant operational internals. |

## Postmark Transactional Email Readiness

Postmark is the selected pilot transactional email provider. Readiness requires safe placeholders and operator evidence only:

- Secret references for Postmark API token, webhook signing secret, transactional Message Stream, sender domain, sender address, and reply-to address are stored through Fly secrets or equivalent without committed values.
- Sender-domain setup records Postmark verification status for SPF, DKIM, and DMARC alignment using sanitized DNS evidence.
- Webhook handling ingests delivery, bounce, spam complaint, suppression-related, and other approved Postmark event metadata through a placeholder URL.
- Bounce, complaint, and suppression workflows pause risky sends, route support/privacy review, and record reason-coded outcomes without exposing protected content.
- Rate controls limit pilot sends by environment, course, and notification queue, with automatic pause criteria for delivery lag, complaint spikes, suppression backlog, or webhook failure.
- Delivery logs reconcile Phoenix notification records with Postmark events using correlation IDs and sanitized recipient references only.

## Pilot Gate

Pilot readiness fails if backup restore, monitoring, incident response, log privacy, S3 object recovery, Postmark email delivery/webhook handling, auth callback visibility, or archive fallback is unproven. Postmark evidence must use sanitized recipient references and must not include real recipient addresses, protected records, grade details, submission text, full message bodies, API tokens, or webhook secret values.
