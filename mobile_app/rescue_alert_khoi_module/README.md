# Rescue Alert Flutter - Module Nguyễn Nhật Khôi

Phạm vi theo tài liệu phân công:
- M2: Người dân - Gửi SOS và theo dõi trạng thái.
- Hỗ trợ M1: Authentication UI.
- Hỗ trợ M6: Citizen Alert List.

## Công nghệ
- Flutter + Dart
- Backend giả định: Node.js + Express
- ORM: Prisma
- Database: PostgreSQL
- JWT Authentication
- GPS: geolocator

## Endpoint backend cần có
- POST /api/auth/login
- POST /api/auth/register
- POST /api/rescue-requests
- GET /api/rescue-requests/my
- GET /api/rescue-requests/:id
- GET /api/alerts
- GET /api/alerts/:id

## Cách chạy
1. Copy thư mục này thành project Flutter hoặc copy phần `lib/` vào project nhóm.
2. Chạy `flutter pub get`.
3. Nếu backend chưa có, giữ `ApiConfig.useMock = true`.
4. Nếu backend đã chạy, đổi `ApiConfig.useMock = false` và chỉnh `baseUrl`.
5. Chạy `flutter run`.

## Ghi chú Android GPS
Cần thêm quyền trong `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```
