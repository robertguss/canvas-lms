# WTS Pilot Readiness Rehearsal Report

## Launch Decision

LAUNCH STATUS: BLOCKED.

The rehearsal may pass for deterministic local gates, but WTS must not launch the pilot until every strict operational gate passes or WTS leadership records an explicit waiver in this report. Launch is blocked because only one approved real sanitized WTS-derived fixture is available; `pilot_course_1`, `pilot_course_2`, and `pilot_course_3` are deterministic aliases of `pilot_course`, not 2-3 distinct real courses.

## Selected Fixtures

| Fixture | Source status | Import diff | Launch meaning |
| --- | --- | --- | --- |
| `pilot_course_1` | Approved real sanitized base fixture reused as deterministic alias | PASS when `mix wts.import.diff --fixture test/fixtures/canvas_sample/pilot_course_1` exits 0 | Rehearsal evidence only; not a distinct second real course. |
| `pilot_course_2` | Approved real sanitized base fixture reused as deterministic alias | PASS when `mix wts.import.diff --fixture test/fixtures/canvas_sample/pilot_course_2` exits 0 | Rehearsal evidence only; not a distinct second real course. |
| `pilot_course_3` | Approved real sanitized base fixture reused as deterministic alias | PASS when `mix wts.import.diff --fixture test/fixtures/canvas_sample/pilot_course_3` exits 0 | Rehearsal evidence only; not a distinct third real course. |
| `pilot_course_with_missing_submission` | Negative alias derived from the missing-assignment mismatch fixture | FAIL expected; non-zero import diff blocks launch | Proves missing required assignment/submission mismatches fail closed. |

## PASS/FAIL Gate Table

| Gate | Evidence | Result | Required action |
| --- | --- | --- | --- |
| Import diff for requested positive fixtures | `scripts/wts_pilot_rehearsal.sh --fixtures pilot_course_1,pilot_course_2,pilot_course_3` runs each `mix wts.import.diff` command | PASS for deterministic aliases | Replace aliases with 2-3 distinct WTS data/privacy owner-approved real sanitized fixtures before actual launch. |
| Negative migration mismatch | `scripts/wts_pilot_rehearsal.sh --fixtures pilot_course_with_missing_submission` exits non-zero | PASS as a blocking control because the negative rehearsal fails | Keep launch blocked for any missing required assignment, submission, grade, file, enrollment, or identity mapping. |
| Student UI workflow | `cd wts-lms-web && npm run test:e2e -- --grep @pilot` | PASS | Re-run after every pilot workflow change. |
| Teacher UI workflow | `cd wts-lms-web && npm run test:e2e -- --grep @pilot` | PASS | Re-run after every pilot workflow change. |
| Admin UI workflow and diff status | `cd wts-lms-web && npm run test:e2e -- --grep @pilot` | PASS | Re-run after every import/admin workflow change. |
| SAML/SIS contracts | `populi_saml.md`, `sis_sync.md`, Task 3 evidence, and Task 6 auth evidence | PASS for deterministic contract evidence | Verify live Populi metadata and SIS extract health before launch without recording private values. |
| Notifications | Task 10 notification/worker evidence plus Postmark readiness docs | PASS for deterministic tests and runbook evidence | Confirm Postmark sender-domain, webhook, bounce, complaint, suppression, and rate-control evidence before launch. |
| Backup/restore | Fly.io/Postmark ops runbooks and Task 13 evidence | FAIL for final launch because S3-compatible object storage provider and distinct real-course restore evidence remain pending | Complete restore drill with selected object storage and approved pilot fixtures before launch, or record WTS leadership waiver. |
| Privacy/security logging | Task 14 audit/security evidence and `privacy_accessibility.md` | PASS for deterministic redaction/audit gates | Re-run after any logging, auth, import, file, grade, or notification change. |
| Accessibility | Task 14 `axe` and `@keyboard` evidence plus `@pilot` deterministic e2e | PASS for deterministic local gates | Re-run in browser/runtime environment when available; any critical WCAG issue blocks launch. |
| 2-3 real-course selection | Current fixture inventory | FAIL for final launch because aliases are not distinct real courses | Obtain additional WTS data/privacy owner-approved sanitized pilot fixtures or WTS leadership waiver. |

## Rollback And Fallback Triggers

- rollback trigger: Any blocking migration mismatch, missing required submission, missing assignment, grade discrepancy, authorization error, missing file, broken Student/Teacher/Admin workflow, failed restore rehearsal, FERPA-significant exposure, critical accessibility violation, or disabled-user revocation failure blocks launch or returns the affected course to hosted Canvas/archive access.
- rollback trigger: If a promoted import corrupts Phoenix-owned pilot data, restore the last verified managed Postgres backup and S3-compatible object snapshot before reopening the course.
- fallback trigger: If Phoenix is unavailable during pilot, instructors and students use hosted Canvas or read-only export archive access for the affected course until service is restored.
- fallback trigger: If DAP lacks payloads required for a pilot course, use Canvas REST API, course export, or file-download evidence; if no source can provide a required day-one field, remove that course from pilot scope.

## Explicit Waivers

No waivers are granted in this report.

WTS leadership must explicitly record any waiver here before launch. A valid waiver must name the failed gate, business owner, privacy owner, technical owner, compensating control, expiration date, rollback trigger, and fallback path. Silent waiver is not permitted.

## Blocked Launch Items

- FAIL: 2-3 distinct real low-risk pilot courses are not yet represented by approved sanitized fixtures; current aliases only prove deterministic rehearsal mechanics.
- FAIL: S3-compatible object storage provider selection and object restore evidence remain final launch gates.
- FAIL: Final backup/restore proof must be repeated with approved real pilot fixtures and safe operator evidence.

## Ready Items

- PASS: Deterministic import diff succeeds for alias fixtures derived from the approved sanitized base fixture.
- PASS: Deterministic `@pilot` e2e covers Student submission, Teacher grading/export, Admin import/diff status, notification visibility, unauthorized access, and safe local source checks.
- PASS: Negative missing-submission rehearsal fails non-zero and requires blocked launch action.
- PASS: Readiness report includes PASS/FAIL results, rollback trigger language, fallback path language, explicit waivers, and launch blocked state.
