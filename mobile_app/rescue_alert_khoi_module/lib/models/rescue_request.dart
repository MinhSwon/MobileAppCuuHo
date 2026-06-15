class RescueRequest {
  final String id;
  final String emergencyType;
  final String description;
  final double latitude;
  final double longitude;
  final String address;
  final String priorityLevel;
  final String status;
  final DateTime createdAt;

  const RescueRequest({
    required this.id,
    required this.emergencyType,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.priorityLevel,
    required this.status,
    required this.createdAt,
  });

  factory RescueRequest.fromJson(Map<String, dynamic> json) {
    return RescueRequest(
      id: json['id']?.toString() ?? '',
      emergencyType: (json['emergency_type'] ?? json['emergencyType'] ?? '')
          .toString(),
      description: json['description']?.toString() ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      address: json['address']?.toString() ?? '',
      priorityLevel: normalizePriority(
        (json['priority_level'] ?? json['priorityLevel'] ?? 'medium')
            .toString(),
      ),
      status: normalizeStatus((json['status'] ?? 'pending').toString()),
      createdAt:
          DateTime.tryParse(
            (json['created_at'] ?? json['createdAt'] ?? '').toString(),
          ) ??
          DateTime.now(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static const List<String> statusSteps = [
    'submitted',
    'pending',
    'assigned',
    'moving',
    'arrived',
    'processing',
    'completed',
    'canceled',
  ];

  static String normalizeStatus(String value) {
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'submitted':
      case 'created':
      case 'da gui yeu cau':
      case 'đã gửi yêu cầu':
        return 'submitted';
      case 'pending':
      case 'waiting':
      case 'dang cho xac nhan':
      case 'đang chờ xác nhận':
        return 'pending';
      case 'assigned':
      case 'da phan cong':
      case 'đã phân công':
        return 'assigned';
      case 'moving':
      case 'on_the_way':
      case 'team_on_the_way':
      case 'doi cuu ho dang di chuyen':
      case 'đội cứu hộ đang di chuyển':
        return 'moving';
      case 'arrived':
      case 'da den noi':
      case 'đã đến nơi':
        return 'arrived';
      case 'processing':
      case 'in_progress':
      case 'dang xu ly':
      case 'đang xử lý':
        return 'processing';
      case 'completed':
      case 'done':
      case 'hoan thanh':
      case 'hoàn thành':
        return 'completed';
      case 'canceled':
      case 'cancelled':
      case 'huy yeu cau':
      case 'hủy yêu cầu':
        return 'canceled';
      default:
        return 'pending';
    }
  }

  static String statusLabel(String status) {
    switch (normalizeStatus(status)) {
      case 'submitted':
        return 'Đã gửi yêu cầu';
      case 'pending':
        return 'Đang chờ xác nhận';
      case 'assigned':
        return 'Đã phân công';
      case 'moving':
        return 'Đội cứu hộ đang di chuyển';
      case 'arrived':
        return 'Đã đến nơi';
      case 'processing':
        return 'Đang xử lý';
      case 'completed':
        return 'Hoàn thành';
      case 'canceled':
        return 'Hủy yêu cầu';
      default:
        return 'Đang chờ xác nhận';
    }
  }

  static String normalizePriority(String value) {
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'low':
      case 'thap':
      case 'thấp':
        return 'low';
      case 'medium':
      case 'trung binh':
      case 'trung bình':
        return 'medium';
      case 'high':
      case 'cao':
        return 'high';
      case 'urgent':
      case 'khan cap':
      case 'khẩn cấp':
        return 'urgent';
      default:
        return 'medium';
    }
  }

  static String priorityLabel(String priority) {
    switch (normalizePriority(priority)) {
      case 'low':
        return 'Thấp';
      case 'medium':
        return 'Trung bình';
      case 'high':
        return 'Cao';
      case 'urgent':
        return 'Khẩn cấp';
      default:
        return 'Trung bình';
    }
  }

  String get statusText => statusLabel(status);
  String get priorityText => priorityLabel(priorityLevel);

  int get statusIndex {
    final index = statusSteps.indexOf(normalizeStatus(status));
    return index < 0 ? 1 : index;
  }
}
