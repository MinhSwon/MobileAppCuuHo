import 'package:mobile_flutter/core/utils/data_helpers.dart';

class AppData {
  AppData(this.raw);
  final Map<String, dynamic> raw;
  List<Map<String, dynamic>> get areas => firstListOf(raw, ['areas', 'administrativeUnits']);
  List<Map<String, dynamic>> get users => firstListOf(raw, ['users']);
  List<Map<String, dynamic>> get profiles => firstListOf(raw, ['citizenProfiles', 'profiles']);
  List<Map<String, dynamic>> get requests => firstListOf(raw, ['rescueRequests', 'requests']);
  List<Map<String, dynamic>> get missions => firstListOf(raw, ['rescueMissions', 'missions']);
  List<Map<String, dynamic>> get missionStatusLogs => firstListOf(raw, ['missionStatusLogs', 'missionLogs']);
  List<Map<String, dynamic>> get teams => firstListOf(raw, ['rescueTeams', 'teams']);
  List<Map<String, dynamic>> get warnings => firstListOf(raw, ['floodWarnings', 'alerts', 'warnings']);
  List<Map<String, dynamic>> get safeZones => firstListOf(raw, ['safeZones']);
  List<Map<String, dynamic>> get routes => firstListOf(raw, ['rescueRoutes', 'routes']);
  List<Map<String, dynamic>> get dams => firstListOf(raw, ['dams']);
  List<Map<String, dynamic>> get households => firstListOf(raw, ['vulnerableHouseholds', 'households']);
  List<Map<String, dynamic>> get sms => firstListOf(raw, ['smsLogs']);
  List<Map<String, dynamic>> get damageReports => firstListOf(raw, ['damageReports']);
  List<Map<String, dynamic>> get activityLogs => firstListOf(raw, ['activityLogs']);
  List<Map<String, dynamic>> get notifications => firstListOf(raw, ['notifications']);
}
