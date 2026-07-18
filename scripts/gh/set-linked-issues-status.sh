#!/usr/bin/env bash
# Set Project Status for issues linked from a PR.
#
# Usage:
#   scripts/gh/set-linked-issues-status.sh <pr-number> <owner/repo> <StatusName>
# Example StatusName: Review | Done | In Progress
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

require_gh

PR_NUMBER="${1:?pr number}"
REPO="${2:?owner/repo}"
STATUS_NAME="${3:?Status name e.g. Review}"

echo "PR #${PR_NUMBER} → linked issues → Status=${STATUS_NAME}"

BODY="$(gh api "repos/${REPO}/pulls/${PR_NUMBER}" --jq '.body // ""')"
BODY_NUMS="$(echo "$BODY" | grep -oiE '(close[sd]?|fix(e[sd])?|resolve[sd]?|refs?)\s*:?\s*#([0-9]+)' | grep -oE '[0-9]+' | sort -u || true)"

# Reliable source: Development / closing references (works even with empty PR body)
REF_NUMS="$(gh pr view "$PR_NUMBER" --repo "$REPO" --json closingIssuesReferences \
  --jq '.closingIssuesReferences[].number' 2>/dev/null | sort -u || true)"

ALL="$(printf '%s\n%s\n' "$BODY_NUMS" "$REF_NUMS" | grep -E '^[0-9]+$' | sort -u || true)"

if [[ -z "$ALL" ]]; then
  echo "No linked issues found for PR #${PR_NUMBER}."
  exit 0
fi

for n in $ALL; do
  echo "→ #${n}"
  if [[ -z "$(item_id_for_issue "$n" || true)" ]]; then
    gh project item-add "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" \
      --url "https://github.com/${REPO}/issues/${n}" >/dev/null || true
    sleep 1
  fi
  ITEM_ID="$(item_id_for_issue "$n" || true)"
  if [[ -z "${ITEM_ID:-}" ]]; then
    echo "warn: #${n} not on Project" >&2
    continue
  fi
  set_project_status "$ITEM_ID" "$STATUS_NAME" || echo "warn: failed Status=${STATUS_NAME} for #${n}" >&2
done
