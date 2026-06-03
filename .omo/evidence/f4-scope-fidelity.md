# F4 Scope Fidelity Check

## Required Verifier

Command run from repo root:

```bash
scripts/verify_scope_fidelity.sh wts-lms-specs/ wts-lms-api/ wts-lms-web/ > .omo/evidence/f4-scope-fidelity.md
```

Exit status: 0

Captured script output before this reviewer analysis replaced the file with the full evidence package:

```text
scope fidelity verified
```

## Reviewed Source Material

Specs and readiness files read:

- `wts-lms-specs/compatibility_matrix.md`
- `wts-lms-specs/non_goals.md`
- `wts-lms-specs/gradebook_rules.md`
- `wts-lms-specs/pilot_success_failure.md`
- `wts-lms-specs/pilot/readiness_report.md`

Notepads read:

- `.omo/notepads/wts-canvas-phoenix-replacement/learnings.md`
- `.omo/notepads/wts-canvas-phoenix-replacement/issues.md`

Representative implementation read:

- `wts-lms-api/lib/wts_lms/schema.ex`
- `wts-lms-api/lib/wts_lms/course_content/content.ex`
- `wts-lms-api/lib/wts_lms/assignments/assignments.ex`
- `wts-lms-api/lib/wts_lms/files/files.ex`
- `wts-lms-api/lib/wts_lms/files/signed_url.ex`
- `wts-lms-api/lib/wts_lms/gradebook/gradebook.ex`
- `wts-lms-api/lib/wts_lms/imports/imports.ex`
- `wts-lms-api/lib/wts_lms/notifications/notifications.ex`
- `wts-lms-api/lib/wts_lms/notifications/email_delivery.ex`
- `wts-lms-api/lib/wts_lms/workers/email_delivery_worker.ex`
- `wts-lms-api/lib/wts_lms/identity/populi_saml.ex`
- `wts-lms-api/lib/wts_lms/sis/dry_run.ex`
- `wts-lms-api/lib/wts_lms/authorization/role_authorization.ex`
- `wts-lms-api/lib/wts_lms/audit/audit.ex`
- `wts-lms-api/lib/wts_lms/security/secure_log.ex`
- `wts-lms-api/lib/wts_lms_web/auth_controller.ex`
- `wts-lms-api/lib/wts_lms_web/course_content_controller.ex`
- `wts-lms-api/lib/wts_lms_web/controllers/submission_controller.ex`
- `wts-lms-web/src/App.tsx`
- `wts-lms-web/src/api/client.ts`
- Representative WTS tests for gradebook, imports, submissions, workflows, pilot e2e, and accessibility.

Searches performed:

- Exclude terms across WTS API/web/spec/script paths: LTI, external tools, developer keys, grade passback, quizzes/New Quizzes, discussions, rubrics, outcomes, collaborations, plugins, Canvas mobile, broad Canvas API, generic Canvas clone, full historical editable migration, advanced gradebook parity, local-password auth, SpeedGrader, `js_env`.
- Preserve/Simplify terms across WTS API/web paths: courses, syllabus, modules, pages, files, announcements, assignments, submissions, gradebook, grade CSV, notifications, SAML, SIS, FERPA, WCAG, audit, accessibility, import, diff, legacy Canvas, fallback, rollback, launch blocked.
- Gradebook terms across WTS gradebook implementation/tests/spec: weighted groups, final percentage, letter display, CSV, ungraded, missing, excused, late, resubmitted, extra credit, dropped scores, unpublished assignments.

## Scope Contract Summary

The specs define a WTS-hosted Canvas replacement for day-one Core Coursework only. Preserve scope is Student Teacher Admin roles; SIS-owned users/terms/courses/sections/enrollments; Populi SAML login; current/future course content; announcements; assignment dates; text-entry, file-upload, and no-submission assignments; comments and grading comments; gradebook rules; CSV export; S3-compatible storage; FERPA/WCAG/audit controls; import/diff; and pilot gates. Simplify scope is the WTS SPA and WTS-owned REST/import/ops surfaces, not Canvas parity. Exclude scope is generic Canvas clone, Canvas mobile, broad Canvas API, LTI/external tools/developer keys/grade passback, quizzes, discussions, rubrics/outcomes/groups/collaborations, plugins, advanced gradebook parity, full historical editable migration, local-password day-one auth, and Phoenix as SIS authority.

