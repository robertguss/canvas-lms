# F2 Code Quality Review

Reviewer: deep-category code quality reviewer.

Scope: WTS LMS API and web implementation for Tasks 8-15, including representative backend contexts/controllers/tests, frontend workflow sources/tests, pilot rehearsal script, and readiness report. I did not access `/Users/robertguss/private-canvas-evidence`.

## Required Test Gates

### Backend

Command:

```bash
cd wts-lms-api && mix test
```

Result:

```text
Running ExUnit with seed: 206324, max_cases: 28

................................................................
Finished in 0.3 seconds (0.2s async, 0.02s sync)
64 tests, 0 failures
```

### Frontend

Command:

```bash
cd wts-lms-web && npm test
```

Result:

```text
> wts-lms-web@0.1.0 test
> node --test

TAP version 13
ok 1 - package metadata declares the deterministic React Vite TypeScript scaffold
ok 2 - App is a TSX React component for WTS coursework workflows
ok 3 - web state exposes deterministic fixture-backed workflows
ok 4 - deterministic accessibility basics exist for core workflows
ok 5 - deterministic accessibility gate covers day-one workflow regions
ok 6 - deterministic e2e workflow surface is represented in source
ok 7 - @keyboard deterministic keyboard gates cover day-one workflows
ok 8 - @pilot deterministic pilot rehearsal covers operational launch gates
ok 9 - student completes assignment submission flow in rendered static state
ok 10 - unauthorized student cannot see another course
ok 11 - teacher grading comment workflow and gradebook export are present
ok 12 - admin import status and diff summary are present
ok 13 - excluded features are absent except explicit not-included copy
1..13
# tests 13
# pass 13
# fail 0
# duration_ms 56.190667
```

## Search Gates

Command:

```bash
rg -n "TODO|FIXME|HACK|xxx|@ts-ignore|as any|access_token|Authorization|Bearer|saml_assertion|private_evidence|raw_url" wts-lms-api wts-lms-web wts-lms-specs scripts
```

Assessment: matches were expected and reviewed. They are sanitizer keywords/tests, authorization module references, script checks for unresolved TODO markers, sanitized fixture `private_evidence_file_*` source-reference placeholders, and readiness/report text. No unreviewed TODO/FIXME/HACK markers were found in WTS implementation code.

Implementation-only follow-up:

```bash
rg -n "TODO|FIXME|HACK|xxx|@ts-ignore|as any|access_token|Authorization|Bearer|saml_assertion|private_evidence|raw_url" wts-lms-api/lib wts-lms-web/src scripts/wts_pilot_rehearsal.sh wts-lms-specs/pilot/readiness_report.md
```

Assessment: implementation matches were limited to `RoleAuthorization`, `PopuliSaml`, `CourseContent`, `Files`, `Assignments`, `Sis.DryRun`, and `SecureLog` sensitive-key definitions/redaction rules. No private raw evidence path or bearer/token value is committed in runtime WTS implementation.

Additional checks:

```bash
rg -n "log|Logger|IO\.inspect|IO\.puts|console\.log|access_token|authorization|saml_assertion|private_key|raw_url|object_url|storage_key|file_content|message_body|submission_body" wts-lms-api/lib wts-lms-web/src
```

Assessment: no logging calls were present. Sensitive field names appear in `SecureLog`, file authorization error shapes, and opaque storage-key boundaries. `SignedUrl` hashes storage keys into `obj_*` references and tests confirm raw storage keys are not exposed in URLs.

## LSP Diagnostics

Checked representative configured files:

- `wts-lms-web/src/App.tsx`: no diagnostics.
- `wts-lms-web/src/api/client.ts`: no diagnostics.
- `wts-lms-web/package.json`: no diagnostics.
- `wts-lms-api/test/fixtures/canvas_sample/pilot_course/manifest.json`: no diagnostics.
- `wts-lms-api/test/fixtures/gradebook/weighted_groups.json`: no diagnostics.
- `wts-lms-api/lib/wts_lms/security/secure_log.ex`: no diagnostics.

## Review Findings

### Authorization

Reviewed representative controllers and contexts: `WtsLmsWeb.AuthController`, `WtsLmsWeb.CourseContentController`, `WtsLmsWeb.SubmissionController`, `WtsLms.CourseContent`, `WtsLms.Assignments`, `WtsLms.Files`, and `WtsLms.Authorization.RoleAuthorization`.

Core route surfaces delegate to contexts that require current active SIS-owned enrollment plus supported `Student`, `Teacher`, or `Admin` role checks. Course content, assignment submission/comment, and file download/upload all reject non-enrolled, dropped, disabled, or unsupported-role users without returning content or object URLs. I found no missing authorization check in the representative core routes.

### Privacy, Secrets, And Audit

Reviewed `WtsLms.Security.SecureLog`, `WtsLms.Audit`, `WtsLms.Files`, `WtsLms.Files.SignedUrl`, import tests, audit tests, secure-log tests, and web workflow tests.

Task 14 secure log/audit tests exist and cover tokens, authorization headers, SAML material, certificates/private keys, raw URLs, file content, message bodies, submission bodies, emails, object URLs, and storage keys. Audit builders sanitize metadata and admin listing returns safe fields only. File tests confirm unauthorized/missing downloads include `object_url: nil`, signed URLs use opaque `obj_*` references, and frontend deterministic tests reject raw HTTP/S3 evidence in workflow fixtures. No unreviewed secrets/PII logging or private raw evidence paths were found in committed WTS runtime implementation.

### Canvas Boundary And Schema Shape

Reviewed `WtsLms.Schema`, schema contract tests, import transform/diff logic, and migration/search markers. The implementation remains WTS-focused: clean domain tables model accounts, terms, users, roles, courses, sections, enrollments, modules, pages, content files, assignment groups, assignments, submissions, grade items, grades, notifications, and legacy mappings. Canvas data is kept at the migration/import boundary via `legacy_canvas_id`, `source_system`, `import_batch_id`, `last_imported_at`, and `source_updated_at`; schema tests explicitly reject `canvas_` or `dap_` operational table clones. I found no unbounded Canvas schema mirroring.

### Deterministic Local Node Tests

Reviewed `wts-lms-web/package.json`, `test/app.test.mjs`, `test/workflows.test.mjs`, `test/e2e.test.mjs`, `test/axe.test.mjs`, `src/App.tsx`, and `src/api/client.ts`.

The Node tests are acceptable for current repo constraints because browser and axe runtime services are absent, while the local tests still cover role-gated course access, Student submission workflows, Teacher grading/export workflow, Admin import/diff status, notifications, unauthorized state, accessibility landmarks/labels/keyboard reachability, pilot gate markers, and exclusion of out-of-scope features. They are not merely trivial package checks.

### Launch Blockers

Reviewed `scripts/wts_pilot_rehearsal.sh`, `wts-lms-specs/pilot/readiness_report.md`, and notepad issues. Task 15 blockers are explicit rather than hidden: launch remains blocked until 2-3 distinct real approved sanitized pilot fixtures exist, S3-compatible object storage is selected, and final restore evidence with approved fixtures is complete or explicitly waived by WTS leadership.

## Verdict Rationale

Both required test suites pass. Representative API and web quality gates show no critical architecture, authorization, privacy, security, or scope defects. Existing launch blockers are properly documented and do not represent hidden implementation defects.
VERDICT: APPROVE
