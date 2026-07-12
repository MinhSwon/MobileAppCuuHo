import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/core/core.dart';
import 'package:mobile_flutter/data/data.dart';
import 'package:mobile_flutter/features/admin/presentation/settings/edit_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.api,
    required this.user,
    this.profile,
    this.darkMode = false,
    this.onToggleTheme,
    this.onRefresh,
  });

  final ApiClient api;
  final Map<String, dynamic> user;
  final Map<String, dynamic>? profile;
  final bool darkMode;
  final Future<void> Function()? onToggleTheme;
  final Future<void> Function()? onRefresh;

  bool get isAdmin => ['ADMIN', 'SUPER_ADMIN'].contains(valueOf(user, 'role'));

  @override
  Widget build(BuildContext context) {
    final name = valueOf(user, 'full_name', fallback: '?');
    return AppList(
      children: [
        const PageTitle('Cài đặt tài khoản', 'Thông tin đăng nhập và hồ sơ'),
        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Palette.accent,
                    child: Text(name.characters.first),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InfoRow('Email', valueOf(user, 'email', fallback: '-')),
              InfoRow('Điện thoại', valueOf(user, 'phone', fallback: '-')),
              InfoRow('Vai trò', valueOf(user, 'role', fallback: '-')),
              InfoRow(
                'Trạng thái',
                valueOf(user, 'status', fallback: 'ACTIVE'),
              ),
              InfoRow('Mã tài khoản', valueOf(user, 'id', fallback: '-')),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(
                      api: api,
                      user: user,
                      profile: profile,
                      onSaved: onRefresh ?? () async {},
                    ),
                  ),
                ),
                icon: const Icon(Icons.edit),
                label: const Text('Chỉnh sửa hồ sơ & Đổi mật khẩu'),
              ),
              if (onRefresh != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.sync),
                  label: const Text('Đồng bộ lại hồ sơ'),
                ),
              ],
            ],
          ),
        ),
        CardBox(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(darkMode ? Icons.dark_mode : Icons.light_mode),
            title: const Text('Giao diện tối'),
            subtitle: const Text('Chuyển nhanh giữa nền sáng và nền tối'),
            value: darkMode,
            onChanged: onToggleTheme == null ? null : (_) => onToggleTheme!(),
          ),
        ),
        if (profile != null && profile!.isNotEmpty) ...[
          const SectionHeader(icon: Icons.badge, title: 'Hồ sơ người dân'),
          CardBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoRow(
                  'Khu vực',
                  valueOf(
                    profile,
                    'area_name',
                    fallback: valueOf(profile, 'area_id', fallback: '-'),
                  ),
                ),
                InfoRow(
                  'Địa chỉ',
                  valueOf(profile, 'address_detail', fallback: '-'),
                ),
                InfoRow(
                  'Số người',
                  valueOf(profile, 'household_size', fallback: '-'),
                ),
                InfoRow(
                  'Người già',
                  valueOf(profile, 'elderly_count', fallback: '0'),
                ),
                InfoRow(
                  'Trẻ em',
                  valueOf(profile, 'children_count', fallback: '0'),
                ),
                InfoRow(
                  'Khuyết tật',
                  valueOf(profile, 'disabled_count', fallback: '0'),
                ),
              ],
            ),
          ),
        ],
        if (isAdmin) ...[
          const SectionHeader(
            icon: Icons.cloud_done,
            title: 'Hạ tầng production',
          ),
          FutureBuilder<Map<String, dynamic>>(
            future: api.fetchNotificationProviderStatus(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CardBox(
                  child: Center(
                    child: CircularProgressIndicator(color: Palette.accent),
                  ),
                );
              }
              if (snapshot.hasError) {
                return CardBox(
                  child: Text(
                    'Không đọc được trạng thái provider: ${snapshot.error}',
                    style: const TextStyle(color: Palette.danger),
                  ),
                );
              }
              final status = snapshot.data ?? {};
              final push = mapOf(status['push']);
              final sms = mapOf(status['sms']);
              return CardBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoRow(
                      'Push FCM',
                      valueOf(push, 'configured') == 'true'
                          ? 'Đã cấu hình'
                          : 'Chưa cấu hình',
                    ),
                    InfoRow(
                      'SMS',
                      valueOf(sms, 'configured') == 'true'
                          ? 'Đã cấu hình ${valueOf(sms, 'provider')}'
                          : 'Chưa cấu hình',
                    ),
                    InfoRow(
                      'Device token',
                      valueOf(status, 'registeredDeviceTokens', fallback: '0'),
                    ),
                    Text(
                      'Endpoint readiness: /api/readiness',
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
