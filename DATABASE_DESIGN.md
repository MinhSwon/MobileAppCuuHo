# Thiết kế PostgreSQL cho RescueVN

## Mục tiêu

Database mới được thiết kế cho app cứu hộ hoạt động độc lập, không dùng chung mô hình dữ liệu cũ của bất kỳ web địa phương nào. Schema vẫn chuẩn bị sẵn để sau này mở thêm web toàn quốc hoặc portal tỉnh/thành mà không phải tách database lại từ đầu.

## Nguyên tắc chính

- Tách dữ liệu theo `app_projects`: mỗi app/web/portal là một project riêng.
- App hiện tại dùng project code `RESCUEVN_APP`.
- Web toàn quốc sau này có thể dùng project code mới, ví dụ `NATIONAL_WEB`.
- Không còn bảng nghiệp vụ tên `flood_alerts`; dùng `alerts` với `EmergencyType` để hỗ trợ y tế, cháy nổ, tai nạn, lũ, sạt lở, mất tích, sơ tán và các tình huống khác.
- Các bảng nghiệp vụ đều có `project_id` để tránh trộn dữ liệu giữa app độc lập và các web khác.

## Nhóm bảng chính

- `app_projects`: quản lý từng sản phẩm/tenant như app độc lập, web toàn quốc, web tỉnh.
- `administrative_units`: cây địa bàn toàn quốc, hỗ trợ quốc gia, vùng, tỉnh, huyện, xã/phường hoặc vùng tự định nghĩa.
- `users`, `citizen_profiles`: tài khoản và hồ sơ người dân.
- `rescue_teams`, `rescue_team_members`, `equipment_assets`: đội cứu hộ, thành viên và phương tiện/thiết bị.
- `rescue_requests`, `request_status_logs`: yêu cầu cứu hộ và lịch sử trạng thái.
- `rescue_missions`, `mission_status_logs`: nhiệm vụ điều phối thực địa và log di chuyển/xử lý.
- `alerts`, `alert_deliveries`, `sms_logs`: cảnh báo đa loại và lịch sử gửi SMS/push/email/in-app.
- `safe_zones`, `rescue_routes`: điểm an toàn và tuyến hỗ trợ.
- `damage_reports`, `vulnerable_households`: báo cáo thiệt hại và hộ ưu tiên.
- `notifications`, `activity_logs`, `audit_logs`: thông báo, nhật ký hoạt động và audit.

## File liên quan

- Prisma schema: `prisma/schema.prisma`
- Migration PostgreSQL: `prisma/migrations/20260608090000_rescuevn_postgres_schema/migration.sql`
- Triển khai schema: `npm run db:deploy` (dùng các migration trong `prisma/migrations/`)
- Seed dữ liệu mẫu: `scripts/seed-prisma.js`
- Backend Express: `server.js`

## Backend hiện tại

Khi `DATABASE_URL` được cấu hình, `server.js` dùng Prisma để đọc/ghi trực tiếp các bảng relational như `users`, `alerts`, `rescue_requests`, `rescue_missions`, `safe_zones`. Backend không còn tạo hoặc ghi bảng `app_state`.

Endpoint `/api/db` vẫn trả dữ liệu theo shape cũ cho frontend để tránh phải thay toàn bộ UI cùng lúc, nhưng nguồn dữ liệu bên dưới là PostgreSQL relational. Chế độ `db.json` chỉ còn là fallback phát triển khi bật `FORCE_JSON_DB=true` hoặc không cấu hình `DATABASE_URL`.

## Cách dựng database mới

Tạo database PostgreSQL mới, ví dụ `rescuevn_app`, rồi cấu hình:

```env
DATABASE_URL="postgresql://USER:PASSWORD@localhost:5432/rescuevn_app?schema=public"
```

Chạy:

```bash
npm run db:deploy
npm run db:generate
npm run db:seed
```

Nếu muốn reset database local:

```bash
npm run db:reset-local
```

## Ghi chú mở rộng web toàn quốc

Khi làm web toàn quốc, không cần dùng lại project `RESCUEVN_APP`. Tạo một dòng mới trong `app_projects` như:

```text
code = NATIONAL_WEB
type = NATIONAL_WEB
```

Sau đó toàn bộ dữ liệu users, alerts, requests, teams, safe zones của web toàn quốc sẽ gắn với `project_id` riêng. Cách này giúp app hiện tại độc lập nhưng vẫn có thể chia sẻ cùng một kiến trúc PostgreSQL nếu cần.
