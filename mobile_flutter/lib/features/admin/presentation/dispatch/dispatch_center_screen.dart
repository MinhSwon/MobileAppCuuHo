import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/core/core.dart';
import 'package:mobile_flutter/data/data.dart';

import 'package:mobile_flutter/features/admin/presentation/shared/admin_dialogs.dart';

class DispatchCenterScreen extends StatelessWidget {
  const DispatchCenterScreen({super.key, required this.api, required this.user, required this.data, required this.onChanged});
  final ApiClient api;
  final Map<String, dynamic> user;
  final AppData data;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final activeMissions = data.missions.where((m) => !['RESCUED', 'TRANSFERRED_SAFEZONE', 'CANCELLED'].contains(m['status'])).toList();
    final pendingRequests = data.requests.where((r) => r['status'] == 'PENDING').toList();
    return AppList(
      children: [
        const PageTitle('Trung tâm điều phối', 'Theo dõi yêu cầu chờ xử lý và nhiệm vụ đang chạy'),
        GridStats(items: [
          StatItem('Yêu cầu chờ', '${pendingRequests.length}', Icons.sos, Palette.danger),
          StatItem('Nhiệm vụ mở', '${activeMissions.length}', Icons.navigation, Palette.accent),
          StatItem('Đội sẵn sàng', '${data.teams.where((t) => t['status'] == 'AVAILABLE').length}', Icons.groups, Palette.success),
          StatItem('Điểm sơ tán', '${data.safeZones.length}', Icons.apartment, Palette.warning),
        ]),
        RescueMap(
          title: 'Bản đồ điều phối',
          points: [
            ...pendingRequests.map((r) => MapPoint.fromMap(r, latKey: 'latitude', lngKey: 'longitude', labelKey: 'full_name', type: MapPointType.request)),
            ...activeMissions.map((m) => MapPoint.fromMap(m, latKey: 'victim_latitude', lngKey: 'victim_longitude', labelKey: 'victim_name', type: MapPointType.victim)),
            ...data.teams.map((t) => MapPoint.fromMap(t, latKey: 'latitude', lngKey: 'longitude', labelKey: 'team_name', type: MapPointType.team)),
            ...data.safeZones.map((s) => MapPoint.fromMap(s, latKey: 'latitude', lngKey: 'longitude', labelKey: 'name', type: MapPointType.safeZone)),
          ],
        ),
        const SectionHeader(icon: Icons.sos, title: 'Cần phân công'),
        if (pendingRequests.isEmpty)
          const EmptyCard(icon: Icons.check_circle, message: 'Không còn yêu cầu chờ phân công')
        else
          ...pendingRequests.map((r) => RequestCard(
                request: r,
                actions: [
                  if (data.teams.isNotEmpty)
                    TextButton.icon(
                      onPressed: () async {
                        final team = await pickRescueTeam(context, data.teams);
                        if (team == null) return;
                        await api.assignTeam(valueOf(r, 'id'), team, user);
                        await onChanged();
                      },
                      icon: const Icon(Icons.assignment_turned_in),
                      label: const Text('Phân công nhanh'),
                    ),
                ],
              )),
        const SectionHeader(icon: Icons.navigation, title: 'Nhiệm vụ đang điều phối'),
        if (activeMissions.isEmpty)
          const EmptyCard(icon: Icons.assignment, message: 'Chưa có nhiệm vụ đang chạy')
        else
          ...activeMissions.map((m) => MissionCard(mission: m)),
      ],
    );
  }
}
