import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/data/data.dart';
import 'package:mobile_flutter/features/admin/admin.dart';
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
    required this.onRefresh,
    required this.onLogout,
  });

  final ApiClient api;
  final Map<String, dynamic> user;
  final Map<String, dynamic>? profile;
  final Map<String, dynamic> db;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLogout;

  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell> {
  int tab = 0;

  bool get isAdmin => ['ADMIN', 'SUPER_ADMIN'].contains(widget.user['role']);
  bool get isRescue => ['RESCUE_LEADER', 'RESCUE_MEMBER'].contains(widget.user['role']);

  List<AppMenuItem> get menuItems {
    if (isAdmin) {
      return const [
        AppMenuItem('Tổng quan', Icons.dashboard, 'Tổng quan'),
        AppMenuItem('Trung tâm điều phối', Icons.navigation, 'Tổng quan'),
        AppMenuItem('Quản lý cảnh báo', Icons.campaign, 'Cảnh báo & SMS'),
        AppMenuItem('SMS cảnh báo', Icons.sms, 'Cảnh báo & SMS'),
        AppMenuItem('Cảnh báo thiên tai', Icons.anchor, 'Cảnh báo & SMS'),
        AppMenuItem('Yêu cầu cứu hộ', Icons.sos, 'Cứu hộ'),
        AppMenuItem('Nhiệm vụ cứu hộ', Icons.assignment, 'Cứu hộ'),
        AppMenuItem('Đội cứu hộ', Icons.groups, 'Cứu hộ'),
        AppMenuItem('Người dân', Icons.people, 'Cộng đồng'),
        AppMenuItem('Hộ dễ tổn thương', Icons.home, 'Cộng đồng'),
        AppMenuItem('Điểm sơ tán', Icons.apartment, 'Cơ sở hạ tầng'),
        AppMenuItem('Tuyến đường cứu hộ', Icons.route, 'Cơ sở hạ tầng'),
        AppMenuItem('Đập/Hồ chứa', Icons.water_drop, 'Cơ sở hạ tầng'),
        AppMenuItem('Báo cáo thiệt hại', Icons.description, 'Báo cáo'),
        AppMenuItem('Thống kê & Báo cáo', Icons.bar_chart, 'Báo cáo'),
        AppMenuItem('Nhật ký hoạt động', Icons.history, 'Báo cáo'),
        AppMenuItem('AI Trợ lý', Icons.smart_toy, 'Công cụ'),
        AppMenuItem('Cài đặt tài khoản', Icons.settings, 'Công cụ'),
      ];
    }
    if (isRescue) {
      return const [
        AppMenuItem('Dashboard cứu hộ', Icons.dashboard, 'Đội cứu hộ'),
        AppMenuItem('Nhiệm vụ được giao', Icons.assignment, 'Đội cứu hộ'),
        AppMenuItem('Cảnh báo khẩn cấp', Icons.campaign, 'Đội cứu hộ'),
      ];
    }
    return const [
      AppMenuItem('Trang chủ', Icons.home, 'Người dân'),
      AppMenuItem('Gửi yêu cầu cứu hộ', Icons.sos, 'Người dân'),
      AppMenuItem('Cảnh báo khẩn cấp', Icons.campaign, 'Người dân'),
      AppMenuItem('Điểm sơ tán', Icons.shield, 'Người dân'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = menuItems;
    final quickItems = isAdmin ? items.take(4).toList() : items;

    return Scaffold(
      appBar: AppBar(
        title: Text(items[tab].label),
        actions: [
          IconButton(onPressed: widget.onRefresh, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: widget.onLogout, icon: const Icon(Icons.logout)),
        ],
      ),
      drawer: AppDrawer(
        title: isAdmin ? 'CUU HO VIET NAM' : isRescue ? 'DOI CUU HO' : 'CUU HO VIET NAM',
        subtitle: isAdmin ? 'Ung dung toan quoc' : isRescue ? 'Nhiem vu toan quoc' : 'Cong nguoi dan',
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
            .map((item) => BottomNavigationBarItem(icon: Icon(item.icon), label: item.shortLabel))
            .toList(),
        onTap: (value) => setState(() => tab = value),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Palette.accent,
        unselectedItemColor: Palette.muted,
        backgroundColor: Palette.elevated,
      ),
    );
  }

  Widget _content() {
    final data = AppData(widget.db);
    if (isAdmin) {
      return [
        AdminHome(user: widget.user, data: data),
        DispatchCenterScreen(api: widget.api, user: widget.user, data: data, onChanged: widget.onRefresh),
        AdminWarnings(api: widget.api, data: data, onChanged: widget.onRefresh),
        SmsLogsScreen(data: data),
        CoastalWarningsScreen(data: data),
        AdminRequests(api: widget.api, user: widget.user, data: data, onChanged: widget.onRefresh),
        MissionScreen(api: widget.api, user: widget.user, data: data, onChanged: widget.onRefresh),
        TeamsScreen(api: widget.api, data: data, onChanged: widget.onRefresh),
        SubscribersScreen(data: data),
        VulnerableHouseholdsScreen(api: widget.api, data: data, onChanged: widget.onRefresh),
        AdminSafeZonesScreen(api: widget.api, data: data, onChanged: widget.onRefresh),
        RescueRoutesScreen(api: widget.api, data: data, onChanged: widget.onRefresh),
        DamsScreen(data: data),
        DamageReportsScreen(data: data),
        ReportsScreen(data: data),
        ActivityLogsScreen(data: data),
        AIAssistantScreen(data: data),
        SettingsScreen(api: widget.api, user: widget.user),
      ][tab];
    }
    if (isRescue) {
      return [
        RescueHome(user: widget.user, data: data),
        MissionScreen(api: widget.api, user: widget.user, data: data, onChanged: widget.onRefresh),
        WarningsScreen(data: data),
      ][tab];
    }
    return [
      CitizenHome(user: widget.user, profile: widget.profile, data: data),
      SOSScreen(api: widget.api, user: widget.user, profile: widget.profile, data: data, onSubmitted: widget.onRefresh),
      WarningsScreen(data: data),
      SafeZonesScreen(data: data),
    ][tab];
  }
}
