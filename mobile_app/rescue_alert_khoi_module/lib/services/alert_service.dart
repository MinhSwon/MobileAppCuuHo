import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../models/alert_model.dart';

class AlertService {
  static final List<AlertModel> _mockAlerts = [
    AlertModel(
      id: 'A001',
      title: 'Cảnh báo mưa lớn',
      content:
          'Khu vực TP.HCM có mưa lớn, người dân hạn chế di chuyển và theo dõi thông báo mới.',
      alertType: 'weather',
      area: 'TP.HCM',
      severityLevel: 'high',
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    AlertModel(
      id: 'A002',
      title: 'Cảnh báo ngập nước',
      content:
          'Một số tuyến đường tại Quận 7 có nguy cơ ngập sâu, cần chú ý an toàn khi di chuyển.',
      alertType: 'flood',
      area: 'Quận 7',
      severityLevel: 'medium',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AlertModel(
      id: 'A003',
      title: 'Sạt lở bờ kênh',
      content:
          'Người dân gần khu vực bờ kênh cần tránh xa vị trí sạt lở và liên hệ lực lượng chức năng khi cần.',
      alertType: 'landslide',
      area: 'Bình Chánh',
      severityLevel: 'urgent',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  Future<List<AlertModel>> getAlerts() async {
    if (ApiConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 250));
      return List.unmodifiable(_mockAlerts);
    }

    // API: GET /api/alerts cho danh sach canh bao nguoi dan.
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/alerts'));
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Không tải được cảnh báo'));
    }

    final decoded = jsonDecode(response.body);
    return _extractList(decoded).map((e) => AlertModel.fromJson(e)).toList();
  }

  Future<AlertModel> getAlertById(String id) async {
    if (ApiConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 250));
      return _mockAlerts.firstWhere(
        (alert) => alert.id == id,
        orElse: () => throw Exception('Không tìm thấy cảnh báo $id'),
      );
    }

    // API: GET /api/alerts/:id cho chi tiet canh bao.
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/alerts/$id'),
    );
    if (response.statusCode != 200) {
      throw Exception(
        _errorMessage(response, 'Không tải được chi tiết cảnh báo'),
      );
    }

    return AlertModel.fromJson(_extractObject(jsonDecode(response.body)));
  }

  List<Map<String, dynamic>> _extractList(dynamic decoded) {
    final rawList = decoded is List
        ? decoded
        : decoded is Map
        ? (decoded['data'] ?? decoded['alerts'] ?? decoded['items'] ?? [])
        : [];

    if (rawList is! List) return [];
    return rawList
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, dynamic> _extractObject(dynamic decoded) {
    final rawObject = decoded is Map
        ? (decoded['data'] ?? decoded['alert'] ?? decoded)
        : {};
    if (rawObject is Map<String, dynamic>) return rawObject;
    if (rawObject is Map) return Map<String, dynamic>.from(rawObject);
    return {};
  }

  String _errorMessage(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] != null)
        return decoded['message'].toString();
      if (decoded is Map && decoded['error'] != null)
        return decoded['error'].toString();
      return fallback;
    } catch (_) {
      return fallback;
    }
  }
}
