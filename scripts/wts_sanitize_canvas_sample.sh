#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
usage: scripts/wts_sanitize_canvas_sample.sh --validate FIXTURE_DIR
       scripts/wts_sanitize_canvas_sample.sh --help

Validates a sanitized Canvas pilot-course fixture directory before it can be
committed. The validator is safe by default: it fails when required source
manifests are missing, when raw-looking private values are present, or when a
real file-download manifest lacks checksum and byte-size evidence.

Examples:
  scripts/wts_sanitize_canvas_sample.sh --validate wts-lms-api/test/fixtures/canvas_sample/pilot_course
  scripts/wts_sanitize_canvas_sample.sh wts-lms-api/test/fixtures/canvas_sample/pilot_course

The current Task 2 placeholder fixture is allowed as a shape marker only. A
real sanitized sample still needs WTS data/privacy owner approval before commit.
USAGE
}

error() {
  printf 'sanitizer validation failed: %s\n' "$1" >&2
  exit 1
}

info() {
  printf 'sanitizer validation: %s\n' "$1"
}

fixture_dir=""

case "${1:-}" in
  --help|-h)
    usage
    exit 0
    ;;
  --validate)
    shift
    fixture_dir="${1:-}"
    ;;
  "")
    usage >&2
    exit 1
    ;;
  *)
    fixture_dir="$1"
    ;;
esac

[[ -n "$fixture_dir" ]] || error "missing fixture directory"
[[ -d "$fixture_dir" ]] || error "fixture directory not found"

required_manifests=(
  "$fixture_dir/manifest.json"
  "$fixture_dir/dap/manifest.json"
  "$fixture_dir/rest/manifest.json"
  "$fixture_dir/course_export/manifest.json"
  "$fixture_dir/file_download/manifest.json"
)

for manifest in "${required_manifests[@]}"; do
  [[ -f "$manifest" ]] || error "missing required manifest: $manifest"
done

scan_files=()
while IFS= read -r -d '' file; do
  scan_files+=("$file")
done < <(find "$fixture_dir" -type f -print0)

[[ "${#scan_files[@]}" -gt 0 ]] || error "fixture directory contains no files"

if grep -REil '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "${scan_files[@]}" >/tmp/wts_sanitize_hits.$$; then
  while IFS= read -r file; do
    printf 'sanitizer validation failed: raw-looking email in %s\n' "$file" >&2
  done </tmp/wts_sanitize_hits.$$
  rm -f /tmp/wts_sanitize_hits.$$
  exit 1
fi
rm -f /tmp/wts_sanitize_hits.$$

if grep -REil '(access[_-]?token|authorization|bearer)[^[:alnum:]]{0,40}([A-Za-z0-9._~+/-]{20,}|[A-Za-z0-9._~+/-]+\.[A-Za-z0-9._~+/-]+\.[A-Za-z0-9._~+/-]+)' "${scan_files[@]}" >/tmp/wts_sanitize_hits.$$; then
  while IFS= read -r file; do
    printf 'sanitizer validation failed: raw-looking access token in %s\n' "$file" >&2
  done </tmp/wts_sanitize_hits.$$
  rm -f /tmp/wts_sanitize_hits.$$
  exit 1
fi
rm -f /tmp/wts_sanitize_hits.$$

if grep -REil 'https?://([^[:space:]"<>]*\.)?(instructure\.com|canvas[^[:space:]"<>]*|wts[^[:space:]"<>]*|watermark[^[:space:]"<>]*)' "${scan_files[@]}" >/tmp/wts_sanitize_hits.$$; then
  while IFS= read -r file; do
    printf 'sanitizer validation failed: private-looking URL in %s\n' "$file" >&2
  done </tmp/wts_sanitize_hits.$$
  rm -f /tmp/wts_sanitize_hits.$$
  exit 1
fi
rm -f /tmp/wts_sanitize_hits.$$

file_manifests=()
while IFS= read -r -d '' file; do
  [[ "$file" == "$fixture_dir/file_download/manifest.json" ]] && continue
  file_manifests+=("$file")
done < <(find "$fixture_dir/file_download" -type f \( -name '*manifest*.json' -o -name '*manifest*.jsonl' -o -name '*manifest*.csv' \) -print0)

[[ "${#file_manifests[@]}" -gt 0 ]] || error "missing file-download checksum/byte-size manifest rows"

real_file_manifest_count=0
for file_manifest in "${file_manifests[@]}"; do
  if grep -Eq '"placeholder"[[:space:]]*:[[:space:]]*true' "$file_manifest"; then
    continue
  fi

  real_file_manifest_count=$((real_file_manifest_count + 1))
  grep -Eiq '(^|[",])([[:space:]]*)(sha256|checksum|sha256_checksum)([[:space:]]*)([",:]|$)' "$file_manifest" || error "missing checksum column or field in $file_manifest"
  grep -Eiq '(^|[",])([[:space:]]*)(byte_size|bytes|size)([[:space:]]*)([",:]|$)' "$file_manifest" || error "missing byte-size column or field in $file_manifest"
  grep -Eq '([0-9a-fA-F]{64}|[A-Za-z0-9+/]{43}=?)' "$file_manifest" || error "missing checksum value in $file_manifest"
  grep -Eq '(^|[^0-9])[1-9][0-9]{1,}([^0-9]|$)' "$file_manifest" || error "missing positive byte-size value in $file_manifest"
done

if [[ "$real_file_manifest_count" -eq 0 ]]; then
  info "placeholder file manifest accepted as a shape marker; real sanitized sample remains blocked"
else
  info "validated $real_file_manifest_count real file-download manifest file(s)"
fi

info "passed without printing private values"
