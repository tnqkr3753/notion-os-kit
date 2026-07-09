HOME_PROFILE_ROOT="$HOME/.notion-os-kit/profiles"
AGENT_SKILLS_ROOT="$HOME/.agents/skills"
SAFE_SLUG_REGEX='^[a-z][a-z0-9-]{0,62}$'
CLI_NAME="${NOTION_OS_KIT_COMMAND:-kit/scripts/notion-os-kit}"

profile="${NOTION_OS_PROFILE:-personal-os}"
failures=0
warnings=0

pass() {
  printf 'PASS  %s\n' "$1"
}

warn() {
  warnings=$((warnings + 1))
  printf 'WARN  %s\n' "$1"
}

fail() {
  failures=$((failures + 1))
  printf 'FAIL  %s\n' "$1"
}

die_usage() {
  local status="$1"
  shift
  printf 'ERROR: %s\n' "$*" >&2
  return "$status"
}

check_file() {
  if [ -f "$1" ]; then
    pass "$2"
  else
    fail "$2 missing: $1"
  fi
}

check_dir() {
  if [ -d "$1" ]; then
    pass "$2"
  else
    fail "$2 missing: $1"
  fi
}

strip_yaml_scalar() {
  local value="$1"
  value="${value%%#*}"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  case "$value" in
    \"*\")
      value="${value#\"}"
      value="${value%\"}"
      ;;
    \'*\')
      value="${value#\'}"
      value="${value%\'}"
      ;;
  esac
  printf '%s\n' "$value"
}

yaml_value() {
  local key="$1"
  local file="$2"
  local value
  if [ ! -f "$file" ]; then
    return 1
  fi
  value="$(awk -F: -v wanted="$key" '
    $1 ~ "^[[:space:]]*" wanted "$" {
      value=$2
      sub(/^[[:space:]]*/, "", value)
      sub(/[[:space:]]*$/, "", value)
      print value
      exit
    }
  ' "$file")"
  strip_yaml_scalar "$value"
}

display_name_from_profile() {
  local name="$1"
  printf '%s\n' "$name" | awk '{
    gsub(/[-_]/, " ")
    for (i = 1; i <= NF; i++) {
      $i = toupper(substr($i, 1, 1)) substr($i, 2)
    }
    print
  }'
}

reject_newline() {
  case "$1" in
    *$'\n'*|*$'\r'*)
      printf 'ERROR: %s cannot contain newlines\n' "$2" >&2
      return 2
      ;;
  esac
}

contains_control_char() {
  LC_ALL=C printf '%s' "$1" | grep -q '[[:cntrl:]]'
}

validate_safe_slug() {
  local value="$1"
  local label="$2"

  if [ -z "$value" ]; then
    printf 'ERROR: %s cannot be empty\n' "$label" >&2
    return 2
  fi
  reject_newline "$value" "$label" || return 2
  if ! [[ "$value" =~ $SAFE_SLUG_REGEX ]]; then
    printf 'ERROR: %s must match %s\n' "$label" "$SAFE_SLUG_REGEX" >&2
    return 2
  fi
}

validate_safe_text_scalar() {
  local value="$1"
  local label="$2"

  if [ -z "$value" ]; then
    printf 'ERROR: %s cannot be empty\n' "$label" >&2
    return 2
  fi
  reject_newline "$value" "$label" || return 2
  if contains_control_char "$value"; then
    printf 'ERROR: %s cannot contain control characters\n' "$label" >&2
    return 2
  fi
  case "$value" in
    *[\#:\{\}\[\]\&\*\!\|\>\'\"\\\`\$\<\>\;]*)
      printf 'ERROR: %s contains unsafe YAML/Markdown scalar characters\n' "$label" >&2
      return 2
      ;;
  esac
}

validate_root_page_scalar() {
  local value="$1"
  local label="$2"

  if [ -z "$value" ]; then
    printf 'ERROR: %s cannot be empty\n' "$label" >&2
    return 2
  fi
  reject_newline "$value" "$label" || return 2
  if contains_control_char "$value"; then
    printf 'ERROR: %s cannot contain control characters\n' "$label" >&2
    return 2
  fi
  case "$value" in
    *..*|*/*|*\\*|*[[:space:]]*|*[\;\&\|\`\$\<\>\(\)\{\}\[\]\'\"!#?:,]*)
      printf 'ERROR: %s contains unsafe scalar characters\n' "$label" >&2
      return 2
      ;;
  esac
}

validate_generated_scalars() {
  validate_safe_slug "$1" "--profile" || return 2
  validate_safe_text_scalar "$2" "display_name" || return 2
  validate_safe_text_scalar "$3" "--workspace" || return 2
  validate_safe_slug "$4" "skill_prefix" || return 2
  validate_root_page_scalar "$5" "--root-page" || return 2
}

verify_ntn_workspace() {
  local workspace_label="$1"
  local ntn_output
  local ntn_status

  if ! command -v ntn >/dev/null 2>&1; then
    printf 'ERROR: ntn is not installed; cannot verify workspace %s\n' "$workspace_label" >&2
    return 1
  fi

  ntn_output="$(ntn doctor 2>&1)"
  ntn_status=$?
  if [ "$ntn_status" -ne 0 ]; then
    printf '%s\n' "$ntn_output" >&2
    printf 'ERROR: ntn doctor exited %s; cannot verify workspace %s\n' "$ntn_status" "$workspace_label" >&2
    return 1
  fi

  if ! printf '%s\n' "$ntn_output" | grep -Fq "($workspace_label)"; then
    printf '%s\n' "$ntn_output" >&2
    printf 'ERROR: ntn doctor does not show requested workspace (%s)\n' "$workspace_label" >&2
    return 1
  fi
}

resolve_profile_source() {
  local name="$1"
  PROFILE_SOURCE_DIR=""
  PROFILE_SOURCE_FILE=""
  PROFILE_SOURCE_KIND=""

  if [ -f "$ROOT_DIR/profiles/$name/profile.yaml" ]; then
    PROFILE_SOURCE_DIR="$ROOT_DIR/profiles/$name"
    PROFILE_SOURCE_FILE="$PROFILE_SOURCE_DIR/profile.yaml"
    PROFILE_SOURCE_KIND="repo"
  elif [ -f "$HOME_PROFILE_ROOT/$name/profile.yaml" ]; then
    PROFILE_SOURCE_DIR="$HOME_PROFILE_ROOT/$name"
    PROFILE_SOURCE_FILE="$PROFILE_SOURCE_DIR/profile.yaml"
    PROFILE_SOURCE_KIND="home"
  elif [ -f "$ROOT_DIR/examples/$name/profile.yaml" ]; then
    PROFILE_SOURCE_DIR="$ROOT_DIR/examples/$name"
    PROFILE_SOURCE_FILE="$PROFILE_SOURCE_DIR/profile.yaml"
    PROFILE_SOURCE_KIND="example"
  else
    return 1
  fi
}

profile_workspace_label() {
  yaml_value "workspace_label" "$1"
}

profile_skill_prefix() {
  local value
  value="$(yaml_value "skill_prefix" "$1")"
  if [ -n "$value" ]; then
    printf '%s\n' "$value"
  else
    yaml_value "name" "$1"
  fi
}

profile_display_name() {
  local value
  value="$(yaml_value "display_name" "$1")"
  if [ -n "$value" ]; then
    printf '%s\n' "$value"
  else
    display_name_from_profile "$(yaml_value "name" "$1")"
  fi
}
