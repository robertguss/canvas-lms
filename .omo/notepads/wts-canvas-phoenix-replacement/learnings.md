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
