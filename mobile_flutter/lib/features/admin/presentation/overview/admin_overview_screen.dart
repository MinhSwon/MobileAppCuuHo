import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/core/core.dart';
import 'package:mobile_flutter/data/data.dart';
import 'package:mobile_flutter/features/admin/presentation/shared/admin_dialogs.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key, required this.user, required this.data});
  final Map<String, dynamic> user;
  final AppData data;

  @override
  Widget build(BuildContext context) {
    final pending = data.requests.where((r) => r['status'] == 'PENDING').length;
    final processing = data.requests.where((r) => ['ASSIGNED', 'ACCEPTED', 'MOVING', 'NEAR_VICTIM', 'ARRIVED_CONFIRMED', 'RESCUING'].contains(r['status'])).length;
    final rescued = data.requests.where((r) => ['RESCUED', 'TRANSFERRED_SAFEZONE'].contains(r['status'])).length;
    return AppList(
      children: [
        PageTitle('Chào mừng, ${valueOf(user, 'full_name')}', 'Bảng điều phối cứu hộ mobile'),
        GridStats(items: [
          StatItem('Người dân', '${data.profiles.length}', Icons.people, Palette.accent),
          StatItem('Hộ ưu tiên', '${data.households.length}', Icons.shield, Palette.warning),
          StatItem('Đội sẵn sàng', '${data.teams.where((t) => t['status'] == 'AVAILABLE').length}/${data.teams.length}', Icons.groups, Palette.success),
          StatItem('Cảnh báo', '${data.warnings.where((w) => w['status'] == 'PUBLISHED').length}', Icons.campaign, Palette.warning),
          StatItem('Chờ tiếp nhận', '$pending', Icons.schedule, Palette.danger),
          StatItem('Đang xử lý', '$processing', Icons.sync, Palette.accent),
          StatItem('Đã cứu', '$rescued', Icons.check_circle, Palette.success),
          StatItem('SMS đã gửi', '${data.sms.where((s) => s['status'] == 'SENT').length}', Icons.sms, Palette.secondary),
        ]),
        const SectionHeader(icon: Icons.sos, title: 'Yêu cầu mới nhất'),
        ...data.requests.take(5).map((r) => RequestCard(request: r)),
      ],
    );
  }
}

class AdminRequests extends StatelessWidget {
  const AdminRequests({super.key, required this.api, required this.user, required this.data, required this.onChanged});
  final ApiClient api;
  final Map<String, dynamic> user;
  final AppData data;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    return AppList(
      children: [
        const PageTitle('Yêu cầu cứu hộ', 'Danh sách dạng card tối ưu cho mobile'),
        ...data.requests.map((r) => RequestCard(
              request: r,
              actions: [
                if (r['assigned_team_id'] == null && data.teams.isNotEmpty)
                  TextButton.icon(
                    onPressed: () async {
                      final team = await pickRescueTeam(context, data.teams);
                      if (team == null) return;
                      await api.assignTeam(valueOf(r, 'id'), team, user);
                      await onChanged();
                    },
                    icon: const Icon(Icons.assignment_turned_in),
                    label: const Text('Phân công đội'),
                  ),
              ],
            )),
      ],
    );
  }
}
