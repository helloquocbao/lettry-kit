# Hướng dẫn cho người mới: clone và dev hệ Lettry

Hệ gồm 3 repo độc lập, cùng đăng nhập qua một trung tâm xác thực:

| Repo | Thư mục khi clone | Làm gì | Local |
| --- | --- | --- | --- |
| [magic-authen](https://github.com/helloquocbao/magic-authen) | `Auth-center` | Trung tâm xác thực (HCG ID): ai **được mở** ứng dụng nào | https://localhost:44303 · SQL 1434 |
| [props-os](https://github.com/helloquocbao/props-os) | `Propos-cde` | PropOS – CDE: dữ liệu dự án bất động sản phía Chủ đầu tư | API https://localhost:44307 · web http://localhost:5174 · SQL 1435 |
| [hcg-report](https://github.com/helloquocbao/hcg-report) | `HCG-Report` | HCG Report: báo cáo tài chính (sổ 111/112, dòng tiền, khoá kỳ) | API https://localhost:44309 · web http://localhost:5177 · SQL 1437 |
| [lettry-kit](https://github.com/helloquocbao/lettry-kit) | (không cần clone) | Plugin Claude Code: 14 agent, skill `/team`, hook | — |

Bức tranh đầy đủ (luồng đăng nhập, client, scope, hai tầng phân quyền): `docs/ecosystem.md` trong repo bất kỳ.

---

## 0. Trước khi bắt đầu (trưởng nhóm làm)

- [ ] Mời người mới làm collaborator của 4 repo trên GitHub (repo private thì bắt buộc, kể cả `lettry-kit`).
- [ ] Người mới gửi SSH public key của họ lên GitHub (Settings → SSH and GPG keys).

## 1. Cài công cụ

| Công cụ | Phiên bản | Ghi chú |
| --- | --- | --- |
| Git, SSH key đã thêm vào GitHub | | `ssh -T git@github.com` phải chào đúng tên tài khoản |
| Docker Desktop | mới | Mỗi repo tự dựng SQL Server 2022 riêng |
| .NET SDK | 10 | `dotnet --version` |
| Node.js | 20.11+ | `node --version` |
| ABP CLI | 10.x | `dotnet tool install -g Volo.Abp.Studio.Cli`, dùng cho `abp install-libs` |
| `jq` | | Hook của plugin cần (`brew install jq`) |
| Claude Code | mới | Desktop app hoặc CLI |

Máy có nhiều tài khoản GitHub: dùng alias trong `~/.ssh/config` và thay `github.com` trong URL clone bằng alias đó.

## 2. Clone

Clone **cạnh nhau trong cùng một thư mục cha** và **đặt đúng tên thư mục** như dưới: vài test của ứng
dụng con đọc `../Auth-center/docs/contracts/application-icon-names.json`.

```bash
mkdir lettry && cd lettry
git clone git@github.com:helloquocbao/magic-authen.git Auth-center
git clone git@github.com:helloquocbao/props-os.git Propos-cde
git clone git@github.com:helloquocbao/hcg-report.git HCG-Report
```

## 3. Cài bộ agent (Claude Code)

Mở Claude Code trong một repo bất kỳ, chọn tin cậy thư mục, rồi:

```
/plugin marketplace add helloquocbao/lettry-kit
/plugin install lettry-team@lettry-kit
```

Mỗi repo đã khai báo plugin trong `.claude/settings.json`, nên Claude Code thường tự gợi ý cài.
Cập nhật về sau: `/plugin marketplace update lettry-kit`.

Kiểm: gõ `/team` thấy skill; `/agents` thấy các agent `lettry-team:*`.

## 4. Chạy local

Luôn chạy **Auth-center trước**: thiếu nó thì không ứng dụng nào đăng nhập được.
`dotnet run` phải chạy **từ trong thư mục project** (ABP đọc `appsettings.json` theo thư mục làm việc).
Web/API và `npm run dev` chạy liên tục: mỗi cái một terminal riêng.

### 4.1 Auth-center (https://localhost:44303)

```bash
cd Auth-center
docker compose up -d
(cd src/MagicAuth.Web && abp install-libs)   # chỉ lần đầu; thiếu thì trang chủ báo 500
cd src/MagicAuth.DbMigrator && DOTNET_ENVIRONMENT=Development dotnet run
cd ../MagicAuth.Web && ASPNETCORE_ENVIRONMENT=Development dotnet run --no-launch-profile --urls "https://localhost:44303"
```

Đăng nhập `admin`. Mật khẩu dev: README của Auth-center, mục "Chạy trong 5 phút" (DbMigrator ở
Development đặt cùng một mật khẩu dev cho mọi user trong DB local).

Cấp quyền mở ứng dụng cho tài khoản sẽ dùng: **Người dùng → chi tiết → Ứng dụng được mở** → tick
`propos-cde`, `hcg-report` → Lưu.

### 4.2 HCG Report (web http://localhost:5177)

```bash
cd HCG-Report
docker compose up -d
cd aspnet-core/src/HCGReport.DbMigrator && dotnet run      # tạo DB, migration, seed danh mục + dữ liệu mẫu dev
cd ../HCGReport.HttpApi.Host && dotnet run                 # https://localhost:44309, kiểm /health/ready = 200
```

```bash
cd HCG-Report/react && npm install && npm run dev
```

- Đăng nhập bằng `admin` của Auth-center: ở máy dev được khớp vào user `admin` đã seed, thấy đủ mọi màn.
- User dev khác: `dev.ketoan.h`, `dev.ketoan.k`, `dev.taichinh`, `dev.bod`, `dev.it` — tạo cùng tên ở Auth-center
  và cấp quyền mở `hcg-report` thì lần đăng nhập đầu sẽ nhận vai trò đã seed.
- Chạy lại DbMigrator thì khởi động lại API (cache permission trong bộ nhớ).
- Chỉ làm giao diện, không cần Auth-center/API: `npm run dev:mocks`.
- File mẫu để thử import sổ 111/112: `docs/samples/import/` (công ty H01, kỳ T09).

### 4.3 PropOS – CDE (web http://localhost:5174)

```bash
cd Propos-cde
docker compose up -d mssql
(cd src/ProposCde.HttpApi.Host && abp install-libs)   # chỉ lần đầu
cd src/ProposCde.DbMigrator && dotnet run                  # schema + cấu hình hệ thống
dotnet run --no-build -- import-hcg --file ../../docs/HCG_QuanLyDuAn_data.json --grant-scope admin
cd ../ProposCde.HttpApi.Host && ASPNETCORE_ENVIRONMENT=Development dotnet run --no-launch-profile --urls "https://localhost:44307"
```

```bash
cd Propos-cde/react && npm install && npm run dev
```

- `import-hcg` nạp dữ liệu nghiệp vụ (khu đô thị, căn, pháp lý, GPMB, tiến độ); chạy lại được.
  `--grant-scope` cấp phạm vi cho các user liệt kê (cách nhau dấu phẩy).
- Swagger: https://localhost:44307/swagger → **Authorize**, scope `ProposCde`.

### Khi gặp lỗi

| Hiện tượng | Nguyên nhân thường gặp |
| --- | --- |
| Đăng nhập báo `invalid_scope` | SPA xin scope (vd. `MagicAuth.Launchpad`) mà Auth-center chưa có: chạy lại DbMigrator của Auth-center rồi khởi động lại Web |
| Đăng nhập xong báo không được mở ứng dụng (403) | Chưa tick ứng dụng ở **Ứng dụng được mở** cho tài khoản đó |
| Trang Auth-center 500 | Chưa `abp install-libs` |
| API không đọc cấu hình dev | Chạy `dotnet run` ngoài thư mục project, hoặc thiếu `ASPNETCORE_ENVIRONMENT=Development` |
| Cổng SQL bị chiếm | Container cũ cùng cổng: `docker ps -a` xem, dừng cái không dùng |

## 5. Làm việc hằng ngày

1. Đọc `CLAUDE.md` của repo đang làm (đủ quy tắc, không phụ thuộc gì bên ngoài) và `docs/ecosystem.md`.
   Tool khác Claude Code (Cursor, Codex…) đọc `AGENTS.md`.
2. Việc nhiều bước: gõ `/team <mô tả việc>`. Claude chính phân loại, trình kế hoạch, **chờ bạn duyệt**, rồi giao
   agent (thiết kế → code → test → review), lưu hồ sơ ở `docs/team/<YYYYMMDD-slug>/`.
3. Kiến thức theo vai trò nằm ở `.claude/skills/` của từng repo (`auth-*`, `hcg-*`, `propos-*`).
4. Hook tự chặn `git push`, `git reset --hard`, `git clean -f`, `rm -rf`, drop database; khi agent kết thúc, hook
   build/typecheck phần vừa sửa và chặn `@ant-design/icons`. **Commit/push do người làm tự chạy.**
5. Trước khi push: chạy test theo skill `*-dod` của repo (BE `dotnet test`, FE `npm run lint && npm run build && npm test`).

## 6. Quy tắc phải nhớ

- **Hai tầng phân quyền**: Auth-center chỉ quyết ai **được mở** ứng dụng (claim `app` trong token); vai trò,
  permission, phạm vi dữ liệu nằm trong DB của từng ứng dụng. Không đưa permission của app vào token.
- **Icon**: chỉ Heroicons, qua `src/components/icons.tsx`; cấm `@ant-design/icons`.
- **Tên thương hiệu**: `VITE_BRAND_NAME` / `Brand:Name`, không viết cứng.
- **Migration mới** phải được người phụ trách duyệt trước khi tạo.
- **Không commit** `.env.local`, `*.secrets.json`, chứng chỉ `.pfx`, dữ liệu thật của khách.
