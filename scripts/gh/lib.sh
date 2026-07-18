#!/usr/bin/env bash
# Shared helpers for DPline GitHub automation.
set -euo pipefail

REPO="${DPLINE_REPO:-skv0r/dpline-task-manager}"
PROJECT_OWNER="${DPLINE_PROJECT_OWNER:-skv0r}"
PROJECT_NUMBER="${DPLINE_PROJECT_NUMBER:-1}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BACKLOG_FILE="${ROOT_DIR}/plan/backlog.md"

require_gh() {
  if ! command -v gh >/dev/null 2>&1; then
    echo "error: gh (GitHub CLI) не установлен. Установи: brew install gh && gh auth login" >&2
    exit 1
  fi
  if ! gh auth status >/dev/null 2>&1; then
    echo "error: gh не авторизован. Запусти: gh auth login" >&2
    exit 1
  fi
}

slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g' | cut -c1-40
}

# Resolve Project V2 node id
project_id() {
  gh project view "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json --jq '.id'
}

# Find Status field option id by name (IceBox, Ready, In Progress, Review, Done)
status_option_id() {
  local name="$1"
  gh project field-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json \
    | jq -r --arg n "$name" '
        .fields[]?
        | select(.name=="Status")
        | .options[]?
        | select(.name==$n)
        | .id
      '
}

field_id_by_name() {
  local name="$1"
  gh project field-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json \
    | jq -r --arg n "$name" '.fields[]? | select(.name==$n) | .id'
}

# Find project item id for an issue number in REPO
item_id_for_issue() {
  local issue_num="$1"
  local issue_url="https://github.com/${REPO}/issues/${issue_num}"
  gh project item-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json --limit 200 \
    | jq -r --arg url "$issue_url" --argjson n "$issue_num" '
        .items[]?
        | select(
            (.content.url // "") == $url
            or (.content.number // 0) == $n
          )
        | .id
      ' | head -1
}

set_project_status() {
  local item_id="$1"
  local status_name="$2"
  local pid field_id opt_id
  pid="$(project_id)"
  field_id="$(field_id_by_name "Status")"
  opt_id="$(status_option_id "$status_name")"
  if [[ -z "$field_id" || -z "$opt_id" || -z "$pid" ]]; then
    echo "warn: не удалось выставить Status=$status_name (проверь название колонки и права gh)" >&2
    return 1
  fi
  gh project item-edit --id "$item_id" --project-id "$pid" --field-id "$field_id" --single-select-option-id "$opt_id"
}

set_single_select_field() {
  local item_id="$1"
  local field_name="$2"
  local option_name="$3"
  local pid field_id opt_id
  pid="$(project_id)"
  field_id="$(field_id_by_name "$field_name")"
  opt_id="$(gh project field-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json \
    | jq -r --arg f "$field_name" --arg o "$option_name" '
        .fields[]? | select(.name==$f) | .options[]? | select(.name==$o) | .id
      ')"
  if [[ -z "$field_id" || -z "$opt_id" ]]; then
    echo "warn: поле $field_name=$option_name не выставлено (нет такого option?)" >&2
    return 1
  fi
  gh project item-edit --id "$item_id" --project-id "$pid" --field-id "$field_id" --single-select-option-id "$opt_id"
}

set_number_field() {
  local item_id="$1"
  local field_name="$2"
  local value="$3"
  local pid field_id
  pid="$(project_id)"
  field_id="$(field_id_by_name "$field_name")"
  if [[ -z "$field_id" ]]; then
    echo "warn: поле $field_name не найдено" >&2
    return 1
  fi
  gh project item-edit --id "$item_id" --project-id "$pid" --field-id "$field_id" --number "$value"
}
