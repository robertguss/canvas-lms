## 2026-06-02 Task: work-session-start
- Plan read: `.omo/plans/wts-canvas-phoenix-replacement.md`.
- Scope guardrails: WTS-specific Canvas replacement; Core Coursework only; no generic Canvas clone, no LTI, no quizzes, no discussions, no Canvas mobile, no broad Canvas API, no full historical editable migration.
- First executable subwave: Wave 1A tasks 1-4 can run independently in parallel.

## 2026-06-02 Task 3: Populi SAML and SIS sync contracts
- Created `wts-lms-specs/integrations/populi_saml.md` defining required SAML attributes, `NameID`/`email`/`sis_user_id` matching, valid assertion handling, missing attribute rejection, disabled user rejection, unmatched user rejection, session behavior, and audit reason codes.
- Created `wts-lms-specs/integrations/sis_sync.md` defining SIS-owned fields, Registrar source-of-truth boundaries, add/drop behavior, role change behavior, section change behavior, term rollover, idempotent re-runs, conflict handling, and failure reporting.
- Both contracts explicitly state Phoenix must not own academic records and must not provide normal local-password auth.

## 2026-06-02 Task 4: Phoenix API and React SPA scaffold
- Created `wts-lms-api/` with `mix.exs`, `config/test.exs`, application startup, config placeholders for contract path, Oban, S3, and email, and an ExUnit contract harness for JSON shape validation.
- Created `wts-lms-api/test/wts_lms_web/contract_harness_test.exs` with a focused `@tag :rejects_invalid_shape` test that proves invalid placeholder API response JSON is rejected.
- Created `wts-lms-web/` with `package.json`, Node-based test harness, TypeScript source placeholders, Vite-compatible config, Playwright config, and generated API client placeholder.
- Captured Task 4 command evidence in `.omo/evidence/task-4-api-scaffold.txt` and `.omo/evidence/task-4-web-scaffold-error.txt`.

## 2026-06-02 Task 1: WTS replacement spec package
- Created top-level Task 1 specs for non-goals, compatibility matrix, gradebook rules, migration fidelity, SIS/Auth contract index, pilot success/failure, ops readiness, and privacy/accessibility.
- Scope is frozen to WTS Core Coursework with Student Teacher Admin workflows; generic Canvas clone, Canvas mobile, broad Canvas API, LTI, quizzes/New Quizzes, discussions, rubrics/outcomes/groups/collaborations, plugins, advanced gradebook parity, and full historical editable migration are explicit exclusions.
- Verification scripts `scripts/verify_plan_compliance.sh` and `scripts/verify_scope_fidelity.sh` are executable and fail when an obvious required scope exclusion is removed.

## 2026-06-02 Task 4 Atlas fix: React/Vite scaffold tightening
- Tightened `wts-lms-web/package.json` to declare React, React DOM, Vite, TypeScript, Vitest, Playwright, React Testing Library, and related type/plugin dependencies plus `dev`, `build`, `test`, and `test:e2e` scripts.
- Updated `wts-lms-web/src/App.tsx` from an object-returning placeholder to a TSX React component returning JSX for the WTS LMS Phoenix REST API placeholder.
- Kept `npm test` dependency-free by making `test/app.test.mjs` inspect package/source text rather than importing TSX or requiring `node_modules`.

## 2026-06-02 Task 1 fix: final-wave script arguments
- Updated `scripts/verify_plan_compliance.sh` to support both no-arg local verification and `PLAN_PATH SPECS_PATH` final-wave invocation.
- Updated `scripts/verify_scope_fidelity.sh` to support both no-arg local verification and `SPECS_PATH API_PATH WEB_PATH` final-wave invocation while preserving strict spec checks.
- Verified smoke outputs in `.omo/evidence/f1-plan-compliance-smoke.md` and `.omo/evidence/f4-scope-fidelity-smoke.md`; appended command evidence to `.omo/evidence/task-1-spec-package.txt`.

## 2026-06-02 Task 2: Canvas migration source inventory
- Created `wts-lms-specs/migration/source_inventory.md` mapping users, terms, courses, sections, enrollments, modules, pages, announcements, assignments, assignment groups, submissions, grades, attachments/files, comments, and legacy Canvas ID mappings to DAP, REST, course export, file download, SIS, or mixed sources.
- DAP is treated as table-like records/metadata for Canvas Data 2, not a proven source for file bytes; file bytes require Canvas REST API, course export resources, or explicit file download manifests unless official docs later prove otherwise.
- Created sanitized placeholder fixture tree under `wts-lms-api/test/fixtures/canvas_sample/pilot_course/` with README/manifest files for DAP, REST, course export, and file download sources.

