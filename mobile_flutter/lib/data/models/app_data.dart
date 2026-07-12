import 'package:mobile_flutter/core/utils/data_helpers.dart';

class AppData {
  AppData(this.raw);
  final Map<String, dynamic> raw;

  static const List<Map<String, dynamic>> fallbackAreas = [
    {
      'id': 'area-1',
      'old_name': 'H\u00e0 N\u1ed9i',
      'current_name': 'TP H\u00e0 N\u1ed9i',
      'area_type': 'Th\u00e0nh ph\u1ed1',
      'risk_level': 'HIGH',
      'latitude': 21.0285,
      'longitude': 105.8542,
    },
    {
      'id': 'area-2',
      'old_name': '\u0110\u00e0 N\u1eb5ng',
      'current_name': 'TP \u0110\u00e0 N\u1eb5ng',
      'area_type': 'Th\u00e0nh ph\u1ed1',
      'risk_level': 'EMERGENCY',
      'latitude': 16.0471,
      'longitude': 108.2068,
    },
    {
      'id': 'area-3',
      'old_name': 'TP H\u1ed3 Ch\u00ed Minh',
      'current_name': 'TP H\u1ed3 Ch\u00ed Minh',
      'area_type': 'Th\u00e0nh ph\u1ed1',
      'risk_level': 'MEDIUM',
      'latitude': 10.7769,
      'longitude': 106.7009,
    },
    {
      'id': 'area-4',
      'old_name': 'C\u1ea7n Th\u01a1',
      'current_name': 'TP C\u1ea7n Th\u01a1',
      'area_type': 'Th\u00e0nh ph\u1ed1',
      'risk_level': 'HIGH',
      'latitude': 10.0452,
      'longitude': 105.7469,
    },
  ];

  List<Map<String, dynamic>> get areas {
    final loadedAreas = firstListOf(raw, ['areas', 'administrativeUnits']);
    return loadedAreas.isNotEmpty ? loadedAreas : fallbackAreas;
  }

  List<Map<String, dynamic>> get users => firstListOf(raw, ['users']);
  List<Map<String, dynamic>> get profiles =>
      firstListOf(raw, ['citizenProfiles', 'profiles']);
  List<Map<String, dynamic>> get requests =>
      firstListOf(raw, ['rescueRequests', 'requests']);
  List<Map<String, dynamic>> get missions =>
      firstListOf(raw, ['rescueMissions', 'missions']);
  List<Map<String, dynamic>> get missionStatusLogs =>
      firstListOf(raw, ['missionStatusLogs', 'missionLogs']);
  List<Map<String, dynamic>> get teams =>
      firstListOf(raw, ['rescueTeams', 'teams']);
  List<Map<String, dynamic>> get warnings =>
      firstListOf(raw, ['floodWarnings', 'alerts', 'warnings']);
  List<Map<String, dynamic>> get safeZones => firstListOf(raw, ['safeZones']);
  List<Map<String, dynamic>> get routes =>
      firstListOf(raw, ['rescueRoutes', 'routes']);
  List<Map<String, dynamic>> get dams => firstListOf(raw, ['dams']);
  List<Map<String, dynamic>> get households =>
      firstListOf(raw, ['vulnerableHouseholds', 'households']);
  List<Map<String, dynamic>> get sms => firstListOf(raw, ['smsLogs']);
  List<Map<String, dynamic>> get damageReports =>
      firstListOf(raw, ['damageReports']);
  List<Map<String, dynamic>> get activityLogs =>
      firstListOf(raw, ['activityLogs']);
  List<Map<String, dynamic>> get notifications =>
      firstListOf(raw, ['notifications']);
  List<Map<String, dynamic>> get chatMessages =>
      firstListOf(raw, ['chatMessages']);
}
