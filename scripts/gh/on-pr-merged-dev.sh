#!/usr/bin/env bash
# After PR merged into dev: close linked issues + set Project Status=Done.
# Needs secrets: GH_PROJECT_TOKEN (PAT with project + repo scope) optional;
# falls back to github.token for issue close (always works).
set -euo pipefail

PR_NUMBER="${1:?pr number}"
REPO="${2:?owner/repo}"

echo "PR #$PR_NUMBER merged into dev — closing linked issues…"

BODY="$(gh api "repos/${REPO}/pulls/${PR_NUMBER}" --jq '.body // ""')"
# Collect issue refs: Closes #N, close #N, Fixes #N, Refs #N (only close for closes/fixes)
CLOSE_NUMS="$(echo "$BODY" | grep -oiE '(close[sd]?|fix(e[sd])?|resolve[sd]?)\s*:?\s*#([0-9]+)' | grep -oE '[0-9]+' | sort -u || true)"
# Also linked issues from timeline
LINKED="$(gh api "repos/${REPO}/issues/${PR_NUMBER}/timeline" --paginate --jq '
  .[] | select(.event=="connected" or .event=="cross-referenced") | .source.issue.number // empty
' 2>/dev/null | sort -u || true)"

ALL="$(printf '%s\n%s\n' "$CLOSE_NUMS" "$LINKED" | grep -E '^[0-9]+$' | sort -u || true)"

if [[ -z "$ALL" ]]; then
  echo "No linked issues found in PR body/timeline."
  exit 0
fi

PROJECT_OWNER="${DPLINE_PROJECT_OWNER:-skv0r}"
PROJECT_NUMBER="${DPLINE_PROJECT_NUMBER:-1}"

for n in $ALL; do
  echo "→ close #$n"
  gh issue close "$n" --repo "$REPO" --comment "Closed automatically after merge to \`dev\` (PR #${PR_NUMBER})." || true

  if command -v jq >/dev/null; then
    ITEM_ID="$(gh project item-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json --limit 200 \
      | jq -r --argjson n "$n" '.items[]? | select(.content.number == $n) | .id' | head -1 || true)"
    if [[ -n "${ITEM_ID:-}" ]]; then
      PID="$(gh project view "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json --jq '.id')"
      FIELD_ID="$(gh project field-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json \
        | jq -r '.fields[]? | select(.name=="Status") | .id')"
      OPT_ID="$(gh project field-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json \
        | jq -r '.fields[]? | select(.name=="Status") | .options[]? | select(.name=="Done") | .id')"
      if [[ -n "$PID" && -n "$FIELD_ID" && -n "$OPT_ID" ]]; then
        gh project item-edit --id "$ITEM_ID" --project-id "$PID" --field-id "$FIELD_ID" --single-select-option-id "$OPT_ID" || true
        echo "✓ Project Status=Done for #$n"
      fi
    fi
  fi
done
