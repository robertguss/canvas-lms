# Handoff: WTS Canvas Phoenix Replacement

## Current state

- Active plan: `.omo/plans/wts-canvas-phoenix-replacement.md`
- Boulder state: `.omo/boulder.json` reports completed for the tracked boulder run.
- Git status before handoff: committed implementation/docs are clean except untracked `.omo/` artifacts.
- Key blocker: no approved real sanitized WTS active-course sample and no file-byte evidence, so remaining production/pilot fidelity tasks cannot honestly pass.

## Recently completed commits

- `5d320652aab feat(wts): add course content APIs`
- `b0e1cc4304f docs(wts): select Postmark email`
- `20118dd0434 docs(wts): select Fly.io hosting`
- `71fd03704c6 feat(wts): add Populi SAML and SIS sync`
- `a7fa71f318e feat(wts): add Ecto Postgres repo`
- Earlier relevant commits: `4f496f9f7a3`, `cf179fffbac`, `357c30a660b`

## Plan checkboxes as of handoff

Completed:
- Tasks 1, 2, 2b, 3, 4, 5, 5b, 6, 7, 13, 13b, 13c.

Blocked / not approved for final completion:
- Tasks 8, 9, 10, 11, 12, 14, 15.
- Final verification F1-F4.

## Main hold-up

Need either:

1. Approved real sanitized WTS pilot-course sample, including file-byte evidence:
   - REST/course export/file-download source evidence.
   - checksum and byte-size rows for files/attachments.
   - WTS data/privacy owner approval before committing sample data.

or

2. Explicit user waiver to continue with deterministic contract fixtures only, knowing this cannot prove production migration/file/grade/pilot fidelity.

## Secondary unresolved decision

- S3-compatible object storage provider remains unselected. Fly.io hosting and Postmark email are selected.

## Start tomorrow with these checks

```bash
git status --short
git log --oneline -10
```

Then inspect:

- `.omo/plans/wts-canvas-phoenix-replacement.md`
- `.omo/notepads/wts-canvas-phoenix-replacement/learnings.md`
- `.omo/notepads/wts-canvas-phoenix-replacement/problems.md`
- `wts-lms-specs/migration/source_inventory.md`
- `wts-lms-specs/migration/sanitization_workflow.md`
- `scripts/wts_sanitize_canvas_sample.sh`

## Exact restart directions for tomorrow

Open a new assistant session in this repo and say:

```text
Please pick up the WTS Canvas Phoenix replacement work from
.omo/drafts/wts-canvas-phoenix-replacement-handoff.md.

First read:
- .omo/plans/wts-canvas-phoenix-replacement.md
- .omo/notepads/wts-canvas-phoenix-replacement/learnings.md
- .omo/notepads/wts-canvas-phoenix-replacement/problems.md
- wts-lms-specs/migration/source_inventory.md
- wts-lms-specs/migration/sanitization_workflow.md

Then run:
- git status --short
- git log --oneline -10

Do not rerun final verification until all remaining blocked tasks are either
completed with evidence or explicitly waived. The main blocker is missing
approved real sanitized WTS active-course sample and file-byte evidence.
```

If you have the sanitized sample tomorrow, tell the assistant where it is and
ask it to validate with:

```bash
scripts/wts_sanitize_canvas_sample.sh --validate <fixture_dir>
```

If you do not have the sample, decide whether to keep waiting or explicitly
waive production migration/file/pilot fidelity and continue using contract
fixtures only.

## If real sanitized sample is available tomorrow

Recommended next action:

1. Validate it with `scripts/wts_sanitize_canvas_sample.sh --validate <fixture_dir>`.
2. Update migration/source inventory with approval/evidence references.
3. Continue Task 8 first, then Tasks 9/10/11, then 12/14/15.
4. Run F1-F4 only after all implementation tasks are complete and not blocked.

## If no sample is available tomorrow

Ask for a decision:

- Wait for approved real sample; or
- Proceed with contract fixtures only and mark migration/file/pilot fidelity as explicitly waived/incomplete.

## Suggested skills for next session

- `tdd` for Tasks 8-11 implementation.
- `ui` for Task 12 and Task 14 frontend/accessibility work.
- `git-master` before committing each atomic task.
- `review-work` only after all unblocked implementation work is complete.

## Important caution

Do not mark final verification F1-F4 complete unless all required implementation tasks are either completed with evidence or explicitly waived by the user. The final wave requires approval from review agents and user okay.
