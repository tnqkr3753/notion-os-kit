usage_today_summary() {
  cat <<'EOF'
Usage:
  kit/scripts/notion-os-kit today-summary --profile <name> [options]

Builds a Workstream/Ticket reconciliation draft from local coding-agent
sessions. This command does not mutate Notion.

Options:
  --profile <name>         Profile name to reconcile. Required.
  --date <YYYY-MM-DD|today> Date to summarize. Defaults to today.
  --timezone <name>        Local day timezone label. Defaults to Asia/Seoul.
  --platform <name>        Limit session search to a platform. Repeatable.
  --limit <n>              Maximum sessions to collect. Defaults to 100.
  --session-finder <path>  Path to find-agent-sessions.py.
  --sessions-json <path>   Use an existing finder JSON result instead of running the finder.
  --output <path>          Write Markdown draft to this path. Defaults to stdout.
  -h, --help               Show this help.
EOF
}

run_today_summary() {
  local name=""
  local date_value="today"
  local timezone_value="${TZ:-Asia/Seoul}"
  local limit_value="100"
  local session_finder="${NOTION_OS_SESSION_FINDER:-}"
  local sessions_json=""
  local output_path=""
  local platform_args=""
  local python_args=()
  local workspace_label
  local display_name
  local skill_prefix
  local local_date

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --profile)
        [ "$#" -ge 2 ] || { usage_today_summary >&2; die_usage 2 "--profile requires a value"; return 2; }
        name="$2"
        shift 2
        ;;
      --date)
        [ "$#" -ge 2 ] || { usage_today_summary >&2; die_usage 2 "--date requires a value"; return 2; }
        date_value="$2"
        shift 2
        ;;
      --timezone)
        [ "$#" -ge 2 ] || { usage_today_summary >&2; die_usage 2 "--timezone requires a value"; return 2; }
        timezone_value="$2"
        shift 2
        ;;
      --platform)
        [ "$#" -ge 2 ] || { usage_today_summary >&2; die_usage 2 "--platform requires a value"; return 2; }
        validate_safe_slug "$2" "--platform" || return 2
        platform_args="$platform_args $2"
        shift 2
        ;;
      --limit)
        [ "$#" -ge 2 ] || { usage_today_summary >&2; die_usage 2 "--limit requires a value"; return 2; }
        limit_value="$2"
        shift 2
        ;;
      --session-finder)
        [ "$#" -ge 2 ] || { usage_today_summary >&2; die_usage 2 "--session-finder requires a value"; return 2; }
        session_finder="$2"
        shift 2
        ;;
      --sessions-json)
        [ "$#" -ge 2 ] || { usage_today_summary >&2; die_usage 2 "--sessions-json requires a value"; return 2; }
        sessions_json="$2"
        shift 2
        ;;
      --output)
        [ "$#" -ge 2 ] || { usage_today_summary >&2; die_usage 2 "--output requires a value"; return 2; }
        output_path="$2"
        shift 2
        ;;
      -h|--help)
        usage_today_summary
        return 0
        ;;
      *)
        usage_today_summary >&2
        die_usage 2 "unknown today-summary option: $1"
        return 2
        ;;
    esac
  done

  if [ -z "$name" ]; then
    usage_today_summary >&2
    printf 'ERROR: missing required --profile\n' >&2
    return 2
  fi
  validate_safe_slug "$name" "--profile" || return 2
  validate_safe_text_scalar "$timezone_value" "--timezone" || return 2
  case "$limit_value" in
    ''|*[!0-9]*)
      printf 'ERROR: --limit must be a positive integer\n' >&2
      return 2
      ;;
  esac
  if [ "$limit_value" -lt 1 ]; then
    printf 'ERROR: --limit must be greater than zero\n' >&2
    return 2
  fi

  if ! resolve_profile_source "$name"; then
    printf 'ERROR: profile %s was not found in repo, home, or examples\n' "$name" >&2
    return 1
  fi

  workspace_label="$(profile_workspace_label "$PROFILE_SOURCE_FILE")"
  display_name="$(profile_display_name "$PROFILE_SOURCE_FILE")"
  skill_prefix="$(profile_skill_prefix "$PROFILE_SOURCE_FILE")"
  [ -n "$skill_prefix" ] || skill_prefix="$name"
  validate_safe_text_scalar "$workspace_label" "workspace_label" || return 2
  validate_safe_text_scalar "$display_name" "display_name" || return 2
  validate_safe_slug "$skill_prefix" "skill_prefix" || return 2

  if [ "$date_value" = "today" ]; then
    local_date="$(TZ="$timezone_value" date +%F)"
  else
    local_date="$date_value"
  fi
  case "$local_date" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
      ;;
    *)
      printf 'ERROR: --date must be today or YYYY-MM-DD\n' >&2
      return 2
      ;;
  esac

  if [ -z "$sessions_json" ] && [ -z "$session_finder" ]; then
    if command -v find-agent-sessions.py >/dev/null 2>&1; then
      session_finder="$(command -v find-agent-sessions.py)"
    else
      printf 'ERROR: provide --session-finder or --sessions-json; find-agent-sessions.py is not on PATH\n' >&2
      return 1
    fi
  fi
  if [ -n "$session_finder" ] && [ ! -f "$session_finder" ]; then
    printf 'ERROR: --session-finder not found: %s\n' "$session_finder" >&2
    return 1
  fi
  if [ -n "$sessions_json" ] && [ ! -f "$sessions_json" ]; then
    printf 'ERROR: --sessions-json not found: %s\n' "$sessions_json" >&2
    return 1
  fi

  python_args=(
    "$SCRIPT_LIB_DIR/today_summary.py"
    --profile "$name"
    --profile-source "$PROFILE_SOURCE_FILE"
    --profile-source-kind "$PROFILE_SOURCE_KIND"
    --workspace-label "$workspace_label"
    --display-name "$display_name"
    --skill-prefix "$skill_prefix"
    --date "$local_date"
    --timezone "$timezone_value"
    --limit "$limit_value"
  )
  if [ -n "$session_finder" ]; then
    python_args+=(--session-finder "$session_finder")
  fi
  if [ -n "$sessions_json" ]; then
    python_args+=(--sessions-json "$sessions_json")
  fi
  if [ -n "$output_path" ]; then
    python_args+=(--output "$output_path")
  fi
  for platform in $platform_args; do
    python_args+=(--platform "$platform")
  done

  python3 "${python_args[@]}"
}
