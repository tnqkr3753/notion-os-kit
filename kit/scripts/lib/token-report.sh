usage_token_report() {
  cat <<EOF
Usage:
  $CLI_NAME token-report

Prints file count, lines, words, chars, approximate token count, and duplicate
template hash status for public source candidates. This command does not require
profile-specific source to exist.

Options:
  -h, --help  Show this help.
EOF
}

collect_public_files() {
  local item
  if git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$ROOT_DIR" ls-files -z --cached --others --exclude-standard -- \
      AGENTS.md README.md pyproject.toml src kit examples docs \
      | sort -z \
      | while IFS= read -r -d '' item; do
          printf '%s/%s\n' "$ROOT_DIR" "$item"
        done
    return
  fi

  for item in AGENTS.md README.md pyproject.toml src kit examples docs; do
    if [ -f "$ROOT_DIR/$item" ]; then
      printf '%s\n' "$ROOT_DIR/$item"
    elif [ -d "$ROOT_DIR/$item" ]; then
      find "$ROOT_DIR/$item" -type f \
        ! -name '.DS_Store' \
        ! -path '*/.git/*' \
        | sort
    fi
  done
}

run_token_report() {
  local file_count=0
  local total_lines=0
  local total_words=0
  local total_chars=0
  local lines
  local words
  local chars
  local approx_tokens
  local rel
  local file

  printf 'notion-os-kit token-report\n\n'
  printf 'Public source candidates:\n'

  while IFS= read -r file; do
    [ -f "$file" ] || continue
    lines="$(wc -l <"$file" | tr -d ' ')"
    words="$(wc -w <"$file" | tr -d ' ')"
    chars="$(LC_ALL=C wc -c <"$file" | tr -d ' ')"
    file_count=$((file_count + 1))
    total_lines=$((total_lines + lines))
    total_words=$((total_words + words))
    total_chars=$((total_chars + chars))
    rel="${file#$ROOT_DIR/}"
    printf '  %s lines=%s words=%s chars=%s approx_tokens=%s\n' \
      "$rel" "$lines" "$words" "$chars" "$(((chars + 3) / 4))"
  done < <(collect_public_files)

  approx_tokens=$(((total_chars + 3) / 4))
  printf '\nTotals:\n'
  printf '  files: %s\n' "$file_count"
  printf '  lines: %s\n' "$total_lines"
  printf '  words: %s\n' "$total_words"
  printf '  chars: %s\n' "$total_chars"
  printf '  approx_tokens: %s\n' "$approx_tokens"

  printf '\nDuplicate template hash status:\n'
  if command -v shasum >/dev/null 2>&1; then
    local duplicates
    duplicates="$(
      collect_public_files \
        | awk '/[.]md$/ { print }' \
        | while IFS= read -r file; do shasum "$file"; done \
        | awk '{ count[$1]++; files[$1]=files[$1] " " $2 } END { for (h in count) if (count[h] > 1) print h files[h] }'
    )"
    if [ -n "$duplicates" ]; then
      printf '  duplicate_template_hashes: found\n'
      printf '%s\n' "$duplicates" | sed 's/^/  /'
    else
      printf '  duplicate_template_hashes: none\n'
    fi
  else
    printf '  duplicate_template_hashes: unknown; shasum not found\n'
  fi
}

dispatch_token_report() {
  case "${1:-}" in
    "")
      run_token_report
      ;;
    -h|--help)
      usage_token_report
      ;;
    *)
      usage_token_report >&2
      die_usage 2 "unknown token-report option: $1"
      return 2
      ;;
  esac
}
