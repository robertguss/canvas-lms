## 2026-06-02 Task: work-session-start
- Execution is in current project directory; no worktree path is set in `.omo/boulder.json`.
- Use contract-first TDD and write executable specs/gates before implementation.

## 2026-06-02 Task 3: Populi SAML and SIS sync contracts
- Use `sis_user_id` as the primary external identity key; use SAML `NameID` as an IdP binding verification key; use normalized `email` as a verification and contact/display key.
- Treat SIS/Registrar records as authoritative for users, terms, courses, sections, roles, and enrollments; Phoenix stores mirrored academic records and Phoenix-owned LMS activity only.

## 2026-06-02 Task 4: Phoenix API and React SPA scaffold
- Used minimal dependency-free compatible scaffolds for `wts-lms-api/` and `wts-lms-web/` so required Mix/npm gates run locally without generator or package-fetch assumptions.
- Kept the primary UI as a separate React/TypeScript SPA scaffold; no Canvas Rails app integration and no LiveView primary UI path were added.

## 2026-06-02 Task 1: WTS replacement spec package
- Preserve/Simplify/Exclude is the Task 1 compatibility vocabulary. Preserve covers WTS-required Core Coursework behavior; Simplify covers smaller WTS-specific equivalents; Exclude blocks day-one Canvas parity scope creep.
- Migration and pilot gates use zero blocking mismatches, 100% required record/file coverage, and 99.5% field-level match for normalized non-blocking content as numeric thresholds.

## 2026-06-02 Task 2: Canvas migration source inventory
- Treat SIS as authoritative for users, terms, courses, sections, and enrollments; use DAP/REST/course export/file download as Canvas migration and legacy ID mapping sources.
- Keep mocked-only data prohibited for Tasks 5, 8, and 11 until `source_inventory.md` records real sanitized sample evidence or an explicit blocker with owner and next action.
