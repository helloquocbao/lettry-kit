# Quy tắc chung của hệ ứng dụng Lettry

Áp dụng cho mọi repo trong hệ: **Auth-center** (trung tâm xác thực, Magic ID),
**PropOS – CDE**, **HCG Report** và các ứng dụng thêm sau. `CLAUDE.md` của từng repo thắng
file này khi có xung đột.

## Bảng phân công agent

| Giai đoạn | Agent | Việc |
| --- | --- | --- |
| Ý tưởng | `product-manager` | Đánh giá giá trị, ưu tiên, phạm vi MVP, tiêu chí thành công |
| Yêu cầu | `business-analyst` | Quy trình nghiệp vụ, user story, tiêu chí nghiệm thu, câu hỏi mở |
| Thiết kế UI | `ui-designer` | Luồng màn hình, bố cục, trạng thái rỗng/lỗi, theo design system sẵn có |
| Thiết kế kỹ thuật | `backend-architect` | Entity, API, event, migration, ranh giới module |
| Code backend | `backend-developer` | Hiện thực API, domain, persistence |
| Code frontend | `frontend-developer` | Hiện thực màn hình, gọi API |
| Kế hoạch QA | `qa-expert` | Kịch bản test, đối chiếu tiêu chí nghiệm thu và Definition of Done |
| Viết test | `test-automator` | Unit / integration / e2e, chạy và báo kết quả |
| Review code | `code-reviewer` | Đúng sai, chất lượng, bảo trì (chỉ đọc) |
| Review kiến trúc | `architect-reviewer` | Tuân thủ kiến trúc và quy tắc bất biến của dự án (chỉ đọc) |
| Bảo mật | `security-auditor` | Xác thực, phân quyền, lộ dữ liệu (chỉ đọc) |
| Sửa lỗi | `debugger` | Tìm nguyên nhân gốc, sửa, thêm test tái hiện |
| Triển khai | `deployment-engineer` | Docker, CI/CD, migration lúc deploy, cấu hình môi trường |
| Tài liệu | `technical-writer` | Tài liệu API, hướng dẫn, cập nhật `docs/` |

## Luồng chuẩn

- **Ý tưởng mới**: product-manager → business-analyst → (ui-designer ∥ backend-architect)
  → *người dùng duyệt* → (backend-developer ∥ frontend-developer) → test-automator
  → (code-reviewer ∥ architect-reviewer ∥ qa-expert) → technical-writer
- **Tính năng đã rõ yêu cầu**: bắt đầu từ thiết kế kỹ thuật, bỏ qua product-manager.
- **Lỗi**: debugger → test-automator → code-reviewer
- **Review / audit**: code-reviewer ∥ architect-reviewer ∥ security-auditor
- **Triển khai**: deployment-engineer → qa-expert (smoke check)

Bỏ bớt bước khi việc nhỏ, nhưng nói rõ trong kế hoạch là bỏ bước nào và vì sao.

## Hai tầng phân quyền — không trộn

| Tầng | Ở đâu | Trả lời |
| --- | --- | --- |
| Trung tâm xác thực (Auth-center, Magic ID) | `ApplicationAccess`, claim `app` trong token | Ai **được mở** ứng dụng nào. Không gì hơn. |
| Từng ứng dụng (CDE, HCG Report…) | Vai trò, permission, phạm vi dữ liệu trong DB của app | Vào rồi thì **được làm gì, thấy gì** |

- Không đưa permission chi tiết của app vào token hay vào Auth-center; không để app tự
  quyết ai được mở nó (đó là việc của Auth-center).
- User nội bộ của app được tạo khi đăng nhập SSO lần đầu (`ExternalUserProvisioner`);
  màn quản trị của app chỉ gán vai trò và phạm vi, không tạo danh tính/mật khẩu.
- Câu chữ UI phải nói rõ tầng nào: Auth nói "được mở ứng dụng", app nói "được làm gì".

## Giao diện — quy chuẩn chung

- **Icon: CẤM `@ant-design/icons`. BẮT BUỘC Heroicons.**
  - React: `@heroicons/react` (ưu tiên `24/outline`), đi qua một chỗ tập trung
    `components/icons.tsx` với tên theo nghĩa của app (`IconApprovals`, `IconSearch`…); nơi khác
    chỉ import từ đó. Icon nội bộ của AntD thay qua prop hoặc `ConfigProvider` khi được; chỗ không
    thay được ghi là ngoại lệ trong báo cáo.
  - Razor/ABP (Auth-center, LeptonX Lite): SVG của Heroicons nhúng. Bootstrap Icons (`bi-*`) còn
    sót là nợ phải thay; không thêm chỗ mới.
  - Hook `quality-gate.sh` của plugin chặn agent kết thúc nếu file vừa sửa còn import
    `@ant-design/icons`. Mỗi repo React nên có test quét `src` để chặn tái phát.
- Tên thương hiệu khai báo một chỗ (`VITE_BRAND_NAME` ở React, `Brand:Name` ở Auth-center);
  không viết cứng tên vào code.

## Lưu ý về các agent

- Prompt agent lấy từ aitmpl.com (davila7/claude-code-templates), viết chung chung. Xung đột thì
  **kiến trúc của dự án thắng** (ví dụ CDE là modular monolith: không đề xuất microservices,
  Kafka hay tách database).
- Một số prompt nhắc "context-manager": không có agent đó; ngữ cảnh đến từ brief và `CLAUDE.md`.
- Agent review chỉ đọc. Muốn sửa theo review thì giao lại cho dev.
- Agent nghiệp vụ trả lời bằng tiếng Việt, giữ nguyên thuật ngữ kỹ thuật.
