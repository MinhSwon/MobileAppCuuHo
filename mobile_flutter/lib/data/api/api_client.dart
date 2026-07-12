import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:mobile_flutter/core/utils/data_helpers.dart';
import 'package:mobile_flutter/data/storage/simple_session_store.dart';

import 'package:mobile_flutter/core/config/api_config.dart';

class ApiClient {
  final _storage = SimpleSessionStore();
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
    ),
  );

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

  List<String> get _apiBaseUrlCandidates {
    final candidates = <String>[];

    void addCandidate(String url) {
      if (url.isNotEmpty && !candidates.contains(url)) candidates.add(url);
    }

    addCandidate(dio.options.baseUrl);
    addCandidate(apiBaseUrl);
    if (useLocalApiFallbacks) {
      for (final fallbackUrl in localApiFallbackBaseUrls) {
        addCandidate(fallbackUrl);
      }
    }

    return candidates;
  }

  Future<Response<dynamic>> _postWithFallback(
    String path, {
    Object? data,
  }) async {
    final originalBaseUrl = dio.options.baseUrl;
    Object? lastError;
    DioException? preferredError;

    for (final baseUrl in _apiBaseUrlCandidates) {
      try {
        dio.options.baseUrl = baseUrl;
        return await dio.post(path, data: data);
      } catch (err) {
        lastError = err;
        if (err is DioException && err.response?.statusCode != null) {
          preferredError ??= err;
        }
      }
    }

    dio.options.baseUrl = originalBaseUrl;
    throw preferredError ?? lastError ?? Exception('Không gọi được API');
  }

  Future<Response<dynamic>> _getWithFallback(String path) async {
    final originalBaseUrl = dio.options.baseUrl;
    Object? lastError;
    DioException? preferredError;

    for (final baseUrl in _apiBaseUrlCandidates) {
      try {
        dio.options.baseUrl = baseUrl;
        return await dio.get(path);
      } catch (err) {
        lastError = err;
        if (err is DioException && err.response?.statusCode != null) {
          preferredError ??= err;
        }
      }
    }

    dio.options.baseUrl = originalBaseUrl;
    throw preferredError ?? lastError ?? Exception('Không gọi được API');
  }

  Never _throwApiMessage(Object err, String fallback) {
    if (err is DioException) {
      final responseData = mapOf(err.response?.data);
      final message = valueOf(responseData, 'message');
      throw Exception(message.isNotEmpty ? message : fallback);
    }
    throw err;
  }

  Future<Map<String, dynamic>> login(
    String emailOrPhone,
    String password,
  ) async {
    late final Response<dynamic> res;
    try {
      res = await _postWithFallback(
        '/api/auth/login',
        data: {'emailOrPhone': emailOrPhone, 'password': password},
      );
    } catch (err) {
      _throwApiMessage(err, 'Đăng nhập không thành công');
    }
    final data = mapOf(res.data);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Đăng nhập không thành công');
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
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    late final Response<dynamic> res;
    try {
      res = await _postWithFallback('/api/auth/register', data: payload);
    } catch (err) {
      _throwApiMessage(err, 'Đăng ký không thành công');
    }
    final data = mapOf(res.data);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Đăng ký không thành công');
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
  }

  Future<Map<String, dynamic>> sendRegisterOtp(String phone) async {
    try {
      final res = await _postWithFallback(
        '/api/auth/otp/send',
        data: {'phone': phone},
      );
      return mapOf(res.data);
    } catch (err) {
      _throwApiMessage(err, 'Không gửi được mã OTP');
    }
  }

  Future<Map<String, dynamic>> verifyRegisterOtp(
    String phone,
    String otp,
  ) async {
    try {
      final res = await _postWithFallback(
        '/api/auth/otp/verify',
        data: {'phone': phone, 'otp': otp},
      );
      return mapOf(res.data);
    } catch (err) {
      _throwApiMessage(err, 'Không xác thực được OTP');
    }
  }

  Future<Map<String, dynamic>> sendAiChat(
    List<Map<String, String>> messages,
  ) async {
    try {
      final res = await _postWithFallback(
        '/api/ai/chat',
        data: {'messages': messages},
      );
      return mapOf(res.data);
    } catch (err) {
      _throwApiMessage(err, 'Chatbot AI đang tạm thời không khả dụng');
    }
  }

  Future<Map<String, dynamic>> fetchDb() async {
    final originalBaseUrl = dio.options.baseUrl;

    Object? lastError;
    for (final baseUrl in _apiBaseUrlCandidates) {
      try {
        dio.options.baseUrl = baseUrl;
        final res = await dio.get('/api/db');
        return mapOf(res.data);
      } catch (err) {
        lastError = err;
      }
    }

    dio.options.baseUrl = originalBaseUrl;
    throw lastError ?? Exception('Không đồng bộ được dữ liệu');
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
    try {
      await _postWithFallback('/api/rescue-requests', data: data);
    } catch (err) {
      _throwApiMessage(err, 'Không gửi được yêu cầu cứu hộ');
    }
  }

  Future<List<Map<String, dynamic>>> fetchChatMessages(String requestId) async {
    try {
      final res = await _getWithFallback(
        '/api/rescue-requests/$requestId/messages',
      );
      return listOf(res.data);
    } catch (err) {
      _throwApiMessage(
        err,
        'Không tải được tin nhắn. Hãy khởi động lại backend và mở lại app.',
      );
    }
  }

  Future<Map<String, dynamic>> sendChatMessage(
    String requestId,
    String message,
  ) async {
    try {
      final res = await _postWithFallback(
        '/api/rescue-requests/$requestId/messages',
        data: {'message': message},
      );
      return mapOf(res.data);
    } catch (err) {
      _throwApiMessage(
        err,
        'Không gửi được tin nhắn. Hãy khởi động lại backend và mở lại app.',
      );
    }
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
        'note': note ?? 'Cập nhật từ ứng dụng Flutter',
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

  Future<void> updateRequestTriage(
    String requestId,
    String status, {
    String? note,
  }) async {
    await dio.post(
      '/api/rescue-requests/$requestId/triage',
      data: {
        'status': status,
        if (note != null && note.isNotEmpty) 'note': note,
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

  Future<Map<String, dynamic>> updateProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _postWithFallback(
        '/api/users/$userId/profile',
        data: data,
      );
      final result = mapOf(response.data);
      if (result['user'] != null) {
        await _storage.write(
          key: 'currentUser',
          value: jsonEncode(result['user']),
        );
      }
      if (result['profile'] != null) {
        await _storage.write(
          key: 'currentProfile',
          value: jsonEncode(result['profile']),
        );
      }
      return result;
    } catch (err) {
      _throwApiMessage(err, 'Không cập nhật được hồ sơ');
    }
  }

  Future<void> updatePassword(
    String userId,
    String oldPassword,
    String newPassword,
  ) async {
    try {
      await _postWithFallback(
        '/api/users/$userId/change-password',
        data: {'oldPassword': oldPassword, 'newPassword': newPassword},
      );
    } catch (err) {
      _throwApiMessage(err, 'Không đổi được mật khẩu');
    }
  }

  Future<void> updateWarningContent(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      await dio.put('/api/warnings/$id', data: data);
    } catch (err) {
      _throwApiMessage(err, 'Không cập nhật được cảnh báo');
    }
  }

  Future<void> logout() async {
    dio.options.headers.remove('Authorization');
    await _storage.deleteAll();
  }
}
