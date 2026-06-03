# SIS And Authentication Contract Index

## Scope

This top-level contract freezes Task 1 expectations for Populi SAML authentication and SIS/Registrar synchronization. Detailed Task 3 contracts live in `wts-lms-specs/integrations/populi_saml.md` and `wts-lms-specs/integrations/sis_sync.md` and are preserved as the implementation source.

## Authority Rules

- SIS/Registrar remains authoritative for users, terms, courses, sections, roles, and enrollments.
- Populi remains the SAML identity provider.
- Phoenix stores mirrored academic records, session state, authorization derived from SIS, audit events, LMS activity, and import metadata.
- Phoenix must not provide normal local-password auth for Students, Teachers, or Admins.

## Required Authentication Cases

| Case | Expected contract |
| --- | --- |
| valid assertion | A valid assertion with signed response, correct audience, `NameID`, normalized `email`, and `sis_user_id` matching one active SIS user creates a Phoenix session and audit event. |
| missing attribute | A missing attribute such as absent `NameID`, `email`, or `sis_user_id` rejects login before user lookup and records a non-enumerating audit reason. |
| disabled user | A disabled user or blocked SIS status rejects login, creates no session, and preserves audit attribution. |
| identity conflict | Conflicting `sis_user_id`, `email`, or `NameID` bindings reject login and report a security conflict. |
| unsupported role | A user without Student, Teacher, or Admin day-one role cannot gain LMS access. |

## Required SIS Sync Cases

| Case | Expected contract |
| --- | --- |
| idempotent | Re-running the same extract with the same source identity and row contents creates no duplicates and no side effects beyond recording the re-run. |
| add/drop | An add creates or reactivates enrollment; a drop removes access at the next authorization check without deleting submissions, grades, comments, files, or audit history. |
| role change | Role changes apply only for Student, Teacher, or Admin and take effect at the next authorization check. |
| section change | Section changes preserve prior submissions and grades while enforcing access to the new SIS-owned section. |
| conflict | Duplicate keys, missing references, unsupported roles, stale rows, or unsafe omissions are quarantined or failed with operator-readable reporting. |

## Preservation Rule

This file summarizes the executable contract surface. Later implementation must preserve the detailed integration contracts and may not weaken the valid assertion, missing attribute, disabled user, idempotent, or add/drop cases.
