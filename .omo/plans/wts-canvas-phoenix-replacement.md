# WTS Canvas Phoenix Replacement

## TL;DR

> **Summary**: Build a WTS-specific replacement for Westminster Theological
> Seminary's Instructure-hosted Canvas instance using a Phoenix REST API,
> React/TypeScript SPA, Populi/SAML auth, SIS-owned academic records, DAP/API
> migration inputs, S3-compatible storage, and contract-first TDD. The first
> production proof is a 2-3 real-course pilot for Core Coursework, not generic
> Canvas parity. **Deliverables**:
>
> - Decision/spec package: non-goals, Canvas behavior compatibility matrix,
>   gradebook rules, migration fidelity, SIS/Auth contracts, pilot
>   success/failure, ops readiness.
> - Phoenix API project in `wts-lms-api/` using clean WTS domain schema with
>   legacy Canvas ID mappings.
> - React/TypeScript SPA in `wts-lms-web/` for Student/Teacher/Admin Core
>   Coursework.
> - DAP/API/file-export migration spike, importer, and automated diff harness.
> - Contract-first ExUnit/API/UI test suite and pilot readiness gates.
>   **Effort**: XL **Parallel**: YES - 7 executable subwaves **Critical Path**:
>   Task 1 specs + Task 2 migration spike + Task 3 SIS/Auth contracts + Task 4
>   scaffolds → Task 5 schema → Tasks 6/8 → Task 7 + Tasks 9/10 → Tasks 11/12 →
>   Tasks 13/14 → Task 15

## Context

### Original Request

The user wants to brainstorm and plan migrating/converting the cloned
open-source Canvas LMS repository from Ruby on Rails to Elixir/Phoenix,
primarily as a backend API so it can be frontend agnostic.

### Interview Summary

- Replacement target: WTS's own Instructure-hosted Canvas instance.
- WTS does not self-host Canvas today; the Phoenix system will replace the
  hosted SaaS instance.
- Day-one scope: Core Coursework only.
- Day-one roles: Student, Teacher, Admin.
- Day-one frontend: new minimal React/TypeScript SPA consuming Phoenix REST API.
- Day-one API compatibility: only endpoints/contracts used by WTS frontend and
  automated verification/migration harnesses.
- Day-one non-goals: generic Canvas clone, official Canvas mobile support, broad
  Canvas API compatibility, LTI/external tools, quizzes, discussions, rubrics,
  groups, plugins, complex notifications, advanced gradebook parity, full
  historical editable migration.
- Data: Active + Archive. Migrate active/current/future data into Phoenix; keep
  historical Canvas data available read-only through old Canvas/export/archive
  strategy.
- Data access: WTS has Instructure DAP/Data Access Platform; supplement with
  Canvas REST APIs/course exports/file downloads where DAP lacks payloads.
- Source of truth: Existing SIS/Registrar process remains authoritative for
  users, courses, sections, terms, and enrollments.
- Auth: Populi SIS SAML IdP, same as current Canvas.
- Storage: S3-compatible object storage.
- Hosting: managed cloud.
- Pilot: 2-3 low-risk real courses, strict operational success criteria,
  fallback/archive plan.
- Test strategy: contract-first TDD using WTS Canvas data/API behavior.
- Data model: new WTS-focused domain schema with legacy Canvas ID mapping; DAP
  may be staging/import source.

### Metis Review (gaps addressed)

Metis required the plan to include explicit non-goals, a Canvas behavior
compatibility matrix, gradebook rules spec, migration fidelity spec, pilot
success/failure spec with rollback triggers, SIS/Auth contract specs,
DAP/REST/file-export validation spike, operational readiness, accessibility, and
FERPA/privacy controls. Remaining unknowns are encoded as gated discovery tasks
rather than left to implementer judgment.

## Work Objectives

### Core Objective

Replace WTS's hosted Canvas usage for Core Coursework with a managed-cloud
Phoenix API and React/TypeScript web UI, proven first by a 2-3 real-course
pilot.

### Deliverables

- `wts-lms-specs/` containing executable product/compatibility specs.
- `wts-lms-api/` Phoenix API with contexts for Identity, Courses, Content,
  Assignments, Submissions, Files, Grades, Notifications, Imports, Admin.
- `wts-lms-web/` React/TypeScript SPA for Student, Teacher, Admin workflows.
- `wts-lms-api/priv/repo/migrations/*` with clean domain schema and
  `legacy_canvas_id`/mapping tables.
- `wts-lms-api/test/fixtures/canvas_sample/` with sanitized WTS
  DAP/API/course-export fixtures.
- `wts-lms-api/lib/wts_lms/imports/` migration importer and diff harness.
- Operational runbooks in `wts-lms-specs/ops/`.

### Definition of Done (verifiable conditions with commands)

- `cd wts-lms-api && mix test` passes.
- `cd wts-lms-web && npm test && npm run test:e2e` passes.
- `cd wts-lms-api && mix wts.import.diff --fixture test/fixtures/canvas_sample/pilot_course`
  exits 0 with configured mismatch tolerance.
- `cd wts-lms-api && mix wts.gradebook.verify --fixture test/fixtures/gradebook/weighted_groups.json`
  exits 0.
- `cd wts-lms-web && npm run axe` exits 0 for pilot workflows.
- `wts-lms-specs/pilot/success_failure.md` contains numeric pass/fail thresholds
  and rollback triggers.

### Must Have

- Populi/SAML auth mapping to SIS-synced users.
- SIS/Registrar sync contract for users/courses/sections/terms/enrollments.
- Student/Teacher/Admin permissions only.
- Courses, syllabus, modules/pages/readings/files, announcements,
  assignment/calendar dates.
- Text-entry, file-upload, no-submission assignments.
- Submission comments, grading comments, timestamps.
- Points + weighted assignment groups + final percentage/letter display + CSV
  export.
- S3-compatible file storage with permissioned uploads/downloads.
- Simple email + in-app notifications.
- DAP/API/file-export migration path with automated diff reporting.
- Managed cloud ops: backups, restore drill, monitoring, logs, incident process.
- FERPA/privacy-conscious logging and WCAG-oriented UI checks.

### Must NOT Have (guardrails, AI slop patterns, scope boundaries)

- Do not implement generic Canvas parity.
- Do not support official Canvas mobile apps day one.
- Do not implement LTI, external tools, developer keys, or grade passback day
  one.
- Do not implement quizzes/New Quizzes day one.
- Do not implement discussions day one.
- Do not implement rubrics/outcomes/groups/collaborations day one.
- Do not mirror Canvas's operational schema as the primary Phoenix schema.
- Do not make Phoenix the authoritative SIS/Registrar system.
- Do not migrate all historical Canvas data into editable Phoenix records.
- Do not infer Canvas semantics from memory; use explicit specs and fixtures.

## Verification Strategy

