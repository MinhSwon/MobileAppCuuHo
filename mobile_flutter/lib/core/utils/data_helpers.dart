import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';

Map<String, dynamic> mapOf(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, val) => MapEntry(key.toString(), val));
  return {};
}

List<Map<String, dynamic>> listOf(dynamic value) {
  if (value is List) return value.map(mapOf).toList();
  return [];
}

Map<String, dynamic>? firstWhere(List<Map<String, dynamic>> list, String key, dynamic value) {
  for (final item in list) {
    if (valueOf(item, key) == value?.toString()) return item;
  }
  return null;
}

const Map<String, List<String>> _fieldAliases = {
  'id': ['id'],
  'full_name': ['full_name', 'fullName', 'name', 'display_name'],
  'user_id': ['user_id', 'userId'],
  'created_by_user_id': ['created_by_user_id', 'createdByUserId', 'user_id', 'userId'],
  'area_id': ['area_id', 'areaId'],
  'area_name': ['area_name', 'areaName'],
  'old_name': ['old_name', 'displayName', 'name'],
  'address_detail': ['address_detail', 'addressDetail', 'address'],
  'number_of_people': ['number_of_people', 'numberOfPeople', 'people_count', 'peopleCount'],
  'emergency_level': ['emergency_level', 'emergencyLevel', 'level', 'severity', 'priority_level', 'priorityLevel'],
  'team_name': ['team_name', 'teamName', 'assigned_team_name', 'assignedTeamName', 'name'],
  'leader_user_id': ['leader_user_id', 'leader_id', 'leaderId'],
  'leader_id': ['leader_id', 'leader_user_id', 'leaderId'],
  'member_count': ['member_count', 'memberCount'],
  'assigned_team_id': ['assigned_team_id', 'assignedTeamId', 'team_id', 'teamId', 'rescue_team_id'],
  'rescue_team_id': ['rescue_team_id', 'team_id', 'teamId', 'assigned_team_id', 'assignedTeamId'],
  'victim_name': ['victim_name', 'full_name', 'fullName'],
  'victim_phone': ['victim_phone', 'phone'],
  'victim_address': ['victim_address', 'address_detail', 'addressDetail', 'address'],
  'victim_latitude': ['victim_latitude', 'latitude', 'latest_latitude', 'latestLatitude'],
  'victim_longitude': ['victim_longitude', 'longitude', 'latest_longitude', 'latestLongitude'],
  'current_rescuer_latitude': ['current_rescuer_latitude', 'latest_latitude', 'latestLatitude'],
  'current_rescuer_longitude': ['current_rescuer_longitude', 'latest_longitude', 'latestLongitude'],
  'mission_id': ['mission_id', 'missionId'],
  'old_status': ['old_status', 'oldStatus'],
  'new_status': ['new_status', 'newStatus'],
  'changed_by_user_id': ['changed_by_user_id', 'changedById'],
  'current_people': ['current_people', 'currentPeople'],
  'contact_person': ['contact_person', 'contactPerson'],
  'contact_phone': ['contact_phone', 'contactPhone'],
  'start_point': ['start_point', 'startPoint', 'from_location', 'fromLocation'],
  'end_point': ['end_point', 'endPoint', 'to_location', 'toLocation'],
  'distance_km': ['distance_km', 'distanceKm'],
  'damage_type': ['damage_type', 'damageType', 'title'],
  'reporter_name': ['reporter_name', 'reporterName'],
  'household_name': ['household_name', 'householdName', 'full_name', 'head_name'],
  'household_size': ['household_size', 'householdSize', 'people_count', 'peopleCount'],
  'priority_level': ['priority_level', 'priorityLevel', 'emergency_level', 'level'],
  'created_at': ['created_at', 'createdAt'],
  'sent_at': ['sent_at', 'sentAt'],
};

String valueOf(Map<String, dynamic>? map, String key, {String fallback = ''}) {
  if (map == null) return fallback;
  for (final candidate in _fieldAliases[key] ?? [key]) {
    final value = map[candidate];
    if (value != null && value.toString() != 'null') return value.toString();
  }
  return fallback;
}

List<Map<String, dynamic>> firstListOf(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final list = listOf(map[key]);
    if (list.isNotEmpty) return list;
  }
  return [];
}

String formatDate(String raw) {
  final date = DateTime.tryParse(raw);
  if (date == null) return raw;
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String statusLabel(String status) {
  const labels = {
    'PENDING': 'Chờ tiếp nhận',
    'CREATED': 'Đã tạo',
    'DISPATCHED': 'Đã điều phối',
    'ASSIGNED': 'Đã phân công',
    'ACCEPTED': 'Đã nhận',
    'MOVING': 'Đang di chuyển',
    'NEAR_VICTIM': 'Gần nạn nhân',
    'ARRIVED_CONFIRMED': 'Đã tiếp cận',
    'ARRIVED': 'Đã tiếp cận',
    'RESCUING': 'Đang cứu hộ',
    'RESCUED': 'Đã cứu',
    'COMPLETED': 'Hoàn tất',
    'TRANSFERRED_SAFEZONE': 'Đến điểm an toàn',
    'UNREACHABLE': 'Không liên lạc',
    'NEED_SUPPORT': 'Cần hỗ trợ',
    'CANCELLED': 'Đã hủy',
    'AVAILABLE': 'Sẵn sàng',
    'BUSY': 'Đang bận',
    'OFFLINE': 'Mất liên lạc',
    'INACTIVE': 'Ngưng hoạt động',
    'FULL': 'Đã đầy',
    'OPEN': 'Thông suốt',
    'CAUTION': 'Cần chú ý',
    'BLOCKED': 'Bị chặn',
    'CLOSED': 'Đã đóng',
    'PUBLISHED': 'Đang phát',
    'DRAFT': 'Bản nháp',
  };
  return labels[status] ?? status;
}

String levelLabel(String level) {
  const labels = {'LOW': 'Thấp', 'MEDIUM': 'Trung bình', 'HIGH': 'Cao', 'EMERGENCY': 'Khẩn cấp'};
  return labels[level] ?? level;
}

Color statusColor(String status) {
  if (['RESCUED', 'TRANSFERRED_SAFEZONE', 'COMPLETED', 'AVAILABLE', 'PUBLISHED'].contains(status)) return Palette.success;
  if (['PENDING', 'UNREACHABLE', 'CANCELLED', 'EMERGENCY'].contains(status)) return Palette.danger;
  if (['BUSY', 'NEED_SUPPORT', 'HIGH'].contains(status)) return Palette.warning;
  return Palette.accent;
}

Color levelColor(String level) {
  if (level == 'EMERGENCY') return Palette.danger;
  if (level == 'HIGH') return const Color(0xffbf5f2a);
  if (level == 'MEDIUM') return Palette.warning;
  return Palette.accent;
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
