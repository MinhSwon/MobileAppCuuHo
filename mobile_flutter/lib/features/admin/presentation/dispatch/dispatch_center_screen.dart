import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/core/core.dart';
import 'package:mobile_flutter/data/data.dart';

import 'package:mobile_flutter/features/admin/presentation/overview/admin_overview_screen.dart';
import 'package:mobile_flutter/features/admin/presentation/shared/admin_dialogs.dart';

class DispatchCenterScreen extends StatelessWidget {
  const DispatchCenterScreen({
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
    final activeMissions = data.missions
        .where(
          (m) => ![
            'RESCUED',
            'TRANSFERRED_SAFEZONE',
            'CANCELLED',
            'FALSE_ALARM',
          ].contains(m['status']),
        )
        .toList();
    final pendingRequests =
        data.requests
            .where(
              (r) => [
                'PENDING',
                'VERIFYING',
                'SUSPICIOUS',
                'VERIFIED',
              ].contains(valueOf(r, 'status')),
            )
            .toList()
          // Sort mới nhất lên đầu
          ..sort((a, b) {
            final aTime = DateTime.tryParse(valueOf(a, 'created_at'));
            final bTime = DateTime.tryParse(valueOf(b, 'created_at'));
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });
    // Chỉ show đội AVAILABLE khi phân công
    final availableTeams = data.teams
        .where((t) => valueOf(t, 'status') == 'AVAILABLE')
        .toList();
    return AppList(
      children: [
        const PageTitle(
          'Trung tâm điều phối',
          'Theo dõi yêu cầu chờ xử lý và nhiệm vụ đang chạy',
        ),
        GridStats(
          items: [
            StatItem(
              'Yêu cầu chờ',
              '${pendingRequests.length}',
              Icons.sos,
              Palette.danger,
            ),
            StatItem(
              'Nhiệm vụ mở',
              '${activeMissions.length}',
              Icons.navigation,
              Palette.accent,
            ),
            StatItem(
              'Đội sẵn sàng',
              '${data.teams.where((t) => t['status'] == 'AVAILABLE').length}',
              Icons.groups,
              Palette.success,
            ),
            StatItem(
              'Điểm sơ tán',
              '${data.safeZones.length}',
              Icons.apartment,
              Palette.warning,
            ),
          ],
        ),
        RescueMap(
          title: 'Bản đồ điều phối',
          points: [
            ...pendingRequests.map(
              (r) => MapPoint.fromMap(
                r,
                latKey: 'latitude',
                lngKey: 'longitude',
                labelKey: 'full_name',
                type: MapPointType.request,
              ),
            ),
            ...activeMissions.map(
              (m) => MapPoint.fromMap(
                m,
                latKey: 'victim_latitude',
                lngKey: 'victim_longitude',
                labelKey: 'victim_name',
                type: MapPointType.victim,
              ),
            ),
            ...data.teams.map(
              (t) => MapPoint.fromMap(
                t,
                latKey: 'latitude',
                lngKey: 'longitude',
                labelKey: 'team_name',
                type: MapPointType.team,
              ),
            ),
            ...data.safeZones.map(
              (s) => MapPoint.fromMap(
                s,
                latKey: 'latitude',
                lngKey: 'longitude',
                labelKey: 'name',
                type: MapPointType.safeZone,
              ),
            ),
          ],
        ),
        const SectionHeader(icon: Icons.sos, title: 'Cần phân công'),
        if (pendingRequests.isEmpty)
          const EmptyCard(
            icon: Icons.check_circle,
            message: 'Không còn yêu cầu chờ phân công',
          )
        else
          ...pendingRequests.map(
            (r) => RequestCard(
              request: r,
              actions: [
                if (['VERIFYING', 'SUSPICIOUS'].contains(valueOf(r, 'status')))
                  TextButton.icon(
                    onPressed: () => updateRequestTriageFromAdmin(
                      context,
                      api,
                      valueOf(r, 'id'),
                      'VERIFIED',
                      onChanged,
                    ),
                    icon: const Icon(Icons.verified),
                    label: const Text('Đã xác minh'),
                  ),
                if (valueOf(r, 'status') == 'VERIFYING')
                  TextButton.icon(
                    onPressed: () => updateRequestTriageFromAdmin(
                      context,
                      api,
                      valueOf(r, 'id'),
                      'SUSPICIOUS',
                      onChanged,
                    ),
                    icon: const Icon(Icons.report),
                    label: const Text('Nghi ngờ'),
                  ),
                if (['VERIFYING', 'SUSPICIOUS'].contains(valueOf(r, 'status')))
                  TextButton.icon(
                    onPressed: () => updateRequestTriageFromAdmin(
                      context,
                      api,
                      valueOf(r, 'id'),
                      'SPAM',
                      onChanged,
                    ),
                    icon: const Icon(Icons.block),
                    label: const Text('Tin rác'),
                  ),
                if (data.teams.isNotEmpty &&
                    ['VERIFIED', 'PENDING'].contains(valueOf(r, 'status'))) ...[
                  if (availableTeams.isEmpty)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Palette.warning,
                      ),
                      onPressed: () async {
                        // Vẫn cho phép chọn nhưng hiển thị cảnh báo trước
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Đội đang bận'),
                            content: const Text(
                              'Hiện không có đội nào sẵn sàng. Phân công sẽ gửi cho đội đang bận.\n\nBạn có muốn tiếp tục không?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Hủy'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Tiếp tục'),
                              ),
                            ],
                          ),
                        );
                        if (ok != true) return;
                        if (!context.mounted) return;
                        final team = await pickRescueTeam(context, data.teams);
                        if (team == null) return;
                        await api.assignTeam(valueOf(r, 'id'), team, user);
                        await onChanged();
                      },
                      icon: const Icon(Icons.assignment_turned_in),
                      label: const Text('Phân công (cảnh báo)'),
                    )
                  else
                    TextButton.icon(
                      onPressed: () async {
                        final team = await pickRescueTeam(
                          context,
                          availableTeams,
                        );
                        if (team == null) return;
                        await api.assignTeam(valueOf(r, 'id'), team, user);
                        await onChanged();
                      },
                      icon: const Icon(Icons.assignment_turned_in),
                      label: const Text('Phân công nhanh'),
                    ),
                ],
              ],
            ),
          ),
        const SectionHeader(
          icon: Icons.navigation,
          title: 'Nhiệm vụ đang điều phối',
        ),
        if (activeMissions.isEmpty)
          const EmptyCard(
            icon: Icons.assignment,
            message: 'Chưa có nhiệm vụ đang chạy',
          )
        else
          ...activeMissions.map((m) => MissionCard(mission: m)),
      ],
    );
  }
}
