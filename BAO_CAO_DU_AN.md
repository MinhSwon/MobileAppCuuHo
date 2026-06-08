# BÁO CÁO CHI TIẾT DỰ ÁN RESCUEVN

## 1. Tổng quan dự án

RescueVN là một hệ thống web hỗ trợ cảnh báo khẩn cấp, tiếp nhận yêu cầu cứu hộ, điều phối đội cứu hộ và quản lý thông tin an toàn cho người dân tại khu vực toàn quốc. Dự án được xây dựng theo hướng mô phỏng nghiệp vụ thực tế: người dân có thể đăng ký nhận cảnh báo, gửi yêu cầu cứu hộ hoặc SOS khẩn cấp; lực lượng cứu hộ có giao diện theo dõi nhiệm vụ; quản trị viên có trung tâm điều phối, bản đồ, báo cáo, SMS và các công cụ quản lý dữ liệu.

Ứng dụng gồm frontend React/Vite và backend Express.js dùng file `db.json` làm cơ sở dữ liệu cục bộ. Dự án cũng có một bộ dữ liệu mẫu trong `src/data/mockData.js`, giúp ứng dụng vẫn có thể chạy ở chế độ mô phỏng khi backend không hoạt động.

## 2. Mục tiêu và phạm vi

Mục tiêu chính của dự án là cung cấp một nền tảng quản lý thiên tai cấp địa phương, tập trung vào các nghiệp vụ:

- Cảnh báo khẩn cấp, triều cường, sạt lở và tình huống khẩn cấp.
- Tiếp nhận yêu cầu cứu hộ từ người dân, gồm yêu cầu thường và SOS nhanh.
- Phân công đội cứu hộ, theo dõi trạng thái nhiệm vụ và vị trí GPS.
- Quản lý điểm sơ tán, tuyến đường cứu hộ, đập/hồ chứa, hộ dễ tổn thương.
- Gửi và ghi nhận SMS cảnh báo.
- Thống kê, báo cáo, nhật ký hoạt động.
- Tìm kiếm ngữ nghĩa bằng vector đơn giản để hỗ trợ lọc yêu cầu, cảnh báo và điểm sơ tán.
- Trợ lý AI mô phỏng để tóm tắt tình hình và gợi ý xử lý.

Phạm vi hiện tại phù hợp với demo/đồ án: dữ liệu lưu local, xác thực đơn giản, SMS và AI là mô phỏng, chưa có tích hợp dịch vụ thật như SMS Gateway, hệ quản trị cơ sở dữ liệu, phân quyền bảo mật nâng cao hoặc realtime server.

## 3. Công nghệ sử dụng

Frontend:

- React 19.
- React Router DOM 7 để định tuyến.
- Vite 8 để phát triển và build.
- Tailwind CSS 4 kết hợp CSS custom trong `src/index.css`.
- Lucide React cho icon.
- React Leaflet và Leaflet cho bản đồ.
- Recharts cho biểu đồ thống kê.
- Axios để gọi API.

Backend:

- Node.js dạng ES Module.
- Express.js.
- CORS.
- File system Node.js để đọc/ghi `db.json`.
- Vector search tự viết trong `vectorDb.js`.

Dữ liệu:

- `src/data/mockData.js` là seed dữ liệu mẫu.
- `db.json` là file database runtime.

## 4. Cấu trúc thư mục