## Preserve Coverage

- Courses/content: covered. `WtsLms.Schema` defines WTS-owned course, section, module, page, content-file, announcement-shaped import records, with Canvas held at the legacy mapping boundary. `WtsLms.CourseContent` returns course, syllabus, modules, pages, file metadata, announcements, and assignment calendar dates only after active enrollment and Student/Teacher/Admin authorization.
- Assignments/submissions/files: covered. `WtsLms.Assignments` supports only text-entry, file-upload, and no-submission/none paths, including timestamps, attempts, comments, grading-friendly submission records, and explicit rejection of unsupported submission modes. `WtsLms.Files` and `WtsLms.Files.SignedUrl` provide permissioned S3-compatible upload/download metadata without exposing object URLs on denied/missing cases.
- Gradebook: covered. `WtsLms.Gradebook` implements points, weighted assignment groups, no-weight total-points fallback, final percentage, letter display, Teacher/Admin CSV export headers, and explicit state handling for ungraded, missing, excused, late, resubmitted/latest selected grade, extra credit via zero possible points, dropped scores, and unpublished assignments. Tests exercise those required edge cases.
- Notifications: covered. `WtsLms.Notifications`, `EmailDelivery`, and `EmailDeliveryWorker` cover announcement, due-date, submission-comment, and grade-release in-app/email notifications with Postmark-shaped delivery jobs, retry/failure audit state, and supported channels limited to `:in_app` and `:email`.
- Auth/SIS contracts: covered. `WtsLms.Identity.PopuliSaml` requires NameID/email/sis_user_id, matches existing SIS-synced users, rejects disabled/unmatched/conflicting users, and does not create local users. `WtsLms.Sis.DryRun` validates SIS-owned extract changes without persistent mutation. `WtsLms.Authorization.RoleAuthorization` allows only Student, Teacher, and Admin roles from current active SIS-owned enrollments/user roles.
- Privacy/audit/accessibility: covered. `WtsLms.Audit` builds safe audit events for login/import/grade/submission/file actions, and `WtsLms.Security.SecureLog` redacts tokens, raw URLs, SAML material, private keys/certificates, emails, object URLs, storage keys, file contents, and submission/message bodies. Web tests cover deterministic region, label, keyboard, alert/status, and excluded secret-string checks.
- Import/diff and pilot gates: covered. `WtsLms.Imports` stages sanitized DAP/REST/course-export/file-manifest inputs, transforms to WTS domain records, preserves legacy Canvas IDs at the boundary, produces diff reports with zero allowed blocking mismatches, and fails on deliberate missing assignment/submission fixtures. `wts-lms-specs/pilot/readiness_report.md` explicitly keeps launch blocked until distinct real pilot fixtures and S3-compatible restore evidence are complete or waived.

Finding: no missing Preserve item found in the reviewed WTS API/web implementation and evidence/spec paths.

## Simplify Fidelity

- REST/API shape remains WTS-owned and narrow: direct controller/module surfaces for SAML, course content, submissions/files, import diff, gradebook verify, and SIS dry-run. No broad Canvas REST compatibility layer was found in WTS implementation.
- UI remains a WTS React/TypeScript SPA for Student Teacher Admin workflows. `wts-lms-web/src/App.tsx` and `src/api/client.ts` expose dashboard/content/assignments/submissions/grades/notifications, Teacher grading/export, Admin import/diff, and unauthorized state, not a Canvas shell clone.
- Migration is DAP/REST/course-export/file-download plus automated diff. Import code treats source material as read-only and audit-labeled; historical access remains read-only/archive-oriented in specs, not editable migration.
- Ops/admin remains managed-cloud runbook/readiness gate language, not self-hosted Canvas operational parity. The readiness report preserves unresolved launch blockers instead of silently expanding scope.
- Notifications are simplified to in-app/email only, with no SMS, mobile push, digest/frequency preference engine, or complex channel preferences in implementation.

