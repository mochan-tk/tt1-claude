#!/usr/bin/env bash
# setup-ruleset.sh — bootstrap the branch ruleset described in README step 5:
# on the default branch, require a pull request (>= 1 approving review) and
# required status checks, via `POST /repos/{owner}/{repo}/rulesets`.
#
# SAFE BY DEFAULT: the ruleset is created with enforcement `disabled` so it
# never blocks merges until a human reviews it and switches it on (repository
# Settings -> Rules -> Rulesets, or a re-run with `--enforcement active`).
#
# Requires: gh (authenticated) and jq. Compatible with bash 3.2 (macOS).

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: setup-ruleset.sh [options]

Create a branch ruleset targeting the repository's default branch that
requires:
  - a pull request with at least 1 approving review
  - required status checks (default: quality,scaffold-self-check)

Options:
  -R, --repo <owner/repo>  Target repository. Default: the repository the
                           current directory belongs to (via `gh repo view`).
  --checks <c1,c2,...>     Comma-separated status check contexts to require.
                           Default: quality,scaffold-self-check.
  --enforcement <mode>     `active` or `disabled`. Default: `disabled`, so
                           the ruleset never blocks merges until a human
                           reviews it and enables it.
  --name <name>            Ruleset name. Default: scaffold-branch-protection.
  --dry-run                Print the request JSON body to stdout and exit
                           without making any API call.
  -h, --help               Show this help and exit.

Examples:
  setup-ruleset.sh --dry-run | jq .
  setup-ruleset.sh -R owner/repo
  setup-ruleset.sh -R owner/repo --checks lint,test --enforcement active

Inspect or remove a created ruleset:
  gh api repos/<owner>/<repo>/rulesets --jq '.[] | {id, name, enforcement}'
  gh api -X DELETE repos/<owner>/<repo>/rulesets/<id>
EOF
}

REPO=""
CHECKS="quality,scaffold-self-check"
ENFORCEMENT="disabled"
NAME="scaffold-branch-protection"
DRY_RUN="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -R|--repo)
      [[ -n "${2:-}" ]] || { echo "error: $1 requires an owner/repo argument" >&2; exit 2; }
      REPO="$2"; shift 2 ;;
    --checks)
      [[ -n "${2:-}" ]] || { echo "error: --checks requires a comma-separated list" >&2; exit 2; }
      CHECKS="$2"; shift 2 ;;
    --enforcement)
      case "${2:-}" in
        active|disabled) ENFORCEMENT="$2" ;;
        *) echo "error: --enforcement must be 'active' or 'disabled'" >&2; exit 2 ;;
      esac
      shift 2 ;;
    --name)
      [[ -n "${2:-}" ]] || { echo "error: --name requires a value" >&2; exit 2; }
      NAME="$2"; shift 2 ;;
    --dry-run)
      DRY_RUN="true"; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "error: unknown argument: $1 (run with --help for usage)" >&2; exit 2 ;;
  esac
done

command -v jq >/dev/null 2>&1 || { echo "error: jq not found on PATH" >&2; exit 1; }

# Build the request body with jq so every value is safely quoted. `$name`,
# `$enforcement`, and `$checks` below are jq variables, not shell expansions.
# shellcheck disable=SC2016
PAYLOAD="$(jq -n \
  --arg name "$NAME" \
  --arg enforcement "$ENFORCEMENT" \
  --arg checks "$CHECKS" \
  '{
    name: $name,
    target: "branch",
    enforcement: $enforcement,
    conditions: { ref_name: { include: ["~DEFAULT_BRANCH"], exclude: [] } },
    rules: [
      {
        type: "pull_request",
        parameters: {
          required_approving_review_count: 1,
          dismiss_stale_reviews_on_push: false,
          require_code_owner_review: false,
          require_last_push_approval: false,
          required_review_thread_resolution: false
        }
      },
      {
        type: "required_status_checks",
        parameters: {
          strict_required_status_checks_policy: false,
          required_status_checks:
            ($checks | split(",")
                     | map(gsub("^\\s+|\\s+$"; ""))
                     | map(select(length > 0))
                     | map({context: .}))
        }
      }
    ]
  }')"

if [[ "$DRY_RUN" == "true" ]]; then
  # stdout carries only the JSON body (pipeable to jq); notes go to stderr.
  echo "dry-run: request body for POST /repos/{owner}/{repo}/rulesets; no API call made." >&2
  printf '%s\n' "$PAYLOAD"
  exit 0
fi

command -v gh >/dev/null 2>&1 || { echo "error: gh CLI not found on PATH" >&2; exit 1; }

if [[ -z "$REPO" ]]; then
  REPO="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
fi
[[ "$REPO" == */* ]] || { echo "error: repository must be owner/repo, got: $REPO" >&2; exit 2; }

if [[ "$ENFORCEMENT" == "active" ]]; then
  echo "warning: enforcement 'active' starts blocking merges on $REPO immediately." >&2
fi

RESPONSE="$(printf '%s' "$PAYLOAD" | gh api --method POST "repos/$REPO/rulesets" --input -)"
RULESET_ID="$(printf '%s' "$RESPONSE" | jq -r '.id')"

echo "Created ruleset '$NAME' (id: $RULESET_ID, enforcement: $ENFORCEMENT) on $REPO."
echo "Inspect: gh api repos/$REPO/rulesets/$RULESET_ID"
echo "Delete:  gh api -X DELETE repos/$REPO/rulesets/$RULESET_ID"
if [[ "$ENFORCEMENT" == "disabled" ]]; then
  echo "Enable after review: Settings -> Rules -> Rulesets, or re-run with --enforcement active."
fi
