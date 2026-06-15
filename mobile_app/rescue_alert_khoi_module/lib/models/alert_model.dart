class AlertModel {
  final String id;
  final String title;
  final String content;
  final String alertType;
  final String area;
  final String severityLevel;
  final DateTime createdAt;

  const AlertModel({
    required this.id,
    required this.title,
    required this.content,
    required this.alertType,
    required this.area,
    required this.severityLevel,
    required this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      alertType: (json['alert_type'] ?? json['alertType'] ?? '').toString(),
      area: json['area']?.toString() ?? '',
      severityLevel: normalizeSeverity(
        (json['severity_level'] ?? json['severityLevel'] ?? 'medium')
            .toString(),
      ),
      createdAt:
          DateTime.tryParse(
            (json['created_at'] ?? json['createdAt'] ?? '').toString(),
          ) ??
          DateTime.now(),
    );
  }

  static const List<String> severityLevels = [
    'low',
    'medium',
    'high',
    'urgent',
  ];

  static String normalizeSeverity(String value) {
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
      case 'emergency':
      case 'khan cap':
      case 'khẩn cấp':
        return 'urgent';
      default:
        return 'medium';
    }
  }

  static String severityLabel(String value) {
    switch (normalizeSeverity(value)) {
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

  String get severityText => severityLabel(severityLevel);
}
