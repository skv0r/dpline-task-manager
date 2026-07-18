#!/usr/bin/env python3
"""Refresh plan/backlog.md Phase-0 table from open GitHub issues + optional project hints in issue body."""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

REPO = "skv0r/dpline-task-manager"
ROOT = Path(__file__).resolve().parents[2]
BACKLOG = ROOT / "plan" / "backlog.md"

MARKER_START = "<!-- backlog:auto:start -->"
MARKER_END = "<!-- backlog:auto:end -->"


def run(cmd: list[str]) -> str:
    return subprocess.check_output(cmd, text=True)


def parse_meta(body: str) -> dict:
    body = body or ""
    meta = {}
    for key in ("type", "label", "phase"):
        m = re.search(rf"{key}:\s*`([^`]+)`", body)
        if m:
            meta[key] = m.group(1)
    return meta


def main() -> int:
    raw = run(
        [
            "gh",
            "issue",
            "list",
            "--repo",
            REPO,
            "--state",
            "open",
            "--limit",
            "100",
            "--json",
            "number,title,labels,body,url",
        ]
    )
    issues = json.loads(raw)
    issues.sort(key=lambda i: i["number"])

    rows = []
    for issue in issues:
        meta = parse_meta(issue.get("body") or "")
        typ = meta.get("type", "?")
        phase = meta.get("phase", "?")
        label = meta.get("label", "")
        labels = ",".join(l["name"] for l in issue.get("labels") or [])
        branch = f"{typ}-{issue['number']}-{label}" if typ in ("app", "pr") and label else ""
        rows.append(
            f"| [#{issue['number']}]({issue['url']}) | {issue['title']} | open | {typ} | {phase} | `{branch}` | {labels} |"
        )

    table = "\n".join(
        [
            "| Issue | Название | State | Type | Phase | Branch | Labels |",
            "|-------|----------|-------|------|-------|--------|--------|",
            *rows,
        ]
    )

    block = f"{MARKER_START}\n{table}\n{MARKER_END}"

    text = BACKLOG.read_text(encoding="utf-8")
    if MARKER_START in text and MARKER_END in text:
        text = re.sub(
            re.escape(MARKER_START) + r".*?" + re.escape(MARKER_END),
            block,
            text,
            flags=re.S,
        )
    else:
        text = text.rstrip() + "\n\n## Авто-зеркало open issues\n\n" + block + "\n"

    BACKLOG.write_text(text, encoding="utf-8")
    print(f"updated {BACKLOG} ({len(issues)} open issues)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
