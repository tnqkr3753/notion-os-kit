usage_connect() {
  cat <<EOF
Usage:
  $CLI_NAME init --profile <name> --workspace <label> --root-page <page-id>

Creates or updates only local files:
  ~/.notion-os-kit/profiles/<name>/profile.yaml
  ~/.notion-os-kit/profiles/<name>/state.local.yaml

Required options:
  --profile <name>      Local profile name to create or update.
  --workspace <label>   Workspace label expected from ntn doctor.
  --root-page <page-id> Root/template hub page id to store in local state.

Options:
  -h, --help            Show this help.
EOF
}

write_profile_yaml() {
  local file="$1"
  local name="$2"
  local display_name="$3"
  local workspace_label="$4"
  local skill_prefix="$5"

  cat >"$file" <<EOF
profile:
  name: $name
  display_name: $display_name
  workspace_label: $workspace_label

model:
  databases:
    - Areas
    - Projects
    - Workstreams
    - Tickets
    - Meetings
    - Knowledge
    - Inbox
  relation_model: Area -> Project -> Workstream -> Ticket

defaults:
  skill_prefix: $skill_prefix
  local_state_path: ~/.notion-os-kit/profiles/$name/state.local.yaml
  generation_mode: generation-first

rules:
  relation: rules/relation-rules.md
  interview: rules/interview-rules.md
  verification: rules/verification-rules.md

templates:
  area: templates/area.md
  project: templates/project.md
  workstream: templates/workstream.md
  ticket: templates/ticket.md
  meeting: templates/meeting.md
  knowledge: templates/knowledge.md
  inbox: templates/inbox.md
EOF
}

write_new_state_yaml() {
  local file="$1"
  local name="$2"
  local workspace_label="$3"
  local root_page="$4"

  cat >"$file" <<EOF
profile: $name
workspace:
  label: $workspace_label
  root_page_id: $root_page

pages:
  template_hub: $root_page
EOF
}

update_state_yaml() {
  local file="$1"
  local name="$2"
  local workspace_label="$3"
  local root_page="$4"
  local tmp

  if [ ! -f "$file" ]; then
    write_new_state_yaml "$file" "$name" "$workspace_label" "$root_page"
    return
  fi

  tmp="$(mktemp)"
  awk -v profile="$name" -v label="$workspace_label" -v root="$root_page" '
    function emit_workspace_missing() {
      if (in_workspace) {
        if (!workspace_label_done) print "  label: " label
        if (!workspace_root_done) print "  root_page_id: " root
      }
    }
    function emit_pages_missing() {
      if (in_pages && !pages_template_done) print "  template_hub: " root
    }
    function leave_sections() {
      emit_workspace_missing()
      emit_pages_missing()
      in_workspace = 0
      in_pages = 0
    }
    /^[^[:space:]][^:]*:/ {
      key = $0
      sub(/:.*/, "", key)
      if (NR > 1) leave_sections()
      if (key == "profile") {
        print "profile: " profile
        profile_done = 1
        next
      }
      if (key == "workspace") {
        print
        in_workspace = 1
        workspace_seen = 1
        workspace_label_done = 0
        workspace_root_done = 0
        next
      }
      if (key == "pages") {
        print
        in_pages = 1
        pages_seen = 1
        pages_template_done = 0
        next
      }
    }
    in_workspace && /^[[:space:]]+label:/ {
      print "  label: " label
      workspace_label_done = 1
      next
    }
    in_workspace && /^[[:space:]]+root_page_id:/ {
      print "  root_page_id: " root
      workspace_root_done = 1
      next
    }
    in_pages && /^[[:space:]]+template_hub:/ {
      print "  template_hub: " root
      pages_template_done = 1
      next
    }
    { print }
    END {
      leave_sections()
      if (!profile_done) print "profile: " profile
      if (!workspace_seen) {
        print "workspace:"
        print "  label: " label
        print "  root_page_id: " root
      }
      if (!pages_seen) {
        print "pages:"
        print "  template_hub: " root
      }
    }
  ' "$file" >"$tmp"
  mv "$tmp" "$file"
}

run_connect() {
  local name=""
  local workspace_label=""
  local root_page=""
  local display_name=""
  local skill_prefix=""
  local profile_dir
  local profile_file
  local state_file

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --profile)
        [ "$#" -ge 2 ] || { usage_connect >&2; die_usage 2 "--profile requires a value"; return 2; }
        name="$2"
        shift 2
        ;;
      --workspace)
        [ "$#" -ge 2 ] || { usage_connect >&2; die_usage 2 "--workspace requires a value"; return 2; }
        workspace_label="$2"
        shift 2
        ;;
      --root-page)
        [ "$#" -ge 2 ] || { usage_connect >&2; die_usage 2 "--root-page requires a value"; return 2; }
        root_page="$2"
        shift 2
        ;;
      -h|--help)
        usage_connect
        return 0
        ;;
      *)
        usage_connect >&2
        die_usage 2 "unknown connect option: $1"
        return 2
        ;;
    esac
  done

  if [ -z "$name" ] || [ -z "$workspace_label" ] || [ -z "$root_page" ]; then
    usage_connect >&2
    [ -n "$name" ] || printf 'ERROR: missing required --profile\n' >&2
    [ -n "$workspace_label" ] || printf 'ERROR: missing required --workspace\n' >&2
    [ -n "$root_page" ] || printf 'ERROR: missing required --root-page\n' >&2
    return 2
  fi
  validate_safe_slug "$name" "--profile" || return 2
  validate_safe_text_scalar "$workspace_label" "--workspace" || return 2
  validate_root_page_scalar "$root_page" "--root-page" || return 2

  profile_dir="$HOME_PROFILE_ROOT/$name"
  profile_file="$profile_dir/profile.yaml"
  state_file="$profile_dir/state.local.yaml"

  if resolve_profile_source "$name"; then
    display_name="$(profile_display_name "$PROFILE_SOURCE_FILE")"
    skill_prefix="$(profile_skill_prefix "$PROFILE_SOURCE_FILE")"
  fi
  [ -n "$display_name" ] || display_name="$(display_name_from_profile "$name")"
  [ -n "$skill_prefix" ] || skill_prefix="notion-os"
  validate_generated_scalars "$name" "$display_name" "$workspace_label" "$skill_prefix" "$root_page" || return 2
  verify_ntn_workspace "$workspace_label" || return 1

  mkdir -p "$profile_dir"
  write_profile_yaml "$profile_file" "$name" "$display_name" "$workspace_label" "$skill_prefix"
  update_state_yaml "$state_file" "$name" "$workspace_label" "$root_page"

  printf 'connected profile=%s workspace=%s\n' "$name" "$workspace_label"
  printf 'profile_file=%s\n' "$profile_file"
  printf 'state_file=%s\n' "$state_file"
}
