#!/usr/bin/env bash
set -euo pipefail

SPECS="wts-lms-specs"
API_PATH=""
WEB_PATH=""

case "$#" in
  0)
    ;;
  1)
    SPECS="${1%/}"
    ;;
  3)
    SPECS="${1%/}"
    API_PATH="${2%/}"
    WEB_PATH="${3%/}"
    ;;
  *)
    echo "usage: $0 [SPECS_PATH API_PATH WEB_PATH]" >&2
    echo "   or: $0 [SPECS_PATH]" >&2
    exit 1
    ;;
esac

test -d "$SPECS" || { echo "missing specs directory: $SPECS" >&2; exit 1; }
if [[ -n "$API_PATH" ]]; then
  test -d "$API_PATH" || { echo "missing API path: $API_PATH" >&2; exit 1; }
fi
if [[ -n "$WEB_PATH" ]]; then
  test -d "$WEB_PATH" || { echo "missing web path: $WEB_PATH" >&2; exit 1; }
fi

MATRIX="$SPECS/compatibility_matrix.md"
NON_GOALS="$SPECS/non_goals.md"
GRADEBOOK="$SPECS/gradebook_rules.md"
MIGRATION="$SPECS/migration_fidelity.md"
PILOT="$SPECS/pilot_success_failure.md"
SIS_AUTH="$SPECS/sis_auth_contracts.md"
OPS="$SPECS/ops_readiness.md"
PRIVACY="$SPECS/privacy_accessibility.md"

for file in "$MATRIX" "$NON_GOALS" "$GRADEBOOK" "$MIGRATION" "$PILOT" "$SIS_AUTH" "$OPS" "$PRIVACY"; do
  test -f "$file" || { echo "missing scope artifact: $file" >&2; exit 1; }
done

require_line() {
  local pattern="$1"
  local file="$2"
  local description="$3"
  if ! grep -Eq "$pattern" "$file"; then
    echo "missing ${description} in ${file}" >&2
    exit 1
  fi
}

require_line "Generic Canvas clone.*Exclude|generic Canvas clone.*Exclude" "$NON_GOALS" "generic Canvas clone exclusion"
require_line "Canvas mobile.*Exclude|Mobile.*Exclude" "$MATRIX" "Canvas mobile exclusion"
require_line "Broad Canvas API.*Exclude|broad Canvas API.*Exclude" "$NON_GOALS" "broad Canvas API exclusion"
require_line "LTI.*Exclude" "$MATRIX" "LTI exclusion"
require_line "Quizzes.*Exclude" "$MATRIX" "quizzes exclusion"
require_line "Discussions.*Exclude" "$MATRIX" "discussions exclusion"
require_line "Rubrics.*collaborations.*Exclude|rubrics.*collaborations.*Exclude" "$NON_GOALS" "rubrics outcomes groups collaborations exclusion"
require_line "Plugins.*Exclude" "$MATRIX" "plugins exclusion"
require_line "Advanced gradebook parity.*Exclude" "$MATRIX" "advanced gradebook exclusion"
require_line "Full historical editable migration.*Exclude" "$NON_GOALS" "full historical editable migration exclusion"
require_line "Preserve" "$MATRIX" "Preserve rows"
require_line "Simplify" "$MATRIX" "Simplify rows"
require_line "Exclude" "$MATRIX" "Exclude rows"
require_line "ungraded" "$GRADEBOOK" "ungraded gradebook case"
require_line "missing" "$GRADEBOOK" "missing gradebook case"
require_line "excused" "$GRADEBOOK" "excused gradebook case"
require_line "late" "$GRADEBOOK" "late gradebook case"
require_line "resubmitted" "$GRADEBOOK" "resubmitted gradebook case"
require_line "extra credit" "$GRADEBOOK" "extra credit gradebook case"
require_line "dropped scores|dropped" "$GRADEBOOK" "dropped scores gradebook case"
require_line "unpublished assignments" "$GRADEBOOK" "unpublished assignments gradebook case"
require_line "numeric threshold" "$MIGRATION" "migration numeric threshold"
require_line "mismatch tolerance" "$MIGRATION" "migration mismatch tolerance"
require_line "rollback trigger" "$MIGRATION" "migration rollback trigger"
require_line "fallback trigger" "$MIGRATION" "migration fallback trigger"
require_line "numeric threshold" "$PILOT" "pilot numeric threshold"
require_line "mismatch tolerance" "$PILOT" "pilot mismatch tolerance"
require_line "rollback trigger" "$PILOT" "pilot rollback trigger"
require_line "fallback trigger" "$PILOT" "pilot fallback trigger"
require_line "valid assertion" "$SIS_AUTH" "valid assertion case"
require_line "missing attribute" "$SIS_AUTH" "missing attribute case"
require_line "disabled user" "$SIS_AUTH" "disabled user case"
require_line "idempotent" "$SIS_AUTH" "idempotent case"
require_line "add/drop" "$SIS_AUTH" "add/drop case"
require_line "FERPA" "$PRIVACY" "FERPA privacy rules"
require_line "WCAG" "$PRIVACY" "WCAG accessibility rules"
require_line "backup restore|restore drill" "$OPS" "ops restore readiness"

if grep -R -nE "TBD|TODO" "$SPECS" | grep -v "DECISION NEEDED:"; then
  echo "found unresolved TBD/TODO in specs" >&2
  exit 1
fi

echo "scope fidelity verified"
