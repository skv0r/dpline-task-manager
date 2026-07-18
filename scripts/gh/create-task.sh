#!/usr/bin/env bash
# Create GitHub issue + add to DPLine Flow project + refresh backlog mirror.
#
# Usage:
#   scripts/gh/create-task.sh \
#     --title "Пустой web" \
#     --type app \
#     --label docs \
#     --phase 0 \
#     --estimate 1 \
#     --status Ready \
#     --body "Acceptance: …"
#
# --type: app | pr
# --status: IceBox | Ready (default Ready)
# --label: short slug used later in branch name (app-13-docs)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

require_gh

TITLE=""
TYPE=""
LABEL=""
PHASE="0"
ESTIMATE=""
STATUS="Ready"
BODY=""
PRIORITY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title) TITLE="$2"; shift 2 ;;
    --type) TYPE="$2"; shift 2 ;;
    --label) LABEL="$2"; shift 2 ;;
    --phase) PHASE="$2"; shift 2 ;;
    --estimate) ESTIMATE="$2"; shift 2 ;;
    --status) STATUS="$2"; shift 2 ;;
    --body) BODY="$2"; shift 2 ;;
    --priority) PRIORITY="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$TITLE" || -z "$TYPE" || -z "$LABEL" ]]; then
  echo "usage: $0 --title T --type app|pr --label slug [--phase 0] [--estimate 1] [--status Ready|IceBox] [--body ...]" >&2
  exit 1
fi

if [[ "$TYPE" != "app" && "$TYPE" != "pr" ]]; then
  echo "error: --type must be app or pr" >&2
  exit 1
fi

LABEL="$(slugify "$LABEL")"
if [[ -z "$LABEL" ]]; then
  echo "error: --label пустой после slugify" >&2
  exit 1
fi

GH_LABEL="enhancement"
if [[ "$TYPE" == "pr" ]]; then
  GH_LABEL="enhancement"
fi

BODY_FILE="$(mktemp)"
trap 'rm -f "$BODY_FILE"' EXIT

{
  echo "${BODY:-}"
  echo ""
  echo "---"
  echo ""
  echo "<!-- dpline-meta -->"
  echo "- type: \`${TYPE}\`"
  echo "- label: \`${LABEL}\`"
  echo "- phase: \`${PHASE}\`"
  echo "- branch: \`${TYPE}-<n>-${LABEL}\` (n = номер issue после создания)"
} >"$BODY_FILE"

echo "→ создаю issue в ${REPO}…"
ISSUE_URL="$(gh issue create \
  --repo "$REPO" \
  --title "$TITLE" \
  --label "$GH_LABEL" \
  --body-file "$BODY_FILE")"

ISSUE_NUM="$(basename "$ISSUE_URL")"
echo "✓ issue #${ISSUE_NUM}: ${ISSUE_URL}"

# Rewrite body with concrete branch name
FINAL_BODY="$(cat "$BODY_FILE" | sed "s/${TYPE}-<n>-${LABEL}/${TYPE}-${ISSUE_NUM}-${LABEL}/")"
gh issue edit "$ISSUE_NUM" --repo "$REPO" --body "$FINAL_BODY" >/dev/null

echo "→ добавляю в Project #${PROJECT_NUMBER}…"
gh project item-add "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --url "$ISSUE_URL" >/dev/null || true

sleep 1
ITEM_ID="$(item_id_for_issue "$ISSUE_NUM" || true)"
if [[ -z "${ITEM_ID:-}" ]]; then
  echo "warn: item не найден в Project сразу после add — выставь Status вручную" >&2
else
  set_project_status "$ITEM_ID" "$STATUS" || true
  # Type field: App / Prac (pr → Prac)
  if [[ "$TYPE" == "app" ]]; then
    set_single_select_field "$ITEM_ID" "Type" "App" || set_single_select_field "$ITEM_ID" "Type" "app" || true
  else
    set_single_select_field "$ITEM_ID" "Type" "Prac" || set_single_select_field "$ITEM_ID" "Type" "prac" || true
  fi
  if [[ -n "$PHASE" ]]; then
    set_number_field "$ITEM_ID" "Phase" "$PHASE" || true
  fi
  if [[ -n "$ESTIMATE" ]]; then
    set_number_field "$ITEM_ID" "Estimate" "$ESTIMATE" || true
  fi
  if [[ -n "$PRIORITY" ]]; then
    set_single_select_field "$ITEM_ID" "Priority" "$PRIORITY" || true
  fi
fi

echo "→ обновляю plan/backlog.md…"
python3 "${SCRIPT_DIR}/sync-backlog.py"

BRANCH_NAME="${TYPE}-${ISSUE_NUM}-${LABEL}"
echo ""
echo "=== готово ==="
echo "issue:  #${ISSUE_NUM}"
echo "url:    ${ISSUE_URL}"
echo "branch: ${BRANCH_NAME}  (создать: /gh-start-task ${ISSUE_NUM}  или  scripts/gh/start-task.sh ${ISSUE_NUM})"
echo "status: ${STATUS}"
