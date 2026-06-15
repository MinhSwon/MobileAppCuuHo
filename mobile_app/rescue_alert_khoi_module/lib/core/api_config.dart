class ApiConfig {
  // API: doi IP nay theo backend Express local cua nhom.
  // Android emulator dung: http://10.0.2.2:3000
  // Thiet bi that dung IP LAN may chay backend, vi du: http://192.168.1.10:3000
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // Bat mock khi backend chua chay de demo duoc UI Flutter.
  static const bool useMock = true;
}
