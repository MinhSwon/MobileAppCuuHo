import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:mobile_flutter/core/config/api_config.dart';
import 'package:mobile_flutter/core/utils/data_helpers.dart';
import 'package:mobile_flutter/data/storage/simple_session_store.dart';

class ApiClient {
  final _storage = SimpleSessionStore();
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
    ),
  );

  Exception _friendlyError(Object error, {required String fallbackMessage}) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message =
            data['message']?.toString() ?? data['error']?.toString();
        if (message != null && message.isNotEmpty) {
          return Exception(message);
        }
      }

      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return Exception('Khong the ket noi toi may chu');
      }
    }

    if (error is Exception) return error;
    return Exception(fallbackMessage);
  }

  Future<void> restoreToken() async {
    final token = await _storage.read(key: 'authToken');
    if (token != null && token.isNotEmpty) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<Map<String, dynamic>?> readJson(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null || raw.isEmpty) return null;
    return mapOf(jsonDecode(raw));
  }

  Future<Map<String, dynamic>> login(
    String emailOrPhone,
    String password,
  ) async {
    try {
      final res = await dio.post(
        '/api/auth/login',
        data: {'emailOrPhone': emailOrPhone, 'password': password},
      );
      final data = mapOf(res.data);
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Dang nhap khong thanh cong');
      }

      final token = data['token']?.toString();
      if (token != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
        await _storage.write(key: 'authToken', value: token);
      }
      await _storage.write(key: 'currentUser', value: jsonEncode(data['user']));
      if (data['profile'] != null) {
        await _storage.write(
          key: 'currentProfile',
          value: jsonEncode(data['profile']),
        );
      }
      return data;
    } catch (error) {
      throw _friendlyError(
        error,
        fallbackMessage: 'Dang nhap khong thanh cong',
      );
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    try {
      final res = await dio.post('/api/auth/register', data: payload);
      final data = mapOf(res.data);
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Dang ky khong thanh cong');
      }

      final token = data['token']?.toString();
      if (token != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
        await _storage.write(key: 'authToken', value: token);
      }
      await _storage.write(key: 'currentUser', value: jsonEncode(data['user']));
      if (data['profile'] != null) {
        await _storage.write(
          key: 'currentProfile',
          value: jsonEncode(data['profile']),
        );
      }
      return data;
    } catch (error) {
      throw _friendlyError(error, fallbackMessage: 'Dang ky khong thanh cong');
    }
  }

  Future<Map<String, dynamic>> fetchDb() async {
    final res = await dio.get('/api/db');
    return mapOf(res.data);
  }

  Future<Map<String, dynamic>> fetchReadiness() async {
    final res = await dio.get('/api/readiness');
    return mapOf(res.data);
  }

  Future<Map<String, dynamic>> fetchNotificationProviderStatus() async {
    final res = await dio.get('/api/notifications/provider-status');
    return mapOf(res.data);
  }

  Future<void> registerDeviceToken(String token, String platform) async {
    await dio.post(
      '/api/notifications/device-token',
      data: {'token': token, 'platform': platform},
    );
  }

  Future<void> createRescueRequest(Map<String, dynamic> data) async {
    await dio.post('/api/rescue-requests', data: data);
  }

  Future<void> updateMissionStatus(
    String id,
    String status,
    Map<String, dynamic> user, {
    Map<String, dynamic> extraData = const {},
    String? note,
  }) async {
    await dio.post(
      '/api/missions/$id/status',
      data: {
        'newStatus': status,
        'extraData': extraData,
        'changedByType': 'RESCUE_TEAM',
        'changedByUser': user,
        'note': note ?? 'Cap nhat tu ung dung Flutter',
      },
    );
  }

  Future<void> assignTeam(
    String requestId,
    Map<String, dynamic> team,
    Map<String, dynamic> user,
  ) async {
    await dio.post(
      '/api/rescue-requests/$requestId/assign',
      data: {
        'teamId': team['id'],
        'teamName': valueOf(team, 'team_name'),
        'currentUser': user,
      },
    );
  }

  Future<void> createWarning(Map<String, dynamic> data) async {
    await dio.post('/api/warnings', data: data);
  }

  Future<void> updateWarning(String id, Map<String, dynamic> data) async {
    await dio.put('/api/warnings/$id', data: data);
  }

  Future<void> deleteWarning(String id) async {
    await dio.delete('/api/warnings/$id');
  }

  Future<void> createTeam(Map<String, dynamic> data) async {
    await dio.post('/api/teams', data: data);
  }

  Future<void> updateTeam(String id, Map<String, dynamic> data) async {
    await dio.put('/api/teams/$id', data: data);
  }

  Future<void> deleteTeam(String id) async {
    await dio.delete('/api/teams/$id');
  }

  Future<void> createSafeZone(Map<String, dynamic> data) async {
    await dio.post('/api/safe-zones', data: data);
  }

  Future<void> updateSafeZone(String id, Map<String, dynamic> data) async {
    await dio.put('/api/safe-zones/$id', data: data);
  }

  Future<void> deleteSafeZone(String id) async {
    await dio.delete('/api/safe-zones/$id');
  }

  Future<void> createRoute(Map<String, dynamic> data) async {
    await dio.post('/api/routes', data: data);
  }

  Future<void> updateRoute(String id, Map<String, dynamic> data) async {
    await dio.put('/api/routes/$id', data: data);
  }

  Future<void> deleteRoute(String id) async {
    await dio.delete('/api/routes/$id');
  }

  Future<void> createVulnerableHousehold(Map<String, dynamic> data) async {
    await dio.post('/api/vulnerable-households', data: data);
  }

  Future<void> updateVulnerableHousehold(
    String id,
    Map<String, dynamic> data,
  ) async {
    await dio.put('/api/vulnerable-households/$id', data: data);
  }

  Future<void> logout() async {
    dio.options.headers.remove('Authorization');
    await _storage.deleteAll();
  }
}
