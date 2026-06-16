# Huong dan sua doi app dua tren du an web tham chieu

Ngay tao: 15/06/2026

## 1. Pham vi so sanh

- App can hoan thien: `D:\HocKy_May2026\BT895_MobileApp\duancuuho`
- Web tham chieu: `D:\Do an 3 mon\duancuuho`

Muc tieu cua tai lieu nay la chi ra nhung phan nen lay tu du an web, nhung phan nen giu cua app mobile hien tai, va thu tu sua doi de tiep tuc hoan thien app ma khong lam hong cau truc da co.

## 2. Nhan xet tong quan

Hai du an cung nen tang React + Vite + Express + Prisma/PostgreSQL. Tuy nhien vai tro cua tung du an dang khac nhau:

- Du an app hien tai da co cau truc mobile/Capacitor, co thu muc `android`, `capacitor.config.json`, `public/manifest.webmanifest`, `public/sw.js`, script `android:sync`, `android:open`, va API client dung token Bearer phu hop voi ung dung native.
- Du an web tham chieu co trai nghiem nguoi dung day du hon: co `HomePage`, public data, offline queue, realtime EventSource, Firebase phone auth, SMS provider, load test script va mot so helper ban do/dieu phoi cuu ho.
- Schema Prisma cua app hien tai lon va chuan hoa hon web tham chieu. App co `AppProject`, `AdministrativeUnit`, `Alert`, `AlertDelivery`, `AuditLog`, `EquipmentAsset`, nhieu enum va quan he da duoc thiet ke cho nhieu kenh/mobile/web. Khong nen thay schema app bang schema web vi nhu vay se la ha cap.

Ket luan: nen lay cac phan trai nghiem, offline, realtime, SMS va tien ich tu web; giu lai schema database, cau truc mobile va co che Bearer token cua app.

## 3. Khac biet cau truc file quan trong

### 3.1 File chi co trong app hien tai

- `android/`: du an Android Capacitor.
- `capacitor.config.json`: cau hinh native app.
- `public/manifest.webmanifest`, `public/sw.js`: ho tro PWA/offline shell.
- `DATABASE_DESIGN.md`: tai lieu thiet ke CSDL cua app.
- `scripts/start-server.js`, `scripts/seed-if-empty.js`: script van hanh rieng cho app.
- `prisma/migrations/20260608090000_rescuevn_postgres_schema/migration.sql`: migration schema lon hon.

Can giu cac file nay.

### 3.2 File chi co trong web tham chieu

Nen xem de tich hop co chon loc:

- `src/pages/public/HomePage.jsx`
- `src/data/publicData.js`
- `src/lib/offlineQueue.js`
- `src/lib/firebase.js`
- `src/lib/firebasePhoneAuth.js`
- `src/components/common/OfflineStatusBanner.jsx`
- `src/components/common/EmergencyFallbackActions.jsx`
- `src/utils/haTinhMap.js`
- `src/utils/rescueCoordination.js`
- `src/utils/safeZones.js`
- `src/App.css`
- `src/assets/hero.png`
- `public/icons.svg`
- `scripts/loadtest-register.mjs`
- `scripts/loadtest-user-actions.mjs`

Khong nen copy may moc. Moi file can duoc ghep voi schema va API hien co cua app.

## 4. Huong sua doi uu tien

### Giai doan 1: Dong bo trai nghiem public va citizen

Muc tieu: app co man hinh dau vao ro rang, khong bi day thang den login khi mo `/`.

Viec nen lam:

1. Copy va dieu chinh `src/pages/public/HomePage.jsx` tu web sang app.
2. Copy cac phu thuoc can thiet cua HomePage:
   - `src/data/publicData.js`
   - `src/assets/hero.png`
   - neu HomePage dung CSS rieng thi can chon loc tu `src/App.css` hoac chuyen vao `src/index.css`.
3. Sua `src/App.jsx` cua app:
   - import `HomePage`;
   - doi route `/` tu `<RoleRedirect />` thanh `<HomePage />`;
   - giu route `/app` de dieu huong theo role sau khi dang nhap.
4. Kiem tra cac link trong HomePage:
   - `/login`
   - `/register`
   - `/sos`
   - `/app`

Ly do: ban web da co luong public tot hon. App mobile nen co landing/home nhe de nguoi dan thay nut SOS, canh bao, vung an toan truoc khi dang nhap.

### Giai doan 2: Tich hop offline queue cho mobile

Muc tieu: khi mat mang, nguoi dan van gui yeu cau cuu ho; doi cuu ho van cap nhat trang thai nhiem vu va dong bo lai khi co mang.

Viec nen lam:

1. Copy `src/lib/offlineQueue.js` tu web sang app.
2. Copy `src/components/common/OfflineStatusBanner.jsx`.
3. Copy `src/components/common/EmergencyFallbackActions.jsx`.
4. Sua `src/contexts/DataContext.jsx` cua app theo huong:
   - them state `isOnline`, `offlineQueueCount`, `offlineSyncing`;
   - them `syncOfflineQueue`;
   - khi `createRescueRequest` loi do mat mang, goi `enqueueOfflineAction('CREATE_RESCUE_REQUEST', data, ...)`;
   - khi `updateMissionStatus` loi do mat mang, goi `enqueueOfflineAction('UPDATE_MISSION_STATUS', payload, ...)`;
   - khi online tro lai, day hang doi len API.
