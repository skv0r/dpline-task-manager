#!/usr/bin/env bash
# After PR merged into dev: close linked issues + set Project Status=Done.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PR_NUMBER="${1:?pr number}"
REPO="${2:?owner/repo}"

echo "PR #$PR_NUMBER merged into dev — closing linked issues…"

BODY="$(gh api "repos/${REPO}/pulls/${PR_NUMBER}" --jq '.body // ""')"
CLOSE_NUMS="$(echo "$BODY" | grep -oiE '(close[sd]?|fix(e[sd])?|resolve[sd]?)\s*:?\s*#([0-9]+)' | grep -oE '[0-9]+' | sort -u || true)"
REF_NUMS="$(gh pr view "$PR_NUMBER" --repo "$REPO" --json closingIssuesReferences \
  --jq '.closingIssuesReferences[].number' 2>/dev/null | sort -u || true)"

ALL="$(printf '%s\n%s\n' "$CLOSE_NUMS" "$REF_NUMS" | grep -E '^[0-9]+$' | sort -u || true)"

if [[ -z "$ALL" ]]; then
  echo "No linked issues found in PR body/closing references."
  exit 0
fi

for n in $ALL; do
  echo "→ close #$n"
  gh issue close "$n" --repo "$REPO" --comment "Closed automatically after merge to \`dev\` (PR #${PR_NUMBER})." || true
done

chmod +x "${SCRIPT_DIR}/set-linked-issues-status.sh"
"${SCRIPT_DIR}/set-linked-issues-status.sh" "$PR_NUMBER" "$REPO" "Done"
