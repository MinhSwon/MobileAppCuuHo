class AlertModel {
  final String id;
  final String title;
  final String content;
  final String alertType;
  final String area;
  final String severityLevel;
  final DateTime createdAt;

  AlertModel({
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
      id: json['id'].toString(),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      alertType: json['alert_type'] ?? json['alertType'] ?? '',
      area: json['area'] ?? '',
      severityLevel: json['severity_level'] ?? json['severityLevel'] ?? 'medium',
      createdAt: DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
