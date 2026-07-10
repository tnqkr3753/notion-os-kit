#!/usr/bin/env python3
from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
import subprocess
import sys
from datetime import UTC, date, datetime, time, timedelta
from pathlib import Path
from typing import Any
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build a Workstream/Ticket reconciliation draft from coding-agent sessions."
    )
    parser.add_argument("--profile", required=True)
    parser.add_argument("--profile-source", required=True)
    parser.add_argument("--profile-source-kind", required=True)
    parser.add_argument("--workspace-label", required=True)
    parser.add_argument("--display-name", required=True)
    parser.add_argument("--skill-prefix", required=True)
    parser.add_argument("--date", required=True)
    parser.add_argument("--timezone", required=True)
    parser.add_argument("--limit", type=int, default=100)
    parser.add_argument("--session-finder")
    parser.add_argument("--sessions-json")
    parser.add_argument("--platform", action="append", default=[])
    parser.add_argument("--output")
    return parser.parse_args()


def load_sessions(args: argparse.Namespace) -> dict[str, Any]:
    if args.sessions_json:
        with open(args.sessions_json, "r", encoding="utf-8") as handle:
            return json.load(handle)

    if not args.session_finder:
        raise SystemExit("session finder is required when --sessions-json is not provided")

    window = local_day_window(args.date, args.timezone)
    finder_limit = max(args.limit * 4, 500)
    command = [
        sys.executable,
        args.session_finder,
        "list",
        "--from",
        window.finder_from,
        "--to",
        window.finder_to,
        "--limit",
        str(finder_limit),
        "--include-subagents",
    ]
    for platform in args.platform:
        command.extend(["--platform", platform])

    completed = subprocess.run(command, check=False, text=True, capture_output=True)
    if completed.returncode != 0:
        sys.stderr.write(completed.stderr)
        raise SystemExit(completed.returncode)
    return json.loads(completed.stdout)


@dataclass(frozen=True, slots=True)
class LocalDayWindow:
    start: datetime
    end: datetime
    finder_from: str
    finder_to: str


def local_day_window(local_date: str, timezone_name: str) -> LocalDayWindow:
    try:
        zone = ZoneInfo(timezone_name)
    except ZoneInfoNotFoundError as error:
        raise SystemExit(f"unknown timezone: {timezone_name}") from error

    try:
        parsed_date = date.fromisoformat(local_date)
    except ValueError as error:
        raise SystemExit(f"invalid date: {local_date}") from error
    start = datetime.combine(parsed_date, time.min, tzinfo=zone)
    end = start + timedelta(days=1)
    utc_start = start.astimezone(UTC)
    utc_end = end.astimezone(UTC)
    finder_from = utc_start.date().isoformat()
    finder_to = (utc_end.date() + timedelta(days=1)).isoformat()
    return LocalDayWindow(start=start, end=end, finder_from=finder_from, finder_to=finder_to)


def session_timestamp(item: dict[str, Any]) -> datetime | None:
    value = scalar(item.get("updated_at")) or scalar(item.get("created_at"))
    if not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def filter_payload(args: argparse.Namespace, payload: dict[str, Any]) -> dict[str, Any]:
    results = payload.get("results") or []
    if not isinstance(results, list):
        raise SystemExit("session JSON must contain a results array")

    window = local_day_window(args.date, args.timezone)
    filtered: list[dict[str, Any]] = []
    for item in results:
        if not isinstance(item, dict):
            continue
        timestamp = session_timestamp(item)
        if timestamp is None:
            continue
        local_timestamp = timestamp.astimezone(window.start.tzinfo)
        if window.start <= local_timestamp < window.end:
            filtered.append(item)

    output = dict(payload)
    output["results"] = filtered[: args.limit]
    output["count"] = len(output["results"])
    return output


def scalar(value: Any) -> str:
    if value is None:
        return ""
    text = str(value)
    return " ".join(text.split())


