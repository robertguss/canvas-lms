# Migration Fidelity Spec

## Scope

Migration fidelity applies to active, current, and future WTS Core Coursework moved into Phoenix from DAP, Canvas REST APIs, course exports, and file downloads. Historical Canvas records outside pilot-active coursework remain available read-only through old Canvas/export/archive strategy and are not fully editable Phoenix records.

## Fidelity Targets

| Entity family | Preserve target | Allowed simplification |
| --- | --- | --- |
| Users, terms, courses, sections, enrollments | Preserve SIS-owned identifiers, statuses, roles, and relationships. | Phoenix stores mirrored records and legacy Canvas ID mappings, not Canvas operational schema. |
| Course content | Preserve syllabus, modules, pages, readings, files, and announcements needed for pilot courses. | Simplify Canvas presentation metadata not used by WTS workflows. |
| Assignments and submissions | Preserve text-entry, file-upload, no-submission assignments, dates, submissions, comments, grading comments, and timestamps. | Simplify unsupported Canvas assignment types into excluded migration findings. |
| Grades | Preserve points, weighted groups, final percentage, letter display, CSV export, and `gradebook_rules.md` edge cases. | Simplify advanced gradebook parity outside the gradebook spec. |
| Files | Preserve file identity, permissioned access, owner/course association, checksums when available, and S3 object mapping. | Simplify Canvas storage internals. |

## Numeric Thresholds

- numeric threshold: A pilot-course import passes only when 100% of required SIS-owned identity, course, section, enrollment, assignment, submission, grade, file manifest, and legacy Canvas ID mapping records are present for the selected fixture set.
- numeric threshold: Content body normalization may tolerate formatting-only differences, but required pages, modules, readings, files, announcements, assignment descriptions, comments, and timestamps must reach at least 99.5% field-level match across the pilot fixture set.
- numeric threshold: File payload verification must reach 100% checksum or byte-size match for every file that Canvas/DAP/export source makes available.
- mismatch tolerance: The automated diff harness may allow at most 0 blocking mismatches and at most 0.5% non-blocking normalized text mismatches across pilot fixture fields.
- mismatch tolerance: Any missing required assignment, submission, enrollment, grade, file, or user mapping is a blocking mismatch regardless of percentage.

## Failure And Recovery Language

- rollback trigger: If a pilot import produces any blocking mismatch, the import is not promoted and the pilot course remains on hosted Canvas or read-only archive until the mismatch is fixed and diff verification exits 0.
- rollback trigger: If a promoted import corrupts Phoenix-owned pilot data, restore the last verified database backup and S3 object snapshot before reopening the course.
- fallback trigger: If DAP lacks payloads required for a pilot course, use Canvas REST API, course export, or file downloads as the documented fallback input and record the source in the import report.
- fallback trigger: If no source can provide a required day-one field, block migration for that course and record a decision in the notepad before implementation proceeds.

## Verification Requirements

- Every migrated record that originated in Canvas keeps a legacy Canvas ID mapping where Canvas supplies a stable ID.
- Every import job emits a machine-readable diff report with pass/fail status, counts, mismatch tolerance application, rollback trigger evaluation, and fallback trigger usage.
- Diff reports must distinguish Preserve, Simplify, and Exclude outcomes so excluded Canvas features do not masquerade as successful imports.
