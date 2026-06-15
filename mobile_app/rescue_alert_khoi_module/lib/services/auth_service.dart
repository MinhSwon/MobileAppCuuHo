import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_config.dart';

class AuthService {
  Future<void> login(String email, String password) async {
    if (ApiConfig.useMock) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', 'mock-jwt-token');
      await prefs.setString('role', 'citizen');
      return;
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode != 200) {
      throw Exception('Đăng nhập thất bại');
    }

    final data = jsonDecode(response.body);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', data['token']);
    await prefs.setString('role', data['user']['role']);
  }

  Future<void> register(String fullName, String phone, String email, String password) async {
    if (ApiConfig.useMock) return;

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'full_name': fullName,
        'phone': phone,
        'email': email,
        'password': password,
        'role': 'citizen',
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Đăng ký thất bại');
    }
  }
}
