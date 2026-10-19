#!/bin/bash
# PostToolUse(Edit|Write|MultiEdit): ghi lại file vừa sửa để quality-gate kiểm tra.
input=$(cat)
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
sid=$(printf '%s' "$input" | jq -r '.session_id // "nosession"')
[ -z "$file" ] && exit 0
state="${CLAUDE_PROJECT_DIR:-$PWD}/.claude/.team-state"
mkdir -p "$state"
echo "$file" >> "$state/touched-$sid.txt"
exit 0