> ZERO HUMAN INTERVENTION - all verification is agent-executed.

- Test decision: Contract-first TDD using ExUnit, Phoenix controller/API tests,
  importer diff tests, React Testing Library, Playwright, and accessibility
  checks.
- QA policy: Every task has agent-executed happy and failure scenarios.
- Evidence: `.omo/evidence/task-{N}-{slug}.{ext}`

## Execution Strategy

### Parallel Execution Waves

> Target: 5-8 tasks per wave. <3 per wave (except final) = under-splitting.
> Extract shared dependencies as Wave-1 tasks for max parallelism.

Wave 1A: Tasks 1-4 — specs/discovery/scaffolding foundations; can run in
parallel because each produces a separate foundation artifact. Wave 2A: Task 2b —
sanitizer workflow before real WTS data enters the repo. Wave 2B: Task 5 — domain
schema, then Task 5b — real Ecto/Postgres Repo and migrations. Wave 2C: Task 6 —
auth/SIS on real persistence. Wave 2D: Task 8 — assignments/files after sanitizer
and schema foundations. Wave 2E: Tasks 7, 9, and 10 — content, gradebook,
notifications; can run in parallel after required foundations. Wave 3A: Tasks 11 and 12 — import
harness and React workflows; can run in parallel after backend contracts exist.
Wave 4A: Tasks 13 and 14 — ops and privacy/accessibility; can run in parallel
after app foundations. Wave 5A: Task 15 — pilot rehearsal; final implementation
gate after all prior tasks.

### Dependency Matrix (full, all tasks)

- T1 blocks T5-T15.
- T2 blocks T2b, T5, T8, T11, T15.
- T2b blocks T8, T11, T15 and must run before T5b by user decision.
- T3 blocks T6, T12, T15.
- T4 blocks T5-T14.
- T5 blocks T5b and T6-T11.
- T5b blocks T6-T11.
- T6 blocks T7, T12, T15.
- T7 blocks T12, T15.
- T8 blocks T10-T12, T15.
- T9 blocks T12, T15.
- T10 blocks T12, T15.
- T11 blocks T15.
- T12 blocks T15.
- T13 and T14 block T15.

### Agent Dispatch Summary (wave → task count → categories)

- Wave 1A → 4 tasks → writing, deep, unspecified-high.
- Wave 2A → 1 task → deep.
- Wave 2B → 2 tasks → deep.
- Wave 2C → 1 task → deep.
- Wave 2D → 1 task → deep.
- Wave 2E → 3 tasks → unspecified-high, deep.
- Wave 3A → 2 tasks → deep, visual-engineering.
- Wave 4A → 2 tasks → unspecified-high, visual-engineering.
- Wave 5A → 1 task → deep.

## TODOs

> Implementation + Test = ONE task. Never separate. EVERY task MUST have: Agent
> Profile + Parallelization + QA Scenarios.

- [x] 1. Create WTS replacement spec package

  **What to do**: Create `wts-lms-specs/` with `non_goals.md`,
  `compatibility_matrix.md`, `gradebook_rules.md`, `migration_fidelity.md`,
  `sis_auth_contracts.md`, `pilot_success_failure.md`, `ops_readiness.md`, and
  `privacy_accessibility.md`. Encode Preserve/Simplify/Exclude decisions exactly
  from this plan. Create executable verification script skeletons
  `scripts/verify_plan_compliance.sh` and `scripts/verify_scope_fidelity.sh`
  that final verification will use and later tasks may extend. **Must NOT do**:
  Do not invent support for LTI, quizzes, discussions, rubrics, mobile apps,
  broad Canvas API, or full historical editable migration.

  **Recommended Agent Profile**:
  - Category: `writing` - Reason: spec writing with precise guardrails.
  - Skills: [] - No special skill needed.
  - Omitted: [`rspec`] - No Ruby specs are being edited.

  **Parallelization**: Can Parallel: YES | Wave 1A | Blocks:
  5,6,7,8,9,10,11,12,13,14,15 | Blocked By: none

  **References**:
  - Pattern: `.omo/drafts/canvas-phoenix-migration.md` - confirmed decisions and
    Metis findings.
  - Pattern: `app/controllers/application_controller.rb` - Canvas frontend/auth
    coupling to avoid cloning.
  - Pattern: `lib/api.rb` and `lib/api/v1/json.rb` - existing Canvas API
    behavior reference.

  **Acceptance Criteria**:
  - [ ] `test -f wts-lms-specs/non_goals.md && test -f wts-lms-specs/compatibility_matrix.md && test -f wts-lms-specs/gradebook_rules.md`
  - [ ] `grep -R "LTI.*Exclude\|Quizzes.*Exclude\|Mobile.*Exclude" wts-lms-specs/compatibility_matrix.md`
  - [ ] `grep -R "rollback trigger\|mismatch tolerance\|FERPA\|WCAG" wts-lms-specs/`
  - [ ] `grep -R "Preserve\|Simplify\|Exclude" wts-lms-specs/compatibility_matrix.md`
  - [ ] `grep -R "ungraded\|missing\|excused\|late\|resubmitted\|extra credit\|dropped" wts-lms-specs/gradebook_rules.md`
  - [ ] `grep -R "numeric threshold\|mismatch tolerance\|rollback trigger\|fallback trigger" wts-lms-specs/migration_fidelity.md wts-lms-specs/pilot_success_failure.md`
  - [ ] `grep -E "valid assertion|missing attribute|disabled user|idempotent|add/drop" wts-lms-specs/sis_auth_contracts.md`
  - [ ] `! (grep -R -nE "TBD|TODO" wts-lms-specs/ | grep -v "DECISION NEEDED:")`
  - [ ] `test -x scripts/verify_plan_compliance.sh && test -x scripts/verify_scope_fidelity.sh`

  **QA Scenarios**:

  ```
  Scenario: Spec package contains all required guardrails
    Tool: Bash
    Steps: Run `grep -R "Generic Canvas clone\|No LTI\|No quizzes\|Student Teacher Admin" wts-lms-specs/`
    Expected: Command returns matching lines for every non-goal and role decision.
    Evidence: .omo/evidence/task-1-spec-package.txt

  Scenario: Missing scope exclusion fails review
    Tool: Bash
    Steps: Run `grep -R "Canvas mobile.*Exclude" wts-lms-specs/compatibility_matrix.md`
    Expected: Exit code 0; absence is a failure.
    Evidence: .omo/evidence/task-1-spec-package-error.txt
  ```

  **Commit**: YES | Message: `docs(wts): define replacement scope specs` |
  Files: [`wts-lms-specs/`, `scripts/verify_plan_compliance.sh`,
  `scripts/verify_scope_fidelity.sh`]

