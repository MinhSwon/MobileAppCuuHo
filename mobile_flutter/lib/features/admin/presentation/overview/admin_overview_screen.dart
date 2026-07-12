import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/core/core.dart';
import 'package:mobile_flutter/data/data.dart';
import 'package:mobile_flutter/features/admin/presentation/shared/admin_dialogs.dart';

Future<void> updateRequestTriageFromAdmin(
  BuildContext context,
  ApiClient api,
  String requestId,
  String status,
  Future<void> Function() onChanged,
) async {
  // Các trạng thái nghiêm trọng cần xác nhận + lý do
  final needsReason = ['SUSPICIOUS', 'SPAM', 'FALSE_ALARM'].contains(status);

  String? reason;
  if (needsReason) {
    reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final reasonCtrl = TextEditingController();
        final isSpam = status == 'SPAM' || status == 'FALSE_ALARM';
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isSpam ? Icons.block : Icons.report_problem,
                color: isSpam ? Palette.danger : Palette.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSpam ? 'Xác nhận đánh dấu tin rác?' : 'Đánh dấu nghi ngờ?',
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSpam
                    ? 'Yêu cầu này sẽ bị loại khỏi danh sách xử lý và KHÔNG được phân công đội cứu hộ.\n\n⚠️ Hành động này có thể ảnh hưởng đến tính mạng nếu đánh giá sai.\n\nVui lòng ghi rõ lý do:'
                    : 'Yêu cầu sẽ được gắn cờ nghi ngờ để điều tra thêm trước khi phân công.\n\nVui lòng ghi rõ lý do nghi ngờ:',
                style: const TextStyle(height: 1.4),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Lý do *',
                  hintText: isSpam
                      ? 'VD: SĐT trùng với SOS giả trước đó, mô tả mâu thuẫn...'
                      : 'VD: GPS ngoài vùng lũ, SĐT mới, thông tin thiếu...',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSpam ? Palette.danger : Palette.warning,
              ),
              onPressed: () {
                if (reasonCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập lý do')),
                  );
                  return;
                }
                Navigator.pop(ctx, reasonCtrl.text.trim());
              },
              child: Text(isSpam ? 'Xác nhận loại bỏ' : 'Đánh dấu nghi ngờ'),
            ),
          ],
        );
      },
    );
    if (reason == null || reason.isEmpty) return; // Người dùng bấm Hủy
  } else if (status == 'VERIFIED') {
    // Xác minh — không cần lý do nhưng nên xác nhận
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.verified, color: Palette.success),
            SizedBox(width: 8),
            Text('Xác nhận đã xác minh?'),
          ],
        ),
        content: const Text(
          'Yêu cầu này sẽ được chuyển sang trạng thái ĐÃ XÁC MINH và có thể phân công đội cứu hộ ngay.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Palette.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (ok != true) return;
  }

  final note = reason != null
      ? 'Điều phối viên: $reason'
      : 'Cập nhật từ quản trị viên di động';

  await api.updateRequestTriage(requestId, status, note: note);
  await onChanged();
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã cập nhật ${statusLabel(status)}')),
    );
  }
}

class AdminHome extends StatelessWidget {
  const AdminHome({super.key, required this.user, required this.data});
  final Map<String, dynamic> user;
  final AppData data;

  @override
  Widget build(BuildContext context) {
    final pending = data.requests.where((r) => r['status'] == 'PENDING').length;
    final processing = data.requests
        .where(
          (r) => [
            'ASSIGNED',
            'ACCEPTED',
            'MOVING',
            'NEAR_VICTIM',
            'ARRIVED_CONFIRMED',
            'RESCUING',
          ].contains(r['status']),
        )
        .length;
    final rescued = data.requests
        .where((r) => ['RESCUED', 'TRANSFERRED_SAFEZONE'].contains(r['status']))
        .length;
    final latestRequests = [...data.requests]
      ..sort((a, b) {
        final aTime = DateTime.tryParse(valueOf(a, 'created_at'));
        final bTime = DateTime.tryParse(valueOf(b, 'created_at'));
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });
    return AppList(
      children: [
        PageTitle(
          'Chào mừng, ${valueOf(user, 'full_name')}',
          'Bảng điều phối cứu hộ trên di động',
        ),
        GridStats(
          items: [
            StatItem(
              'Người dân',
              '${data.profiles.length}',
              Icons.people,
              Palette.accent,
            ),
            StatItem(
              'Hộ ưu tiên',
              '${data.households.length}',
              Icons.shield,
              Palette.warning,
            ),
            StatItem(
              'Đội sẵn sàng',
              '${data.availableTeams.length}/${data.teams.length}',
              Icons.groups,
              Palette.success,
            ),
            StatItem(
              'Cảnh báo',
              '${data.activeWarnings.length}',
              Icons.campaign,
              Palette.warning,
            ),
            StatItem(
              'Chờ tiếp nhận',
              '$pending',
              Icons.schedule,
              Palette.danger,
            ),
            StatItem('Đang xử lý', '$processing', Icons.sync, Palette.accent),
            StatItem('Đã cứu', '$rescued', Icons.check_circle, Palette.success),
            StatItem(
              'SMS đã gửi',
              '${data.sms.where((s) => s['status'] == 'SENT').length}',
              Icons.sms,
              Palette.secondary,
            ),
          ],
        ),
        const SectionHeader(icon: Icons.sos, title: 'Yêu cầu mới nhất'),
        ...latestRequests.take(5).map((r) => RequestCard(request: r)),
      ],
    );
  }
}

class AdminRequests extends StatelessWidget {
  const AdminRequests({
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
    return AppList(
      children: [
        const PageTitle(
          'Yêu cầu cứu hộ',
          'Danh sách dạng thẻ tối ưu cho di động',
        ),
        ...data.requests.map(
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
              if (r['assigned_team_id'] == null &&
                  data.teams.isNotEmpty &&
                  ['VERIFIED', 'PENDING'].contains(valueOf(r, 'status')))
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
          ),
        ),
      ],
    );
  }
}
