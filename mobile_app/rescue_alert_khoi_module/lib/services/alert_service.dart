import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/alert_model.dart';

class AlertService {
  Future<List<AlertModel>> getAlerts() async {
    if (ApiConfig.useMock) {
      return [
        AlertModel(
          id: 'A001',
          title: 'Cảnh báo mưa lớn',
          content: 'Khu vực TP.HCM có mưa lớn, người dân hạn chế di chuyển.',
          alertType: 'weather',
          area: 'TP.HCM',
          severityLevel: 'cao',
          createdAt: DateTime.now(),
        ),
        AlertModel(
          id: 'A002',
          title: 'Cảnh báo ngập nước',
          content: 'Một số tuyến đường có nguy cơ ngập, cần chú ý an toàn.',
          alertType: 'flood',
          area: 'Quận 7',
          severityLevel: 'trung bình',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];
    }

    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/alerts'));
    if (response.statusCode != 200) throw Exception('Không tải được cảnh báo');
    return (jsonDecode(response.body) as List).map((e) => AlertModel.fromJson(e)).toList();
  }
}