- [x] 2. Prove DAP/API/file migration inputs on one sanitized active course

  **What to do**: Create `wts-lms-api/test/fixtures/canvas_sample/` with
  sanitized DAP records, Canvas REST samples, course export metadata, and
  file-download manifest for one representative active course. Create
  `wts-lms-specs/migration/source_inventory.md` listing which fields come from
  DAP, REST API, course export, or file download. Add an explicit gate: Tasks 5,
  8, and 11 cannot proceed to production-quality implementation until real
  sanitized samples exist or `source_inventory.md` records a blocking gap with
  owner and next action. **Must NOT do**: Do not assume DAP contains file bytes
  or all runtime semantics; do not let schema/import/file/submission
  implementation proceed on mocked-only data without a recorded blocker.

  **Recommended Agent Profile**:
  - Category: `deep` - Reason: migration source mapping and data fidelity
    decisions.
  - Skills: [] - No special skill needed.
  - Omitted: [`librarian`] - DAP docs already identified; use only if docs gaps
    appear.

  **Parallelization**: Can Parallel: YES | Wave 1A | Blocks: 5,8,11,15 | Blocked
  By: none

  **References**:
  - External:
    `https://developerdocs.instructure.com/services/dap/dataset/dataset-namespaces/dataset-canvas` -
    DAP canvas namespace.
  - Pattern: `app/models/assignment.rb`, `app/models/submission.rb`,
    `app/models/attachment.rb` - Canvas domain references if needed.

  **Acceptance Criteria**:
  - [ ] `test -f wts-lms-specs/migration/source_inventory.md`
  - [ ] `test -d wts-lms-api/test/fixtures/canvas_sample`
  - [ ] `grep -R "DAP\|REST\|file download\|course export" wts-lms-specs/migration/source_inventory.md`
  - [ ] `grep -R "BLOCKER\|real sanitized sample\|mocked-only data prohibited" wts-lms-specs/migration/source_inventory.md`

  **QA Scenarios**:

  ```
  Scenario: Source inventory maps each pilot entity
    Tool: Bash
    Steps: Run `grep -E "courses|users|enrollments|assignments|submissions|grades|attachments|modules|pages" wts-lms-specs/migration/source_inventory.md`
    Expected: Every listed entity has a source and fallback/source limitation note.
    Evidence: .omo/evidence/task-2-source-inventory.txt

  Scenario: Missing file payload assumption is caught
    Tool: Bash
    Steps: Run `grep -i "DAP.*metadata.*file\|file bytes.*REST\|file bytes.*download" wts-lms-specs/migration/source_inventory.md`
    Expected: Inventory explicitly states how file bytes are retrieved.
    Evidence: .omo/evidence/task-2-source-inventory-error.txt
  ```

  **Commit**: YES | Message: `docs(wts): inventory Canvas migration sources` |
  Files: [`wts-lms-specs/migration/`,
  `wts-lms-api/test/fixtures/canvas_sample/`]

- [x] 2b. Build Canvas pilot-course sanitization workflow

  **What to do**: Create a sanitizer checklist and scripts for producing a real
  sanitized active-course sample from Canvas DAP records, Canvas REST responses,
  course export metadata, and file-download manifests. The workflow must redact
  student/faculty identities, grades, submission text, comments, private file
  names where needed, and private URLs while preserving entity shape, legacy
  Canvas IDs, byte sizes, checksums, content types, dates, workflow states, and
  relationships needed by import/diff tests. The migration lead runs the
  sanitizer, and a WTS data/privacy owner must approve sanitized output before it
  is committed. **Must NOT do**: Do not commit raw
  private Canvas data, file bytes, access tokens, SAML assertions, or private URLs.

  **Acceptance Criteria**:
  - [ ] `test -f wts-lms-specs/migration/sanitization_workflow.md`
  - [ ] `test -x scripts/wts_sanitize_canvas_sample.sh`
  - [ ] `scripts/wts_sanitize_canvas_sample.sh --help`
  - [ ] sanitizer validation rejects raw-looking emails, access tokens, private URLs, and missing file checksum/byte-size rows.

  **Commit**: YES | Message: `test(wts): add Canvas sample sanitizer` | Files:
  [`wts-lms-specs/migration/sanitization_workflow.md`, `scripts/wts_sanitize_canvas_sample.sh`,
  `wts-lms-api/test/fixtures/canvas_sample/`]

- [x] 3. Define Populi SAML and SIS sync contracts

  **What to do**: Create `wts-lms-specs/integrations/populi_saml.md` and
  `wts-lms-specs/integrations/sis_sync.md`. Specify SAML attributes, user
  matching, disabled-user behavior, SIS fields, sync frequency, add/drop timing,
  section changes, term rollover, idempotency, and conflict handling. **Must NOT
  do**: Do not let Phoenix own academic records or local passwords for normal
  users.

  **Recommended Agent Profile**:
  - Category: `deep` - Reason: auth and SIS contracts are production-critical.
  - Skills: [] - No special skill needed.
  - Omitted: [`axe`] - No simulator work.

  **Parallelization**: Can Parallel: YES | Wave 1A | Blocks: 6,12,15 | Blocked
  By: none

  **References**:
  - Pattern: `app/models/pseudonym_session.rb` - Canvas session behavior
    reference to avoid direct cloning.
  - Pattern: `app/models/authentication_provider.rb` - Canvas auth-provider
    complexity reference.
  - External: `https://hexdocs.pm/phoenix/mix_phx_gen_auth.html` - Phoenix auth
    guidance.

  **Acceptance Criteria**:
  - [ ] `grep -R "SAML attribute\|NameID\|email\|sis_user_id\|disabled" wts-lms-specs/integrations/populi_saml.md`
  - [ ] `grep -R "idempotent\|add/drop\|section\|term rollover\|conflict" wts-lms-specs/integrations/sis_sync.md`

  **QA Scenarios**:

  ```
  Scenario: SAML contract covers valid and invalid assertions
    Tool: Bash
    Steps: Run `grep -E "valid assertion|missing attribute|disabled user|unmatched user" wts-lms-specs/integrations/populi_saml.md`
    Expected: All four cases are specified.
    Evidence: .omo/evidence/task-3-saml-contract.txt

  Scenario: SIS sync contract covers enrollment changes
    Tool: Bash
    Steps: Run `grep -E "add|drop|role change|section change|term rollover" wts-lms-specs/integrations/sis_sync.md`
    Expected: Each enrollment change has deterministic expected behavior.
    Evidence: .omo/evidence/task-3-sis-contract-error.txt
  ```

  **Commit**: YES | Message: `docs(wts): define Populi and SIS contracts` |
  Files: [`wts-lms-specs/integrations/`]

