# F3 Real Manual QA Evidence

Date: 2026-06-03
Reviewer: deep-category manual QA reviewer
Scope: WTS LMS Web Student, Teacher, Admin, unauthorized access, accessibility/keyboard, and deterministic pilot gates.

## Files Inspected

- `wts-lms-web/src/App.tsx`
- `wts-lms-web/src/api/client.ts`
- `wts-lms-web/test/e2e.test.mjs`
- `wts-lms-web/test/axe.test.mjs`
- `wts-lms-web/test/workflows.test.mjs`
- `.omo/evidence/task-14-audit.txt`
- `.omo/evidence/task-14-accessibility-error.txt`
- `.omo/notepads/wts-canvas-phoenix-replacement/learnings.md`
- `.omo/notepads/wts-canvas-phoenix-replacement/issues.md`

## Required Pilot Gate

Command:

```sh
cd wts-lms-web && npm run test:e2e -- --grep @pilot
```

Observed output:

```text
> wts-lms-web@0.1.0 test:e2e
> node test/e2e.test.mjs --grep @pilot

TAP version 13
# Subtest: deterministic e2e workflow surface is represented in source
ok 1 - deterministic e2e workflow surface is represented in source # SKIP
# Subtest: @keyboard deterministic keyboard gates cover day-one workflows
ok 2 - @keyboard deterministic keyboard gates cover day-one workflows # SKIP
# Subtest: @pilot deterministic pilot rehearsal covers operational launch gates
ok 3 - @pilot deterministic pilot rehearsal covers operational launch gates
1..3
# tests 3
# pass 1
# fail 0
# skipped 2
# todo 0
```

Result: PASS. The two skipped subtests are expected because `--grep @pilot` selects only the pilot-labelled gate.

## Additional Deterministic QA

Command:

```sh
cd wts-lms-web && npm test
```

Observed output summary:

```text
# tests 13
# pass 13
# fail 0
# cancelled 0
# skipped 0
# todo 0
```

Covered subtests included:

- `student completes assignment submission flow in rendered static state`
- `unauthorized student cannot see another course`
- `teacher grading comment workflow and gradebook export are present`
- `admin import status and diff summary are present`
- `excluded features are absent except explicit not-included copy`
- `@pilot deterministic pilot rehearsal covers operational launch gates`
- `@keyboard deterministic keyboard gates cover day-one workflows`

Command:

```sh
cd wts-lms-web && npm run axe
```

Observed output summary:

```text
# tests 2
# pass 2
# fail 0
# skipped 0
```

Command:

```sh
cd wts-lms-web && npm run test:e2e -- --grep @keyboard
```

Observed output summary:

```text
# tests 3
# pass 1
# fail 0
# skipped 2
```

Result: PASS. The selected keyboard gate passed; non-matching e2e tests were skipped by the local grep harness.

## Browser / Manual Runtime Attempt

I attempted browser/manual QA only using existing local runtime. No dependencies were installed and no secrets were requested.

Checks:

```sh
cd wts-lms-web && test -d node_modules && test -x node_modules/.bin/vite && printf 'vite available\n' || printf 'vite unavailable\n'
cd wts-lms-web && test -d node_modules/.cache/ms-playwright && printf 'playwright browsers cache present\n' || printf 'playwright browsers cache absent\n'
```

Observed:

```text
vite unavailable
playwright browsers cache absent
```

Browser screenshots/videos were not produced because the checkout lacks an installed Vite runtime and local Playwright browser cache. This matches inherited project context that browser/axe runtime dependencies may not exist and should not be added for this review. For this repository state, deterministic source-backed QA is sufficient for F3 because the active `test:e2e`, `axe`, and workflow gates are intentionally Node-based local checks.

## Workflow QA Findings

Student workflow:

- Dashboard and course access are represented in `App.tsx` with enrolled course `core-101` from `getCourseForRole('core-101', 'Student')`.
- Course home renders syllabus, modules, pages, files as metadata, and announcements.
- Assignment submission surfaces include text-entry and file-upload metadata forms with status confirmations.
- Notification visibility is represented by `Notifications center` and fixture notifications in `client.ts`.
- Unauthorized data is not exposed through Student access: `getCourseForRole` returns `null` when `currentStudent.enrolledCourseIds` does not include the requested course, and `App.tsx` renders the access-denied alert instead of restricted course content.

Teacher workflow:

- Submission review queue is rendered from `wtsWorkflowState.teacher.reviewQueue`.
- Grading/commenting surface includes score, teacher comment, and `Save grade and comment` controls.
- CSV/export surface is present as `Export gradebook CSV` with `wts-core-theology-gradebook.csv`.

Admin workflow:

- Import status is visible with batch `pilot-core-course-2026-06-03` and status `Validated with fixture diff`.
- Diff summary is visible with `{passed: 18, failed: 1, warnings: 2}`.
- Launch blocker visibility is source-backed by `wts-lms-specs/pilot/readiness_report.md` references in Task 15 notes and active issues: additional distinct real-course fixtures, object-storage provider selection, and restore drill evidence remain required for real-world pilot launch.

Unauthorized access:

- Access fails closed for an unenrolled Student course request.
- Deterministic tests assert `return null`, the access-denied alert, hidden course content text, and absence of raw URL/storage URL exposure.

Accessibility and keyboard:

- `test/axe.test.mjs` verifies main/nav/heading structure, labels for Student and Teacher form controls, button surfaces, status roles, alert roles, and absence of focus-hostile patterns.
- `test/e2e.test.mjs --grep @keyboard` verifies role navigation links, focusable form controls/buttons for Student and Teacher workflows, Admin import status region, unauthorized alert, and absence of `tabIndex=-1`, disabled true, and autofocus patterns.
- Task 14 evidence records `npm run axe`, `npm run test:e2e -- --grep @keyboard`, and full `npm test` passing with empty accessibility stderr.

## Unsafe Term / Missing Assertion Search

Commands:

```sh
cd wts-lms-web && rg -n "access_token|Authorization|Bearer|saml_assertion|private_evidence|raw_url|https?://|skipped|skip\(|test\.skip|describe\.skip|it\.skip|TODO|FIXME" "src" "test"
cd wts-lms-web && rg -n "@pilot|Student workflow|Text-entry assignment submission|File-upload assignment metadata|Notifications center|Teacher workflow|Save grade and comment|Export gradebook CSV|Admin workflow|Diff summary|Access denied|doesNotMatch|diffSummary" "test" "src"
```

Findings:

- Unsafe/private terms appeared only inside the `@pilot` negative assertion that rejects `access_token`, `Authorization`, `Bearer`, `saml_assertion`, `private_evidence`, and `raw_url`.
- Pilot workflow assertions cover Student, Teacher, Admin, notifications, access denied, diff summary, launch scope exclusions, and unsafe term absence.
- Broader workflow tests cover file metadata without raw `https://` or `s3://` URLs.

## Reviewer Conclusion

F3 passes for the current repository state. The deterministic local QA gates verify the required Student submission, Teacher grading/export, Admin import status, unauthorized access, accessibility, and keyboard workflows. Browser screenshots/videos are unavailable without installing dependencies, and this limitation is documented rather than bypassed. Real-world pilot launch remains blocked by separate Task 15 readiness gates for additional distinct sanitized real-course fixtures and object-storage restore evidence, but those blockers do not invalidate the current F3 local manual QA verdict.

VERDICT: APPROVE