```text
duancuuho/
├── server.js                 Backend Express API
├── vectorDb.js               Bộ máy embedding và tìm kiếm vector đơn giản
├── db.json                   Cơ sở dữ liệu JSON cục bộ
├── package.json              Scripts và dependencies
├── vite.config.js            Cấu hình Vite, proxy API
├── src/
│   ├── App.jsx               Định tuyến toàn ứng dụng và bảo vệ route
│   ├── main.jsx              Entry point React
│   ├── index.css             Design system, layout, table, badge, modal, responsive
│   ├── contexts/
│   │   ├── AuthContext.jsx   Đăng nhập, đăng xuất, role hiện tại
│   │   ├── DataContext.jsx   State dữ liệu, gọi API, fallback offline
│   │   └── ToastContext.jsx  Hệ thống thông báo toast
│   ├── components/
│   │   ├── layout/           Sidebar, Header, Layout theo role
│   │   └── common/           StatusBadge và LevelBadge
│   ├── pages/
│   │   ├── public/           Home, Login, Register, SOS
│   │   ├── citizen/          Dashboard người dân, gửi cứu hộ, cảnh báo, điểm sơ tán
│   │   ├── rescue/           Dashboard và chi tiết nhiệm vụ cứu hộ
│   │   └── admin/            Dashboard, điều phối, cảnh báo, SMS, báo cáo, quản trị dữ liệu
│   ├── data/mockData.js      Dữ liệu mẫu
│   └── utils/haversine.js    Tính khoảng cách GPS/geofence
└── public/                   Icon, favicon
```

## 5. Kiến trúc tổng thể

Dự án đang dùng kiến trúc client-server đơn giản:

```text
React UI
  |
  | axios /api/*
  v
Vite dev proxy
  |
  v
Express server.js
  |
  | đọc/ghi
  v
db.json

Fallback:
React DataContext dùng mockData nếu backend không phản hồi.
```

Điểm đáng chú ý là `DataContext` đóng vai trò trung tâm dữ liệu của frontend. Khi ứng dụng khởi động, context gọi `GET /api/db` để đồng bộ toàn bộ database. Nếu backend lỗi hoặc không chạy, ứng dụng dùng dữ liệu seed từ `mockData.js` và các thao tác CRUD chỉ cập nhật state trong trình duyệt.

## 6. Vai trò người dùng và phân quyền route

Ứng dụng chia người dùng theo 3 nhóm chính:

1. Admin/Super Admin:
   - Truy cập `/admin`.
   - Quản lý cảnh báo, yêu cầu cứu hộ, nhiệm vụ, đội cứu hộ, SMS, người dân, hộ dễ tổn thương, điểm sơ tán, tuyến đường, đập/hồ chứa, báo cáo và nhật ký.

2. Đội cứu hộ:
   - Truy cập `/rescue`.
   - Xem dashboard cứu hộ, nhận và cập nhật nhiệm vụ, bật GPS tracking, xác nhận tiếp cận nạn nhân, báo cứu thành công hoặc yêu cầu hỗ trợ.

3. Người dân:
   - Truy cập `/citizen`.
   - Xem cảnh báo, điểm sơ tán, dashboard cá nhân và gửi yêu cầu cứu hộ.

Các route được bảo vệ bằng component `RequireAuth` trong `src/App.jsx`. Nếu chưa đăng nhập, người dùng bị chuyển về `/login`. Nếu role không hợp lệ, ứng dụng chuyển về `/`.

## 7. Backend API

Backend nằm trong `server.js`, lắng nghe mặc định cổng `5000`. Các API chính:

### 7.1 Đồng bộ database

- `GET /api/db`: trả toàn bộ trạng thái database.

### 7.2 Xác thực

- `POST /api/auth/login`: đăng nhập bằng email hoặc số điện thoại và mật khẩu.

Hiện tại mật khẩu được so sánh trực tiếp với `password_hash` trong dữ liệu. Đây là cách phù hợp cho demo nhưng không an toàn cho production.

### 7.3 Tìm kiếm ngữ nghĩa

- `GET /api/search?q=...&type=requests`
- `GET /api/search?q=...&type=warnings`
- `GET /api/search?q=...&type=safezones`

API dùng `vectorDb.js` để tạo vector 8 chiều và sắp xếp kết quả theo cosine similarity.

### 7.4 Cảnh báo

- `POST /api/warnings`
- `PUT /api/warnings/:id`
- `DELETE /api/warnings/:id`

Khi tạo hoặc sửa cảnh báo, backend tạo lại `vector_embedding` dựa trên tiêu đề, nội dung và khu vực.

### 7.5 Yêu cầu cứu hộ và phân công

- `POST /api/rescue-requests`
- `PUT /api/rescue-requests/:id`
- `POST /api/rescue-requests/:id/assign`

