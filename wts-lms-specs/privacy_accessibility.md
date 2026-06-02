# Privacy And Accessibility Spec

## Scope

The WTS Phoenix LMS must protect student educational records and provide WCAG-oriented access for day-one Core Coursework workflows. Task 14 will implement detailed gates; Task 1 freezes the expectations.

## FERPA And Privacy Rules

- FERPA: Treat grades, submissions, comments, enrollment status, course membership, identity mappings, files, and audit trails as protected educational records.
- FERPA: Logs must not include passwords, SAML assertions, secrets, access tokens, full file contents, full submission bodies, or unnecessary grade details.
- FERPA: Audit events must identify who accessed or changed protected records, when, from where, and why, using correlation IDs and reason codes.
- FERPA: Student users may access only their own enrolled course records; Teachers may access assigned sections; Admins may access only operationally necessary records.
- FERPA: Migration fixtures used for automated tests must be sanitized before committing.

## WCAG Accessibility Rules

- WCAG: Student, Teacher, and Admin pilot workflows must support keyboard navigation, visible focus, semantic headings, labels, error messages, and screen-reader-friendly status updates.
- WCAG: Submission, grading, file download/upload, announcement, gradebook, and admin import/status views must have automated accessibility checks before pilot launch.
- WCAG: Critical accessibility violations block pilot readiness.
- WCAG: Accessibility is a release gate, not a best-effort cleanup.

## Preserve/Simplify/Exclude Linkage

- Preserve FERPA-conscious logging, auditability, least-privilege access, and WCAG-oriented checks for pilot workflows.
- Simplify privacy and accessibility scope to Student Teacher Admin Core Coursework workflows first.
- Exclude broad Canvas UI parity, official Canvas mobile support, and plugin/external tool surfaces from day-one privacy/accessibility testing.
