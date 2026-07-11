import 'package:mobile_flutter/core/core.dart';
import 'package:mobile_flutter/data/data.dart';

Map<String, dynamic>? currentRescueTeam(
  Map<String, dynamic> user,
  AppData data,
) {
  final userId = valueOf(user, 'id');
  final userTeamId = valueOf(user, 'rescue_team_id');
  return data.teams.where((t) {
    final teamId = valueOf(t, 'id');
    return valueOf(t, 'leader_id') == userId ||
        valueOf(t, 'leader_user_id') == userId ||
        (userTeamId.isNotEmpty && userTeamId == teamId);
  }).firstOrNull;
}