## 2026-06-02 Task 5: WTS LMS domain schema
- Added dependency-free WTS domain schema modules under `wts-lms-api/lib/wts_lms/` for accounts, academic terms, users, roles, courses, sections, enrollments, learning modules, pages, content files, assignment groups, assignments, submissions, grade items, grades, notifications, and legacy mappings.
- Kept SIS/Registrar ownership explicit through `owner_system: :sis` enrollment support and SIS IDs on academic identity records; Canvas remains a boundary mapping through `legacy_canvas_id`, `source_system`, `import_batch_id`, `last_imported_at`, and `source_updated_at`.
- Added a migration manifest with clean WTS table names and `unique_legacy_mapping_index` on `source_system`, `entity_type`, and `legacy_canvas_id`; targeted tests prove duplicate Canvas IDs are rejected for the same source/type while allowed across different source/type pairs.
- Required Task 5 evidence was captured in `.omo/evidence/task-5-schema.txt` and `.omo/evidence/task-5-schema-error.txt`.

## 2026-06-02 Task 13: Managed-cloud operational readiness package
- Created provider-neutral ops runbooks under `wts-lms-specs/ops/` for managed-cloud deployment, backup restore, and incident response.
- Kept hosting provider, managed Postgres provider, S3-compatible storage provider, and email provider as explicit readiness gates instead of selected vendors.
- Restore readiness now includes scripted drill steps, expected artifacts, RPO/RTO targets, pass/fail criteria, and escalation.
- Incident response now aligns with pilot rollback/fallback triggers, FERPA-safe logging/audit constraints, severity levels, and archive fallback coordination.

## 2026-06-02 Task 2b: Canvas pilot-course sanitization workflow
- Created `wts-lms-specs/migration/sanitization_workflow.md` to require migration lead sanitizer execution and WTS data/privacy owner approval before any sanitized Canvas sample is committed.
- Created executable `scripts/wts_sanitize_canvas_sample.sh` with `--help` and `--validate FIXTURE_DIR`; it fails closed on missing DAP/REST/course export/file-download manifests, raw-looking emails, access tokens, private URLs, and real file manifests missing checksum or byte-size evidence.
- Kept DAP scoped to table-like records/metadata; file bytes still require REST, course export, or explicit file-download manifest rows with checksum and byte size.
- Captured Task 2b verification in `.omo/evidence/task-2b-sanitizer.txt` and `.omo/evidence/task-2b-sanitizer-error.txt`.

## 2026-06-02 Task 5b: Ecto/Postgres Repo
- Added real `ecto_sql` and `postgrex` dependencies, `WtsLms.Repo`, Repo supervision, and dev/test Repo configuration with non-secret environment overrides.
- Replaced the manifest-only migration contract with a real Ecto SQL migration that creates clean WTS domain tables, legacy audit fields, legacy import indexes, and `unique_legacy_mapping_index` on `legacy_mappings(source_system, entity_type, legacy_canvas_id)`.
- Converted `WtsLms.LegacyMapping` into an Ecto schema/changeset while preserving the existing constructor and in-memory contract helper for schema tests.
- Targeted tests now prove duplicate legacy mappings fail through the database unique constraint; evidence is in `.omo/evidence/task-5b-ecto-postgres.txt`.

## 2026-06-02 Task 6: Populi SAML, SIS sync, and role authorization
- Added contract-level `WtsLms.Identity.PopuliSaml`, `WtsLms.Authorization.RoleAuthorization`, `WtsLms.Sis.DryRun`, `WtsLmsWeb.AuthController`, and `mix wts.sis.dry_run` without new SAML dependencies or local-password auth.
- Populi assertions now require `NameID`, normalized `email`, and exact `sis_user_id`; accepted assertions bind `saml_name_id` only for an existing active SIS user with Student/Teacher/Admin authorization.
- Authorization checks recompute from current user, role, and active SIS enrollment state, rejecting disabled users and unsupported roles.
- SIS dry-run parses deterministic CSV fixtures, reports inserted/updated/unchanged/dropped/conflicted counts, and does not mutate existing structs or Repo state.
- Evidence for targeted tests, SIS dry-run, rejection scenarios, and CLI manual QA is in `.omo/evidence/task-6-auth.txt` and `.omo/evidence/task-6-auth-error.txt`.
- Task 6 retry tightened SIS duplicate handling so every row sharing a duplicate `sis_user_id` in the same extract is conflicted; the first duplicate row is no longer previewed as inserted or updated.