def preview(text: Any, limit: int = 110) -> str:
    cleaned = scalar(text)
    if len(cleaned) <= limit:
        return cleaned
    return cleaned[: limit - 1].rstrip() + "..."


def cwd_label(cwd: Any) -> str:
    cleaned = scalar(cwd)
    if not cleaned:
        return "unknown"
    return Path(cleaned).name or cleaned


def session_rows(results: list[dict[str, Any]]) -> list[str]:
    rows = [
        "| # | Platform | Repo/CWD | Prompt clue | Updated | Tokens | Session |",
        "| --- | --- | --- | --- | --- | ---: | --- |",
    ]
    for index, item in enumerate(results, start=1):
        usage = item.get("usage") or {}
        tokens = usage.get("total_tokens") or ""
        rows.append(
            "| {idx} | {platform} | {cwd} | {prompt} | {updated} | {tokens} | `{sid}` |".format(
                idx=index,
                platform=scalar(item.get("platform")) or "unknown",
                cwd=cwd_label(item.get("cwd")),
                prompt=preview(item.get("first_user_message") or item.get("last_user_message")),
                updated=scalar(item.get("updated_at")),
                tokens=tokens,
                sid=scalar(item.get("id")),
            )
        )
    return rows


def candidate_lines(results: list[dict[str, Any]]) -> list[str]:
    lines: list[str] = []
    seen: set[str] = set()
    for item in results:
        label = cwd_label(item.get("cwd"))
        if label in seen:
            continue
        seen.add(label)
        lines.append(f"- [ ] `{label}`: confirm the matching Notion OS Workstream.")
    if not lines:
        lines.append("- [ ] No sessions found. Confirm whether the day should remain unchanged.")
    return lines


def build_markdown(args: argparse.Namespace, payload: dict[str, Any]) -> str:
    results = payload.get("results") or []
    if not isinstance(results, list):
        raise SystemExit("session JSON must contain a results array")

    generated_at = datetime.now().astimezone().isoformat(timespec="seconds")
    lines = [
        f"# Today Summary Reconciliation - {args.date}",
        "",
        f"- Profile: `{args.profile}` ({args.display_name})",
        f"- Workspace label: {args.workspace_label}",
        f"- Profile source: {args.profile_source_kind} `{args.profile_source}`",
        f"- Local day boundary: `{args.timezone}`",
        f"- Sessions found: {len(results)}",
        f"- Generated at: {generated_at}",
        "",
        "## Source Sessions",
        "",
    ]
    lines.extend(session_rows(results))
    lines.extend(
        [
            "",
            "## Workstream Mapping To Confirm",
            "",
            "Map each source repo/session group to an existing Workstream before updating Notion.",
            "",
        ]
    )
    lines.extend(candidate_lines(results))
    lines.extend(
        [
            "",
            "## Ticket Updates To Confirm",
            "",
            "- [ ] For each session, decide whether it updates an existing Ticket, creates a new Ticket, or belongs only as a Workstream progress note.",
            "- [ ] Do not mark a Ticket complete from agent success text alone; require acceptance evidence or explicit user confirmation.",
            "- [ ] Keep Tickets under Workstreams. Do not create direct operational Project-Ticket mappings.",
            "",
            "## Grill Questions",
            "",
            "Ask these one at a time, with a recommended answer, before applying Notion writes:",
            "",
            "1. Which Workstream should each unmapped repo/session group update?",
            "2. Which items should become new Tickets instead of progress notes?",
            "3. Which completed-looking sessions have enough evidence to move a Ticket status?",
            "4. Which decisions or reusable learnings should also become Knowledge?",
            "",
            "## Apply Gate",
            "",
            "This draft is read-only. After confirmation, apply changes through the profile's Notion OS workflow and verify by fetching changed Workstreams/Tickets.",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    payload = filter_payload(args, load_sessions(args))
    markdown = build_markdown(args, payload)
    if args.output:
        output = Path(args.output)
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(markdown, encoding="utf-8")
    else:
        print(markdown)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
