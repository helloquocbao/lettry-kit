#!/bin/bash
# PreToolUse(Bash): chặn lệnh phá huỷ hoặc ra ngoài mà deny-rule dạng tiền tố bỏ lọt
# (ví dụ lệnh nằm sau && hay trong subshell).
cmd=$(jq -r '.tool_input.command // empty')
deny() { echo "Bị chặn bởi guard của đội Lettry: $1. Nhờ người dùng tự chạy nếu thật sự cần." >&2; exit 2; }
printf '%s' "$cmd" | grep -qE '(^|[;&|(]\s*)git\s+push\b'                 && deny "git push"
printf '%s' "$cmd" | grep -qE 'git\s+reset\s+--hard|git\s+clean\s+-[a-z]*f' && deny "git reset --hard / git clean"
printf '%s' "$cmd" | grep -qE '\brm\s+-[a-zA-Z]*r[a-zA-Z]*f|\brm\s+-[a-zA-Z]*f[a-zA-Z]*r' && deny "rm -rf"
printf '%s' "$cmd" | grep -qiE 'ef\s+database\s+drop|drop\s+(table|database)\b|truncate\s+table' && deny "xoá database/bảng"
exit 0
