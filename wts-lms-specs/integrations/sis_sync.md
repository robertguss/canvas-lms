# SIS Sync Contract

## Scope

This contract defines how Phoenix imports SIS/Registrar records for Core Coursework. The SIS/Registrar system remains the source of truth for users, courses, sections, terms, roles, and enrollments. Phoenix must not own academic records and must not provide normal local-password auth to bypass SIS state.

Phoenix stores SIS-owned records so the LMS can authorize access, render courses, accept coursework, and produce LMS-specific audit trails. Phoenix-local records may reference academic records but must not become authoritative for them.

## Source Of Truth

| Entity | Source of truth | Phoenix behavior |
| --- | --- | --- |
| Users | SIS/Registrar via Populi-backed feed | Mirror identity, display, email, and status fields needed for LMS access. |
| Terms | SIS/Registrar | Mirror term identity, dates, and rollover status. |
| Courses | SIS/Registrar | Mirror course identity and catalog metadata needed for Core Coursework. |
| Sections | SIS/Registrar | Mirror section identity, course association, term association, and meeting metadata if supplied. |
| Enrollments | SIS/Registrar | Mirror add/drop state, role, section, effective dates, and status. |
| Roles | SIS/Registrar policy for day-one roles | Accept only Student, Teacher, and Admin. Reject or quarantine unsupported roles. |

Phoenix-owned data includes submissions, comments, files, notifications, grade calculations, audit events, import job records, and legacy Canvas ID mappings. Those records must reference SIS-owned academic rows but must not change the SIS source of truth.

## Required Fields

### User Fields

- `sis_user_id`: required stable unique identifier.
- `email`: required normalized primary email.
- `first_name`: required display field.
- `last_name`: required display field.
- `disabled`: required boolean access flag.
- `status`: required SIS status value, mapped to active or blocked LMS access.
- `updated_at_source`: required source timestamp or monotonically increasing source version.

### Term Fields

- `sis_term_id`: required stable unique identifier.
- `name`: required display field.
- `starts_on`: required date.
- `ends_on`: required date.
- `status`: required lifecycle value such as future, active, completed, or archived.
- `updated_at_source`: required source timestamp or version.

### Course Fields

- `sis_course_id`: required stable unique identifier.
- `name`: required display field.
- `course_code`: required display/search code.
- `status`: required lifecycle value.
- `updated_at_source`: required source timestamp or version.

### Section Fields

- `sis_section_id`: required stable unique identifier.
- `sis_course_id`: required parent course identifier.
- `sis_term_id`: required parent term identifier.
- `name`: required display field.
- `status`: required lifecycle value.
- `updated_at_source`: required source timestamp or version.

### Enrollment Fields

- `sis_enrollment_id`: required stable unique identifier when available; otherwise use deterministic composite key `sis_user_id + sis_section_id + role`.
- `sis_user_id`: required enrolled user identifier.
- `sis_section_id`: required enrolled section identifier.
- `role`: required day-one role, one of Student, Teacher, or Admin.
- `status`: required enrollment lifecycle value, including active and dropped.
- `starts_on`: optional effective access date.
- `ends_on`: optional effective access end date.
- `updated_at_source`: required source timestamp or version.

## Sync Cadence And Job Boundaries

DECISION NEEDED: confirm production sync frequency, acceptable propagation delay for add/drop changes, and whether Populi provides push webhooks, scheduled exports, or API polling.

Until that decision is resolved, implementation must expose a deterministic dry-run path and a repeatable batch import path. Every sync job must have a job ID, source extract ID, started/finished timestamps, row counts, error counts, warning counts, and a persisted per-row outcome.

## Deterministic Change Handling

### Add/drop

An add creates or reactivates the enrollment identified by `sis_enrollment_id` or the deterministic enrollment composite key. A drop marks the enrollment inactive/dropped and removes access to the section at the next authorization check. Dropping a user must not delete submissions, grades, comments, files, audit events, or historical enrollment records.

If the feed sends a full authoritative section enrollment roster, an omitted prior enrollment is treated as a drop only when the extract declares itself a full roster for that section and term. If the feed sends incremental changes, omission means no change.

