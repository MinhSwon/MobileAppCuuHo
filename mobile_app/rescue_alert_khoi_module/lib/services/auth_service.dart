import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_config.dart';

class AuthService {
  Future<void> login(String email, String password) async {
    if (ApiConfig.useMock) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', 'mock-jwt-token-khoi');
      await prefs.setString('role', 'citizen');
      await prefs.setString('full_name', 'Nguyễn Nhật Khôi');
      return;
    }

    // API: POST /api/auth/login, nhan JWT va luu vao SharedPreferences.
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Đăng nhập thất bại'));
    }

    final body = _decodeObject(response.body);
    final payload = _objectFrom(body['data']) ?? body;
    final token =
        _readString(payload, ['token', 'access_token', 'accessToken']) ??
        _readString(body, ['token', 'access_token', 'accessToken']);

    if (token == null || token.isEmpty) {
      throw Exception('Đăng nhập thành công nhưng backend chưa trả token JWT.');
    }

    final user = _objectFrom(payload['user']) ?? _objectFrom(body['user']);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString(
      'role',
      _readString(user ?? payload, ['role']) ?? 'citizen',
    );
    await prefs.setString(
      'full_name',
      _readString(user ?? payload, ['full_name', 'fullName', 'name']) ??
          'Người dân',
    );
  }

  Future<void> register(
    String fullName,
    String phone,
    String email,
    String password,
  ) async {
    if (ApiConfig.useMock) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mock_registered_email', email);
      await prefs.setString('mock_registered_name', fullName);
      return;
    }

    // API: POST /api/auth/register cho tai khoan nguoi dan.
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
      throw Exception(_errorMessage(response, 'Đăng ký thất bại'));
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('full_name');
  }

  Map<String, dynamic> _decodeObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return {};
  }

  Map<String, dynamic>? _objectFrom(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  String? _readString(Map<String, dynamic>? source, List<String> keys) {
    if (source == null) return null;
    for (final key in keys) {
      final value = source[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  String _errorMessage(http.Response response, String fallback) {
    try {
      final body = _decodeObject(response.body);
      return _readString(body, ['message', 'error']) ?? fallback;
    } catch (_) {
      return fallback;
    }
  }
}