- [x] 4. Scaffold Phoenix API, React SPA, and contract-test harness

  **What to do**: Create `wts-lms-api/` as a Phoenix API-only app with Postgres,
  ExUnit, OpenAPI/JSON contract testing support, Oban dependency placeholder,
  S3/email config placeholders, and `wts-lms-web/` as Vite React/TypeScript app
  with Vitest, Playwright, React Testing Library, and shared generated API
  client placeholder. **Must NOT do**: Do not modify Canvas Rails app to serve
  the new UI; do not use LiveView for primary day-one UI.

  **Recommended Agent Profile**:
  - Category: `unspecified-high` - Reason: multi-project scaffolding and test
    harness setup.
  - Skills: [] - No special skill needed.
  - Omitted: [`ui`] - UI design comes later.

  **Parallelization**: Can Parallel: YES | Wave 1A | Blocks:
  5,6,7,8,9,10,11,12,13,14 | Blocked By: none

  **References**:
  - External: `https://hexdocs.pm/phoenix/json_and_apis.html` - Phoenix JSON/API
    app patterns.
  - External: `https://hexdocs.pm/phoenix/testing.html` - Phoenix testing.

  **Acceptance Criteria**:
  - [ ] `cd wts-lms-api && mix test`
  - [ ] `cd wts-lms-web && npm test`
  - [ ] `test -f wts-lms-api/config/test.exs && test -f wts-lms-web/playwright.config.ts`

  **QA Scenarios**:

  ```
  Scenario: Backend scaffold runs tests
    Tool: Bash
    Steps: Run `cd wts-lms-api && mix test`
    Expected: Exit code 0.
    Evidence: .omo/evidence/task-4-api-scaffold.txt

  Scenario: Contract harness rejects invalid response shape
    Tool: Bash
    Steps: Run `cd wts-lms-api && mix test test/wts_lms_web/contract_harness_test.exs --only rejects_invalid_shape`
    Expected: Test passes by proving the harness fails invalid API JSON shapes.
    Evidence: .omo/evidence/task-4-web-scaffold-error.txt
  ```

  **Commit**: YES | Message: `chore(wts): scaffold Phoenix API and React app` |
  Files: [`wts-lms-api/`, `wts-lms-web/`]

- [x] 5. Implement clean Phoenix domain schema with legacy Canvas mappings

  **What to do**: Add Ecto schemas/migrations for accounts, terms, users, roles,
  courses, sections, enrollments, modules, pages, files, assignments,
  submissions, grade items/groups, grades, notifications, and legacy mapping
  tables. Include `legacy_canvas_id`, `source_system`, and import audit fields
  where applicable. **Must NOT do**: Do not mirror Canvas/DAP tables as
  operational schema; DAP mirror/staging is allowed only for imports.

  **Recommended Agent Profile**:
  - Category: `deep` - Reason: foundational data model.
  - Skills: [] - No special skill needed.
  - Omitted: [`squash-migrations`] - New Phoenix migrations, not Canvas Rails
    migrations.

  **Parallelization**: Can Parallel: NO | Wave 2A | Blocks: 6,7,8,9,10,11 |
  Blocked By: 1,2,4

  **References**:
  - Pattern: `app/models/user.rb` - Canvas complexity reference, not model to
    clone.
  - External: `https://hexdocs.pm/ecto/` - Ecto schemas/migrations.
  - Spec: `wts-lms-specs/compatibility_matrix.md` - included/excluded behavior.

  **Acceptance Criteria**:
  - [ ] `cd wts-lms-api && mix ecto.migrate && mix test test/wts_lms/schema_contract_test.exs`
  - [ ] `grep -R "legacy_canvas_id" wts-lms-api/lib/wts_lms wts-lms-api/priv/repo/migrations`

  **QA Scenarios**:

  ```
  Scenario: Schema supports core relationships
    Tool: Bash
    Steps: Run `cd wts-lms-api && mix test test/wts_lms/schema_contract_test.exs`
    Expected: Tests create course, section, teacher/student enrollments, assignment, submission, grade, and module page.
    Evidence: .omo/evidence/task-5-schema.txt

  Scenario: Duplicate Canvas IDs are rejected
    Tool: Bash
    Steps: Run `cd wts-lms-api && mix test test/wts_lms/legacy_mapping_test.exs`
    Expected: Duplicate `legacy_canvas_id` for same source/type fails with constraint error.
    Evidence: .omo/evidence/task-5-schema-error.txt
  ```

  **Commit**: YES | Message: `feat(wts): add core LMS domain schema` | Files:
  [`wts-lms-api/lib/wts_lms/`, `wts-lms-api/priv/repo/migrations/`,
  `wts-lms-api/test/`]

- [x] 5b. Add real Ecto/Postgres Repo and convert schema manifest to migrations

  **What to do**: Add real Ecto/Postgres dependencies, configure `WtsLms.Repo`,
  replace the manifest-only `mix ecto.migrate` validator with real Ecto SQL
  migrations, and preserve the clean WTS domain schema and legacy mapping
  constraints from Task 5. **Must NOT do**: Do not mirror Canvas/DAP operational
  tables; do not add unrelated backend features.

  **Acceptance Criteria**:
  - [ ] `cd wts-lms-api && mix deps.get && mix ecto.create && mix ecto.migrate`
  - [ ] `cd wts-lms-api && mix test test/wts_lms/schema_contract_test.exs test/wts_lms/legacy_mapping_test.exs`
  - [ ] duplicate legacy mappings fail through a real database constraint, not only an in-memory check.

  **Commit**: YES | Message: `feat(wts): add Ecto Postgres repo` | Files:
  [`wts-lms-api/mix.exs`, `wts-lms-api/config/`, `wts-lms-api/lib/wts_lms/repo.ex`,
  `wts-lms-api/priv/repo/migrations/`, `wts-lms-api/test/`]