Finding: no overbuilt Simplify item found. The implementation is intentionally smaller than Canvas parity and aligned to the WTS day-one contract.

## Exclude Fidelity

Search results in WTS implementation showed excluded terms only in three acceptable contexts:

- Explicit user-facing/spec text saying not included, for example `wts-lms-web/src/App.tsx` lists quizzes, discussions, LTI tools, Canvas app shell, `js_env`, and mobile-app compatibility as not included.
- Rejection/filtering tests, for example `wts-lms-api/test/wts_lms/assignments/submissions_test.exs` rejects `:online_quiz`, `wts-lms-api/test/wts_lms/imports/imports_test.exs` verifies LTI/external tool rows do not reappear, and web tests assert excluded UI features are absent.
- Sanitized source fixture metadata naming excluded Canvas source rows, for example `wts-lms-api/test/fixtures/canvas_sample/pilot_course/**` contains `external_tool` and `basic_lti_launch` only as source/excluded-count evidence, while `WtsLms.Imports` filters unsupported assignment/submission types and records `:excluded_scope` audit entries.

No implemented LTI/external-tool/developer-key/grade-passback feature, quiz engine, discussion board, rubric/outcome/group/collaboration feature, plugin architecture, Canvas mobile support, broad Canvas API compatibility, generic Canvas clone surface, advanced gradebook parity beyond `gradebook_rules.md`, normal local-password auth, or full historical editable migration path was found in WTS implementation.

## Gradebook Rule Alignment

- Points and weighted groups: `WtsLms.Gradebook.final_percentage/7` calculates weighted group percentages when weights exist and total earned/possible when no weights exist.
- Final percentage and letter: `student_view` and `teacher_view` return formatted final percentage and letter display using configured grading scheme or default pilot scheme.
- CSV export: `export_csv` includes student identity, course, section, assignment columns, current final percentage, final letter display, and notes; tests verify stable headers and absence of private audit/grader fields.
- Edge cases: ungraded and unposted do not count; missing counts only with explicit missing policy; excused removes numerator/denominator; late policy applies only when configured; resubmitted selects latest posted/updated grade and preserves comments/timestamps; extra credit earns points against zero possible; dropped scores are excluded and noted; unpublished assignments are hidden from Students and visible/non-counting for Teachers.

Finding: gradebook implementation and tests align with `wts-lms-specs/gradebook_rules.md`; no advanced parity implementation found beyond named rules.

## Pilot Success/Failure Alignment

- `wts-lms-specs/pilot_success_failure.md` defines strict pass/fail criteria, zero blocking mismatches, 99.5% normalized non-blocking field tolerance, 100% required academic/content/submission/grade/file/auth records for selected fixtures, rollback triggers, and fallback triggers.
- `wts-lms-specs/pilot/readiness_report.md` includes `LAUNCH STATUS: BLOCKED`, explicit PASS/FAIL gates, rollback/fallback language, no silent waivers, and blocked launch items for insufficient distinct real-course fixtures plus unresolved S3-compatible object storage/restore evidence.
- Inherited notepad wisdom matches the readiness report: Task 15 aliases prove rehearsal mechanics only, not actual 2-3 distinct real-course readiness.

Finding: pilot criteria are represented accurately, including launch-blocked status for unresolved operational gates. These blockers are intentional launch gates, not scope-fidelity failures.

## Final Reviewer Judgment

The required scope fidelity script exited 0. Deep review found Preserve coverage for Core Coursework, Simplify scope held to WTS-specific surfaces, Exclude scope absent from implementation except explicit blocked/not-included/filtering evidence, gradebook behavior aligned to the documented rules, and pilot readiness correctly blocked on unresolved operational gates.

VERDICT: APPROVE
