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

  RescueRequest({
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
      id: json['id'].toString(),
      emergencyType: json['emergency_type'] ?? json['emergencyType'] ?? '',
      description: json['description'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] ?? '',
      priorityLevel: json['priority_level'] ?? json['priorityLevel'] ?? 'medium',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