Khi admin phân công một yêu cầu cho đội cứu hộ, backend:

- Cập nhật request sang `ASSIGNED`.
- Tạo một rescue mission tương ứng.
- Ghi activity log.
- Tạo notification cho đội cứu hộ.

### 7.6 Nhiệm vụ cứu hộ

- `POST /api/missions/:id/status`

API này cập nhật trạng thái nhiệm vụ, ghi log trạng thái và đồng bộ trạng thái ngược lại cho rescue request.

### 7.7 Quản lý dữ liệu phụ trợ

- Đội cứu hộ: `POST/PUT/DELETE /api/teams`.
- Điểm sơ tán: `POST/PUT/DELETE /api/safe-zones`.
- Tuyến đường: `POST/PUT/DELETE /api/routes`.
- Báo cáo thiệt hại: `POST /api/damage-reports`.
- Hộ dễ tổn thương: `POST/PUT /api/vulnerable-households`.
- SMS logs: `POST /api/sms-logs`.
- Notification read: `PUT /api/notifications/:id/read`.

## 8. Dữ liệu hiện có

Theo `db.json`, dữ liệu hiện tại gồm:

| Bảng dữ liệu | Số lượng |
|---|---:|
| areas | 4 |
| users | 9 |
| citizenProfiles | 5 |
| vulnerableHouseholds | 4 |
| floodWarnings | 5 |
| rescueRequests | 6 |
| rescueMissions | 3 |
| missionStatusLogs | 5 |
| rescueTeams | 5 |
| safeZones | 5 |
| rescueRoutes | 4 |
| dams | 2 |
| smsLogs | 5 |
| damageReports | 3 |
| activityLogs | 6 |
| notifications | 3 |

Các nhóm dữ liệu chính trong `mockData.js` gồm khu vực hành chính, tài khoản demo, hồ sơ công dân, hộ dễ tổn thương, đội cứu hộ, cảnh báo khẩn cấp, yêu cầu cứu hộ, nhiệm vụ cứu hộ, điểm sơ tán, tuyến cứu hộ, đập/hồ chứa, SMS, báo cáo thiệt hại, nhật ký hoạt động và thông báo.

## 9. Các phân hệ chức năng

### 9.1 Trang công khai

Nhóm public gồm:

- Trang chủ: giới thiệu hệ thống, cảnh báo đang hoạt động, điểm sơ tán, tình hình cứu hộ.
- Đăng nhập: có tài khoản demo cho admin, đội cứu hộ và người dân.
- Đăng ký: tạo tài khoản người dân và hồ sơ hộ gia đình.
- SOS: luồng gửi cứu hộ khẩn cấp không cần đăng nhập.

Trang SOS là một điểm nổi bật. Luồng gồm chọn loại tình huống, nhập số điện thoại, lấy GPS hoặc chọn khu vực thủ công, đếm ngược 3 giây, rồi tạo rescue request với `sos_mode: true` và mức `EMERGENCY`.

### 9.2 Cổng người dân

Người dân có các chức năng:

- Dashboard cá nhân hiển thị cảnh báo, yêu cầu đã gửi, điểm sơ tán.
- Gửi yêu cầu cứu hộ với mức độ khẩn cấp, thông tin người cần cứu, địa chỉ, GPS, số người, các đặc điểm ưu tiên như người già, trẻ em, khuyết tật, bệnh nhân, cần lương thực.
- Xem danh sách cảnh báo khẩn cấp.
- Xem điểm sơ tán.

Form cứu hộ có tích hợp `navigator.geolocation` để lấy tọa độ, giúp đội cứu hộ xác định vị trí nhanh hơn.

### 9.3 Cổng đội cứu hộ

Đội cứu hộ có:

- Dashboard cứu hộ: tổng quan nhiệm vụ và cảnh báo.
- Màn hình nhiệm vụ: xem nhiệm vụ được giao, thông tin nạn nhân, số điện thoại, địa chỉ, đặc điểm ưu tiên.
- Bản đồ Leaflet hiển thị vị trí nạn nhân, vị trí đội cứu hộ và vùng geofence.
- GPS tracking bằng `navigator.geolocation.watchPosition`.
- Mô phỏng vị trí gần nạn nhân để demo.
- Cập nhật trạng thái nhiệm vụ theo luồng: `ASSIGNED -> ACCEPTED -> MOVING -> ARRIVED_CONFIRMED -> RESCUING -> RESCUED`.
- Báo không liên lạc được hoặc cần hỗ trợ thêm.

