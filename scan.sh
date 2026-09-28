#!/usr/bin/env bash
# Scans every skill under INPUT_PATH with skillspector, one skill at a time,
# because skillspector rejects --baseline on a multi-skill (--recursive) scan.
set -euo pipefail
shopt -s nullglob

default_baseline=.skillspector-baseline.yaml
path=${INPUT_PATH:-skills}
baseline=${INPUT_BASELINE:-$default_baseline}

# Workflow command data must escape %, CR and LF, or a directory name could
# end the command and start another.
esc() {
  local s=${1//%/%25}
  s=${s//$'\r'/%0D}
  printf '%s' "${s//$'\n'/%0A}"
}

fail() {
  echo "::error title=setup-skillspector::$(esc "$1")"
  exit 2
}

enabled() {
  [[ $2 == true || $2 == false ]] || fail "Input $1 must be true or false, got: $2"
  [[ $2 == true ]]
}

args=()
enabled llm "${INPUT_LLM:-false}" || args+=(--no-llm)
enabled fail-on-findings "${INPUT_FAIL_ON_FINDINGS:-false}" && args+=(--fail-on-findings)
enabled fail-on-incomplete "${INPUT_FAIL_ON_INCOMPLETE:-false}" && args+=(--fail-on-incomplete)

if [[ -f $baseline ]]; then
  args+=(--baseline "$baseline")
elif [[ $baseline != "$default_baseline" ]]; then
  fail "Baseline file not found: $baseline"
fi

[[ -d $path ]] || fail "Path is not a directory: $path"
skills=()
if [[ -f $path/SKILL.md ]]; then
  skills=("$path")
else
  for dir in "$path"/*/; do
    [[ -f ${dir}SKILL.md ]] && skills+=("${dir%/}")
  done
fi
(( ${#skills[@]} )) || fail "No SKILL.md found in $path or its immediate subdirectories"

report_dir=${RUNNER_TEMP:-$(mktemp -d)}/skillspector-reports
mkdir -p "$report_dir"
echo "report-dir=$report_dir" >> "${GITHUB_OUTPUT:-/dev/null}"
summary=${GITHUB_STEP_SUMMARY:-/dev/null}

# Reports quote skill content, so pause workflow commands while printing them.
token=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')
status=0
for skill in "${skills[@]}"; do
  name=$(basename "$skill")
  report=$report_dir/$name.md
  echo "::group::$(esc "$skill")"
  echo "::stop-commands::$token"
  code=0
  skillspector scan "$skill" --format markdown --output "$report" "${args[@]}" || code=$?
  [[ -f $report ]] && cat "$report"
  echo "::$token::"
  echo "::endgroup::"
  # ponytail: GitHub drops a step summary over 1 MiB; split per skill if repos get that large.
  [[ -f $report ]] && { cat "$report"; echo; } >> "$summary"
  if (( code )); then
    echo "::error title=skillspector::$(esc "$skill") failed the scan (exit $code)"
    status=1
  fi
done
exit "$status"
