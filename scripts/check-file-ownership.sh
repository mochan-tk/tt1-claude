#!/usr/bin/env bash
# check-file-ownership.sh — deterministic gate for the single-writer rule
# (AGENTS.md §5): fail when a PR's diff includes paths outside the
# `## File ownership` section of its linked Task issue.
#
# Rationale: the retro skill prefers "the most deterministic asset that can
# host the fix — a CI check beats an instruction line". Ownership was
# enforced only at review time (reviewer diff-audit); this makes it a wall.
#
# Usage:
#   check-file-ownership.sh --pr <number> [-R owner/repo]
#   check-file-ownership.sh --self-test
#
# Rules:
#   - The PR body must link its Task issue via `Closes #<n>`
#     (Fixes/Resolves variants accepted; first same-repo link wins).
#   - Ownership patterns come from the issue's `## File ownership` section:
#     one pattern per list item; inline backticks stripped; a trailing `/`
#     claims the subtree (`docs/` == `docs/*`).
#   - Matching uses bash patterns where `*` also crosses `/`
#     (`firmware/*` matches `firmware/a/b.c`) — prefer directory prefixes.
#   - Escape hatch: the PR label `ownership-exempt` downgrades every finding
#     to a warning. The label is visible on the PR, so exemptions stay
#     auditable (add it to scripts/setup-labels.sh).
#
# Exit codes: 0 in bounds (or exempt); 1 violation / missing data; 2 usage.
# Requires: gh (authenticated) except for --self-test, which runs offline —
# wire it into the scaffold-self-check CI job. bash 3.2 compatible.

set -euo pipefail

usage() { sed -n '2,/^$/{s/^# \{0,1\}//p;}' "$0"; }

fail() { echo "error: $*" >&2; exit 1; }

PR="" SELF_TEST=false
REPO_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --pr) PR="$2"; shift 2 ;;
    -R|--repo) REPO_ARGS=(--repo "$2"); shift 2 ;;
    --self-test) SELF_TEST=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "error: unknown argument: $1" >&2; exit 2 ;;
  esac
done

# ---------- pure helpers (no gh; covered by --self-test) ----------

# stdin: issue body -> stdout: one ownership pattern per line.
# Strips CR, HTML comment blocks, list bullets, and inline backticks.
extract_patterns() {
  awk '
    BEGIN { insec = 0; incomment = 0 }
    { gsub(/\r/, "") }
    /^##[[:space:]]+File ownership/ { insec = 1; next }
    insec && /^##[[:space:]]/ { insec = 0 }
    insec == 0 { next }
    {
      line = $0
      if (incomment) {
        if (line ~ /-->/) { incomment = 0; sub(/^.*-->/, "", line) }
        else next
      }
      while (line ~ /<!--/) {
        if (line ~ /<!--.*-->/) sub(/<!--[^>]*-->/, "", line)
        else { sub(/<!--.*$/, "", line); incomment = 1 }
      }
      print line
    }
  ' | sed -e 's/^[[:space:]]*[-*][[:space:]]*//' \
        -e 's/`//g' \
        -e 's/[[:space:]]*$//' \
        -e 's/^[[:space:]]*//' \
    | { grep -v '^$' || true; }
}

# stdin: PR body -> stdout: first linked same-repo issue number, or nothing.
extract_issue() {
  tr '[:upper:]' '[:lower:]' \
    | { grep -oE '(close|closes|closed|fix|fixes|fixed|resolve|resolves|resolved)[[:space:]]*:?[[:space:]]*#[0-9]+' || true; } \
    | head -n 1 | { grep -oE '[0-9]+' || true; }
}

# path_matches <path> <pattern>: bash pattern match; trailing / = subtree.
path_matches() {
  local path="$1" pat="$2"
  case "$pat" in */) pat="${pat}*" ;; esac
  # $pat must stay unquoted below to act as a pattern:
  # shellcheck disable=SC2254
  case "$path" in
    $pat) return 0 ;;
  esac
  return 1
}

# ---------- self-test ----------

