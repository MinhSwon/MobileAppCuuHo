import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/core/core.dart';
import 'package:mobile_flutter/data/data.dart';
import 'package:mobile_flutter/features/rescue/presentation/mission_detail_screen.dart';
import 'package:mobile_flutter/features/rescue/utils/rescue_team_helpers.dart';

class RescueHome extends StatelessWidget {
  const RescueHome({
    super.key,
    required this.api,
    required this.user,
    required this.data,
    required this.onChanged,
    required this.onOpenMissionList,
  });

  final ApiClient api;
  final Map<String, dynamic> user;
  final AppData data;
  final Future<void> Function() onChanged;
  final VoidCallback onOpenMissionList;

  @override
  Widget build(BuildContext context) {
    final team = currentRescueTeam(user, data);
    final missions = data.missions
        .where(
          (m) =>
              team == null ||
              valueOf(m, 'rescue_team_id') == valueOf(team, 'id'),
        )
        .toList();
    final active = missions
        .where(
          (m) => ![
            'RESCUED',
            'TRANSFERRED_SAFEZONE',
            'COMPLETED',
            'CANCELLED',
            'UNREACHABLE',
            'FALSE_ALARM',
          ].contains(valueOf(m, 'status')),
        )
        .toList();
    final completed = missions
        .where(
          (m) => [
            'RESCUED',
            'TRANSFERRED_SAFEZONE',
            'COMPLETED',
          ].contains(valueOf(m, 'status')),
        )
        .toList();

    return AppList(
      children: [
        PageTitle(
          'Chào mừng, ${valueOf(user, 'full_name')}',
          team == null
              ? 'Đội cứu hộ'
              : '${valueOf(team, 'team_name')} · ${valueOf(team, 'area_name', fallback: 'Toàn quốc')}',
        ),
        GridStats(
          items: [
            StatItem(
              'Đang xử lý',
              '${active.length}',
              Icons.sync,
              Palette.accent,
            ),
            StatItem(
              'Cứu thành công',
              '${completed.length}',
              Icons.check_circle,
              Palette.success,
            ),
            StatItem(
              'Tổng nhiệm vụ',
              '${missions.length}',
              Icons.schedule,
              Palette.secondary,
            ),
            StatItem(
              'Trạng thái đội',
              valueOf(team, 'status', fallback: 'READY'),
              Icons.shield,
              Palette.warning,
            ),
          ],
        ),
        const SectionHeader(
          icon: Icons.assignment_rounded,
          title: 'Nhiệm vụ đang thực hiện',
        ),
        if (active.isEmpty)
          const EmptyCard(
            icon: Icons.check_circle,
            message: 'Không có nhiệm vụ đang thực hiện',
          )
        else
          ...active.map(
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
                TextButton.icon(
                  onPressed: onOpenMissionList,
                  icon: const Icon(Icons.list_alt),
                  label: const Text('Tất cả'),
                ),
              ],
            ),
          ),
        if (team != null) ...[
          const SectionHeader(icon: Icons.groups, title: 'Thông tin đội'),
          CardBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoRow('Trưởng đội', valueOf(team, 'leader_name')),
                InfoRow('Điện thoại', valueOf(team, 'phone')),
                InfoRow('Thành viên', '${valueOf(team, 'member_count')} người'),
                InfoRow(
                  'Phương tiện',
                  valueOf(team, 'vehicle_type', fallback: '-'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
