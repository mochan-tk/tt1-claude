#!/usr/bin/env bash
# claim-task.sh — claim, release, or inspect the claim on a Task issue so
# that concurrent orchestrators cannot double-dispatch it.
#
# GitHub offers no compare-and-swap, but issue comments are appended in
# server order — a total order. Claims therefore work as an append-only
# ledger (first-writer-wins, resolved after the fact):
#
#   1. read the ledger; an active claim by someone else -> back off (exit 3)
#   2. append your own `[claim] CLAIM <session-id>` comment
#   3. re-read the ledger; the EARLIEST active claim wins
#   4. not the winner? append `[claim] RELEASE <session-id>` (withdraw)
#      and back off (exit 3)
#
# Two racers can both pass step 1, but step 3 resolves deterministically:
# exactly one session proceeds. The ledger is also the audit trail — who
# claimed, who yielded, who released, all on the issue (AGENTS.md §1:
# GitHub is the only shared memory).
#
# Usage:
#   claim-task.sh <issue> --session <id> [-R owner/repo]        claim
#   claim-task.sh <issue> --session <id> --release [-R ...]     release
#   claim-task.sh <issue> --status [-R owner/repo]              show holder
#   claim-task.sh --self-test                                   offline tests
#
# Session id: any stable, whitespace-free token for this session (e.g. the
# Copilot session name or codex-<thread>). Re-claiming with the holder's own
# id is idempotent. A claim is advisory for humans but binding for
# orchestrators: dispatch only what you hold (session-orchestration skill).
#
# Trust boundary: the ledger is cooperative. Markers count only as the
# FIRST line of a comment, and comments are treated as append-only (edits
# are visible in the UI but not policed). A claim held by a crashed session
# never expires — recover by posting `[claim] RELEASE <its-session-id>`
# yourself (any actor may; the ledger, not the assignee, is authoritative).
#
# Exit codes: 0 success; 3 already claimed by another session (holder
# printed); 1 error; 2 usage. Requires: gh (authenticated) except for
# --self-test. JSON via gh's built-in --jq (no external jq). bash 3.2
# compatible (macOS /bin/bash).

set -euo pipefail

usage() { sed -n '2,/^$/{s/^# \{0,1\}//p;}' "$0"; }

fail() { echo "error: $*" >&2; exit 1; }

ISSUE="" SESSION="" MODE="claim" SELF_TEST=false REPO_SPEC=""
REPO_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --session) [[ $# -ge 2 ]] || { echo "error: --session requires a value" >&2; exit 2; }
               SESSION="$2"; shift 2 ;;
    --release) MODE="release"; shift ;;
    --status) MODE="status"; shift ;;
    --self-test) SELF_TEST=true; shift ;;
    -R|--repo) [[ $# -ge 2 ]] || { echo "error: $1 requires a value" >&2; exit 2; }
               REPO_SPEC="$2"; REPO_ARGS=(--repo "$2"); shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "error: unknown argument: $1" >&2; exit 2 ;;
    *)
      [[ -z "$ISSUE" ]] || { echo "error: multiple issue numbers" >&2; exit 2; }
      ISSUE="$1"; shift ;;
  esac
done

# ---------- pure helper (no gh; covered by --self-test) ----------

# stdin: ledger lines "[claim] CLAIM|RELEASE <id> ..." in server order.
# stdout: the active holder's session id, or nothing when unclaimed.
# Active = earliest CLAIM whose id has no later RELEASE.
holder_from_ledger() {
  local verbs=() ids=() line verb id i j count released
  while IFS= read -r line; do
    line="${line%$'\r'}"
    [[ -z "$line" ]] && continue
    verb=$(printf '%s\n' "$line" | awk '{print $2}')
    id=$(printf '%s\n' "$line" | awk '{print $3}')
    [[ -n "$id" ]] || continue
    case "$verb" in CLAIM|RELEASE) ;; *) continue ;; esac
    verbs+=("$verb")
    ids+=("$id")
  done
  count=${#ids[@]}
  [[ "$count" -eq 0 ]] && return 0
  for ((i = 0; i < count; i++)); do
    [[ "${verbs[$i]}" == "CLAIM" ]] || continue
    released=false
    for ((j = i + 1; j < count; j++)); do
      if [[ "${verbs[$j]}" == "RELEASE" && "${ids[$j]}" == "${ids[$i]}" ]]; then
        released=true
        break
      fi
    done
    if ! $released; then
      printf '%s\n' "${ids[$i]}"
      return 0
    fi
  done
  return 0
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

  check "empty ledger -> unclaimed" "" \
    "$(printf '' | holder_from_ledger)"
  check "single claim" "alpha" \
    "$(printf '[claim] CLAIM alpha\n' | holder_from_ledger)"
  check "claim then release -> unclaimed" "" \
    "$(printf '[claim] CLAIM alpha\n[claim] RELEASE alpha\n' | holder_from_ledger)"
  check "race: earliest active claim wins" "alpha" \
    "$(printf '[claim] CLAIM alpha\n[claim] CLAIM beta\n' | holder_from_ledger)"
  check "race resolved: loser withdrew" "alpha" \
    "$(printf '[claim] CLAIM alpha\n[claim] CLAIM beta\n[claim] RELEASE beta (yield)\n' | holder_from_ledger)"
  check "handover to the later claimant" "beta" \
    "$(printf '[claim] CLAIM alpha\n[claim] CLAIM beta\n[claim] RELEASE alpha\n' | holder_from_ledger)"
  check "re-claim after full release" "gamma" \
    "$(printf '[claim] CLAIM a\n[claim] RELEASE a\n[claim] CLAIM gamma\n' | holder_from_ledger)"
  check "noise lines ignored" "alpha" \
    "$(printf 'Starting work.\n[claim] CLAIM alpha\nOutcome: completed\n' | holder_from_ledger)"
  check "CRLF tolerated" "alpha" \
    "$(printf '[claim] CLAIM alpha\r\n' | holder_from_ledger)"
  check "duplicate claim, one release -> released (holding is boolean)" "" \
    "$(printf '[claim] CLAIM a\n[claim] CLAIM a\n[claim] RELEASE a\n' | holder_from_ledger)"

  [[ "$fails" -eq 0 ]] || { echo "self-test: ${fails} failure(s)" >&2; exit 1; }
  echo "self-test: all passed"
}

