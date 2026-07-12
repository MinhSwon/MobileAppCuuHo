import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/core/core.dart';
import 'package:mobile_flutter/data/data.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.api, required this.user});
  final ApiClient api;
  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    return AppList(
      children: [
        const PageTitle('Cài đặt tài khoản', 'Thông tin đăng nhập và phân quyền'),
        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                CircleAvatar(backgroundColor: Palette.accent, child: Text(valueOf(user, 'full_name', fallback: '?').characters.first)),
                const SizedBox(width: 12),
                Expanded(child: Text(valueOf(user, 'full_name'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
              ]),
              const SizedBox(height: 12),
              InfoRow('Email', valueOf(user, 'email')),
              InfoRow('Điện thoại', valueOf(user, 'phone')),
              InfoRow('Vai trò', valueOf(user, 'role')),
              InfoRow('Trạng thái', valueOf(user, 'status', fallback: 'ACTIVE')),
            ],
          ),
        ),
        const SectionHeader(icon: Icons.cloud_done, title: 'Hạ tầng production'),
        FutureBuilder<Map<String, dynamic>>(
          future: api.fetchNotificationProviderStatus(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CardBox(child: Center(child: CircularProgressIndicator(color: Palette.accent)));
            }
            if (snapshot.hasError) {
              return CardBox(child: Text('Không đọc được trạng thái provider: ${snapshot.error}', style: const TextStyle(color: Palette.danger)));
            }
            final status = snapshot.data ?? {};
            final push = mapOf(status['push']);
            final sms = mapOf(status['sms']);
            return CardBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoRow('Push FCM', valueOf(push, 'configured') == 'true' ? 'Đã cấu hình' : 'Chưa cấu hình'),
                  InfoRow('SMS', valueOf(sms, 'configured') == 'true' ? 'Đã cấu hình ${valueOf(sms, 'provider')}' : 'Chưa cấu hình'),
                  InfoRow('Device token', valueOf(status, 'registeredDeviceTokens', fallback: '0')),
                  Text('Endpoint readiness: /api/readiness', style: const TextStyle(color: Palette.muted, fontSize: 12)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