- [x] 6. Implement Populi SAML, SIS sync, and role authorization

  **What to do**: Implement SAML login callback, user matching to SIS-synced
  records, Student/Teacher/Admin authorization plugs/policies, SIS sync importer
  with idempotent add/drop/role/section/term behavior, and disabled-user
  blocking. Use an 8-hour idle timeout and 12-hour absolute session expiration
  for normal authenticated web sessions. Use Populi SAML via configured IdP
  metadata URL, with metadata URL and certificate validation configured through
  environment/secret references rather than committed values. Run SIS sync hourly
  during the pilot, with a maximum acceptable add/drop propagation delay of 2
  hours from SIS/Registrar source update to Phoenix access state. SIS sync
  conflicts, including duplicate SIS IDs, role conflicts, and missing section
  mappings, are owned by the Registrar as source-of-truth owner; Phoenix must
  block ambiguous changes and report conflicts rather than resolving academic
  record conflicts locally. **Must NOT do**: Do not create local password auth for normal users;
  do not add custom Canvas roles.

  **Recommended Agent Profile**:
  - Category: `deep` - Reason: security/auth and academic-record sync.
  - Skills: [] - No special skill needed.
  - Omitted: [`rspec`] - Phoenix ExUnit only.

  **Parallelization**: Can Parallel: YES | Wave 2B | Blocks: 7,12,15 | Blocked
  By: 1,3,4,5,5b

  **References**:
  - Spec: `wts-lms-specs/integrations/populi_saml.md` - SAML contract.
  - Spec: `wts-lms-specs/integrations/sis_sync.md` - SIS contract.

  **Acceptance Criteria**:
  - [ ] `cd wts-lms-api && mix test test/wts_lms/identity test/wts_lms_web/controllers/auth_controller_test.exs`
  - [ ] `cd wts-lms-api && mix wts.sis.dry_run --fixture test/fixtures/sis/add_drop.csv`

  **QA Scenarios**:

  ```
  Scenario: Valid Populi SAML maps to synced user
    Tool: Bash
    Steps: Run `cd wts-lms-api && mix test test/wts_lms_web/controllers/saml_callback_test.exs --only valid_assertion`
    Expected: User session token is created and role-scoped courses are returned.
    Evidence: .omo/evidence/task-6-auth.txt

  Scenario: Disabled SIS user cannot log in
    Tool: Bash
    Steps: Run `cd wts-lms-api && mix test test/wts_lms_web/controllers/saml_callback_test.exs --only disabled_user`
    Expected: Login rejected with 403 and audit event written.
    Evidence: .omo/evidence/task-6-auth-error.txt
  ```

  **Commit**: YES | Message: `feat(wts): add Populi SAML and SIS sync` | Files:
  [`wts-lms-api/lib/wts_lms/identity/`, `wts-lms-api/lib/wts_lms/sis/`,
  `wts-lms-api/test/`]

- [x] 7. Implement course content, syllabus, modules, pages, announcements, and
     calendar dates

  **What to do**: Implement CourseContent context and API endpoints for course
  home/syllabus, modules, pages/readings/files metadata, announcements, and
  assignment/calendar dates. Enforce Student/Teacher/Admin access. **Must NOT
  do**: Do not implement discussions, outcomes, collaborations, arbitrary Canvas
  rich-content edge cases, or plugin views.

  **Recommended Agent Profile**:
  - Category: `unspecified-high` - Reason: domain API implementation with
    permissions.
  - Skills: [] - No special skill needed.
  - Omitted: [`ui`] - Backend API only.

  **Parallelization**: Can Parallel: YES | Wave 2C | Blocks: 12,15 | Blocked By:
  1,4,5,6

  **References**:
  - Pattern: `app/controllers/context_controller.rb` - Canvas hybrid page
    complexity to simplify.
  - Pattern: `app/controllers/files_controller.rb` - file/content access
    behavior reference.
  - Spec: `wts-lms-specs/compatibility_matrix.md` - content
    Preserve/Simplify/Exclude decisions.

  **Acceptance Criteria**:
  - [ ] `cd wts-lms-api && mix test test/wts_lms/course_content test/wts_lms_web/controllers/course_content_controller_test.exs`

  **QA Scenarios**:

  ```
  Scenario: Student sees enrolled course modules and announcements
    Tool: Bash
    Steps: Run `cd wts-lms-api && mix test test/wts_lms_web/controllers/course_content_controller_test.exs --only student_enrolled`
    Expected: API returns syllabus, modules, pages, announcements, and dates for enrolled course.
    Evidence: .omo/evidence/task-7-content.txt

  Scenario: Student cannot access non-enrolled course content
    Tool: Bash
    Steps: Run `cd wts-lms-api && mix test test/wts_lms_web/controllers/course_content_controller_test.exs --only unauthorized_course`
    Expected: API returns 403 and no content payload.
    Evidence: .omo/evidence/task-7-content-error.txt
  ```

  **Commit**: YES | Message: `feat(wts): add course content APIs` | Files:
  [`wts-lms-api/lib/wts_lms/course_content/`, `wts-lms-api/test/`]

- [~] 8. Implement assignments, submissions, comments, and S3-backed files

  **What to do**: Implement assignments with text-entry, file-upload, and
  no-submission modes; submission timestamps; comments; S3-compatible
  upload/download flows with signed URLs or proxied authorization; attachment
  metadata; large/missing file handling. **Must NOT do**: Do not implement
  quizzes, peer review, group submissions, Turnitin, external-tool submissions,
  anonymous/moderated grading, or Canvas SpeedGrader parity.

  **Recommended Agent Profile**:
  - Category: `deep` - Reason: core LMS workflow plus storage/security.
  - Skills: [] - No special skill needed.
  - Omitted: [`librarian`] - Use existing S3 library docs only if needed.

  **Parallelization**: Can Parallel: YES | Wave 2B | Blocks: 9,10,11,12,15 |
  Blocked By: 1,2,4,5

  **References**:
  - Spec: `wts-lms-specs/gradebook_rules.md` - grading-related assignment rules.
  - Pattern: `app/controllers/files_controller.rb` - Canvas file permission
    complexity reference.
  - Pattern: `app/models/submission.rb` - Canvas submission complexity
    reference.

  **Acceptance Criteria**:
  - [ ] `cd wts-lms-api && mix test test/wts_lms/assignments test/wts_lms/files test/wts_lms_web/controllers/submission_controller_test.exs`

  **QA Scenarios**:

  ```
  Scenario: Student submits text and file assignment
    Tool: Bash
    Steps: Run `cd wts-lms-api && mix test test/wts_lms_web/controllers/submission_controller_test.exs --only file_and_text_submission`
    Expected: Submission saved with timestamp, text body, file metadata, and authorized download URL.
    Evidence: .omo/evidence/task-8-submissions.txt

  Scenario: Unauthorized file download is blocked
    Tool: Bash
    Steps: Run `cd wts-lms-api && mix test test/wts_lms/files/file_authorization_test.exs --only unauthorized_download`
    Expected: API returns 403 and does not expose object URL.
    Evidence: .omo/evidence/task-8-submissions-error.txt
  ```

  **Commit**: YES | Message: `feat(wts): add assignments submissions and files`
  | Files: [`wts-lms-api/lib/wts_lms/assignments/`,
  `wts-lms-api/lib/wts_lms/files/`, `wts-lms-api/test/`]

