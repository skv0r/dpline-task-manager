#!/usr/bin/env bash
# Create a GitHub sub-issue under an existing parent (issue or sub-issue).
# Thin wrapper: requires --parent, then delegates to create-task.sh
#
# Usage:
#   scripts/gh/create-subtask.sh --parent 10 --title "…" --type app --label health …
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PARENT=""
ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --parent)
      PARENT="$2"
      ARGS+=(--parent "$2")
      shift 2
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ -z "$PARENT" ]]; then
  echo "usage: $0 --parent <issue-number> --title T --type app|pr --label slug [same flags as create-task.sh]" >&2
  exit 1
fi

exec "${SCRIPT_DIR}/create-task.sh" "${ARGS[@]}"
