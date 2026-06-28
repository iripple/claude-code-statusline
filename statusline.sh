#!/usr/bin/env bash
# claude-code-statusline (macOS / Linux)
# Reads Claude Code's status JSON on stdin, prints one status line.

json="$(cat)"
config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
esc=$'\033'
parts=()

jget() { printf '%s' "$1" | sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -n1; }
col() { printf '%s[38;5;%sm%s%s[0m' "$esc" "$1" "$2" "$esc"; }
titlecase() { printf '%s%s' "$(printf '%s' "${1:0:1}" | tr '[:lower:]' '[:upper:]')" "$(printf '%s' "${1:1}" | tr '[:upper:]' '[:lower:]')"; }

# Claude account email (auto-updates on account switch)
email="$(jget "$(cat "$HOME/.claude.json" 2>/dev/null)" emailAddress)"
[ -n "$email" ] && parts+=("$(col 141 "[$email]")")

# model (+ weekly usage % when available — Pro/Max, after first API response)
model="$(jget "$json" display_name)"
if [ -n "$model" ]; then
  # [^}]* keeps the match inside the seven_day object so we grab its used_percentage, not five_hour's
  week="$(printf '%s' "$json" | sed -n 's/.*"seven_day"[^}]*"used_percentage"[[:space:]]*:[[:space:]]*\([0-9.]*\).*/\1/p')"
  if [ -n "$week" ]; then
    p="$(printf '%.1f' "$week")"
    ci="${p%.*}"  # integer part for threshold compare
    p="${p%.0}"   # drop trailing .0 — show decimal only when non-zero
    c=67; [ "$ci" -ge 50 ] && c=179; [ "$ci" -ge 80 ] && c=196
    parts+=("$(col "$c" "[$model:${p}%]")")
  else
    parts+=("$(col 67 "[$model]")")
  fi
fi

# current folder
dir="$(jget "$json" current_dir)"; [ -z "$dir" ] && dir="$(jget "$json" cwd)"
[ -n "$dir" ] && parts+=("$(col 110 "[$(basename "$dir")]")")

# git branch (+ * if dirty), [] when not a repo
branch=""
[ -n "$dir" ] && branch="$(cd "$dir" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null)"
if [ -n "$branch" ]; then
  dirty=""; [ -n "$(cd "$dir" && git status --porcelain 2>/dev/null)" ] && dirty="*"
  parts+=("$(col 179 "[$branch$dirty]")")
else
  parts+=("$(col 179 "[]")")
fi

# active skill badges: any <config>/.<name>-active flag file
shopt -s nullglob
for f in "$config_dir"/.*-active; do
  [ -f "$f" ] || continue
  name="$(basename "$f")"; name="${name#.}"; name="${name%-active}"
  name="$(titlecase "$name")"
  mode="$(head -n1 "$f" | tr -d '[:space:]')"
  if [ -n "$mode" ] && [ "$mode" != "full" ]; then
    parts+=("$(col 108 "[$name:$(titlecase "$mode")]")")
  else
    parts+=("$(col 108 "[$name]")")
  fi
done

# join with a single space
sep="$(col 240 ' ')"
out=""
for i in "${!parts[@]}"; do
  [ "$i" -gt 0 ] && out+="$sep"
  out+="${parts[$i]}"
done
printf '%s' "$out"