- [~] 9. Implement gradebook engine and CSV export

  **What to do**: Implement points + weighted assignment groups, final
  percentage/letter display, manual grading/comments, grade visibility rules,
  and CSV export with fixed headers/order/encoding. Explicitly define behavior
  for ungraded, missing, excused, late, resubmitted, extra credit, dropped
  scores, and unpublished assignments according to `gradebook_rules.md`. **Must
  NOT do**: Do not add late/missing automation, grade posting policies, rubrics,
  hidden/muted grades, overrides, analytics, or SIS grade passback unless
  `gradebook_rules.md` explicitly requires them.

  **Recommended Agent Profile**:
  - Category: `deep` - Reason: grade calculation correctness is critical.
  - Skills: [] - No special skill needed.
  - Omitted: [`rspec`] - Phoenix ExUnit only.

  **Parallelization**: Can Parallel: YES | Wave 2C | Blocks: 12,15 | Blocked By:
  1,4,5,8

  **References**:
  - Spec: `wts-lms-specs/gradebook_rules.md` - canonical grade behavior.
  - Pattern: `app/models/assignment.rb` - Canvas assignment-group complexity
    reference.

  **Acceptance Criteria**:
  - [ ] `cd wts-lms-api && mix test test/wts_lms/gradebook`
  - [ ] `cd wts-lms-api && mix wts.gradebook.verify --fixture test/fixtures/gradebook/weighted_groups.json`

  **QA Scenarios**:

  ```
  Scenario: Weighted groups calculate final grade
    Tool: Bash
    Steps: Run `cd wts-lms-api && mix test test/wts_lms/gradebook/weighted_groups_test.exs`
    Expected: Fixture final percentages and letter grades match `gradebook_rules.md` exactly.
    Evidence: .omo/evidence/task-9-gradebook.txt

  Scenario: Ungraded/missing cases follow explicit rules
    Tool: Bash
    Steps: Run `cd wts-lms-api && mix test test/wts_lms/gradebook/edge_cases_test.exs`
    Expected: Ungraded, missing, excused, late, and resubmitted cases match spec.
    Evidence: .omo/evidence/task-9-gradebook-error.txt
  ```

  **Commit**: YES | Message: `feat(wts): implement weighted gradebook` | Files:
  [`wts-lms-api/lib/wts_lms/gradebook/`, `wts-lms-api/test/`]

- [~] 10. Implement Oban-backed notifications and email/in-app delivery

  **What to do**: Add notification context, Oban workers, email adapter config,
  in-app unread notifications, and events for announcements, due-date changes,
  submission comments, and grade releases. Add delivery failure retry/audit
  behavior using Postmark as the selected transactional email provider for the
  pilot. **Must NOT do**: Do not implement Canvas-style notification
  preferences, digests, SMS, mobile push, or multi-channel frequency controls.

  **Recommended Agent Profile**:
  - Category: `unspecified-high` - Reason: background jobs and user-visible
    events.
  - Skills: [] - No special skill needed.
  - Omitted: [`tmux`] - No long-running dev server required.

  **Parallelization**: Can Parallel: YES | Wave 2C | Blocks: 12,15 | Blocked By:
  1,4,5,8

  **References**:
  - External: `https://hexdocs.pm/oban/` - Oban jobs.
  - External: `https://hexdocs.pm/oban/testing.html` - Oban test modes.

  **Acceptance Criteria**:
  - [ ] `cd wts-lms-api && mix test test/wts_lms/notifications`
  - [ ] `cd wts-lms-api && mix test test/wts_lms/workers`

  **QA Scenarios**:

  ```
  Scenario: Grade release sends email and in-app notification
    Tool: Bash
    Steps: Run `cd wts-lms-api && mix test test/wts_lms/notifications/grade_release_test.exs`
    Expected: Email job enqueued, in-app notification unread, event audit row written.
    Evidence: .omo/evidence/task-10-notifications.txt

  Scenario: Email failure retries and records error
    Tool: Bash
    Steps: Run `cd wts-lms-api && mix test test/wts_lms/workers/email_delivery_failure_test.exs`
    Expected: Job retry policy applies and failure is visible to admin/audit.
    Evidence: .omo/evidence/task-10-notifications-error.txt
  ```

  **Commit**: YES | Message: `feat(wts): add LMS notifications` | Files:
  [`wts-lms-api/lib/wts_lms/notifications/`, `wts-lms-api/lib/wts_lms/workers/`,
  `wts-lms-api/test/`]

- [~] 11. Implement Canvas import pipeline and automated diff harness

  **What to do**: Implement import staging, transforms from
  DAP/API/course-export fixtures to domain schema, file import manifest
  processing, idempotent re-runs, import audit logs, and diff command comparing
  source vs target counts/key fields using `migration_fidelity.md`. **Must NOT
  do**: Do not silently ignore mismatches; do not make historical archive data
  editable.

  **Recommended Agent Profile**:
  - Category: `deep` - Reason: migration fidelity and auditability.
  - Skills: [] - No special skill needed.
  - Omitted: [`update-gems`] - No Ruby gem updates.

  **Parallelization**: Can Parallel: YES | Wave 3A | Blocks: 15 | Blocked By:
  1,2,4,5,8,9

  **References**:
  - Spec: `wts-lms-specs/migration_fidelity.md` - mismatch thresholds and field
    rules.
  - Spec: `wts-lms-specs/migration/source_inventory.md` - source mapping.
  - External: DAP docs URL above.

  **Acceptance Criteria**:
  - [ ] `cd wts-lms-api && mix test test/wts_lms/imports`
  - [ ] `cd wts-lms-api && mix wts.import.diff --fixture test/fixtures/canvas_sample/pilot_course`

  **QA Scenarios**:

  ```
  Scenario: Import sample course and diff succeeds
    Tool: Bash
    Steps: Run `cd wts-lms-api && mix wts.import.reset && mix wts.import.run --fixture test/fixtures/canvas_sample/pilot_course && mix wts.import.diff --fixture test/fixtures/canvas_sample/pilot_course`
    Expected: Diff exits 0 and reports counts/key fields within tolerance.
    Evidence: .omo/evidence/task-11-import.txt

  Scenario: Deliberate missing assignment causes diff failure
    Tool: Bash
    Steps: Run `cd wts-lms-api && mix wts.import.diff --fixture test/fixtures/canvas_sample/pilot_course_missing_assignment`
    Expected: Diff exits non-zero with actionable missing assignment report.
    Evidence: .omo/evidence/task-11-import-error.txt
  ```

  **Commit**: YES | Message: `feat(wts): add Canvas import diff harness` |
  Files: [`wts-lms-api/lib/wts_lms/imports/`, `wts-lms-api/test/fixtures/`,
  `wts-lms-api/test/`]

