import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_config.dart';
import '../models/rescue_request.dart';

class RescueRequestService {
  final List<RescueRequest> _mockRequests = [
    RescueRequest(
      id: 'REQ001',
      emergencyType: 'Tai nạn giao thông',
      description: 'Có người bị thương cần hỗ trợ.',
      latitude: 10.7769,
      longitude: 106.7009,
      address: 'Quận 1, TP.HCM',
      priorityLevel: 'high',
      status: 'Đang chờ xác nhận',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
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
    if (ApiConfig.useMock) return 'REQ${DateTime.now().millisecondsSinceEpoch}';

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/rescue-requests'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
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
      throw Exception('Gửi SOS thất bại');
    }

    return jsonDecode(response.body)['id'].toString();
  }

  Future<List<RescueRequest>> getMyRequests() async {
    if (ApiConfig.useMock) return _mockRequests;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/rescue-requests/my'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) throw Exception('Không tải được lịch sử yêu cầu');
    return (jsonDecode(response.body) as List).map((e) => RescueRequest.fromJson(e)).toList();
  }
}
