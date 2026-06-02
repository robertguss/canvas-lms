# WTS Replacement Non-Goals

## Scope Boundary

The WTS Phoenix LMS replaces WTS day-one Core Coursework usage of hosted Canvas. It is not a generic Canvas clone. It serves Student Teacher Admin workflows for active, current, and future coursework, with historical Canvas material retained through read-only export/archive access.

## Explicit Day-One Non-Goals

| Non-goal | Decision | Rationale | Verification phrase |
| --- | --- | --- | --- |
| Generic Canvas clone | Exclude | WTS needs a focused replacement for its hosted Canvas Core Coursework workflows, not full Instructure product parity. | Generic Canvas clone Exclude |
| Official Canvas mobile support | Exclude | Day-one UI is the WTS React web SPA. Canvas mobile app API behavior is outside the replacement proof. | Canvas mobile Exclude |
| Broad Canvas API compatibility | Exclude | Only API contracts used by the WTS frontend, migration harness, and verification tools are in scope. | Broad Canvas API Exclude |
| LTI, external tools, developer keys, grade passback | Exclude | External tool ecosystems are not required for the pilot and would expand the product beyond Core Coursework. | No LTI Exclude |
| Quizzes and New Quizzes | Exclude | Day-one assessment scope is assignments with text-entry, file-upload, and no-submission types. | No quizzes Exclude |
| Discussions | Exclude | Course communication is announcements, comments, simple email, and in-app notifications. | Discussions Exclude |
| Rubrics, outcomes, groups, collaborations | Exclude | These Canvas collaboration and assessment-management features are outside the pilot proof. | Rubrics outcomes groups collaborations Exclude |
| Plugins and Canvas extension parity | Exclude | The Phoenix system will use WTS-owned contracts instead of Canvas plugin architecture. | Plugins Exclude |
| Advanced gradebook parity | Exclude | The gradebook preserves WTS-required points, weighted groups, final percentage, letter display, CSV export, and documented edge cases only. | Advanced gradebook parity Exclude |
| Full historical editable migration | Exclude | Active/current/future data migrates into Phoenix; old Canvas/export/archive data remains read-only unless a later approved task changes that. | Full historical editable migration Exclude |
| Phoenix as SIS/Registrar authority | Exclude | SIS/Registrar remains authoritative for users, terms, courses, sections, roles, and enrollments. | SIS authority Exclude |

## Required Positive Scope

- Preserve Student Teacher Admin day-one roles only.
- Preserve Core Coursework course access, syllabus, modules, pages, readings, files, announcements, assignments, submissions, comments, grading comments, timestamps, grade display, CSV export, S3-compatible file storage, simple notifications, Populi SAML authentication, SIS-owned academic records, and DAP/API/file-export migration verification.
- Simplify Canvas behavior wherever WTS does not need generic parity, mobile compatibility, plugin extension points, or broad Canvas API compatibility.
- Exclude every non-goal above from implementation, tests, fixtures, and acceptance evidence unless a later plan task explicitly changes the scope.
