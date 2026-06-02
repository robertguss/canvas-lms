#!/usr/bin/env bash
set -euo pipefail

PLAN_PATH=".omo/plans/wts-canvas-phoenix-replacement.md"
SPECS="wts-lms-specs"
SCRIPTS="scripts"

case "$#" in
  0)
    ;;
  1)
    if [[ -f "$1" ]]; then
      PLAN_PATH="$1"
    else
      SPECS="${1%/}"
    fi
    ;;
  2)
    PLAN_PATH="$1"
    SPECS="${2%/}"
    ;;
  *)
    echo "usage: $0 [PLAN_PATH SPECS_PATH]" >&2
    echo "   or: $0 [SPECS_PATH]" >&2
    exit 1
    ;;
esac

test -f "$PLAN_PATH" || { echo "missing plan: $PLAN_PATH" >&2; exit 1; }
test -d "$SPECS" || { echo "missing specs directory: $SPECS" >&2; exit 1; }

required_files=(
  "$SPECS/non_goals.md"
  "$SPECS/compatibility_matrix.md"
  "$SPECS/gradebook_rules.md"
  "$SPECS/migration_fidelity.md"
  "$SPECS/sis_auth_contracts.md"
  "$SPECS/pilot_success_failure.md"
  "$SPECS/ops_readiness.md"
  "$SPECS/privacy_accessibility.md"
)

for file in "${required_files[@]}"; do
  test -f "$file" || { echo "missing required spec: $file" >&2; exit 1; }
done

test -x "$SCRIPTS/verify_plan_compliance.sh" || { echo "verify_plan_compliance.sh is not executable" >&2; exit 1; }
test -x "$SCRIPTS/verify_scope_fidelity.sh" || { echo "verify_scope_fidelity.sh is not executable" >&2; exit 1; }

grep -R "LTI.*Exclude\|Quizzes.*Exclude\|Mobile.*Exclude" "$SPECS/compatibility_matrix.md" >/dev/null
grep -R "rollback trigger\|mismatch tolerance\|FERPA\|WCAG" "$SPECS" >/dev/null
grep -R "Preserve\|Simplify\|Exclude" "$SPECS/compatibility_matrix.md" >/dev/null
grep -R "ungraded\|missing\|excused\|late\|resubmitted\|extra credit\|dropped" "$SPECS/gradebook_rules.md" >/dev/null
grep -R "numeric threshold\|mismatch tolerance\|rollback trigger\|fallback trigger" "$SPECS/migration_fidelity.md" "$SPECS/pilot_success_failure.md" >/dev/null
grep -E "valid assertion|missing attribute|disabled user|idempotent|add/drop" "$SPECS/sis_auth_contracts.md" >/dev/null

if grep -R -nE "TBD|TODO" "$SPECS" | grep -v "DECISION NEEDED:"; then
  echo "found unresolved TBD/TODO in specs" >&2
  exit 1
fi

echo "plan compliance verified"
