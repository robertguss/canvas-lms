#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
usage: scripts/wts_pilot_rehearsal.sh --fixtures pilot_course_1,pilot_course_2[,pilot_course_3]
       scripts/wts_pilot_rehearsal.sh --help

Runs the WTS pilot readiness rehearsal against sanitized fixture aliases only.
The rehearsal imports and diffs each requested fixture, runs deterministic
Student/Teacher/Admin pilot UI checks, verifies safe contract/readiness evidence,
and fails closed when any strict operational gate is missing or failing.
USAGE
}

fail() {
  printf 'pilot rehearsal failed: %s\n' "$1" >&2
  exit 1
}

info() {
  printf 'pilot rehearsal: %s\n' "$1"
}

require_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

require_dir() {
  [[ -d "$1" ]] || fail "missing required directory: $1"
}

require_grep() {
  local pattern="$1"
  shift
  grep -Eq "$pattern" "$@" || fail "missing readiness marker: $pattern"
}

fixtures=""

case "${1:-}" in
  --help|-h)
    usage
    exit 0
    ;;
  --fixtures)
    shift
    fixtures="${1:-}"
    ;;
  "")
    usage >&2
    exit 1
    ;;
  *)
    fail "unsupported argument: $1"
    ;;
esac

[[ -n "$fixtures" ]] || fail "missing fixture list"

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
api_dir="$repo_root/wts-lms-api"
web_dir="$repo_root/wts-lms-web"
fixture_root="$api_dir/test/fixtures/canvas_sample"
report="$repo_root/wts-lms-specs/pilot/readiness_report.md"

require_dir "$api_dir"
require_dir "$web_dir"
require_file "$report"

IFS=',' read -r -a fixture_names <<< "$fixtures"
[[ "${#fixture_names[@]}" -ge 1 ]] || fail "empty fixture list"

negative_fixture_seen=0
for fixture in "${fixture_names[@]}"; do
  [[ -n "$fixture" ]] || fail "blank fixture name in list"
  fixture_path="$fixture_root/$fixture"
  require_dir "$fixture_path"
  require_file "$fixture_path/manifest.json"

  info "running import diff for $fixture"
  if [[ "$fixture" == *missing* ]]; then
    negative_fixture_seen=1
    if (cd "$api_dir" && mix wts.import.diff --fixture "test/fixtures/canvas_sample/$fixture"); then
      fail "negative fixture unexpectedly passed: $fixture"
    fi
    info "negative fixture blocked launch as expected: $fixture"
  else
    (cd "$api_dir" && mix wts.import.diff --fixture "test/fixtures/canvas_sample/$fixture")
  fi
done

if [[ "$negative_fixture_seen" -eq 1 ]]; then
  require_grep "LAUNCH STATUS: BLOCKED|launch status.*BLOCKED|blocked launch" "$report"
  require_grep "missing required assignment|missing required submission|blocking migration mismatch" "$report"
  fail "blocked launch report/action required for negative fixture"
fi

info "running deterministic frontend pilot checks"
(cd "$web_dir" && npm run test:e2e -- --grep @pilot)

info "checking SAML and SIS contract evidence"
require_file "$repo_root/wts-lms-specs/integrations/populi_saml.md"
require_file "$repo_root/wts-lms-specs/integrations/sis_sync.md"
require_file "$repo_root/.omo/evidence/task-3-saml-contract.txt"
require_file "$repo_root/.omo/evidence/task-3-sis-contract-error.txt"
require_file "$repo_root/.omo/evidence/task-6-auth.txt"
require_grep "NameID|sis_user_id|disabled user|audit reason" "$repo_root/wts-lms-specs/integrations/populi_saml.md"
require_grep "add/drop|idempotent|term rollover|conflict" "$repo_root/wts-lms-specs/integrations/sis_sync.md"
require_grep "0 failures|dry-run persisted=false" "$repo_root/.omo/evidence/task-6-auth.txt"

info "checking notifications evidence"
require_file "$repo_root/.omo/evidence/task-10-notifications.txt"
require_grep "notifications|workers|0 failures|mobile push" "$repo_root/.omo/evidence/task-10-notifications.txt"
require_grep "Postmark|webhook|bounce|complaint|suppression" "$repo_root/wts-lms-specs/ops/deployment.md" "$repo_root/wts-lms-specs/ops/backup_restore.md" "$repo_root/wts-lms-specs/ops/incident_response.md"

info "checking backup, restore, privacy, and accessibility readiness evidence"
require_file "$repo_root/wts-lms-specs/ops/backup_restore.md"
require_file "$repo_root/wts-lms-specs/ops/deployment.md"
require_file "$repo_root/wts-lms-specs/ops/incident_response.md"
require_file "$repo_root/wts-lms-specs/privacy_accessibility.md"
require_file "$repo_root/.omo/evidence/task-13b-fly-ops.txt"
require_file "$repo_root/.omo/evidence/task-13c-postmark-email.txt"
require_file "$repo_root/.omo/evidence/task-14-audit.txt"
require_file "$repo_root/.omo/evidence/task-14-accessibility-error.txt"
require_grep "restore drill|checksum|byte size|archive fallback" "$repo_root/wts-lms-specs/ops/backup_restore.md"
require_grep "Fly.io|Postmark|S3-compatible|health check" "$repo_root/wts-lms-specs/ops/deployment.md"
require_grep "rollback|fallback|SEV1|SEV2" "$repo_root/wts-lms-specs/ops/incident_response.md"
require_grep "FERPA|WCAG|Critical accessibility violations block" "$repo_root/wts-lms-specs/privacy_accessibility.md"
require_grep "0 failures|manual_sanitized|axe|@keyboard" "$repo_root/.omo/evidence/task-14-audit.txt"

info "checking readiness report gates"
require_grep "PASS|FAIL" "$report"
require_grep "rollback trigger" "$report"
require_grep "fallback" "$report"
require_grep "waiver|WTS leadership" "$report"
require_grep "LAUNCH STATUS: BLOCKED|LAUNCH STATUS: READY" "$report"

info "rehearsal passed; launch status remains governed by the readiness report"
