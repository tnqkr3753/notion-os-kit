usage_doctor() {
  cat <<EOF
Usage:
  $CLI_NAME doctor [--profile <name>]

Options:
  --profile <name>  Profile name to check. Defaults to NOTION_OS_PROFILE or personal-os.
  -h, --help        Show this help.
EOF
}

run_doctor() {
  local profile_dir
  local profile_file
  local state_file
  local skill_prefix=""
  local workspace_label=""
  local state_workspace_label=""
  local ntn_output
  local ntn_status

  validate_safe_slug "$profile" "--profile" || return 2
  state_file="$HOME_PROFILE_ROOT/$profile/state.local.yaml"

  printf 'notion-os-kit doctor profile=%s\n\n' "$profile"

  check_dir "$ROOT_DIR/kit" "kit source directory exists"
  if [ -d "$ROOT_DIR/profiles" ]; then
    pass "repo profiles directory exists"
  else
    warn "repo profiles directory is absent; home/example profiles remain valid"
  fi

  if resolve_profile_source "$profile"; then
    profile_dir="$PROFILE_SOURCE_DIR"
    profile_file="$PROFILE_SOURCE_FILE"
    pass "profile source resolved: $PROFILE_SOURCE_KIND $profile_file"
  else
    fail "profile.yaml missing in repo, home, and examples for profile=$profile"
    profile_dir="$ROOT_DIR/profiles/$profile"
    profile_file="$profile_dir/profile.yaml"
  fi

  check_file "$profile_file" "profile.yaml exists"
  check_file "$state_file" "home-directory state.local.yaml exists"

  if [ -f "$profile_file" ]; then
    workspace_label="$(profile_workspace_label "$profile_file")"
    skill_prefix="$(profile_skill_prefix "$profile_file")"
  fi

  if [ -n "$workspace_label" ]; then
    pass "profile workspace_label=$workspace_label"
  else
    fail "profile workspace_label is missing"
  fi

  if [ -n "$skill_prefix" ]; then
    pass "profile skill_prefix=$skill_prefix"
  else
    fail "profile skill_prefix is missing"
  fi

  if [ -d "$profile_dir/rules" ]; then
    check_file "$profile_dir/rules/relation-rules.md" "relation rules exist"
    check_file "$profile_dir/rules/interview-rules.md" "interview rules exist"
    check_file "$profile_dir/rules/verification-rules.md" "verification rules exist"
  else
    warn "profile rules directory not present; expecting kit defaults or generated local rules"
  fi

  if [ -d "$profile_dir/templates" ]; then
    check_file "$profile_dir/templates/project.md" "Project template exists"
    check_file "$profile_dir/templates/workstream.md" "Workstream template exists"
    check_file "$profile_dir/templates/ticket.md" "Ticket template exists"
    check_file "$profile_dir/templates/meeting.md" "Meeting template exists"
    check_file "$profile_dir/templates/knowledge.md" "Knowledge template exists"
    check_file "$profile_dir/templates/inbox.md" "Inbox template exists"
    check_file "$profile_dir/templates/area.md" "Area template exists"
    if [ -f "$profile_dir/templates/today-summary.md" ]; then
      pass "Today Summary template exists"
    else
      check_file "$ROOT_DIR/kit/templates/today-summary.md" "generic Today Summary template exists"
    fi
  else
    check_file "$ROOT_DIR/kit/templates/project.md" "generic Project template exists"
    check_file "$ROOT_DIR/kit/templates/workstream.md" "generic Workstream template exists"
    check_file "$ROOT_DIR/kit/templates/ticket.md" "generic Ticket template exists"
    check_file "$ROOT_DIR/kit/templates/meeting.md" "generic Meeting template exists"
    check_file "$ROOT_DIR/kit/templates/knowledge.md" "generic Knowledge template exists"
    check_file "$ROOT_DIR/kit/templates/inbox.md" "generic Inbox template exists"
    check_file "$ROOT_DIR/kit/templates/area.md" "generic Area template exists"
    check_file "$ROOT_DIR/kit/templates/today-summary.md" "generic Today Summary template exists"
  fi

  if find "$ROOT_DIR" -path "$ROOT_DIR/.git" -prune -o -name state.local.yaml -print | grep -q .; then
    fail "state.local.yaml exists inside repo; keep deployment state under ~/.notion-os-kit"
  else
    pass "no state.local.yaml inside repo"
  fi

  if [ -f "$state_file" ] && [ -n "$workspace_label" ]; then
    state_workspace_label="$(yaml_value "label" "$state_file")"
    if [ "$state_workspace_label" = "$workspace_label" ]; then
      pass "state.local.yaml workspace label matches profile"
    else
      fail "state.local.yaml workspace label does not match profile workspace_label=$workspace_label"
    fi
  fi

  if command -v ntn >/dev/null 2>&1; then
    pass "ntn is installed: $(command -v ntn)"
    ntn_output="$(ntn doctor 2>&1)"
    ntn_status=$?
    if [ "$ntn_status" -eq 0 ]; then
      pass "ntn doctor exits 0"
    else
      fail "ntn doctor exits $ntn_status"
    fi
    if [ -n "$workspace_label" ] && printf '%s\n' "$ntn_output" | grep -q "($workspace_label)"; then
      pass "ntn default workspace is $workspace_label"
    elif [ -n "$workspace_label" ]; then
      fail "ntn default workspace is not $workspace_label"
    fi
    if printf '%s\n' "$ntn_output" | grep -q 'available'; then
      warn "ntn reports an update is available"
    fi
  else
    fail "ntn is not installed"
  fi

  check_file "$ROOT_DIR/kit/skills/notion-os/SKILL.md" "generic notion-os skill source exists"
  if [ -n "$skill_prefix" ]; then
    if [ -d "$AGENT_SKILLS_ROOT/$skill_prefix" ]; then
      pass "installed profile skill exists in ~/.agents/skills"
    else
      warn "installed profile skill missing in ~/.agents/skills; run install-skills --profile $profile"
    fi
  fi

  printf '\nSummary: %s failure(s), %s warning(s)\n' "$failures" "$warnings"
  if [ "$failures" -gt 0 ]; then
    return 1
  fi
}

dispatch_doctor() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --profile)
        [ "$#" -ge 2 ] || { usage_doctor >&2; die_usage 2 "--profile requires a value"; return 2; }
        profile="$2"
        validate_safe_slug "$profile" "--profile" || return 2
        shift 2
        ;;
      -h|--help)
        usage_doctor
        return 0
        ;;
      *)
        usage_doctor >&2
        die_usage 2 "unknown doctor option: $1"
        return 2
        ;;
    esac
  done
  run_doctor
}