run_self_test() {
  local fails=0
  check() { # check <description> <expected> <actual>
    if [[ "$2" == "$3" ]]; then
      printf 'ok   %s\n' "$1"
    else
      printf 'FAIL %s (expected [%s] got [%s])\n' "$1" "$2" "$3"
      fails=$((fails + 1))
    fi
  }

  local body patterns
  # Fixture text; backticks are literal by design:
  # shellcheck disable=SC2016
  body='## Objective
One sentence.

## File ownership

<!-- Paths (globs allowed) this task may modify. The diff must stay inside
     them (AGENTS.md §5). Parallel tasks must not overlap. -->

- `firmware/*`
- docs/
- scripts/setup-labels.sh

## Verification

```bash
true
```'
  patterns=$(printf '%s\n' "$body" | extract_patterns)
  check "pattern count"  "3"                       "$(printf '%s\n' "$patterns" | { grep -c . || true; })"
  check "backticks gone" "firmware/*"              "$(printf '%s\n' "$patterns" | sed -n 1p)"
  check "subtree kept"   "docs/"                   "$(printf '%s\n' "$patterns" | sed -n 2p)"
  check "exact file"     "scripts/setup-labels.sh" "$(printf '%s\n' "$patterns" | sed -n 3p)"

  local r
  path_matches "firmware/a/b.c" "firmware/*" && r=in || r=out
  check "glob crosses /" "in" "$r"
  path_matches "docs/agreements/x.md" "docs/" && r=in || r=out
  check "trailing slash claims subtree" "in" "$r"
  path_matches "scripts/setup-labels.sh" "scripts/setup-labels.sh" && r=in || r=out
  check "exact match" "in" "$r"
  path_matches "AGENTS.md" "firmware/*" && r=in || r=out
  check "outside is out" "out" "$r"

  check "closes link"    "42" "$(printf 'Summary\ncloses #42, also Fixes #7' | extract_issue)"
  check "resolves colon" "9"  "$(printf 'Resolves: #9' | extract_issue)"
  check "no link"        ""   "$(printf 'no reference here' | extract_issue)"
  check "comment placeholder ignored" "" \
    "$(printf 'Closes #<!-- Task issue number -->' | extract_issue)"

  [[ "$fails" -eq 0 ]] || { echo "self-test: ${fails} failure(s)" >&2; exit 1; }
  echo "self-test: all passed"
}

if $SELF_TEST; then
  run_self_test
  exit 0
fi

# ---------- main (gh-backed) ----------

[[ -n "$PR" ]] || { echo "error: --pr <number> is required (see --help)" >&2; exit 2; }
command -v gh >/dev/null 2>&1 || fail "gh CLI not found"

annotate() { # annotate <error|warning> <file> <message>
  if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
    printf '::%s file=%s::%s\n' "$1" "$2" "$3"
  fi
}

EXEMPT=false
if gh pr view "$PR" ${REPO_ARGS[@]+"${REPO_ARGS[@]}"} --json labels \
     -q '.labels[].name' | grep -qx 'ownership-exempt'; then
  EXEMPT=true
fi

# Findings are errors normally, warnings when the PR is labeled exempt.
finding() { # finding <message> [file]
  local msg="$1" file="${2:-.github/PULL_REQUEST_TEMPLATE.md}"
  if $EXEMPT; then
    echo "warning (ownership-exempt): $msg"
    annotate warning "$file" "$msg"
  else
    echo "VIOLATION: $msg"
    annotate error "$file" "$msg"
    FOUND=1
  fi
}

FOUND=0

PR_BODY=$(gh pr view "$PR" ${REPO_ARGS[@]+"${REPO_ARGS[@]}"} --json body -q .body)
ISSUE=$(printf '%s\n' "$PR_BODY" | extract_issue)

if [[ -z "$ISSUE" ]]; then
  finding "PR #${PR} body has no 'Closes #<n>' link (unit of work, AGENTS.md §4)"
  [[ "$FOUND" -eq 0 ]] || exit 1
  exit 0
fi

ISSUE_BODY=$(gh issue view "$ISSUE" ${REPO_ARGS[@]+"${REPO_ARGS[@]}"} --json body -q .body)
PATTERNS=$(printf '%s\n' "$ISSUE_BODY" | extract_patterns)

if [[ -z "$PATTERNS" ]]; then
  finding "issue #${ISSUE} has an empty File ownership section — the brief is incomplete (planner quality bar)"
  [[ "$FOUND" -eq 0 ]] || exit 1
  exit 0
fi

CHANGED=$(gh pr diff "$PR" ${REPO_ARGS[@]+"${REPO_ARGS[@]}"} --name-only)

VIOLATIONS=()
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  inside=false
  while IFS= read -r p; do
    [[ -z "$p" ]] && continue
    if path_matches "$f" "$p"; then inside=true; break; fi
  done < <(printf '%s\n' "$PATTERNS")
  $inside || VIOLATIONS+=("$f")
done < <(printf '%s\n' "$CHANGED")

echo "PR #${PR} -> issue #${ISSUE}; ownership patterns:"
printf '  %s\n' "$PATTERNS" | sed 's/^  $//'

if [[ ${#VIOLATIONS[@]} -gt 0 ]]; then
  echo
  for f in ${VIOLATIONS[@]+"${VIOLATIONS[@]}"}; do
    finding "path outside File ownership of issue #${ISSUE}: ${f}" "$f"
  done
  if [[ "$FOUND" -ne 0 ]]; then
    echo
    echo "Fix: stay inside the owned paths, or replan ownership on the issue"
    echo "(AGENTS.md §5 / §6 — label needs:replan), then re-run."
    exit 1
  fi
  exit 0
fi

echo "OK: all $(printf '%s\n' "$CHANGED" | { grep -c . || true; }) changed path(s) inside File ownership."