5. Hien `OfflineStatusBanner` o layout hoac trong cac man hinh citizen/rescue quan trong.

Luu y rieng cho app mobile:

- Web tham chieu dung `navigator.onLine` va IndexedDB/local storage. Can test tren Capacitor Android vi hanh vi mang co the khac browser desktop.
- Khong nen dung offline fallback de cap nhat cac nghiep vu admin quan trong nhu phan cong doi cuu ho, xoa du lieu, sua khu an toan. Cac tac vu nay nen can server xac nhan.

### Giai doan 3: Realtime sync tu web, nhung giu Bearer token cua app

Web tham chieu co endpoint:

- `GET /api/events`
- phat su kien `db:update`

App hien tai chua co realtime endpoint nay trong `server.js`.

Viec nen lam:

1. Them endpoint SSE `/api/events` vao `server.js` cua app.
2. Sau moi API lam thay doi du lieu quan trong, goi ham broadcast state moi.
3. Sua `DataContext.jsx`:
   - tao `EventSource('/api/events')`;
   - khi nhan `db:update`, goi ham apply state tu backend;
   - dong ket noi khi logout/unmount.

Luu y bao mat:

- Web tham chieu dung cookie/session style (`withCredentials`), con app hien tai dung `Authorization: Bearer <token>`.
- `EventSource` truyen custom header khong tot. Neu giu Bearer token, can chon 1 trong 2 cach:
  - Cach A: SSE khong truyen du lieu nhay cam, chi bao "co cap nhat", app goi lai `/api/db` bang Bearer token.
  - Cach B: dung query token ngan han cho SSE, nhung can can than log URL.

Khuyen nghi: dung Cach A cho don gian va an toan hon trong giai doan hien tai.

### Giai doan 4: Dong bo API SMS va notification

Web tham chieu co them:

- `GET /api/notifications/provider-status`
- `POST /api/sms/send`
- `POST /api/notifications/esms-callback`
- ham `sendSmsNotification` trong `DataContext.jsx`

App hien tai chi co:

- `POST /api/sms-logs`
- `PUT /api/notifications/:id/read`

Viec nen lam:

1. Mang cac endpoint SMS tu web sang `server.js` cua app.
2. Dieu chinh mapping theo schema app hien tai:
   - web dung `FloodAlert`, app dung `Alert`;
   - web dung `SmsStatus`, app dung `DeliveryStatus`;
   - app co `AlertDelivery`, nen neu gui SMS tu canh bao, nen tao ca delivery log neu can.
3. Them `sendSmsNotification` vao `DataContext.jsx`.
4. Cap nhat `AlertsAndSMS.jsx` neu UI web co nut/gui SMS tot hon app.
5. Them bien moi truong vao `.env.example` cua app neu can:
   - API key nha cung cap SMS;
   - secret callback;
   - ten brandname hoac provider.

### Giai doan 5: Tich hop cac tien ich dieu phoi va ban do

Web co cac helper nen xem:

- `src/utils/haTinhMap.js`
- `src/utils/rescueCoordination.js`
- `src/utils/safeZones.js`

Viec nen lam:

1. Copy cac helper vao app neu cac man hinh admin/rescue dang can tinh khoang cach, chon doi gan nhat, goi y khu an toan.
2. Kiem tra man hinh:
   - `src/pages/admin/DispatchCenter.jsx`
   - `src/pages/admin/RescueRequests.jsx`
   - `src/pages/admin/RescueTeams.jsx`
   - `src/pages/rescue/MissionDetail.jsx`
   - `src/pages/citizen/CitizenSafeZones.jsx`
3. Neu app da co `src/utils/haversine.js`, tranh trung lap logic tinh khoang cach. Nen de `haversine.js` lam ham thap tang, cac file moi chi lam dieu phoi nghiep vu.

### Giai doan 6: Firebase phone auth

Web co:

- `src/lib/firebase.js`
- `src/lib/firebasePhoneAuth.js`
- dependency `firebase`

App hien tai chua co dependency `firebase`.

Viec nen lam sau, khong uu tien ngay:

1. Xac dinh co bat buoc OTP bang Firebase tren mobile hay khong.
2. Neu co, them dependency `firebase` vao `package.json`.
3. Copy va sua 2 file Firebase.
4. Them env:
   - `VITE_FIREBASE_API_KEY`
   - `VITE_FIREBASE_AUTH_DOMAIN`
   - `VITE_FIREBASE_PROJECT_ID`
   - cac bien Firebase khac neu file yeu cau.
5. Test ky tren Android, vi reCAPTCHA/phone auth co khac biet giua browser va native webview.

Khuyen nghi: hoan thien login/password + offline + SOS truoc, Firebase OTP lam sau.

