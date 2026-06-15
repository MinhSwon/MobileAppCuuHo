class ApiConfig {
  // Đổi IP này theo backend Express local của nhóm.
  // Android emulator dùng: http://10.0.2.2:3000
  // Thiết bị thật dùng IP LAN máy chạy backend, ví dụ: http://192.168.1.10:3000
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // Bật mock khi backend chưa chạy.
  static const bool useMock = true;
}