Điểm quan trọng là hệ thống có logic geofence: nếu đội cứu hộ nằm trong bán kính 100m quanh nạn nhân, ứng dụng có thể xác nhận trạng thái `NEAR_VICTIM`.

### 9.4 Cổng quản trị

Admin là phân hệ lớn nhất, gồm:

- Dashboard tổng quan: thống kê người dân, hộ dễ tổn thương, đội cứu hộ, cảnh báo, yêu cầu chờ xử lý, SMS, biểu đồ theo ngày và theo khu vực.
- Trung tâm điều phối: bản đồ nhiệm vụ, điểm sơ tán, vị trí đội cứu hộ, geofence, mô phỏng cập nhật GPS và cảnh báo nhiệm vụ cần hỗ trợ.
- Quản lý yêu cầu cứu hộ: lọc theo khu vực, mức độ, trạng thái, SOS; xem chi tiết; phân công đội; hủy yêu cầu.
- Tìm kiếm ngữ nghĩa AI Vector trong yêu cầu cứu hộ.
- Quản lý nhiệm vụ cứu hộ và lịch sử trạng thái.
- Quản lý đội cứu hộ.
- Quản lý điểm sơ tán.
- Quản lý tuyến đường cứu hộ.
- Quản lý cảnh báo và SMS.
- Quản lý người dân, hộ dễ tổn thương.
- Quản lý đập/hồ chứa.
- Quản lý báo cáo thiệt hại.
- Báo cáo thống kê bằng Recharts.
- Nhật ký hoạt động.
- Trợ lý AI mô phỏng.
- Cài đặt tài khoản.

## 10. Luồng nghiệp vụ cứu hộ

Luồng chính của hệ thống:

1. Người dân gửi yêu cầu cứu hộ hoặc SOS.
2. Request được lưu với trạng thái `PENDING`.
3. Admin xem danh sách yêu cầu, lọc theo mức khẩn cấp/SOS/khu vực.
4. Admin phân công một đội cứu hộ sẵn sàng.
5. Backend tạo rescue mission và cập nhật request sang `ASSIGNED`.
6. Đội cứu hộ đăng nhập, nhận nhiệm vụ.
7. Đội cứu hộ cập nhật trạng thái di chuyển và bật GPS.
8. Khi vào vùng gần nạn nhân, hệ thống có thể ghi nhận `NEAR_VICTIM`.
9. Đội cứu hộ xác nhận tiếp cận, cứu hộ, hoàn thành hoặc báo lỗi/cần hỗ trợ.
10. Admin theo dõi toàn bộ trên trung tâm điều phối và báo cáo.

Các trạng thái chính:

- `PENDING`: chờ tiếp nhận.
- `ASSIGNED`: đã phân công.
- `ACCEPTED`: đội đã nhận.
- `MOVING`: đang di chuyển.
- `NEAR_VICTIM`: đã đến gần.
- `ARRIVED_CONFIRMED`: đã tiếp cận.
- `RESCUING`: đang cứu hộ.
- `RESCUED`: cứu thành công.
- `TRANSFERRED_SAFEZONE`: đã đưa đến nơi an toàn.
- `UNREACHABLE`: không liên lạc được.
- `NEED_SUPPORT`: cần hỗ trợ thêm.
- `CANCELLED`: đã hủy.

## 11. Tìm kiếm vector và trợ lý AI

### 11.1 Vector search

File `vectorDb.js` triển khai một hệ embedding thủ công 8 chiều:

1. Nhu cầu cứu hộ vật lý.
2. Lương thực/nước uống.
3. Y tế.
4. Ngập lụt/môi trường nước.
5. Sạt lở.
6. Hạ tầng an toàn/điểm sơ tán.
7. Mức cảnh báo/khẩn cấp.
8. Nhóm dễ tổn thương như người già, trẻ em, phụ nữ mang thai.

