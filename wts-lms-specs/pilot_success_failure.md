# Pilot Success And Failure Spec

## Scope

The first production proof is a 2-3 real-course pilot for WTS Core Coursework. Pilot launch is allowed only after prior task gates pass for specs, migration, SIS/Auth, API, UI, gradebook, notifications, ops, privacy, accessibility, and rehearsal.

## Numeric Success Thresholds

- numeric threshold: 2-3 low-risk real courses are selected, sanitized for fixtures, imported, diffed, and rehearsed before launch.
- numeric threshold: 100% of pilot Students, Teachers, Admins, courses, sections, enrollments, assignments, submissions, files, comments, grades, and legacy Canvas ID mappings required by the selected fixtures pass migration diff verification.
- numeric threshold: 0 blocking mismatches are allowed at launch.
- numeric threshold: At least 99.5% field-level match is required for normalized non-blocking content fields.
- numeric threshold: 100% of pilot happy-path Student, Teacher, and Admin workflows must pass automated UI/API checks.
- numeric threshold: 0 critical WCAG accessibility violations and 0 FERPA/privacy logging violations are allowed for pilot workflows.

## Mismatch Tolerance

- mismatch tolerance: The pilot accepts no missing required academic, content, submission, grade, file, or auth records.
- mismatch tolerance: Formatting-only content differences may be accepted only within the 0.5% non-blocking tolerance and must appear in the readiness report.
- mismatch tolerance: Any mismatch that changes access, grade outcome, submission state, due date, file availability, or identity mapping is blocking.

## Pass Criteria

- PASS when all required Task 1-14 verification commands pass, pilot rehearsal exits 0, and the readiness report lists no active rollback trigger or fallback trigger.
- PASS when Teacher/Admin grade CSV output matches the migrated gradebook rules for every pilot fixture.
- PASS when Student users can discover courses, read content, submit coursework, view comments, and see grades for in-scope workflows.
- PASS when operations has backup, restore drill, monitoring, logs, incident, and archive fallback procedures ready.

## Failure Criteria And Triggers

- FAIL when any prior required acceptance command fails.
- FAIL when any Preserve item in `compatibility_matrix.md` is absent from fixtures, contracts, or implementation.
- FAIL when any Simplify item exceeds the documented simplified scope without approval.
- FAIL when any Exclude item is implemented or required for launch.
- rollback trigger: Any blocking migration mismatch, grade discrepancy, authorization error, missing file, broken submission workflow, or failed restore rehearsal blocks launch or returns the course to hosted Canvas/archive access.
- rollback trigger: Any FERPA-significant data exposure, critical WCAG violation in a pilot workflow, or inability to revoke disabled-user access blocks launch.
- fallback trigger: If Phoenix is unavailable during pilot, instructors and students use the documented hosted Canvas/archive fallback path for the affected course until service is restored.
- fallback trigger: If a source data gap prevents faithful import, use documented DAP/API/course-export/file-download fallback source; if none exists, the course is removed from pilot scope.