### Role Change

A role change updates the enrollment role for the same user and section only when the new role is Student, Teacher, or Admin. The change takes effect at the next authorization check. Unsupported roles are rejected or quarantined as a conflict and must not grant access.

When a role change would reduce permissions, Phoenix must preserve prior Phoenix-owned coursework and audit records while immediately enforcing the reduced access.

### Section Change

A section change is represented as a drop from the old `sis_section_id` and an add to the new `sis_section_id`, unless the SIS supplies a stable enrollment ID that explicitly changes section. Phoenix must preserve user submissions and grades tied to the original section for audit and gradebook history. Access to the old section stops when the drop is applied, and access to the new section starts when the add is applied.

### Term Rollover

Term rollover creates or activates future term, course, section, and enrollment records without mutating completed term history. Completed terms become read-only for normal Student and Teacher workflows unless a later spec grants Admin correction tools. Future-term access follows SIS effective dates and role policy.

Course shells and sections for a new term must use new `sis_term_id`, `sis_course_id`, and `sis_section_id` values supplied by SIS. Phoenix must not clone prior term academic records as authoritative data.

### Disabled Users

When a user row has `disabled = true` or a blocked SIS status, Phoenix must revoke active sessions and deny login. The user row remains present so submissions, grades, comments, and audit history remain attributable.

## Idempotency

Every sync job must be idempotent. Re-running the same extract with the same source extract ID and row contents must produce no duplicate users, courses, terms, sections, enrollments, roles, audit rows, or side effects beyond recording that the job was re-run.

Idempotent keys:

- Users: `sis_user_id`.
- Terms: `sis_term_id`.
- Courses: `sis_course_id`.
- Sections: `sis_section_id`.
- Enrollments: `sis_enrollment_id` when present; otherwise `sis_user_id + sis_section_id + role`.

For each row, Phoenix compares source timestamp/version and content hash. Older rows must not overwrite newer accepted source data. Identical rows are no-ops. Newer rows update mirrored SIS-owned fields and append an import audit outcome.

## Conflicts

A conflict is any source row or batch condition that cannot be applied without judgment. Phoenix must fail or quarantine the affected row, keep the last known good state for that row, and report the conflict.

Conflict cases include:

- Duplicate `sis_user_id`, `sis_term_id`, `sis_course_id`, `sis_section_id`, or enrollment key within the same extract.
- Enrollment references a missing user, section, course, or term.
- Section references a missing course or term.
- Email changes to an address already used by another `sis_user_id`.
- `NameID` or SAML binding from the Populi SAML contract conflicts with a changed `sis_user_id`.
- Unsupported role outside Student, Teacher, or Admin.
- Older source timestamp attempts to overwrite newer mirrored data.
- Incremental extract attempts to imply a drop by omission.

Row-level conflicts must not stop unrelated valid rows unless the batch declares itself atomic. Batch-level conflicts, such as a malformed file or invalid extract identity, fail the entire job.

## Failure Reporting

Each sync run must produce an operator-readable report and machine-readable job record with:

- Job ID and source extract ID.
- Sync mode: dry-run or apply.
- Feed mode: full roster or incremental.
- Counts for inserted, updated, unchanged, dropped, disabled, skipped, conflicted, and failed rows.
- Per-row entity type, source key, action, outcome, and reason.
- List of blocking conflicts requiring Registrar or Admin resolution.

Dry-run mode must apply the same validation and conflict detection as apply mode, but it must not persist mirrored academic record changes. Apply mode must be transactionally safe at the row or declared batch boundary.

## Implementation Requirements For Later Phoenix Work

- Treat this file as the contract for Task 6 SIS importer tests.
- Keep SIS/Registrar authoritative for academic records.
- Do not create local-password auth as a workaround for disabled, unmatched, or missing SIS users.
- Do not invent custom Canvas roles for day one.
- Make add/drop, role change, section change, term rollover, idempotent re-runs, conflict detection, and failure reporting directly testable.
