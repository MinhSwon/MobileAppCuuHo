import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/core/core.dart';

Future<Map<String, dynamic>?> pickRescueTeam(BuildContext context, List<Map<String, dynamic>> teams) {
  final ordered = [...teams]..sort((a, b) {
      final aReady = valueOf(a, 'status') == 'AVAILABLE' ? 0 : 1;
      final bReady = valueOf(b, 'status') == 'AVAILABLE' ? 0 : 1;
      return aReady.compareTo(bReady);
    });
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const PageTitle('Chọn đội cứu hộ', 'Ưu tiên đội đang sẵn sàng và gần khu vực sự cố'),
          const SizedBox(height: 10),
          if (ordered.isEmpty)
            const EmptyCard(icon: Icons.groups, message: 'Chưa có đội cứu hộ')
          else
            ...ordered.map((team) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CardBox(
                    child: InkWell(
                      onTap: () => Navigator.pop(context, team),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.groups, color: Palette.success),
                              const SizedBox(width: 8),
                              Expanded(child: Text(valueOf(team, 'team_name'), style: const TextStyle(fontWeight: FontWeight.w900))),
                              StatusBadge(status: valueOf(team, 'status')),
                            ],
                          ),
                          const SizedBox(height: 8),
                          InfoRow('Trưởng đội', valueOf(team, 'leader_name', fallback: '-')),
                          InfoRow('Điện thoại', valueOf(team, 'phone', fallback: '-')),
                          InfoRow('Thành viên', '${valueOf(team, 'member_count', fallback: '0')} người'),
                        ],
                      ),
                    ),
                  ),
                )),
        ],
      ),
    ),
  );
}

Future<bool> confirmAction(BuildContext context, String title, String message) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xác nhận')),
          ],
        ),
      ) ??
      false;
}
