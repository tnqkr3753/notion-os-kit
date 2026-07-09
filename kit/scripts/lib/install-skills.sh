usage_install_skills() {
  cat <<'EOF'
Usage:
  kit/scripts/notion-os-kit install-skills --profile <name>

Generates compact orchestrator and workflow skills from profile metadata:
  ~/.agents/skills/<skill_prefix>/SKILL.md
  ~/.agents/skills/<skill_prefix>-<template-key>/SKILL.md

Options:
  --profile <name>  Profile name to install. Required.
  -h, --help        Show this help.
EOF
}

profile_template_slugs() {
  local file="$1"
  awk '
    /^templates:[[:space:]]*$/ {
      in_templates = 1
      next
    }
    in_templates && /^[^[:space:]][^:]*:/ {
      in_templates = 0
    }
    in_templates && /^[[:space:]]+[A-Za-z][A-Za-z0-9_-]*:[[:space:]]*/ {
      line = $0
      sub(/^[[:space:]]+/, "", line)
      split(line, parts, ":")
      key = tolower(parts[1])
      if (key ~ /s$/) {
        sub(/s$/, "", key)
      }
      print key
    }
  ' "$file" | sort -u
}

title_from_slug() {
  printf '%s\n' "$1" | awk '{
    gsub(/[-_]/, " ")
    for (i = 1; i <= NF; i++) {
      $i = toupper(substr($i, 1, 1)) substr($i, 2)
    }
    print
  }'
}

run_install_skills() {
  local name=""
  local workspace_label
  local display_name
  local skill_prefix
  local skill_dir
  local skill_file
  local template_slug
  local wrapper_name
  local wrapper_title

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --profile)
        [ "$#" -ge 2 ] || { usage_install_skills >&2; die_usage 2 "--profile requires a value"; return 2; }
        name="$2"
        shift 2
        ;;
      -h|--help)
        usage_install_skills
        return 0
        ;;
      *)
        usage_install_skills >&2
        die_usage 2 "unknown install-skills option: $1"
        return 2
        ;;
    esac
  done

  if [ -z "$name" ]; then
    usage_install_skills >&2
    printf 'ERROR: missing required --profile\n' >&2
    return 2
  fi
  validate_safe_slug "$name" "--profile" || return 2

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

  skill_dir="$AGENT_SKILLS_ROOT/$skill_prefix"
  skill_file="$skill_dir/SKILL.md"
  mkdir -p "$skill_dir"
  cat >"$skill_file" <<EOF
---
name: $skill_prefix
description: Manage the $display_name Notion OS profile through notion-os-kit CLI commands.
---

# $display_name

Use this skill when the user asks to operate the \`$name\` Notion OS profile.

Start with deterministic local checks:

\`\`\`bash
kit/scripts/notion-os-kit doctor --profile $name
\`\`\`

Profile source resolution order is repo, home, then example. Local deployment
state stays under:

\`\`\`text
~/.notion-os-kit/profiles/$name/state.local.yaml
\`\`\`

Use \`connect\` only to update local files, not live Notion content. Use
\`install-skills --profile $name\` to regenerate this skill and its workflow
wrappers.

Workspace label: $workspace_label
EOF

  printf 'installed_skill=%s\n' "$skill_file"

  while IFS= read -r template_slug; do
    [ -n "$template_slug" ] || continue
    validate_safe_slug "$template_slug" "template key" || return 2
    wrapper_name="$skill_prefix-$template_slug"
    wrapper_title="$(title_from_slug "$template_slug")"
    skill_dir="$AGENT_SKILLS_ROOT/$wrapper_name"
    skill_file="$skill_dir/SKILL.md"
    mkdir -p "$skill_dir"
    cat >"$skill_file" <<EOF
---
name: $wrapper_name
description: Operate the $wrapper_title workflow for the $display_name Notion OS profile through notion-os-kit metadata and local state.
---

# $display_name $wrapper_title

Use this generated wrapper when the user asks for the \`$template_slug\`
workflow in the \`$name\` Notion OS profile.

Start with deterministic local checks:

\`\`\`bash
kit/scripts/notion-os-kit doctor --profile $name
\`\`\`

Profile metadata comes from the resolved profile source. Local deployment state
stays under:

\`\`\`text
~/.notion-os-kit/profiles/$name/state.local.yaml
\`\`\`

Keep detailed rules and templates in profile metadata or kit templates. Do not
embed long workflow prose in this generated skill.

Workspace label: $workspace_label
Workflow template key: $template_slug
EOF
    printf 'installed_skill=%s\n' "$skill_file"
  done < <(profile_template_slugs "$PROFILE_SOURCE_FILE")
}
