# Auth Module Overview

Nguoi phu trach: `NHDK`

Phan nay gom 3 man hinh public cho Flutter mobile:

- `LoginScreen`: dang nhap bang email hoac so dien thoai, co demo account va nut mo nhanh dang ky / SOS.
- `RegisterScreen`: tao tai khoan nguoi dan, chon khu vuc, khai bao so nhan khau va ghi chu y te.
- `PublicAccessScreen`: dieu huong qua lai giua dang nhap, dang ky va SOS cong khai.

API lien quan:

- `POST /api/auth/login`
- `POST /api/auth/register`
- `GET /api/db`

Lenh chay local de test:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000
```
