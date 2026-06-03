## 2026-06-02 Task: work-session-start
- Treat every `DECISION NEEDED` and `BLOCKER` as blocking until resolved or explicitly waived.

## 2026-06-02 Task 3: Populi SAML and SIS sync contracts
- DECISION NEEDED: confirm Phoenix session absolute and idle expiration durations before Task 6 implementation.
- DECISION NEEDED: confirm SIS sync frequency, acceptable propagation delay for add/drop changes, and Populi integration mode before Task 6 implementation.

## 2026-06-02 Task 1: WTS replacement spec package
- No Task 1 blocker found. Verification evidence captured in `.omo/evidence/task-1-spec-package.txt` and `.omo/evidence/task-1-spec-package-error.txt`.

## 2026-06-02 Task 2: Canvas migration source inventory
- BLOCKER: No real sanitized sample for the representative active course has been committed yet; placeholders are non-sensitive shape markers only and do not unblock production-quality Tasks 5, 8, or 11.
- BLOCKER: File payload verification cannot rely on DAP metadata alone; the migration lead must prove REST/course export/file download byte acquisition with checksum and byte-size evidence for every pilot course file and submission attachment.

## 2026-06-02 Task 5: WTS LMS domain schema
- BLOCKER: `wts-lms-api` still has the Task 4 dependency-free scaffold with no Ecto Repo or SQL adapter, so `mix ecto.migrate` validates the migration manifest deterministically instead of applying real database DDL. Owner: backend/API lead. Next action: choose Repo/adapter dependencies and convert the manifest to real Ecto SQL migrations when external dependency selection is approved.
- BLOCKER: No real sanitized active-course sample is present, so schema coverage is contract-level and not production-import fidelity for files, submissions, gradebook edge cases, or migrated content bodies. Owner: migration lead. Next action: provide the sanitized pilot sample recorded in `wts-lms-specs/migration/source_inventory.md`.

## 2026-06-02 Task 13: Managed-cloud operational readiness package
- DECISION NEEDED: hosting provider remains unresolved; ops docs define provider-neutral requirements and escalation placeholders but do not mark hosting selected.
- DECISION NEEDED: email provider remains unresolved; ops docs define delivery, logging, bounce/complaint, and health-check requirements but do not mark email selected.
- BLOCKER remains: `wts-lms-api` has no real Ecto Repo or SQL adapter, so managed Postgres restore validation is a future deployment dependency rather than completed implementation evidence.
- BLOCKER remains: no real sanitized active-course sample is committed, so final pilot restore evidence cannot claim production import/file fidelity yet.

## 2026-06-02 Task 2b: Canvas pilot-course sanitization workflow
- BLOCKER remains: no real sanitized active-course sample is committed yet; Task 2b added the workflow and validator only, so downstream production importer/file/submission/gradebook tasks still need approved sample evidence.
- BLOCKER remains: WTS data/privacy owner approval is required before committing any real sanitized Canvas sample.

## 2026-06-02 Task 5b: Ecto/Postgres Repo
- No active Task 5b Postgres availability blocker remains on this workstation. Initial `mix ecto.create` failed because local Postgres lacked role `postgres`; dev/test config now defaults to the OS user with environment overrides, and `mix ecto.create`, `mix ecto.migrate`, and targeted tests pass.
- BLOCKER remains from prior migration work: no real sanitized active-course sample is committed, so this task proves schema/constraint behavior but not production import/file/submission/gradebook fidelity.

## 2026-06-02 Task 6: Populi SAML, SIS sync, and role authorization
- No implementation blocker remains for the minimal Phoenix API contract surface; required targeted tests and dry-run command pass locally.
- Stale `DECISION NEEDED` text remains in `wts-lms-specs/integrations/populi_saml.md` and `wts-lms-specs/integrations/sis_sync.md`, but Task 6 implemented the resolved plan values: 8-hour idle timeout, 12-hour absolute expiration, hourly SIS sync expectation, max 2-hour add/drop propagation, Populi metadata URL mode, and Registrar-owned conflicts.
- The stale spec files were not edited because Task 6 scope explicitly prohibited modifications outside `wts-lms-api/`, `.omo/evidence/`, and `.omo/notepads/wts-canvas-phoenix-replacement/`.
- Retry finding: Atlas correctly flagged that `duplicate_lines/2` only conflicted later duplicate `sis_user_id` rows. Fixed by grouping the whole extract by `sis_user_id` and returning all lines for any repeated key.

## 2026-06-02 Task 13b: Fly.io ops readiness
- Hosting provider gate is resolved for the pilot: Fly.io selected.
- Email provider gate remains unresolved in these ops docs for Task 13c to handle; S3-compatible object storage provider remains a separate unresolved decision.
- BLOCKER remains: no real sanitized active-course sample is committed, so final pilot restore evidence and migration/file fidelity cannot be claimed yet.

## 2026-06-02 Task 13c: Postmark email readiness
- Email provider gate is resolved for the pilot: Postmark selected for transactional email.
- S3-compatible object storage provider remains a separate unresolved decision; this task did not select or imply an object storage provider.
- BLOCKER remains: no real sanitized active-course sample is committed, so final pilot restore, migration, and file-fidelity readiness cannot be claimed yet.

## 2026-06-02 Task 7: Course content API
- No Task 7 implementation blocker remains for the contract API surface; targeted content/controller tests and full `mix test` pass locally.
- BLOCKER remains from migration tasks: no real sanitized active-course sample is committed, so this task uses deterministic contract fixtures and does not claim production migration/file fidelity.
