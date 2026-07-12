import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/core/core.dart';
import 'package:mobile_flutter/data/data.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key, required this.data});
  final AppData data;

  @override
  Widget build(BuildContext context) {
    final pending = data.requests.where((r) => r['status'] == 'PENDING').length;
    final done = data.requests.where((r) => ['RESCUED', 'TRANSFERRED_SAFEZONE'].contains(r['status'])).length;
    return AppList(
      children: [
        const PageTitle('Thống kê & Báo cáo', 'Bản mobile của dashboard biểu đồ trong React'),
        GridStats(items: [
          StatItem('Yêu cầu', '${data.requests.length}', Icons.sos, Palette.danger),
          StatItem('Đang chờ', '$pending', Icons.schedule, Palette.warning),
          StatItem('Hoàn tất', '$done', Icons.check_circle, Palette.success),
          StatItem('Cảnh báo', '${data.warnings.length}', Icons.campaign, Palette.accent),
        ]),
        const SectionHeader(icon: Icons.bar_chart, title: 'Theo khu vực'),
        ...data.areas.map((a) {
          final count = data.requests.where((r) => valueOf(r, 'area_id') == valueOf(a, 'id')).length;
          return CardBox(
            child: Row(
              children: [
                Expanded(child: Text(valueOf(a, 'old_name'), style: const TextStyle(fontWeight: FontWeight.w800))),
                BadgePill(label: '$count yêu cầu', bg: Palette.accentLight, fg: Palette.accent),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class ActivityLogsScreen extends StatelessWidget {
  const ActivityLogsScreen({super.key, required this.data});
  final AppData data;

  @override
  Widget build(BuildContext context) {
    return AppList(
      children: [
        const PageTitle('Nhật ký hoạt động', 'Lịch sử thao tác trong hệ thống'),
        if (data.activityLogs.isEmpty)
          const EmptyCard(icon: Icons.history, message: 'Chưa có nhật ký')
        else
          ...data.activityLogs.map((l) => CardBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(valueOf(l, 'action'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text('${valueOf(l, 'user_name', fallback: 'SYSTEM')} · ${formatDate(valueOf(l, 'created_at'))}', style: const TextStyle(color: Palette.muted, fontSize: 12)),
                    Text(valueOf(l, 'note'), style: const TextStyle(color: Palette.secondary)),
                  ],
                ),
              )),
      ],
    );
  }
}

class AIAssistantScreen extends StatelessWidget {
  const AIAssistantScreen({super.key, required this.data});
  final AppData data;

  @override
  Widget build(BuildContext context) {
    final urgent = data.requests.where((r) => ['HIGH', 'EMERGENCY'].contains(r['emergency_level']) && r['status'] == 'PENDING').toList();
    return AppList(
      children: [
        const PageTitle('AI Trợ lý', 'Gợi ý ưu tiên điều phối dựa trên dữ liệu hiện có'),
        AlertPanel(
          title: 'Gợi ý ưu tiên',
          message: urgent.isEmpty ? 'Không có yêu cầu khẩn cấp đang chờ.' : 'Nên ưu tiên ${valueOf(urgent.first, 'full_name')} tại ${valueOf(urgent.first, 'area_name')}.',
          color: urgent.isEmpty ? Palette.success : Palette.danger,
          icon: Icons.smart_toy,
        ),
        const SectionHeader(icon: Icons.tips_and_updates, title: 'Khuyến nghị vận hành'),
        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoRow('Đội sẵn sàng', '${data.teams.where((t) => t['status'] == 'AVAILABLE').length} đội'),
              InfoRow('Điểm còn chỗ', '${data.safeZones.where((s) => s['status'] == 'AVAILABLE').length} điểm'),
              InfoRow('Cảnh báo đang phát', '${data.warnings.where((w) => w['status'] == 'PUBLISHED').length} cảnh báo'),
            ],
          ),
        ),
      ],
    );
  }
}
