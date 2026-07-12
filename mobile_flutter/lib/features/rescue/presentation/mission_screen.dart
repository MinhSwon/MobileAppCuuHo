import 'package:flutter/material.dart';

import 'package:mobile_flutter/core/core.dart';
import 'package:mobile_flutter/data/data.dart';

import 'package:mobile_flutter/features/rescue/presentation/mission_detail_screen.dart';
import 'package:mobile_flutter/features/rescue/utils/rescue_team_helpers.dart';

class MissionScreen extends StatelessWidget {
  const MissionScreen({
    super.key,
    required this.api,
    required this.user,
    required this.data,
    required this.onChanged,
  });
  final ApiClient api;
  final Map<String, dynamic> user;
  final AppData data;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final isRescue = [
      'RESCUE_LEADER',
      'RESCUE_MEMBER',
    ].contains(valueOf(user, 'role'));
    final team = isRescue ? currentRescueTeam(user, data) : null;
    final missions = isRescue && team != null
        ? data.missions
              .where((m) => valueOf(m, 'rescue_team_id') == valueOf(team, 'id'))
              .toList()
        : data.missions;
    return AppList(
      children: [
        const PageTitle(
          'Nhiệm vụ cứu hộ',
          'Cập nhật trạng thái theo tiến độ thực tế',
        ),
        if (missions.isEmpty)
          const EmptyCard(icon: Icons.assignment, message: 'Chưa có nhiệm vụ')
        else
          ...missions.map(
            (m) => MissionCard(
              mission: m,
              actions: [
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MissionDetailScreen(
                        api: api,
                        user: user,
                        data: data,
                        mission: m,
                        onChanged: onChanged,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Chi tiết'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