Hệ thống token hóa câu, ánh xạ từ khóa tiếng Việt có dấu/không dấu sang vector, lấy trung bình, chuẩn hóa L2 và tính cosine similarity. Đây là cách đơn giản nhưng phù hợp để minh họa tìm kiếm ngữ nghĩa trong đồ án.

Hạn chế: do dictionary thủ công, chất lượng tìm kiếm phụ thuộc vào danh sách từ khóa. Một số chữ tiếng Việt trong file đang bị lỗi encoding, có thể ảnh hưởng trực tiếp đến khả năng match từ có dấu.

### 11.2 AI Assistant

Trang `AIAssistant.jsx` là trợ lý mô phỏng, không gọi API AI thật. Nó phân tích câu hỏi bằng keyword và trả lời theo các nhóm:

- Tóm tắt tình hình.
- Khu vực nguy cơ cao.
- Đội cứu hộ sẵn sàng.
- Gợi ý nội dung SMS.
- Phân tích thống kê.
- Tình trạng điểm sơ tán.

Đây là chức năng tốt cho demo, nhưng nếu triển khai thật cần kết nối model AI hoặc service backend có kiểm soát quyền truy cập dữ liệu.

## 12. Giao diện và trải nghiệm người dùng

Dự án có design system khá rõ trong `src/index.css`:

- Tông màu ấm, nghiêm túc, phù hợp bối cảnh điều phối.
- Sidebar theo từng vai trò.
- Header sticky.
- Card, bảng, modal, toast, badge trạng thái, filter bar dùng chung.
- Responsive cơ bản cho mobile: sidebar chuyển sang off-canvas khi màn hình nhỏ.
- Bản đồ Leaflet được dùng trong admin và rescue.
- Biểu đồ Recharts trong dashboard và báo cáo.

Giao diện có nhiều chi tiết nghiệp vụ như badge SOS, geofence, notification, trạng thái nhiệm vụ và thống kê, giúp dự án có chiều sâu hơn một CRUD thông thường.

## 13. Điểm mạnh của dự án

- Phân hệ nghiệp vụ đầy đủ: public, citizen, rescue, admin.
- Có luồng cứu hộ end-to-end từ gửi yêu cầu đến phân công, di chuyển, xác nhận và hoàn thành.
- Có bản đồ, GPS và geofence, phù hợp bài toán cứu hộ thực địa.
- Có mô phỏng SMS, notification, activity log và báo cáo.
- Có dữ liệu mẫu phong phú, đủ để demo.
- Có backend local giúp dữ liệu tồn tại qua reload nhờ `db.json`.
- Có fallback offline ở frontend, tăng khả năng demo khi server chưa chạy.
- Có tìm kiếm vector tự viết, tạo điểm nhấn kỹ thuật cho đồ án.

## 14. Hạn chế và rủi ro

### 14.1 Bảo mật

- Mật khẩu đang lưu và so sánh dạng plain text.
- Không có JWT/session/token.
- Không có middleware xác thực API ở backend.
- Frontend bảo vệ route nhưng backend không kiểm tra role.
- API có thể bị gọi trực tiếp nếu biết endpoint.

Khuyến nghị: dùng bcrypt để hash mật khẩu, JWT hoặc session, middleware xác thực và phân quyền theo role.

### 14.2 Lưu trữ dữ liệu

- `db.json` không phù hợp cho nhiều người dùng đồng thời.
- Ghi file bằng `fs.writeFileSync` có thể gây race condition nếu nhiều request cùng lúc.
- Không có transaction, backup, migration hoặc validate schema.

Khuyến nghị: chuyển sang PostgreSQL/MySQL/MongoDB hoặc SQLite nếu vẫn muốn gọn nhẹ.

### 14.3 Encoding tiếng Việt

Một số file hiển thị lỗi mã hóa như `HÆ°Æ¡ng KhĂª`, `ÄÄƒng nháº­p`, `PhĂ¢n cĂ´ng`. Điều này ảnh hưởng đến giao diện, báo cáo và vector search tiếng Việt có dấu.

