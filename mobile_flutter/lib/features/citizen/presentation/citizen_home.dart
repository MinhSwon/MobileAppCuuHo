import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/core/core.dart';
import 'package:mobile_flutter/data/data.dart';
import 'package:mobile_flutter/features/chat/chat.dart';

class CitizenHome extends StatelessWidget {
  const CitizenHome({
    super.key,
    required this.api,
    required this.user,
    required this.profile,
    required this.data,
    required this.onSelectTab,
  });

  final ApiClient api;
  final Map<String, dynamic> user;
  final Map<String, dynamic>? profile;
  final AppData data;
  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final activeWarnings = data.warnings
        .where((w) => w['status'] == 'PUBLISHED')
        .toList();
    final userId = valueOf(user, 'id');
    final userPhone = valueOf(user, 'phone');
    final myRequests =
        data.requests.where((r) {
          return valueOf(r, 'user_id') == userId ||
              valueOf(r, 'created_by_user_id') == userId ||
              valueOf(r, 'phone') == userPhone;
        }).toList()..sort((a, b) {
          final aTime = DateTime.tryParse(valueOf(a, 'created_at'));
          final bTime = DateTime.tryParse(valueOf(b, 'created_at'));
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });
    final areaId = valueOf(profile, 'area_id');
    final areaName = areaId.isEmpty
        ? 'Toàn bộ Việt Nam'
        : valueOf(
            firstWhere(data.areas, 'id', areaId),
            'old_name',
            fallback: 'Việt Nam',
          );
    final nearSafeZones = data.safeZones
        .where((s) => areaId.isEmpty || valueOf(s, 'area_id') == areaId)
        .toList();
    final emergency = activeWarnings
        .where((w) => w['level'] == 'EMERGENCY')
        .toList();

    return AppList(
      children: [
        PageTitle(
          'Xin chào, ${valueOf(user, 'full_name')}',
          'Vị trí: $areaName',
        ),
        if (emergency.isNotEmpty)
          AlertPanel(
            title: 'CẢNH BÁO KHẨN CẤP TRONG KHU VỰC',
            message: valueOf(emergency.first, 'title'),
            color: Palette.danger,
            icon: Icons.warning_amber,
          ),
        const SectionHeader(icon: Icons.flash_on, title: 'Hành động nhanh'),
        ActionCard(
          color: Palette.danger,
          icon: Icons.sos,
          onTap: () => onSelectTab(1),
          title: 'Gửi yêu cầu cứu hộ',
          subtitle: 'Cần hỗ trợ khẩn cấp',
        ),
        ActionCard(
          color: Palette.warning,
          icon: Icons.campaign,
          onTap: () => onSelectTab(4),
          title: 'Cảnh báo đang hoạt động',
          subtitle: '${activeWarnings.length} cảnh báo cần theo dõi',
        ),
        ActionCard(
          color: Palette.accent,
          icon: Icons.shield,
          onTap: () => onSelectTab(5),
          title: 'Điểm sơ tán gần nhất',
          subtitle:
              '${nearSafeZones.where((s) => s['status'] == 'AVAILABLE').length} điểm còn chỗ',
        ),
        const SectionHeader(icon: Icons.assignment, title: 'Yêu cầu của tôi'),
        if (myRequests.isEmpty)
          const EmptyCard(
            icon: Icons.check_circle,
            message: 'Bạn chưa có yêu cầu cứu hộ nào',
          )
        else
          ...myRequests.map((r) {
            final isAssigned = valueOf(r, 'assigned_team_id').isNotEmpty;
            return RequestCard(
              request: r,
              actions: [
                TextButton.icon(
                  onPressed: !isAssigned
                      ? null
                      : () {
                          final messages = data.chatMessages
                              .where(
                                (m) =>
                                    valueOf(m, 'request_id') ==
                                    valueOf(r, 'id'),
                              )
                              .toList();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RequestChatScreen(
                                api: api,
                                user: user,
                                request: r,
                                initialMessages: messages,
                                onChanged: () async {},
                              ),
                            ),
                          );
                        },
                  icon: Icon(isAssigned ? Icons.chat : Icons.lock),
                  label: Text(
                    isAssigned ? 'Chat cứu hộ' : 'Chờ admin phân công',
                  ),
                ),
              ],
            );
          }),
        const SectionHeader(icon: Icons.phone, title: 'Số khẩn cấp'),
        Row(
          children: const [
            Expanded(
              child: PhoneCard(label: 'Cứu hộ', phone: '114'),
            ),
            SizedBox(width: 10),
            Expanded(
              child: PhoneCard(label: 'Cấp cứu', phone: '115'),
            ),
          ],
        ),
      ],
    );
  }
}
