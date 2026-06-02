# Canvas Pilot-Course Sanitization Workflow

This workflow defines how the migration lead produces a real sanitized active-course sample from Canvas DAP records, Canvas REST responses, course export metadata, and file-download manifests. It does not implement the import pipeline and does not unblock production import, file, submission, or gradebook work until the sanitized sample is approved and committed.

## Required Approvals

- The migration lead selects the pilot course, runs the sanitizer, captures validation evidence, and records unresolved source gaps.
- A WTS data/privacy owner must approve the sanitized output before it is committed.
- The no raw private data rule applies before commit. This includes student names, faculty names, real emails, grades, submission text, comments, access tokens, SAML assertions, private URLs, real course identifiers, and private file bytes.
- The real sanitized sample blocker in `source_inventory.md` and the project notepad remains open until the approved sample exists in the fixture tree.

## Representative Low-Risk Pilot Course

Select one active WTS Core Coursework course that is representative but low risk:

- Include modules, pages, at least one course file, a text-entry assignment, a file-upload assignment, and a no-submission assignment.
- Include ordinary submissions, comments, and grades needed to prove relationships and gradebook calculations.
- Prefer routine FERPA data only; avoid unusual sensitive edge cases such as accommodations, disciplinary content, health information, pastoral counseling details, or unusually identifying file names.
- Avoid courses with external-tool/LTI, quizzes, discussions beyond announcements, or non-Core Coursework surfaces that are outside day-one scope.

## Source Inputs

- DAP provides table-like Canvas records and metadata only. Preserve entity shape, legacy Canvas IDs, dates, workflow states, content types, relationships, and source table names.
- Canvas REST responses verify runtime semantics, submission/comment detail, assignment/page/module presentation, and source gaps not proven by DAP.
- Course export metadata verifies `imsmanifest.xml`, module ordering, page/assignment body resource references, and course file references without committing raw private content.
- File downloads provide byte evidence. DAP metadata alone is not proof of file bytes; every pilot course file and submission attachment needs REST, course export, or file download evidence with checksum and byte size.

## Sanitization Checklist

1. Export DAP records for the selected active course into a private workspace outside the repository.
2. Fetch the required Canvas REST responses in the same private workspace without committing raw response bodies.
3. Generate course export metadata summaries from the IMSCC package; do not commit raw private page bodies, assignment bodies, or file bytes.
4. Download or otherwise verify every course file and submission attachment outside the repository, then produce a manifest row with legacy Canvas attachment ID, sanitized source reference, SHA-256 checksum, byte size, content type, and sanitization status.
5. Replace identities with stable synthetic labels that preserve roles and relationships, such as Student 001, Teacher 001, and Admin 001.
6. Replace private course identifiers, section names, file names, submission text, comments, grade details, and private URLs with synthetic values while preserving required legacy Canvas IDs and relationship keys.
7. Run `scripts/wts_sanitize_canvas_sample.sh --validate wts-lms-api/test/fixtures/canvas_sample/pilot_course`.
8. Review the sanitized fixture manually against FERPA rules in `wts-lms-specs/privacy_accessibility.md`.
9. Obtain WTS data/privacy owner approval before commit and record the approval in the migration evidence notes.

## Validator Rules

`scripts/wts_sanitize_canvas_sample.sh` is the repository gate for sanitized sample fixtures. It supports `--help` and `--validate FIXTURE_DIR`.

The validator fails closed when required DAP, REST, course export, or file-download manifests are missing. It rejects raw-looking emails, access tokens, private Canvas/WTS URLs, and real file-download manifests that lack checksum or byte size evidence. It reports only file paths and rule names, not private values.

Example:

```bash
scripts/wts_sanitize_canvas_sample.sh --validate wts-lms-api/test/fixtures/canvas_sample/pilot_course
```

The current placeholder fixture may pass as a non-sensitive shape marker, but that pass is not approval of a real sample and does not lift downstream blockers.
