#!/usr/bin/env bash
# Move issue to In Progress and create local branch type-N-label from dev.
#
# Usage:
#   scripts/gh/start-task.sh 20
#   scripts/gh/start-task.sh 20 --label docs   # override label slug
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

require_gh

ISSUE_NUM="${1:-}"
shift || true
LABEL_OVERRIDE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --label) LABEL_OVERRIDE="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$ISSUE_NUM" || ! "$ISSUE_NUM" =~ ^[0-9]+$ ]]; then
  echo "usage: $0 <issue-number> [--label slug]" >&2
  exit 1
fi

cd "$ROOT_DIR"

META="$(gh issue view "$ISSUE_NUM" --repo "$REPO" --json title,body,labels,state)"
STATE="$(echo "$META" | jq -r '.state')"
TITLE="$(echo "$META" | jq -r '.title')"
BODY="$(echo "$META" | jq -r '.body // ""')"

if [[ "$STATE" != "OPEN" ]]; then
  echo "error: issue #${ISSUE_NUM} не OPEN (state=$STATE)" >&2
  exit 1
fi

TYPE="$(echo "$BODY" | sed -nE 's/.*type: `([^`]+)`.*/\1/p' | head -1)"
LABEL="$(echo "$BODY" | sed -nE 's/.*label: `([^`]+)`.*/\1/p' | head -1)"
PHASE="$(echo "$BODY" | sed -nE 's/.*phase: `([^`]+)`.*/\1/p' | head -1)"

sync_project_fields_from_meta() {
  local item_id="$1"
  [[ -z "$item_id" ]] && return 0
  if [[ "$TYPE" == "app" ]]; then
    set_single_select_field "$item_id" "Type" "App" || set_single_select_field "$item_id" "Type" "app" || true
  elif [[ "$TYPE" == "pr" ]]; then
    set_single_select_field "$item_id" "Type" "Prac" || set_single_select_field "$item_id" "Type" "prac" || true
  fi
  if [[ -n "$PHASE" ]]; then
    set_single_select_field "$item_id" "Phase" "$PHASE" || true
  fi
}

if [[ -n "$LABEL_OVERRIDE" ]]; then
  LABEL="$(slugify "$LABEL_OVERRIDE")"
fi

if [[ -z "$TYPE" ]]; then
  # fallback: title prefix app- / pr-
  if [[ "$TITLE" =~ ^app[-_] ]]; then TYPE="app"; fi
  if [[ "$TITLE" =~ ^pr[-_] ]]; then TYPE="pr"; fi
fi
if [[ -z "$TYPE" ]]; then
  echo "error: не смог определить type (app|pr). Укажи в теле issue: - type: \`app\` или передай через recreate." >&2
  exit 1
fi
if [[ -z "$LABEL" ]]; then
  LABEL="$(slugify "$TITLE")"
fi
if [[ -z "$LABEL" ]]; then
  echo "error: пустой label" >&2
  exit 1
fi

BRANCH="${TYPE}-${ISSUE_NUM}-${LABEL}"

echo "→ issue #${ISSUE_NUM}: ${TITLE}"
echo "→ ветка: ${BRANCH}"

# Project → In Progress
ITEM_ID="$(item_id_for_issue "$ISSUE_NUM" || true)"
if [[ -n "${ITEM_ID:-}" ]]; then
  sync_project_fields_from_meta "$ITEM_ID"
  set_project_status "$ITEM_ID" "In Progress" || true
else
  echo "warn: issue нет в Project — добавляю…" >&2
  gh project item-add "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --url "https://github.com/${REPO}/issues/${ISSUE_NUM}" >/dev/null || true
  sleep 1
  ITEM_ID="$(item_id_for_issue "$ISSUE_NUM" || true)"
  if [[ -n "${ITEM_ID:-}" ]]; then
    sync_project_fields_from_meta "$ITEM_ID"
    set_project_status "$ITEM_ID" "In Progress" || true
  fi
fi

# Git branch from fresh dev
if [[ -n "$(git status --porcelain)" ]]; then
  echo "error: working tree не чистый. Закоммить или stash перед стартом задачи." >&2
  git status -sb >&2
  exit 1
fi

git fetch origin
git checkout dev
git pull --ff-only origin dev

if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
  echo "→ локальная ветка уже есть, переключаюсь"
  git checkout "$BRANCH"
else
  git checkout -b "$BRANCH"
fi

python3 "${SCRIPT_DIR}/sync-backlog.py" || true

echo ""
echo "=== готово ==="
echo "ветка:  ${BRANCH}"
echo "issue:  https://github.com/${REPO}/issues/${ISSUE_NUM}"
echo "дальше: код → commit → push -u origin HEAD → открой PR в base=dev сам"
echo "в PR укажи: Closes #${ISSUE_NUM} (закрытие issue при merge в main;"
echo "            для merge в dev сработает workflow on-pr-merged-dev)"