if $SELF_TEST; then
  run_self_test
  exit 0
fi

# ---------- gh-backed operations ----------

[[ -n "$ISSUE" ]] || { echo "error: issue number is required (see --help)" >&2; exit 2; }
command -v gh >/dev/null 2>&1 || fail "gh CLI not found"

if [[ "$MODE" != "status" ]]; then
  [[ -n "$SESSION" ]] || { echo "error: --session <id> is required" >&2; exit 2; }
  case "$SESSION" in
    *[[:space:]]*) fail "--session must not contain whitespace" ;;
  esac
fi

# First line of every comment, claims only — via REST, fully paginated, in
# ascending immutable-comment-id order (a total order every reader shares).
# `gh issue view --json comments` is unsuitable here: it caps at 100
# comments (silent truncation wedges or double-dispatches the ledger) and
# orders by second-granularity createdAt (ties let two racers disagree).
REPO_PATH="{owner}/{repo}"
if [[ -n "$REPO_SPEC" ]]; then REPO_PATH="$REPO_SPEC"; fi
ledger() {
  gh api --paginate "repos/${REPO_PATH}/issues/${ISSUE}/comments?per_page=100" \
      --jq '.[].body | split("\n")[0]' \
    | { grep -E '^\[claim\] (CLAIM|RELEASE) ' || true; }
}

post() { # post <body-line>
  gh issue comment "$ISSUE" ${REPO_ARGS[@]+"${REPO_ARGS[@]}"} \
    --body "$1" >/dev/null
}

STATE=$(gh issue view "$ISSUE" ${REPO_ARGS[@]+"${REPO_ARGS[@]}"} \
  --json state -q .state)
[[ "$STATE" == "OPEN" ]] || fail "issue #${ISSUE} is ${STATE}, not OPEN"

HOLDER=$(ledger | holder_from_ledger)

case "$MODE" in
  status)
    if [[ -n "$HOLDER" ]]; then
      echo "claimed by: ${HOLDER}"
    else
      echo "unclaimed"
    fi
    ;;

  claim)
    if [[ "$HOLDER" == "$SESSION" ]]; then
      echo "already held by this session (${SESSION})"
      exit 0
    fi
    if [[ -n "$HOLDER" ]]; then
      echo "already claimed by: ${HOLDER}" >&2
      exit 3
    fi
    post "[claim] CLAIM ${SESSION}"
    # Re-read with brief retries: the read can lag the write. Never treat
    # an empty read as a lost race — withdrawing on it would drop a claim
    # this session may in fact hold.
    HOLDER=""
    for _ in 1 2 3; do
      HOLDER=$(ledger | holder_from_ledger)
      if [[ -n "$HOLDER" ]]; then break; fi
      sleep 2
    done
    if [[ "$HOLDER" == "$SESSION" ]]; then
      # Best-effort visibility in the UI; the ledger stays authoritative.
      gh issue edit "$ISSUE" ${REPO_ARGS[@]+"${REPO_ARGS[@]}"} \
        --add-assignee "@me" >/dev/null 2>&1 || true
      echo "claimed #${ISSUE} as ${SESSION}"
    elif [[ -z "$HOLDER" ]]; then
      fail "own claim not visible after retries (stale read?) — re-run to resolve"
    else
      post "[claim] RELEASE ${SESSION} (lost the race to ${HOLDER})"
      echo "already claimed by: ${HOLDER} (withdrew own claim)" >&2
      exit 3
    fi
    ;;

  release)
    if [[ "$HOLDER" != "$SESSION" ]]; then
      fail "not the holder of #${ISSUE} (holder: ${HOLDER:-none})"
    fi
    post "[claim] RELEASE ${SESSION}"
    gh issue edit "$ISSUE" ${REPO_ARGS[@]+"${REPO_ARGS[@]}"} \
      --remove-assignee "@me" >/dev/null 2>&1 || true
    echo "released #${ISSUE} (${SESSION})"
    ;;
esac