## 2026-06-02 Task 13b: Fly.io ops readiness
- Converted ops deployment, backup/restore, and incident response runbooks from provider-neutral hosting language to Fly.io-selected pilot hosting language.
- Fly.io readiness now names Fly apps, Fly Machines, `fly.toml`, Fly secrets, release health checks, private-networking posture, provider escalation placeholders, deploy evidence, and rollback evidence without committing private provider values.
- Task 5b means the ops docs now treat the real Ecto/Postgres Repo as present; managed Postgres restore readiness must validate real SQL state instead of waiting for a future Repo/adapter.

## 2026-06-02 Task 13c: Postmark email readiness
- Converted ops deployment, backup/restore, incident response, and ops readiness docs from provider-neutral email language to Postmark-selected pilot transactional email readiness.
- Postmark readiness now records safe placeholder-only requirements for API token references, webhook signing secret references, transactional Message Stream, sender-domain verification, webhook events, bounce/complaint/suppression handling, rate controls, delivery logs, health checks, and FERPA-safe evidence.
- Preserved Fly.io hosting selection and kept S3-compatible object storage as a separate unresolved readiness gate.

## 2026-06-02 Task 7: Course content API
- Added `WtsLms.CourseContent` as a dependency-light content context that returns course home/syllabus, modules, pages, file metadata only, announcements, and assignment calendar dates for enrolled Student/Teacher/Admin users.
- Added `WtsLmsWeb.CourseContentController.show/3` as a thin Phoenix-compatible map-returning controller surface matching the existing Task 6 direct controller style.
- Course content access reuses `WtsLms.Authorization.RoleAuthorization` and requires an active SIS-owned enrollment in the requested course before returning any payload.
- Evidence for targeted/full tests and unauthorized controller QA is in `.omo/evidence/task-7-content.txt` and `.omo/evidence/task-7-content-error.txt`.

## 2026-06-03 Task 8: Assignments, submissions, comments, and S3-backed files
- Added dependency-light `WtsLms.Assignments` and `WtsLms.Files` contexts for text-entry, file-upload metadata, no-submission acknowledgement, submission comments, and authorized S3-compatible signed URL metadata.
- File URL minting now validates active course enrollment before returning opaque object references; unauthorized and missing-file responses include no object URL.
- Task 8 intentionally keeps quiz/external-tool/SpeedGrader parity out of scope; the only out-of-scope reference in targeted paths is the explicit `:online_quiz` rejection test.
- Evidence for targeted/full tests and direct module QA is in `.omo/evidence/task-8-submissions.txt` and `.omo/evidence/task-8-submissions-error.txt`.

## 2026-06-03 Task 9: Gradebook engine and CSV export
- Added dependency-light `WtsLms.Gradebook` and `WtsLms.Gradebook.Verify` for pure weighted grade calculations, letter display, status-specific score inclusion, dropped-score marking, unpublished assignment visibility rules, and fixed-header CSV export.
- Gradebook behavior is deterministic for ungraded, missing, excused, late, resubmitted, extra credit, dropped scores, and unpublished assignments; missing and late policy effects only apply when explicitly supplied in fixture/config opts.
- Added `mix wts.gradebook.verify --fixture test/fixtures/gradebook/weighted_groups.json` plus the weighted-groups JSON fixture for CLI/manual verification.
- Evidence for targeted/full tests, CLI verifier, manual module QA, diagnostics, and exclusion-term check is in `.omo/evidence/task-9-gradebook.txt` and `.omo/evidence/task-9-gradebook-error.txt`.

## 2026-06-03 Task 10: Oban-backed notifications and delivery
- Added dependency-light `WtsLms.Notifications` event helpers for announcement published/updated, due-date changed, submission comment added, and grade released events, producing unread in-app notification records plus email delivery jobs for active enrolled recipients.
- Kept the worker boundary Oban-compatible without adding real Oban dependency churn; `WtsLms.Workers.EmailDeliveryWorker` records queue, attempts, max attempts, retry scheduling, delivered audit state, and terminal failure state.
- Email delivery requests are Postmark-oriented with placeholder-safe `message_stream`, template/subject/body, event ID, and recipient metadata, and contain no token, webhook secret, sender secret, SMS, mobile push, digest, preference, or frequency-control implementation.
- Evidence for targeted notification tests, targeted worker tests, full backend tests, exclusion grep, manual module QA, and empty stderr is in `.omo/evidence/task-10-notifications.txt` and `.omo/evidence/task-10-notifications-error.txt`.

