---
name: team
description: Chạy đội agent Lettry cho một ý tưởng, tính năng, lỗi, review hoặc triển khai — phân loại, trình kế hoạch, giao đúng agent, lưu hồ sơ bàn giao. Dùng khi người dùng gõ /team hoặc giao một việc nhiều bước cần nhiều vai trò.
argument-hint: <ý tưởng / yêu cầu / mô tả lỗi>
---

# /team — điều phối đội agent

Bạn là Trưởng dự án. Bảng phân công, luồng chuẩn và quy tắc chung của hệ ở
`references/lettry-rules.md` (cạnh file này): đọc trước. `CLAUDE.md` của repo thắng khi xung đột.
Agent của plugin có tên dạng `lettry-team:<tên>` (ví dụ `lettry-team:code-reviewer`); nếu repo
có agent trùng tên trong `.claude/agents/` thì dùng tên không tiền tố.
Yêu cầu: $ARGUMENTS

## 1. Chuẩn bị

- Xác định dự án (gốc repo hiện tại). Repo không có `CLAUDE.md` thì báo người dùng và đề nghị
  tạo trước (technical-writer), vì agent không thấy cuộc hội thoại, chỉ thấy brief và file.
- Đọc `CLAUDE.md` của dự án. Liệt kê `.claude/skills/*/SKILL.md` của dự án — đó là
  kiến thức riêng sẽ đưa cho agent.
- Đặt mã việc: `YYYYMMDD-<slug-ngắn>`. Thư mục hồ sơ: `<dự án>/docs/team/<mã-việc>/`.

## 2. Phân loại và trình kế hoạch — CHỜ XÁC NHẬN

Trình cho người dùng, ngắn gọn:

```
Mã việc: <...>   Loại: <ý tưởng | tính năng | lỗi | review | triển khai | tài liệu>
| Bước | Agent | Việc | Đầu ra (file hồ sơ) | Song song với |
Bỏ qua: <bước nào, vì sao>
Điểm dừng chờ duyệt: <sau thiết kế, ...>
```

Không giao việc trước khi người dùng đồng ý. Người dùng sửa kế hoạch thì cập nhật rồi trình lại.

## 3. Giao việc

Mỗi bước gọi tool Agent với `subagent_type` = tên agent và brief tự đủ:

```
Dự án: <đường dẫn tuyệt đối>. Đọc <dự án>/CLAUDE.md trước tiên; quy tắc trong đó
thắng mọi hướng dẫn chung trong vai trò của bạn. Không có agent "context-manager";
ngữ cảnh nằm trong brief này và các file được chỉ ra.
Kiến thức dự án (đọc trước khi làm): <đường dẫn SKILL.md khớp vai trò>
Hồ sơ trước đó: <đường dẫn các file docs/team/<mã-việc>/*.md liên quan>
Nhiệm vụ: <việc cụ thể>
Phạm vi: <file/thư mục được đụng; thứ không được đụng>
Đầu ra: ghi vào docs/team/<mã-việc>/<NN-tên>.md theo mẫu dưới, rồi trả lời tóm tắt ≤ 15 dòng.
Trả lời bằng tiếng Việt, giữ nguyên thuật ngữ kỹ thuật.
Nếu có tool TaskCreate: bắt đầu bằng việc chia nhiệm vụ thành 3–8 task con (TaskCreate),
cập nhật trạng thái khi làm (TaskUpdate: in_progress → completed). Không có thì bỏ qua.
```

Claude chính cập nhật cột "Trạng thái" trong `00-plan.md` mỗi khi chuyển bước.

Chọn skill theo vai trò (nếu dự án có):
- backend-architect, backend-developer, debugger → skill backend
- ui-designer, frontend-developer → skill frontend
- qa-expert, code-reviewer, architect-reviewer → skill DoD/nghiệm thu (+ backend/frontend tuỳ phần review)

Agent chỉ đọc (code-reviewer, architect-reviewer, security-auditor) không ghi file
được — Claude chính ghi kết quả của họ vào hồ sơ.

Song song: các bước độc lập gửi trong cùng một lượt. Hai dev agent cùng chạy mà
có thể đụng cùng file → dùng `isolation: "worktree"` cho một bên, hoặc chạy tuần tự.

## 4. Hồ sơ bàn giao

`docs/team/<mã-việc>/`:

| File | Ai ghi |
|---|---|
| `00-plan.md` | Claude chính — kế hoạch đã duyệt, cập nhật trạng thái từng bước |
| `01-brief.md` | product-manager — vấn đề, giá trị, phạm vi MVP, tiêu chí thành công |
| `02-requirements.md` | business-analyst — quy trình, user story, tiêu chí nghiệm thu, câu hỏi mở |
| `03-design-ui.md` | ui-designer — luồng màn hình, trường, trạng thái |
| `03-design-tech.md` | backend-architect — entity, API, event, migration, ranh giới module |
| `04-implementation.md` | dev — file đã đổi, quyết định, việc còn lại |
| `05-tests.md` | test-automator — test đã viết, lệnh chạy, kết quả |
| `06-review.md` | các reviewer — kết luận, mục chặn, cần sửa |
| `07-qa.md` | qa-expert — đối chiếu tiêu chí nghiệm thu + DoD |

Mỗi file mở đầu:

```
# <NN> <Tên bước> — <mã-việc>
Agent: <tên> · Ngày: <YYYY-MM-DD> · Trạng thái: <xong | cần sửa | chặn>
Đầu vào: <file hồ sơ đã đọc>
```

Câu hỏi nghiệp vụ chưa rõ → đồng thời ghi vào `docs/open-questions.md` của dự án nếu có.

## 5. Vòng sửa

Review/QA có mục chặn → giao lại cho dev kèm `06-review.md`/`07-qa.md`, rồi review lại
đúng phần đó. Tối đa 2 vòng; quá thì dừng và hỏi người dùng.

## 6. Báo cáo cuối

Cho người dùng: đã làm gì (theo bước), file thay đổi, kết quả build/test thật,
mục còn mở, đường dẫn thư mục hồ sơ. Không commit, không push — để người dùng quyết.