Khuyến nghị: chuẩn hóa toàn bộ source về UTF-8, kiểm tra editor encoding và sửa các chuỗi bị mojibake.

### 14.4 Tích hợp thật

- SMS chỉ được ghi log, chưa gửi qua SMS Gateway.
- AI Assistant là keyword-based, chưa phải AI thật.
- GPS tracking chỉ nằm phía client, chưa realtime stream về backend.
- Bản đồ dùng OpenStreetMap tile public, cần cân nhắc giới hạn sử dụng nếu production.

### 14.5 Kiểm thử

- Chưa thấy test unit/integration/e2e.
- Chưa có validation chặt ở backend.
- Một số chức năng export PDF/Excel mới là alert placeholder.

Khuyến nghị: bổ sung test cho API, DataContext, luồng phân công, cập nhật mission status và geofence.

## 15. Hướng dẫn chạy dự án

Cài dependencies:

```bash
npm install
```

Chạy backend:

```bash
npm run server
```

Chạy frontend:

```bash
npm run dev
```

Build production:

```bash
npm run build
```

Do `vite.config.js` đã cấu hình proxy `/api` sang `http://localhost:5000`, khi chạy dev server frontend có thể gọi API backend bằng đường dẫn `/api/...`.

## 16. Tài khoản demo

Trong màn hình đăng nhập có 3 nhóm tài khoản demo:

| Vai trò | Email | Mật khẩu |
|---|---|---|
| Admin / Điều phối viên | `admin@floodguard.vn` | `admin123` |
| Đội cứu hộ | `doicuuho1@floodguard.vn` | `rescue123` |
| Người dân | `nguoidan1@gmail.com` | `citizen123` |

## 17. Đề xuất phát triển tiếp

Ưu tiên cao:

1. Sửa lỗi encoding tiếng Việt trong toàn bộ source.
2. Bổ sung xác thực backend bằng JWT/session.
3. Hash mật khẩu bằng bcrypt.
4. Chuyển `db.json` sang database thật.
5. Thêm validate dữ liệu request bằng schema.
6. Đồng bộ trạng thái đội cứu hộ khi nhận nhiệm vụ hoặc hoàn thành nhiệm vụ.

Ưu tiên trung bình:

1. Tích hợp SMS Gateway thật.
2. Tích hợp realtime bằng WebSocket/SSE cho bản đồ điều phối.
3. Lưu lịch sử GPS của đội cứu hộ.
4. Thêm export PDF/Excel thật.
5. Tích hợp AI thật cho trợ lý và tìm kiếm.
6. Thêm audit log đầy đủ cho mọi thao tác quan trọng.

Ưu tiên giao diện:

1. Chuẩn hóa responsive cho các màn hình bảng lớn.
2. Tối ưu mobile cho dashboard và bản đồ.
3. Tách các inline style lớn thành component/CSS module để dễ bảo trì.
4. Chuẩn hóa copywriting tiếng Việt sau khi sửa encoding.

## 18. Kết luận

RescueVN là một dự án đồ án có phạm vi tốt và có tính ứng dụng rõ ràng. Điểm mạnh nhất của dự án là mô phỏng được toàn bộ quy trình cứu hộ thiên tai: cảnh báo, tiếp nhận yêu cầu, phân công đội, theo dõi bản đồ/GPS, cập nhật trạng thái, báo cáo và thống kê. So với một ứng dụng quản lý thông thường, dự án có thêm các yếu tố kỹ thuật đáng chú ý như Leaflet map, geofence, vector search, SMS log và AI assistant mô phỏng.

Tuy nhiên, dự án hiện vẫn ở mức demo/prototype. Nếu muốn nâng cấp lên mức sử dụng thực tế, cần ưu tiên bảo mật, cơ sở dữ liệu thật, realtime tracking, tích hợp SMS thật, xử lý encoding và bổ sung kiểm thử. Với các cải tiến đó, hệ thống có thể trở thành một nền tảng điều phối cứu hộ địa phương hoàn chỉnh hơn.