## 2026-06-03 Task 11: Canvas import pipeline and diff harness
- Added dependency-light `WtsLms.Imports` staging, transform, audit, idempotency, and diff reporting for the approved sanitized pilot fixture without Repo writes or private raw data access.
- Import output maps DAP/REST/course-export/file-download fixture evidence into domain-shaped course, module, page, announcement, assignment group, assignment, submission/comment, file manifest, file, grade item, grade, and legacy mapping records; source/audit metadata remains read-only.
- Added `mix wts.import.diff --fixture ...`; approved fixture exits 0 with zero blocking mismatches, while the deliberate missing-assignment fixture exits non-zero with count and missing-record actions.
- Evidence for targeted import tests, approved/negative diff CLI, full backend tests, and exclusion grep is in `.omo/evidence/task-11-import.txt` and `.omo/evidence/task-11-import-error.txt`.

## 2026-06-03 Task 12: React/TypeScript Student Teacher Admin workflows
- Implemented a deterministic fixture-backed WTS React coursework workspace in `wts-lms-web/src/` for Student dashboard/course content/announcements/assignments/submissions/grades/notifications, Teacher submission review/grading/comment/export, Admin import status/diff summary, and unauthorized access-denied state.
- Kept day-one exclusions explicit as user-facing "not included" copy only: quizzes, discussions, LTI tools, Canvas app shell, `js_env`, and mobile-app compatibility remain absent from implementation surfaces.
- Switched `test:e2e` and `axe` to local Node test scripts because browser/axe runtime dependencies are not installed in this checkout; required `npm test`, `npm run test:e2e`, and `npm run axe` pass and evidence is in `.omo/evidence/task-12-web-ui.txt` with empty stderr in `.omo/evidence/task-12-web-ui-error.txt`.

## 2026-06-03 Task 14: Privacy, audit, security, and accessibility gates
- Added pure WTS audit event primitives for login, import diff, grade change/release, submission create/comment, and file authorization with safe actor/action/target/course/timestamp/outcome/reason/metadata fields.
- Added secure log sanitization for tokens, authorization headers, SAML material, private keys/certificates, raw URLs, storage keys, file contents, submission bodies, email, and private message bodies; admin audit listing returns only safe fields and filtered events.
- Extended deterministic local web accessibility gates with day-one workflow region checks and @keyboard coverage for Student submission, Teacher grading/export, Admin import status, and unauthorized access without requiring browser services.
- Evidence captured in `.omo/evidence/task-14-audit.txt`; stderr capture `.omo/evidence/task-14-accessibility-error.txt` is empty.

## 2026-06-03 Task 15: Pilot readiness rehearsal
- Created executable `scripts/wts_pilot_rehearsal.sh` to run sanitized fixture import diffs, deterministic `@pilot` frontend checks, SAML/SIS contract evidence checks, notification readiness checks, backup/restore readiness checks, and readiness report term gates.
- Added deterministic pilot fixture aliases `pilot_course_1`, `pilot_course_2`, and `pilot_course_3` derived from the single approved sanitized `pilot_course`; they are rehearsal aliases, not distinct real-course readiness proof.
- Added negative alias `pilot_course_with_missing_submission`, which removes assignment `83856` from the target transform and fails non-zero with missing assignment/submission mismatches.
- Created `wts-lms-specs/pilot/readiness_report.md` with PASS/FAIL gates, rollback trigger language, fallback path language, explicit waiver rules, and `LAUNCH STATUS: BLOCKED` until additional real-course fixture and ops gates are satisfied or waived by WTS leadership.
- Captured Task 15 verification in `.omo/evidence/task-15-pilot-rehearsal.txt` and `.omo/evidence/task-15-pilot-rehearsal-error.txt`.

## 2026-06-03 F1 remediation
- Resolved stale Task 6 spec decisions in `wts-lms-specs/integrations/populi_saml.md` and `wts-lms-specs/integrations/sis_sync.md`: SAML sessions use 8-hour idle and 12-hour absolute expiration; SIS pilot cadence is hourly scheduled sync/dry-run with a maximum 2-hour add/drop propagation target.
- Kept the S3-compatible object-storage provider decision unresolved because Task 15/readiness materials intentionally treat it as a launch blocker.
