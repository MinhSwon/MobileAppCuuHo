import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/core/core.dart';
import 'package:mobile_flutter/data/data.dart';

class SmsLogsScreen extends StatelessWidget {
  const SmsLogsScreen({super.key, required this.data});
  final AppData data;

  @override
  Widget build(BuildContext context) {
    return AppList(
      children: [
        const PageTitle('SMS cảnh báo', 'Nhật ký tin nhắn đã gửi qua hệ thống'),
        if (data.sms.isEmpty)
          const EmptyCard(icon: Icons.sms, message: 'Chưa có SMS')
        else
          ...data.sms.map(
            (s) => CardBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sms, color: Palette.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          valueOf(s, 'phone'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      StatusBadge(status: valueOf(s, 'status')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    valueOf(s, 'message'),
                    style: const TextStyle(
                      color: Palette.secondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${valueOf(s, 'provider', fallback: 'SMS')} · ${formatDate(valueOf(s, 'sent_at'))}',
                    style: const TextStyle(color: Palette.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class CoastalWarningsScreen extends StatelessWidget {
  const CoastalWarningsScreen({super.key, required this.data});
  final AppData data;

  @override
  Widget build(BuildContext context) {
    final high = data.warnings
        .where((w) => ['HIGH', 'EMERGENCY'].contains(w['level']))
        .toList();
    return AppList(
      children: [
        const PageTitle(
          'Cảnh báo thiên tai & sự cố',
          'Bản di động của mục cảnh báo ven biển và cảnh báo tổng hợp',
        ),
        AlertPanel(
          title: 'Theo dõi nguy cơ cao',
          message: '${high.length} cảnh báo mức cao hoặc khẩn cấp',
          color: Palette.warning,
          icon: Icons.anchor,
        ),
        ...data.warnings.map((w) => WarningCard(warning: w)),
      ],
    );
  }
}
