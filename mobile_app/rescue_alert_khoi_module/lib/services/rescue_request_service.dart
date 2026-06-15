import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_config.dart';
import '../models/rescue_request.dart';

class RescueRequestService {
  static final List<RescueRequest> _mockRequests = [
    RescueRequest(
      id: 'REQ001',
      emergencyType: 'Tai nạn giao thông',
      description: 'Có người bị thương cần hỗ trợ y tế và cứu hộ nhanh.',
      latitude: 10.7769,
      longitude: 106.7009,
      address: 'Quận 1, TP.HCM',
      priorityLevel: 'high',
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    RescueRequest(
      id: 'REQ002',
      emergencyType: 'Ngập nước',
      description: 'Nước dâng nhanh, người dân cần được hỗ trợ di chuyển.',
      latitude: 10.735,
      longitude: 106.721,
      address: 'Quận 7, TP.HCM',
      priorityLevel: 'urgent',
      status: 'moving',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  Future<String> createRequest({
    required String emergencyType,
    required String description,
    required double latitude,
    required double longitude,
    required String address,
    required String priorityLevel,
  }) async {
    if (ApiConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 350));
      final id = 'REQ${DateTime.now().millisecondsSinceEpoch}';
      _mockRequests.insert(
        0,
        RescueRequest(
          id: id,
          emergencyType: emergencyType,
          description: description,
          latitude: latitude,
          longitude: longitude,
          address: address,
          priorityLevel: priorityLevel,
          status: 'submitted',
          createdAt: DateTime.now(),
        ),
      );
      return id;
    }

    // API: POST /api/rescue-requests kem JWT cua nguoi dan.
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/rescue-requests'),
      headers: await _authHeaders(includeJson: true),
      body: jsonEncode({
        'emergency_type': emergencyType,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'priority_level': priorityLevel,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Gửi SOS thất bại'));
    }

    final object = _extractObject(jsonDecode(response.body));
    return (object['id'] ?? object['request_id'] ?? object['requestId'] ?? '')
        .toString();
  }

  Future<List<RescueRequest>> getMyRequests() async {
    if (ApiConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 250));
      return List.unmodifiable(_mockRequests);
    }

    // API: GET /api/rescue-requests/my lay lich su yeu cau cua nguoi dan.
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/rescue-requests/my'),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _errorMessage(response, 'Không tải được lịch sử yêu cầu'),
      );
    }

    final decoded = jsonDecode(response.body);
    return _extractList(decoded).map((e) => RescueRequest.fromJson(e)).toList();
  }

  Future<RescueRequest> getRequestById(String id) async {
    if (ApiConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 250));
      return _mockRequests.firstWhere(
        (request) => request.id == id,
        orElse: () => throw Exception('Không tìm thấy yêu cầu $id'),
      );
    }

    // API: GET /api/rescue-requests/:id xem trang thai chi tiet.
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/rescue-requests/$id'),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _errorMessage(response, 'Không tải được chi tiết yêu cầu'),
      );
    }

    return RescueRequest.fromJson(_extractObject(jsonDecode(response.body)));
  }

  Future<Map<String, String>> _authHeaders({bool includeJson = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      if (includeJson) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  List<Map<String, dynamic>> _extractList(dynamic decoded) {
    final rawList = decoded is List
        ? decoded
        : decoded is Map
        ? (decoded['data'] ?? decoded['requests'] ?? decoded['items'] ?? [])
        : [];

    if (rawList is! List) return [];
    return rawList
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, dynamic> _extractObject(dynamic decoded) {
    final rawObject = decoded is Map
        ? (decoded['data'] ?? decoded['request'] ?? decoded)
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
