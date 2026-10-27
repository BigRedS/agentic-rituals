#!/usr/bin/env bash
# PreToolUse hook for Claude Code — emits "ask" when Write/Edit targets an
# EXISTING file under $GUARDED_DIR (default ~/notes). New files pass through
# to whatever Write()/Edit() allow rule you have; overwrites get a prompt.
#
# Why: a blanket Write(~/notes/**) allow rule is what makes scheduled skills
# run unattended, but it also lets a skill clobber a hand-written file
# silently. This keeps "always allow new, confirm overwrite" without
# per-file rules.
#
# Wire it in ~/.claude/settings.json:
#   "hooks": { "PreToolUse": [ { "matcher": "Write|Edit",
#     "hooks": [ { "type": "command", "command": "$HOME/.claude/hooks/overwrite-guard.sh" } ] } ] }
set -u
GUARDED_DIR="${GUARDED_DIR:-$HOME/notes}"
input=$(cat)
tool_name=$(printf '%s' "$input" | jq -r '.tool_name // ""')
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')
case "$tool_name" in Write|Edit) ;; *) exit 0 ;; esac
case "$file_path" in "$GUARDED_DIR/"*) ;; *) exit 0 ;; esac
[ -e "$file_path" ] || exit 0
cat <<JSON
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask",
    "permissionDecisionReason": "Overwriting existing file under $GUARDED_DIR ($file_path) — confirm intent."
  }
}
JSON