- [~] 12. Implement React/TypeScript Student Teacher Admin workflows

  **What to do**: Build SPA workflows for login redirect/session handling,
  dashboard, course home, syllabus/modules/pages/files, announcements,
  assignment list/detail, text/file submission, teacher grading/comments,
  gradebook view/export, admin import/status view, and notification center.
  **Must NOT do**: Do not implement Canvas UI clone, Canvas app shell/js_env,
  quizzes, discussions, LTI tools, or mobile app compatibility.

  **Recommended Agent Profile**:
  - Category: `visual-engineering` - Reason: user-facing UI and accessibility.
  - Skills: [`ui`] - Needed for frontend UI/UX refinement.
  - Omitted: [`axe`] - iOS simulator not needed; use web accessibility tools.

  **Parallelization**: Can Parallel: YES | Wave 3A | Blocks: 15 | Blocked By:
  1,3,4,6,7,8,9,10

  **References**:
  - Spec: `wts-lms-specs/compatibility_matrix.md` - exact frontend scope.
  - API: generated OpenAPI/client from `wts-lms-api/`.

  **Acceptance Criteria**:
  - [ ] `cd wts-lms-web && npm test`
  - [ ] `cd wts-lms-web && npm run test:e2e`
  - [ ] `cd wts-lms-web && npm run axe`

  **QA Scenarios**:

  ```
  Scenario: Student completes assignment submission
    Tool: Playwright
    Steps: Log in as seeded student, open seeded course, open assignment, submit text and uploaded fixture file, view confirmation.
    Expected: Submission appears with timestamp and file name; API stores submission.
    Evidence: .omo/evidence/task-12-student-submission.png

  Scenario: Unauthorized student cannot open another course
    Tool: Playwright
    Steps: Log in as seeded student, navigate directly to non-enrolled course URL.
    Expected: UI shows access denied and no course content is rendered.
    Evidence: .omo/evidence/task-12-access-denied.png
  ```

  **Commit**: YES | Message: `feat(wts): add core coursework web UI` | Files:
  [`wts-lms-web/`]

- [x] 13. Implement managed-cloud operational readiness package

  **What to do**: Create deployment manifests/config templates for managed
  cloud, managed Postgres, S3-compatible storage, email provider, environment
  secrets, logging, monitoring, backup/restore, Oban queues, health checks, and
  incident runbooks. **Must NOT do**: Do not hard-code a vendor if WTS has not
  selected one; encode provider-neutral requirements and mark final provider
  selection as a gated decision.

  **Recommended Agent Profile**:
  - Category: `unspecified-high` - Reason: production ops planning and
    infrastructure scaffolding.
  - Skills: [] - No special skill needed.
  - Omitted: [`tmux`] - No server startup needed.

  **Parallelization**: Can Parallel: YES | Wave 4A | Blocks: 15 | Blocked By:
  1,4

  **References**:
  - Spec: `wts-lms-specs/ops_readiness.md` - ops requirements.

  **Acceptance Criteria**:
  - [ ] `test -f wts-lms-specs/ops/deployment.md && test -f wts-lms-specs/ops/backup_restore.md && test -f wts-lms-specs/ops/incident_response.md`
  - [ ] `grep -R "health check\|backup restore\|monitoring\|Oban\|S3\|email" wts-lms-specs/ops/`

  **QA Scenarios**:

  ```
  Scenario: Restore drill is scripted
    Tool: Bash
    Steps: Run `grep -R "restore drill" wts-lms-specs/ops/backup_restore.md`
    Expected: Restore drill steps and pass/fail criteria are present.
    Evidence: .omo/evidence/task-13-ops.txt

  Scenario: Missing provider decision remains gated
    Tool: Bash
    Steps: Run `grep -R "DECISION NEEDED: hosting provider\|DECISION NEEDED: email provider" wts-lms-specs/ops/`
    Expected: Undecided provider choices are explicit gates, not hidden assumptions.
    Evidence: .omo/evidence/task-13-ops-error.txt
  ```

  **Commit**: YES | Message: `docs(wts): add managed cloud readiness` | Files:
  [`wts-lms-specs/ops/`, deployment templates if created]

- [x] 13b. Convert ops readiness from provider-neutral to Fly.io hosting

  **What to do**: Update the managed-cloud readiness package to use Fly.io as
  the selected hosting provider for the pilot while preserving managed Postgres,
  S3-compatible storage, email, secrets, monitoring, backup/restore, Oban queue,
  health check, incident response, and rollback/fallback requirements. Add
  Fly.io-specific deployment template placeholders only where they do not require
  secrets. **Must NOT do**: Do not commit Fly.io tokens, private app names,
  production URLs, private WireGuard details, or billing/account identifiers.

  **Acceptance Criteria**:
  - [ ] `grep -R "Fly.io" wts-lms-specs/ops/`
  - [ ] `grep -R "fly.toml\|Machines\|Postgres\|secrets" wts-lms-specs/ops/`
  - [ ] `! grep -R -E "fly_[A-Za-z0-9]|access token|private key|wireguard" wts-lms-specs/ops/`

  **Commit**: YES | Message: `docs(wts): select Fly.io hosting` | Files:
  [`wts-lms-specs/ops/`, Fly.io template files if created]

- [x] 13c. Convert email readiness from provider-neutral to Postmark

  **What to do**: Update ops and notification readiness to use Postmark as the
  selected pilot transactional email provider. Capture required secret references,
  sender-domain setup, inbound/webhook event handling, bounce/complaint handling,
  suppression review, rate controls, delivery logs, and FERPA-safe evidence rules.
  **Must NOT do**: Do not commit Postmark API tokens, account IDs, private webhook
  secrets, real recipient addresses, or message bodies containing protected records.

  **Acceptance Criteria**:
  - [ ] `grep -R "Postmark" wts-lms-specs/ops/ wts-lms-specs/`
  - [ ] `grep -R "bounce\|complaint\|suppression\|webhook\|delivery" wts-lms-specs/ops/`
  - [ ] `! grep -R -E "POSTMARK_API_TOKEN=|server token|webhook secret:" wts-lms-specs/ops/`

  **Commit**: YES | Message: `docs(wts): select Postmark email` | Files:
  [`wts-lms-specs/ops/`, `wts-lms-specs/`]

- [~] 14. Add privacy, audit, security, and accessibility gates

  **What to do**: Add FERPA-conscious privacy rules, audit logs for
  login/import/grade/submission/file events, secure logging constraints, admin
  audit API, WCAG accessibility checks, keyboard navigation tests, and
  Playwright/axe coverage for day-one workflows. **Must NOT do**: Do not log
  PII/secrets/access tokens/file contents; do not treat accessibility as
  manual-only review.

  **Recommended Agent Profile**:
  - Category: `visual-engineering` - Reason: accessibility plus UI workflow
    verification.
  - Skills: [`ui`] - Needed for accessible UI patterns.
  - Omitted: [`axe`] - Mobile simulator not needed.

  **Parallelization**: Can Parallel: YES | Wave 4A | Blocks: 15 | Blocked By:
  1,4,6,8,12

  **References**:
  - Spec: `wts-lms-specs/privacy_accessibility.md` - privacy/accessibility
    requirements.

  **Acceptance Criteria**:
  - [ ] `cd wts-lms-api && mix test test/wts_lms/audit test/wts_lms/security`
  - [ ] `cd wts-lms-web && npm run axe && npm run test:e2e -- --grep @keyboard`

  **QA Scenarios**:

  ```
  Scenario: Grade change audit event is recorded without leaking secrets
    Tool: Bash
    Steps: Run `cd wts-lms-api && mix test test/wts_lms/audit/grade_audit_test.exs`
    Expected: Audit row includes actor/action/target/timestamp but no token or file content.
    Evidence: .omo/evidence/task-14-audit.txt

  Scenario: Student submission flow passes accessibility gate
    Tool: Playwright
    Steps: Run `cd wts-lms-web && npm run axe -- --path /courses/fixture/assignments/fixture`
    Expected: No critical accessibility violations; keyboard submission path works.
    Evidence: .omo/evidence/task-14-accessibility-error.txt
  ```

  **Commit**: YES | Message: `feat(wts): add audit privacy accessibility gates`
  | Files: [`wts-lms-api/`, `wts-lms-web/`,
  `wts-lms-specs/privacy_accessibility.md`]

