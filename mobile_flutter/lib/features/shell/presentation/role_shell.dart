import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/data/data.dart';
import 'package:mobile_flutter/features/admin/admin.dart';
import 'package:mobile_flutter/features/chat/chat.dart';
import 'package:mobile_flutter/features/citizen/citizen.dart';
import 'package:mobile_flutter/features/rescue/rescue.dart';
import 'package:mobile_flutter/features/shell/presentation/app_drawer.dart';
import 'package:mobile_flutter/features/shell/presentation/app_menu_item.dart';

class RoleShell extends StatefulWidget {
  const RoleShell({
    super.key,
    required this.api,
    required this.user,
    required this.profile,
    required this.db,
    required this.darkMode,
    required this.onToggleTheme,
    required this.onRefresh,
    required this.onLogout,
  });

  final ApiClient api;
  final Map<String, dynamic> user;
  final Map<String, dynamic>? profile;
  final Map<String, dynamic> db;
  final bool darkMode;
  final Future<void> Function() onToggleTheme;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLogout;

  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell> {
  int tab = 0;

  bool get isAdmin =>
      ['ADMIN', 'SUPER_ADMIN', 'DISPATCHER'].contains(widget.user['role']);
  bool get isRescue =>
      ['RESCUE_LEADER', 'RESCUE_MEMBER'].contains(widget.user['role']);

  List<AppMenuItem> get menuItems {
    if (isAdmin) {
      return const [
        AppMenuItem('Tổng quan', Icons.dashboard, 'Tổng quan'),
        AppMenuItem('Trung tâm điều phối', Icons.navigation, 'Tổng quan'),
        AppMenuItem('Hộp thư điều phối', Icons.chat, 'Tin nhắn'),
        AppMenuItem('Quản lý cảnh báo', Icons.campaign, 'Cảnh báo'),
        AppMenuItem('SMS cảnh báo', Icons.sms, 'SMS'),
        AppMenuItem('Cảnh báo thiên tai', Icons.anchor, 'Cảnh báo'),
        AppMenuItem('Yêu cầu cứu hộ', Icons.sos, 'Cứu hộ'),
        AppMenuItem('Nhiệm vụ cứu hộ', Icons.assignment, 'Nhiệm vụ'),
        AppMenuItem('Đội cứu hộ', Icons.groups, 'Đội'),
        AppMenuItem('Người dân', Icons.people, 'Cộng đồng'),
        AppMenuItem('Hộ dễ tổn thương', Icons.home, 'Hộ dân'),
        AppMenuItem('Điểm sơ tán', Icons.apartment, 'Sơ tán'),
        AppMenuItem('Tuyến đường cứu hộ', Icons.route, 'Tuyến'),
        AppMenuItem('Đập/Hồ chứa', Icons.water_drop, 'Đập'),
        AppMenuItem('Báo cáo thiệt hại', Icons.description, 'Thiệt hại'),
        AppMenuItem('Thống kê & Báo cáo', Icons.bar_chart, 'Báo cáo'),
        AppMenuItem('Nhật ký hoạt động', Icons.history, 'Nhật ký'),
        AppMenuItem('Trợ lý AI', Icons.smart_toy, 'AI'),
        AppMenuItem('Cài đặt tài khoản', Icons.settings, 'Cài đặt'),
      ];
    }

    if (isRescue) {
      return const [
        AppMenuItem('Bảng điều khiển cứu hộ', Icons.dashboard, 'Đội cứu hộ'),
        AppMenuItem('Nhiệm vụ được giao', Icons.assignment, 'Nhiệm vụ'),
        AppMenuItem('Tin nhắn', Icons.chat, 'Tin nhắn'),
        AppMenuItem('Chatbot AI', Icons.smart_toy, 'AI'),
        AppMenuItem('Cảnh báo khẩn cấp', Icons.campaign, 'Cảnh báo'),
        AppMenuItem('Cài đặt tài khoản', Icons.settings, 'Cài đặt'),
      ];
    }

    return const [
      AppMenuItem('Trang chủ', Icons.home, 'Trang chủ'),
      AppMenuItem('Gửi yêu cầu cứu hộ', Icons.sos, 'SOS'),
      AppMenuItem('Tin nhắn', Icons.chat, 'Tin nhắn'),
      AppMenuItem('Chatbot AI', Icons.smart_toy, 'AI'),
      AppMenuItem('Cảnh báo khẩn cấp', Icons.campaign, 'Cảnh báo'),
      AppMenuItem('Điểm sơ tán', Icons.shield, 'Sơ tán'),
      AppMenuItem('Cài đặt tài khoản', Icons.settings, 'Cài đặt'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = menuItems;
    final quickItems = items.take(4).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(items[tab].label),
        actions: [
          IconButton(
            tooltip: 'Làm mới dữ liệu',
            onPressed: widget.onRefresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: widget.darkMode
                ? 'Chuyển giao diện sáng'
                : 'Chuyển giao diện tối',
            onPressed: widget.onToggleTheme,
            icon: Icon(widget.darkMode ? Icons.light_mode : Icons.dark_mode),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: AppDrawer(
        title: isRescue ? 'ĐỘI CỨU HỘ' : 'CỨU HỘ VIỆT NAM',
        subtitle: isAdmin
            ? 'Ứng dụng toàn quốc'
            : isRescue
            ? 'Nhiệm vụ toàn quốc'
            : 'Cổng người dân',
        user: widget.user,
        items: items,
        selected: tab,
        onSelect: (index) => setState(() => tab = index),
        onLogout: widget.onLogout,
      ),
      body: RefreshIndicator(onRefresh: widget.onRefresh, child: _content()),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tab < quickItems.length ? tab : 0,
        items: quickItems
            .map(
              (item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                label: item.shortLabel,
              ),
            )
            .toList(),
        onTap: (value) => setState(() => tab = value),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Palette.accent,
      ),
    );
  }

  Widget _content() {
    final data = AppData(widget.db);

    if (isAdmin) {
      return [
        AdminHome(user: widget.user, data: data),
        DispatchCenterScreen(
          api: widget.api,
          user: widget.user,
          data: data,
          onChanged: widget.onRefresh,
        ),
        ChatListScreen(
          api: widget.api,
          user: widget.user,
          profile: widget.profile,
          data: data,
          onChanged: widget.onRefresh,
        ),
        AdminWarnings(api: widget.api, data: data, onChanged: widget.onRefresh),
        SmsLogsScreen(data: data),
        CoastalWarningsScreen(data: data),
        AdminRequests(
          api: widget.api,
          user: widget.user,
          data: data,
          onChanged: widget.onRefresh,
        ),
        MissionScreen(
          api: widget.api,
          user: widget.user,
          data: data,
          onChanged: widget.onRefresh,
        ),
        TeamsScreen(api: widget.api, data: data, onChanged: widget.onRefresh),
        SubscribersScreen(data: data),
        VulnerableHouseholdsScreen(
          api: widget.api,
          data: data,
          onChanged: widget.onRefresh,
        ),
        AdminSafeZonesScreen(
          api: widget.api,
          data: data,
          onChanged: widget.onRefresh,
        ),
        RescueRoutesScreen(
          api: widget.api,
          data: data,
          onChanged: widget.onRefresh,
        ),
        DamsScreen(data: data),
        DamageReportsScreen(data: data),
        ReportsScreen(data: data),
        ActivityLogsScreen(data: data),
        AiChatScreen(api: widget.api),
        SettingsScreen(
          api: widget.api,
          user: widget.user,
          profile: widget.profile,
          darkMode: widget.darkMode,
          onToggleTheme: widget.onToggleTheme,
          onRefresh: widget.onRefresh,
        ),
      ][tab];
    }

    if (isRescue) {
      return [
        RescueHome(
          api: widget.api,
          user: widget.user,
          data: data,
          onChanged: widget.onRefresh,
          onOpenMissionList: () => setState(() => tab = 1),
        ),
        MissionScreen(
          api: widget.api,
          user: widget.user,
          data: data,
          onChanged: widget.onRefresh,
        ),
        ChatListScreen(
          api: widget.api,
          user: widget.user,
          profile: widget.profile,
          data: data,
          onChanged: widget.onRefresh,
        ),
        AiChatScreen(api: widget.api),
        WarningsScreen(data: data),
        SettingsScreen(
          api: widget.api,
          user: widget.user,
          profile: widget.profile,
          darkMode: widget.darkMode,
          onToggleTheme: widget.onToggleTheme,
          onRefresh: widget.onRefresh,
        ),
      ][tab];
    }

    return [
      CitizenHome(
        api: widget.api,
        user: widget.user,
        profile: widget.profile,
        data: data,
        onSelectTab: (index) => setState(() => tab = index),
      ),
      SOSScreen(
        api: widget.api,
        user: widget.user,
        profile: widget.profile,
        data: data,
        onSubmitted: widget.onRefresh,
      ),
      ChatListScreen(
        api: widget.api,
        user: widget.user,
        profile: widget.profile,
        data: data,
        onChanged: widget.onRefresh,
      ),
      AiChatScreen(api: widget.api),
      WarningsScreen(data: data),
      SafeZonesScreen(data: data),
      SettingsScreen(
        api: widget.api,
        user: widget.user,
        profile: widget.profile,
        darkMode: widget.darkMode,
        onToggleTheme: widget.onToggleTheme,
        onRefresh: widget.onRefresh,
      ),
    ][tab];
  }
}
