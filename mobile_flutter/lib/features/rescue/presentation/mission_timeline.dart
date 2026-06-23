import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/core/core.dart';

class MissionTimeline extends StatelessWidget {
  const MissionTimeline({super.key, required this.logs, required this.currentStatus});

  final List<Map<String, dynamic>> logs;
  final String currentStatus;

  @override
  Widget build(BuildContext context) {
    final items = logs.isEmpty
        ? [
            {
              'new_status': currentStatus,
              'note': 'Trạng thái hiện tại',
              'created_at': '',
            }
          ]
        : logs;

    return CardBox(
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            _TimelineRow(
              log: items[i],
              isLast: i == items.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.log, required this.isLast});

  final Map<String, dynamic> log;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final status = valueOf(log, 'new_status');
    final color = statusColor(status);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            if (!isLast) Container(width: 2, height: 42, color: Palette.border),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(statusLabel(status), style: TextStyle(color: color, fontWeight: FontWeight.w900)),
                if (valueOf(log, 'note').isNotEmpty) Text(valueOf(log, 'note'), style: const TextStyle(color: Palette.secondary)),
                if (valueOf(log, 'created_at').isNotEmpty) Text(formatDate(valueOf(log, 'created_at')), style: const TextStyle(color: Palette.muted, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
