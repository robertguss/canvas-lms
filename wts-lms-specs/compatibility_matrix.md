# Canvas Behavior Compatibility Matrix

## Decision Vocabulary

- Preserve means Phoenix must match the WTS-observed Canvas behavior closely enough for pilot users and automated fixtures.
- Simplify means Phoenix implements the WTS-required outcome through a smaller product surface, with no generic Canvas parity promise.
- Exclude means the behavior is out of day-one scope and must not be implemented as accidental scope creep.

## Matrix

| Canvas behavior area | Decision | Day-one WTS contract | Exclusion guardrail |
| --- | --- | --- | --- |
| Student Teacher Admin roles | Preserve | Preserve only Student, Teacher, and Admin authorization derived from SIS-owned records. | Exclude unsupported Canvas roles and custom role proliferation. |
| Course membership from SIS | Preserve | Preserve SIS/Registrar source of truth for users, terms, courses, sections, roles, and enrollments. | Exclude Phoenix-owned academic record edits as source of truth. |
| Populi SAML login | Preserve | Preserve SAML browser login mapped to SIS-synced users through the integration contracts. | Exclude normal local-password auth for day-one users. |
| Courses and sections | Preserve | Preserve active/current/future Core Coursework course and section access with legacy Canvas ID mappings. | Exclude full Canvas course settings parity. |
| Syllabus, modules, pages, readings, files | Preserve | Preserve teacher-managed course content required by WTS Core Coursework. | Exclude Canvas plugin or LTI content surfaces. |
| Announcements | Preserve | Preserve course announcements visible to enrolled users. | Exclude discussion-board parity. |
| Assignment dates and calendar display | Preserve | Preserve due, available, and lock date behavior required for pilot coursework. | Exclude broad Canvas calendar API compatibility. |
| Text-entry assignments | Preserve | Preserve text submission workflow, timestamps, comments, and grading comments. | Exclude quiz-style response engines. |
| File-upload assignments | Preserve | Preserve upload, permissioned download, timestamp, comments, and grading comments. | Exclude external tool submission handoffs. |
| No-submission assignments | Preserve | Preserve gradebook-visible assignments without student upload text. | Exclude attendance or advanced assignment types unless later approved. |
| Points and weighted assignment groups | Preserve | Preserve final percentage and letter display using `gradebook_rules.md`. | Exclude advanced gradebook parity beyond specified edge cases. |
| Grade CSV export | Preserve | Preserve Teacher/Admin CSV export for pilot grade reporting. | Exclude broad Canvas gradebook import/export parity. |
| S3-compatible file storage | Preserve | Preserve permissioned object storage for course files and submission uploads. | Exclude Canvas file storage internals. |
| Simple email and in-app notifications | Simplify | Simplify to essential assignment, comment, grade, and announcement notifications. | Exclude complex notification preferences and channels day one. |
| Canvas REST API | Simplify | Simplify to REST endpoints used by the WTS React SPA, import diff harness, and contract tests. | Broad Canvas API Exclude. |
| Canvas UI | Simplify | Simplify into a WTS React/TypeScript SPA for Student Teacher Admin workflows. | Generic Canvas clone Exclude. |
| Migration source access | Simplify | Simplify migration to DAP/API/file-export inputs with automated diff reports. | Exclude manual point-and-click migration as the primary path. |
| Historical course access | Simplify | Simplify to read-only old Canvas/export/archive strategy for non-active historical records. | Full historical editable migration Exclude. |
| Operational administration | Simplify | Simplify to managed-cloud health, backup, restore, monitoring, logs, and incident runbooks. | Exclude self-hosted Canvas operational parity. |
| FERPA and WCAG controls | Preserve | Preserve privacy-conscious logging and WCAG-oriented checks for pilot workflows. | Exclude accessibility as best-effort only. |
| Mobile app compatibility | Exclude | Canvas mobile Exclude. | Do not implement official Canvas mobile app support day one. |
| LTI and external tools | Exclude | LTI Exclude. | Do not implement LTI, external tools, developer keys, or grade passback day one. |
| Quizzes and New Quizzes | Exclude | Quizzes Exclude. | Do not implement quizzes/New Quizzes day one. |
| Discussions | Exclude | Discussions Exclude. | Do not implement Canvas discussions day one. |
| Rubrics, outcomes, groups, collaborations | Exclude | Rubrics outcomes groups collaborations Exclude. | Do not implement these Canvas feature families day one. |
| Plugins | Exclude | Plugins Exclude. | Do not recreate Canvas plugin architecture. |
| Advanced gradebook parity | Exclude | Advanced gradebook parity Exclude. | Do not implement gradebook behavior not listed in `gradebook_rules.md`. |
