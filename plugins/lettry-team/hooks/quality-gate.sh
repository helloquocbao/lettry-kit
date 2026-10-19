#!/bin/bash
# Stop / SubagentStop: build lại phần đã sửa. Lỗi thì exit 2 để agent tự sửa tiếp.
input=$(cat)
sid=$(printf '%s' "$input" | jq -r '.session_id // "nosession"')
again=$(printf '%s' "$input" | jq -r '.stop_hook_active // false')
root="${CLAUDE_PROJECT_DIR:-$PWD}"
list="$root/.claude/.team-state/touched-$sid.txt"
[ -s "$list" ] || exit 0

files=$(sort -u "$list" | while read -r f; do [ -f "$f" ] && echo "$f"; done)
[ -z "$files" ] && { rm -f "$list"; exit 0; }

# Tìm file cha gần nhất khớp mẫu, dừng ở gốc dự án.
nearest() { local d; d=$(dirname "$1"); while [ "${d#$root}" != "$d" ]; do
  for p in $2; do m=$(ls "$d"/$p 2>/dev/null | head -1); [ -n "$m" ] && { echo "$m"; return; }; done
  [ "$d" = "$root" ] && return; d=$(dirname "$d"); done; }

errors=""
sln=$(printf '%s\n' "$files" | grep -E '\.(cs|csproj|props|targets)$' | head -1)
if [ -n "$sln" ]; then
  target=$(nearest "$sln" "*.slnx *.sln")
  if [ -n "$target" ]; then
    out=$(cd "$(dirname "$target")" && dotnet build "$target" -nologo -v q -clp:ErrorsOnly 2>&1)
    if [ $? -ne 0 ]; then
      real=$(printf '%s\n' "$out" | grep -E 'error' | grep -vE 'MSB3021|MSB3026|MSB3027|being used by another process' | sort -u | head -40)
      [ -n "$real" ] && errors+=$'\n'"dotnet build $(basename "$target") lỗi:"$'\n'"$real"
    fi
  fi
fi

for ts in $(printf '%s\n' "$files" | grep -E '\.(ts|tsx)$' | while read -r f; do nearest "$f" "tsconfig.json"; done | sort -u); do
  dir=$(dirname "$ts")
  [ -d "$dir/node_modules" ] || continue
  out=$(cd "$dir" && npx --no-install tsc -b 2>&1)
  if [ $? -ne 0 ]; then
    errors+=$'\n'"tsc ($dir) lỗi:"$'\n'"$(printf '%s\n' "$out" | grep -E 'error TS' | head -40)"
  fi
done

# Quy tắc HCG: cấm icon của Ant Design, bắt buộc Heroicons (xem skills/team/references/lettry-rules.md).
antd=$(printf '%s\n' "$files" | grep -E '\.(ts|tsx|js|jsx)$' | while read -r f; do
  grep -nE "from ['\"]@ant-design/icons['\"]|require\(['\"]@ant-design/icons['\"]\)" "$f" 2>/dev/null | sed "s|^|$f:|" | head -3
done | head -20)
if [ -n "$antd" ]; then
  errors+=$'\n'"Cấm dùng @ant-design/icons, phải dùng Heroicons (@heroicons/react, qua components/icons.tsx). Còn import ở:"$'\n'"$antd"
fi

if [ -n "$errors" ]; then
  if [ "$again" = "true" ]; then
    # Đã chặn một lần mà vẫn lỗi: thả cho dừng để không lặp vô hạn, nhưng giữ danh sách file.
    echo "Quality gate vẫn còn lỗi sau khi sửa:$errors" >&2
    exit 0
  fi
  echo "Quality gate: build/typecheck chưa qua. Sửa các lỗi sau rồi mới kết thúc:$errors" >&2
  exit 2
fi
rm -f "$list"
exit 0
