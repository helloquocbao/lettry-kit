# lettry-kit

Bộ công cụ Claude Code dùng chung cho các repo của hệ Lettry:

| Repo | Vai trò |
| --- | --- |
| [magic-authen](https://github.com/helloquocbao/magic-authen) | Auth-center (Magic ID): trung tâm xác thực, quyết ai **được mở** ứng dụng nào |
| [props-os](https://github.com/helloquocbao/props-os) | PropOS – CDE: dữ liệu dự án bất động sản phía Chủ đầu tư |
| [hcg-report](https://github.com/helloquocbao/hcg-report) | HCG Report: báo cáo tài chính (import sổ 111/112, dòng tiền, khoá kỳ) |

Repo này là một **plugin marketplace**. Plugin `lettry-team` gồm:

- **14 agent**: product-manager, business-analyst, ui-designer, backend-architect, backend-developer,
  frontend-developer, qa-expert, test-automator, code-reviewer, architect-reviewer, security-auditor,
  debugger, deployment-engineer, technical-writer. Gọi dạng `lettry-team:<tên>`.
- **Skill `/team`**: Claude chính làm Trưởng dự án — phân loại yêu cầu, trình kế hoạch, giao agent,
  lưu hồ sơ ở `docs/team/<YYYYMMDD-slug>/`. Quy tắc chung của hệ ở
  [`skills/team/references/lettry-rules.md`](plugins/lettry-team/skills/team/references/lettry-rules.md).
- **Hook**:
  - `guard.sh` (PreToolUse/Bash): chặn `git push`, `git reset --hard`, `git clean -f`, `rm -rf`, drop/truncate database.
  - `track-edits.sh` + `quality-gate.sh` (Stop/SubagentStop): build .NET / `tsc` phần vừa sửa, chặn import `@ant-design/icons`.
  - Cần `jq` trên máy.

## Cài đặt

Trong Claude Code, ở bất kỳ repo nào của hệ:

```
/plugin marketplace add helloquocbao/lettry-kit
/plugin install lettry-team@lettry-kit
```

Ba repo trên đã khai báo sẵn marketplace và plugin trong `.claude/settings.json`
(`extraKnownMarketplaces`, `enabledPlugins`), nên khi mở repo và tin cậy thư mục, Claude Code sẽ gợi ý cài.

Cập nhật: `/plugin marketplace update lettry-kit`.

## Kiến thức riêng từng repo

Không nằm ở đây. Mỗi repo tự mang:

- `CLAUDE.md` (và `AGENTS.md` cho tool khác): quy tắc, cấu trúc, cách chạy.
- `.claude/skills/<repo>-backend|frontend|dod/SKILL.md`: kiến thức theo vai trò, Claude chính đưa đường dẫn cho agent.
- `docs/ecosystem.md`: ba ứng dụng nối với nhau thế nào (client, scope, cổng, domain).

## Sửa bộ công cụ

Sửa trong `plugins/lettry-team/`, tăng `version` ở cả `plugin.json` và `.claude-plugin/marketplace.json`,
rồi push. Agent lấy từ [davila7/claude-code-templates](https://github.com/davila7/claude-code-templates);
khi xung đột, kiến trúc của từng repo thắng.
