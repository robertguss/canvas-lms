# Gradebook Rules

## Scope

The gradebook covers WTS Core Coursework only. It preserves points, weighted assignment groups, final percentage, letter display, CSV export, and the explicit edge cases in this file. It excludes advanced gradebook parity outside these rules.

## Calculation Contract

1. Each published assignment has a point value, an assignment group, an optional weight through that group, and a submission state.
2. Final percentage is the sum of earned group percentages multiplied by group weights. If no weights exist for a course, final percentage is total earned points divided by total possible graded points.
3. Letter display uses the configured WTS grading scheme for the course. If no course scheme exists, use the institution default selected for the pilot.
4. CSV export must include student identity, course, section, assignment columns, current final percentage, final letter display, and notes for excluded states such as excused or dropped scores.
5. Grade changes, submission timestamps, grading timestamps, grading comments, and submission comments must be auditable.

## Required Edge Cases

| Case | Required behavior |
| --- | --- |
| ungraded | An ungraded submitted assignment does not count as earned points and does not count as a zero until a grade is posted or the missing rule applies. It remains visible as ungraded in Teacher/Admin gradebook views. |
| missing | A missing assignment after the due date receives the course missing policy when one is configured; otherwise it is displayed as missing without inventing a score. |
| excused | An excused assignment is removed from numerator and denominator for that student and does not reduce the weighted group percentage. CSV export marks the cell as excused. |
| late | A late submission retains the submitted timestamp and receives the configured late policy deduction only when that policy is present in the fixture or course configuration. |
| resubmitted | A resubmitted assignment keeps prior submission history, uses the latest submission selected for grading, and preserves grader comments and timestamps for audit. |
| extra credit | Extra credit adds earned points without increasing required possible points, capped only when the course grading scheme explicitly defines a cap. |
| dropped scores | Dropped scores are excluded from group calculations according to the configured drop rule, while remaining visible in audit and CSV notes. |
| unpublished assignments | Unpublished assignments are not visible to Students and do not count in grade calculations until published. Teacher/Admin views may display them as unpublished assignments. |

## Preserve/Simplify/Exclude Linkage

- Preserve WTS points, weighted assignment groups, final percentage, letter display, CSV export, submission comments, grading comments, timestamps, and the required edge cases above.
- Simplify Canvas gradebook behavior to only the rules that have fixtures and contract tests.
- Exclude advanced gradebook parity, including gradebook behavior not named in this file, unless a later approved spec adds it.
