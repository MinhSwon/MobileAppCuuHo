import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/core/core.dart';
import 'package:mobile_flutter/data/data.dart';

class CitizenHome extends StatelessWidget {
  const CitizenHome({super.key, required this.user, required this.profile, required this.data});

  final Map<String, dynamic> user;
  final Map<String, dynamic>? profile;
  final AppData data;

  @override
  Widget build(BuildContext context) {
    final activeWarnings = data.warnings.where((w) => w['status'] == 'PUBLISHED').toList();
    final userId = valueOf(user, 'id');
    final userPhone = valueOf(user, 'phone');
    final myRequests = data.requests.where((r) {
      return valueOf(r, 'user_id') == userId ||
          valueOf(r, 'created_by_user_id') == userId ||
          valueOf(r, 'phone') == userPhone;
    }).toList();
    final areaId = valueOf(profile, 'area_id');
    final areaName = areaId.isEmpty ? 'Toàn bộ Việt Nam' : valueOf(firstWhere(data.areas, 'id', areaId), 'old_name', fallback: 'Việt Nam');
    final nearSafeZones = data.safeZones.where((s) => areaId.isEmpty || valueOf(s, 'area_id') == areaId).toList();
    final emergency = activeWarnings.where((w) => w['level'] == 'EMERGENCY').toList();

    return AppList(
      children: [
        PageTitle('Xin chào, ${valueOf(user, 'full_name')}', 'Vị trí: $areaName'),
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
          title: 'Gửi yêu cầu cứu hộ',
          subtitle: 'Cần hỗ trợ khẩn cấp',
        ),
        ActionCard(
          color: Palette.warning,
          icon: Icons.campaign,
          title: 'Cảnh báo đang hoạt động',
          subtitle: '${activeWarnings.length} cảnh báo cần theo dõi',
        ),
        ActionCard(
          color: Palette.accent,
          icon: Icons.shield,
          title: 'Điểm sơ tán gần nhất',
          subtitle: '${nearSafeZones.where((s) => s['status'] == 'AVAILABLE').length} điểm còn chỗ',
        ),
        const SectionHeader(icon: Icons.assignment, title: 'Yêu cầu của tôi'),
        if (myRequests.isEmpty)
          const EmptyCard(icon: Icons.check_circle, message: 'Bạn chưa có yêu cầu cứu hộ nào')
        else
          ...myRequests.map((r) => RequestCard(request: r)),
        const SectionHeader(icon: Icons.phone, title: 'Số khẩn cấp'),
        Row(
          children: const [
            Expanded(child: PhoneCard(label: 'Cứu hộ', phone: '114')),
            SizedBox(width: 10),
            Expanded(child: PhoneCard(label: 'Cấp cứu', phone: '115')),
          ],
        ),
      ],
    );
  }
}
