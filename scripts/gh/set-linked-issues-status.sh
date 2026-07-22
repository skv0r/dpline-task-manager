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
  echo "hint: укажи в body PR: Closes #N (или Close/Fixes/Resolves #N)" >&2
  exit 0
fi

FAILED=0
for n in $ALL; do
  echo "→ #${n}"
  if [[ -z "$(item_id_for_issue "$n" || true)" ]]; then
    # item-add может падать с unknown owner type в CI — не блокируем GraphQL path
    gh project item-add "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" \
      --url "https://github.com/${REPO}/issues/${n}" >/dev/null 2>&1 || true
    sleep 1
  fi
  ITEM_ID="$(item_id_for_issue "$n" || true)"
  if [[ -z "${ITEM_ID:-}" ]]; then
    echo "error: #${n} not on Project (проверь GH_PROJECT_TOKEN: scopes project + read:project, не истёк)" >&2
    FAILED=1
    continue
  fi
  if ! set_project_status "$ITEM_ID" "$STATUS_NAME"; then
    echo "error: failed Status=${STATUS_NAME} for #${n}" >&2
    FAILED=1
  else
    echo "✓ #${n} → ${STATUS_NAME}"
    # Done → Target date = дата закрытия (локальный календарный день)
    if [[ "$STATUS_NAME" == "Done" ]]; then
      if set_date_field "$ITEM_ID" "Target date" "$(today_ymd)"; then
        echo "✓ #${n} Target date=$(today_ymd)"
      else
        echo "warn: #${n} Target date не выставлен" >&2
      fi
    fi
  fi
done

if [[ "$FAILED" -ne 0 ]]; then
  echo "error: не все linked issues переведены в ${STATUS_NAME}" >&2
  exit 1
fi

# Project «Auto-add» часто кидает сам PR на доску — дубль рядом с issue. Убираем.
remove_pr_from_project "$PR_NUMBER" || true