- [~] 15. Run pilot readiness rehearsal with 2-3 real-course fixtures

  **What to do**: Select 2-3 low-risk real pilot courses, sanitize fixtures,
  create `scripts/wts_pilot_rehearsal.sh`, import the fixtures, run diff
  harness, run Student/Teacher/Admin Playwright flows, verify SAML/SIS
  contracts, verify notifications, verify backup/restore, and produce
  `wts-lms-specs/pilot/readiness_report.md` with pass/fail results and
  fallback/rollback triggers. **Must NOT do**: Do not launch pilot until every
  strict operational gate passes or is explicitly waived by WTS leadership in
  the report.

  **Recommended Agent Profile**:
  - Category: `deep` - Reason: full-system verification and launch gating.
  - Skills: [] - No special skill needed.
  - Omitted: [`git-master`] - No git history work.

  **Parallelization**: Can Parallel: NO | Wave 5A | Blocks: final verification |
  Blocked By: 1-14

  **References**:
  - Spec: `wts-lms-specs/pilot_success_failure.md` - numeric criteria and
    rollback triggers.
  - Spec: `wts-lms-specs/migration_fidelity.md` - migration mismatch criteria.

  **Acceptance Criteria**:
  - [ ] `test -x scripts/wts_pilot_rehearsal.sh`
  - [ ] `cd wts-lms-api && mix wts.import.diff --fixture test/fixtures/canvas_sample/pilot_course_1`
  - [ ] `cd wts-lms-web && npm run test:e2e -- --grep @pilot`
  - [ ] `grep -R "PASS\|FAIL\|rollback trigger\|fallback" wts-lms-specs/pilot/readiness_report.md`

  **QA Scenarios**:

  ```
  Scenario: Pilot course rehearsal passes strict operational gates
    Tool: Bash
    Steps: Run `scripts/wts_pilot_rehearsal.sh --fixtures pilot_course_1,pilot_course_2,pilot_course_3`
    Expected: Script exits 0; report shows no lost files/submissions/grades, correct grade calculations, successful UI flows, and backup restore pass.
    Evidence: .omo/evidence/task-15-pilot-rehearsal.txt

  Scenario: Rehearsal blocks launch on migration mismatch
    Tool: Bash
    Steps: Run `scripts/wts_pilot_rehearsal.sh --fixtures pilot_course_with_missing_submission`
    Expected: Script exits non-zero and readiness report marks pilot launch blocked with rollback/fix action.
    Evidence: .omo/evidence/task-15-pilot-rehearsal-error.txt
  ```

  **Commit**: YES | Message: `test(wts): add pilot readiness rehearsal` | Files:
  [`wts-lms-specs/pilot/`, `scripts/`, `wts-lms-api/test/fixtures/`,
  `wts-lms-web/tests/`]

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated
> results to user and get explicit "okay" before completing. **Do NOT
> auto-proceed after verification. Wait for user's explicit approval before
> marking work complete.** **Never mark F1-F4 as checked before getting user's
> okay.** Rejection or user feedback -> fix -> re-run -> present again -> wait
> for okay.

- [~] F1. Plan Compliance Audit — oracle
  - Required evidence: `.omo/evidence/f1-plan-compliance.md`
  - Pass command/evidence:
    `scripts/verify_plan_compliance.sh .omo/plans/wts-canvas-phoenix-replacement.md wts-lms-specs/ > .omo/evidence/f1-plan-compliance.md`
    exits 0 and reviewer confirms every completed task maps to this plan, every
    `DECISION NEEDED` gate is resolved or explicitly waived, and no day-one
    non-goal appears in implemented scope.
  - Failure condition: any implementation of LTI, quizzes, discussions, Canvas
    mobile compatibility, broad Canvas API, or full historical editable
    migration without user re-approval.
- [~] F2. Code Quality Review — unspecified-high
  - Required evidence: `.omo/evidence/f2-code-quality.md`
  - Pass command/evidence: `cd wts-lms-api && mix test` and
    `cd wts-lms-web && npm test` pass; reviewer reports no critical
    architecture/security defects.
  - Failure condition: failing tests, missing authorization checks for core
    routes, unreviewed secrets/PII logging, or unbounded Canvas schema
    mirroring.
- [~] F3. Real Manual QA — unspecified-high (+ playwright for UI)
  - Required evidence: `.omo/evidence/f3-manual-qa.md`, screenshots/videos under
    `.omo/evidence/f3/`
  - Pass command/evidence: `cd wts-lms-web && npm run test:e2e -- --grep @pilot`
    plus reviewer-driven browser QA for Student submission, Teacher grading,
    Admin import status, and unauthorized access.
  - Failure condition: student cannot submit, teacher cannot grade, admin cannot
    inspect import, unauthorized access succeeds, or evidence missing.
- [~] F4. Scope Fidelity Check — deep
  - Required evidence: `.omo/evidence/f4-scope-fidelity.md`
  - Pass command/evidence:
    `scripts/verify_scope_fidelity.sh wts-lms-specs/ wts-lms-api/ wts-lms-web/ > .omo/evidence/f4-scope-fidelity.md`
    exits 0 and reviewer compares implementation to
    `wts-lms-specs/compatibility_matrix.md`, `non_goals.md`,
    `gradebook_rules.md`, and `pilot_success_failure.md`; all Preserve items
    covered, Simplify items match spec, Exclude items absent.
  - Failure condition: any Preserve item missing, any Simplify item exceeding
    spec without approval, or any Exclude item implemented.

## Commit Strategy

- Commit each task independently.
- Use concise messages matching Canvas guidance where applicable, but this new
  WTS code can use conventional-style messages shown per task.
- Never combine spec decisions, backend implementation, frontend implementation,
  and pilot readiness in one commit.
- Include test evidence paths in commit body or PR description.

## Success Criteria

- WTS has explicit day-one scope and non-goals.
- DAP/API/file-export migration assumptions are proven against real WTS data
  before core build-out depends on them.
- Populi/SAML and SIS sync contracts are executable and tested.
- Phoenix API and React SPA support Core Coursework for Student/Teacher/Admin.
- Active-course import/diff, gradebook, submissions, files, notifications, and
  UI workflows are fully automated.
- Pilot readiness report proves strict operational criteria for 2-3 real courses
  before broader replacement discussion.
