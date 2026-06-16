# Rescue Management System

Ứng dụng di động quản lý cảnh báo và cứu hộ trong các tình huống khẩn cấp.

## Mô tả dự án

Rescue Management System là hệ thống hỗ trợ người dân gửi yêu cầu cứu hộ (SOS), nhận cảnh báo nguy hiểm và theo dõi quá trình xử lý cứu hộ theo thời gian thực.

Hệ thống gồm ba nhóm người dùng:

* Người dân
* Đội cứu hộ
* Quản trị viên

## Tính năng chính

### Người dân

* Đăng ký và đăng nhập
* Gửi yêu cầu SOS khẩn cấp
* Chia sẻ vị trí GPS
* Theo dõi trạng thái cứu hộ
* Nhận cảnh báo theo khu vực
* Xem hướng dẫn an toàn

### Đội cứu hộ

* Nhận nhiệm vụ cứu hộ
* Xem vị trí nạn nhân trên bản đồ
* Cập nhật trạng thái nhiệm vụ
* Gửi báo cáo hiện trường
* Chia sẻ vị trí thời gian thực

### Quản trị viên

* Quản lý người dùng
* Quản lý yêu cầu cứu hộ
* Phân công đội cứu hộ
* Tạo cảnh báo khẩn cấp
* Theo dõi bản đồ điều phối
* Xem thống kê và báo cáo

## Công nghệ sử dụng

### Mobile

* Flutter
* Dart
* Riverpod
* Google Maps API
* Firebase Cloud Messaging

### Backend

* Node.js
* Express.js
* Prisma ORM
* PostgreSQL
* Socket.IO
* JWT Authentication

## Kiến trúc hệ thống

```text
Flutter App
      ↓
REST API + Socket.IO
      ↓
Express Server
      ↓
Prisma ORM
      ↓
PostgreSQL
```

## Cấu trúc thư mục

```text
rescue-management-system/
│
├── mobile_app/
├── backend/
├── database/
├── docs/
└── README.md
```

## Cài đặt dự án

### Clone repository

```bash
git clone <repository-url>
cd rescue-management-system
```

### Mobile App

```bash
cd mobile_app
flutter pub get
flutter run
```

### Backend

```bash
cd backend
npm install
npm run dev
```

## Biến môi trường

Tạo file `.env` trong thư mục `backend`:

```env
DATABASE_URL=
JWT_SECRET=
PORT=3000
```

## Database Migration

```bash
npx prisma migrate dev --name init
```

Khởi tạo Prisma Client:

```bash
npx prisma generate
```

Mở Prisma Studio:

```bash
npx prisma studio
```

## Trạng thái dự án

Dự án hiện đang trong giai đoạn phát triển.

## Giấy phép

Dự án được phát triển phục vụ mục đích học tập và nghiên cứu.