## 5. Nhung phan khong nen copy nguyen tu web

### 5.1 `prisma/schema.prisma`

Khong thay schema app bang schema web. Schema app hien tai day du hon va phu hop mo hinh nhieu du an/nhieu cap hanh chinh.

Neu can lay logic tu web, hay mapping ten bang:

- Web `FloodAlert` -> App `Alert`
- Web `AlertLevel` -> App `RiskLevel`
- Web `SmsStatus` -> App `DeliveryStatus`
- Web `RescueTeam.latitude/longitude Float` -> App `Decimal`
- Web khong co `AppProject`; app can gan `projectId` cho cac ban ghi.

### 5.2 `src/lib/apiClient.js`

Khong copy nguyen file web sang app.

App hien tai dung:

- `VITE_API_BASE_URL`
- Bearer token trong `Authorization`
- can canh bao khi native build thieu API base URL

Day la huong phu hop hon cho Capacitor. Chi nen lay y tuong fallback production neu that su can deploy chung web.

### 5.3 `AuthContext.jsx`

Khong copy nguyen ban web, vi ban app hien tai da luu `authToken` va set header Authorization.

Co the bo sung logout goi server neu app them endpoint `/api/auth/logout`, nhung phai van xoa local token nhu hien tai.

## 6. Checklist sua file cu the

### Buoc 1: Public Home

- Tao/copy: `src/pages/public/HomePage.jsx`
- Tao/copy: `src/data/publicData.js`
- Tao/copy: `src/assets/hero.png`
- Sua: `src/App.jsx`
- Kiem thu: mo `/`, `/login`, `/register`, `/sos`, `/app`

### Buoc 2: Offline

- Tao/copy: `src/lib/offlineQueue.js`
- Tao/copy: `src/components/common/OfflineStatusBanner.jsx`
- Tao/copy: `src/components/common/EmergencyFallbackActions.jsx`
- Sua: `src/contexts/DataContext.jsx`
- Sua layout/page de hien banner
- Kiem thu: tat server/mat mang, gui SOS, bat lai server, dong bo lai

### Buoc 3: Server realtime

- Sua: `server.js`
- Them endpoint: `/api/events`
- Them broadcast sau cac route POST/PUT/DELETE quan trong
- Sua: `src/contexts/DataContext.jsx`
- Kiem thu: mo 2 tab, cap nhat o tab admin, tab rescue/citizen nhan state moi

### Buoc 4: SMS

- Sua: `server.js`
- Sua: `src/contexts/DataContext.jsx`
- Sua: `src/pages/admin/AlertsAndSMS.jsx`
- Sua: `.env.example`
- Kiem thu: provider-status, gui SMS test, callback neu co

### Buoc 5: Map/dieu phoi

- Tao/copy: `src/utils/haTinhMap.js`
- Tao/copy: `src/utils/rescueCoordination.js`
- Tao/copy: `src/utils/safeZones.js`
- Sua cac page dispatch/rescue/safe zones neu can
- Kiem thu: doi gan nhat, tinh khoang cach, khu an toan gan nhat

## 7. Thu tu uu tien de tranh loi lon

1. Them HomePage va public data.
2. Them offline queue cho `createRescueRequest`.
3. Them offline queue cho `updateMissionStatus`.
4. Them banner/offline fallback UI.
5. Them realtime SSE chi bao co update, app tu goi lai `/api/db`.
6. Them SMS provider.
7. Them helper dieu phoi/ban do.
8. Xem xet Firebase OTP.

## 8. Kiem thu sau moi dot sua

Lenh nen chay trong app:

```powershell
npm run lint
npm run build
```

Neu sua backend:

```powershell
npm run server
```

Neu sua native/mobile:

```powershell
npm run android:sync
```

Neu can mo Android Studio:

```powershell
npm run android:open
```

## 9. Rui ro can chu y

- Ma tieng Viet trong mot so file hien dang bi loi encoding o ca hai du an. Khi sua UI, nen chuan hoa file ve UTF-8.
- App dung Bearer token, web dung cookie/credential. Khong tron hai co che neu chua co ly do ro.
- Schema app co `projectId` bat buoc o nhieu bang; khi copy logic server tu web phai bo sung project hien hanh.
- Offline queue co the tao ban ghi tam thoi ID local. UI can hien ro trang thai "dang cho dong bo" de nguoi dung khong gui lap.
- SMS la tac vu co chi phi va phu thuoc nha cung cap. Can co che test/dry-run truoc khi gui that.

## 10. De xuat huong trien khai tiep theo

Nen bat dau bang Giai doan 1 va 2 vi tac dong truc tiep den app mobile:

- Dot 1: Them HomePage + offline queue gui yeu cau cuu ho.
- Dot 2: Offline update nhiem vu + banner/offline fallback.
- Dot 3: Realtime SSE + SMS.
- Dot 4: Dieu phoi thong minh, Firebase OTP, load test.

Huong nay giup app co trai nghiem gan voi web tham chieu nhung van giu duoc kien truc mobile va database manh hon cua app hien tai.
