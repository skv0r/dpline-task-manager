#!/usr/bin/env bash
# Shared helpers for DPline GitHub automation.
set -euo pipefail

REPO="${DPLINE_REPO:-skv0r/dpline-task-manager}"
PROJECT_OWNER="${DPLINE_PROJECT_OWNER:-skv0r}"
PROJECT_NUMBER="${DPLINE_PROJECT_NUMBER:-1}"
# Optional cache — GraphQL fallback if `gh project --owner` fails in CI
# ("unknown owner type" = often bad/expired token OR gh OwnerIDAndType bug)
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

_repo_owner() {
  echo "${REPO%%/*}"
}

_repo_name() {
  echo "${REPO#*/}"
}

# Resolve Project V2 node id (CLI first, then GraphQL user/org)
project_id() {
  local id
  id="$(gh project view "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json --jq '.id' 2>/dev/null || true)"
  if [[ -n "${id:-}" && "$id" != "null" ]]; then
    echo "$id"
    return 0
  fi
  id="$(gh api graphql \
    -f query='query($login:String!,$n:Int!){user(login:$login){projectV2(number:$n){id}} organization(login:$login){projectV2(number:$n){id}} }' \
    -f login="$PROJECT_OWNER" \
    -F n="$PROJECT_NUMBER" \
    --jq '.data.user.projectV2.id // .data.organization.projectV2.id // empty' 2>/dev/null || true)"
  if [[ -z "${id:-}" ]]; then
    echo "error: не удалось получить project id (#${PROJECT_NUMBER} owner=${PROJECT_OWNER}). Проверь GH_TOKEN scopes: project, read:project." >&2
    return 1
  fi
  echo "$id"
}

# Status / single-select options via GraphQL (works when `gh project field-list --owner` fails)
_project_field_json() {
  local pid field_name
  pid="$(project_id)"
  field_name="$1"
  gh api graphql \
    -f query='query($id:ID!){ node(id:$id){ ... on ProjectV2 { fields(first:50){ nodes { ... on ProjectV2SingleSelectField { id name options { id name } } ... on ProjectV2FieldCommon { id name } } } } } }' \
    -f id="$pid" \
    --jq --arg n "$field_name" '
      .data.node.fields.nodes[]
      | select(.name==$n)
    '
}

status_option_id() {
  local name="$1"
  local opt
  opt="$(gh project field-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json 2>/dev/null \
    | jq -r --arg n "$name" '
        .fields[]?
        | select(.name=="Status")
        | .options[]?
        | select(.name==$n)
        | .id
      ' || true)"
  if [[ -n "${opt:-}" && "$opt" != "null" ]]; then
    echo "$opt"
    return 0
  fi
  _project_field_json "Status" | jq -r --arg n "$name" '.options[]? | select(.name==$n) | .id' | head -1
}

field_id_by_name() {
  local name="$1"
  local fid
  fid="$(gh project field-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json 2>/dev/null \
    | jq -r --arg n "$name" '.fields[]? | select(.name==$n) | .id' || true)"
  if [[ -n "${fid:-}" && "$fid" != "null" ]]; then
    echo "$fid"
    return 0
  fi
  _project_field_json "$name" | jq -r '.id // empty'
}

# Find project item id for an issue number — prefer issue.projectItems (no --owner)
item_id_for_issue() {
  local issue_num="$1"
  local item_id issue_url
  item_id="$(gh api graphql \
    -f query='query($o:String!,$r:String!,$n:Int!){ repository(owner:$o,name:$r){ issue(number:$n){ projectItems(first:20){ nodes { id project { number } } } } } }' \
    -f o="$(_repo_owner)" \
    -f r="$(_repo_name)" \
    -F n="$issue_num" \
    --jq --argjson pn "$PROJECT_NUMBER" '
      .data.repository.issue.projectItems.nodes[]?
      | select(.project.number == $pn)
      | .id
    ' 2>/dev/null | head -1 || true)"
  if [[ -n "${item_id:-}" && "$item_id" != "null" ]]; then
    echo "$item_id"
    return 0
  fi

  # Fallback: gh project item-list (локально обычно ок)
  issue_url="https://github.com/${REPO}/issues/${issue_num}"
  gh project item-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json --limit 200 2>/dev/null \
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
    echo "warn: не удалось выставить Status=$status_name (field=$field_id opt=$opt_id pid=$pid)" >&2
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
  opt_id="$(gh project field-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json 2>/dev/null \
    | jq -r --arg f "$field_name" --arg o "$option_name" '
        .fields[]? | select(.name==$f) | .options[]? | select(.name==$o) | .id
      ' || true)"
  if [[ -z "${opt_id:-}" || "$opt_id" == "null" ]]; then
    opt_id="$(_project_field_json "$field_name" | jq -r --arg o "$option_name" '.options[]? | select(.name==$o) | .id' | head -1)"
  fi
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

# DATE fields: "Start date", "Target date" (YYYY-MM-DD)
# DPline: Start date = старт задачи; Target date = дата закрытия (Done)
set_date_field() {
  local item_id="$1"
  local field_name="$2"
  local date_value="${3:-}"
  local pid field_id
  if [[ -z "$date_value" ]]; then
    date_value="$(date +%Y-%m-%d)"
  fi
  pid="$(project_id)"
  field_id="$(field_id_by_name "$field_name")"
  if [[ -z "$field_id" ]]; then
    echo "warn: поле $field_name не найдено" >&2
    return 1
  fi
  gh project item-edit --id "$item_id" --project-id "$pid" --field-id "$field_id" --date "$date_value"
}

today_ymd() {
  date +%Y-%m-%d
}

# Project item id for a PR (auto-add workflow often adds PR cards — we remove them)
item_id_for_pr() {
  local pr_num="$1"
  local pn="${PROJECT_NUMBER}"
  gh api graphql \
    -f query='query($o:String!,$r:String!,$n:Int!){ repository(owner:$o,name:$r){ pullRequest(number:$n){ projectItems(first:20){ nodes { id project { number } } } } } }' \
    -f o="$(_repo_owner)" \
    -f r="$(_repo_name)" \
    -F n="$pr_num" \
    --jq ".data.repository.pullRequest.projectItems.nodes[]? | select(.project.number == ${pn}) | .id" \
    2>/dev/null | head -1 || true
}

# Убрать карточку PR с доски (оставляем только linked issues)
remove_pr_from_project() {
  local pr_num="$1"
  local item_id pid
  item_id="$(item_id_for_pr "$pr_num")"
  if [[ -z "${item_id:-}" || "$item_id" == "null" ]]; then
    return 0
  fi
  pid="$(project_id)" || return 0
  if gh api graphql \
    -f query='mutation($p:ID!,$i:ID!){ deleteProjectV2Item(input:{projectId:$p,itemId:$i}){ deletedItemId } }' \
    -f p="$pid" \
    -f i="$item_id" >/dev/null 2>&1; then
    echo "✓ PR #${pr_num} убран с Project (на доске только issues)"
  else
    echo "warn: не удалось убрать PR #${pr_num} с Project" >&2
  fi
}
