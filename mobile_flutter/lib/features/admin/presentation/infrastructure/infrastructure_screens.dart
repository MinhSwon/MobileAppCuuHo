import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/core/core.dart';
import 'package:mobile_flutter/data/data.dart';

import 'package:mobile_flutter/features/admin/presentation/shared/admin_dialogs.dart';

class AdminSafeZonesScreen extends StatelessWidget {
  const AdminSafeZonesScreen({super.key, required this.api, required this.data, required this.onChanged});
  final ApiClient api;
  final AppData data;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) => SafeZonesScreen(data: data, api: api, onChanged: onChanged);
}

class RescueRoutesScreen extends StatelessWidget {
  const RescueRoutesScreen({super.key, required this.api, required this.data, required this.onChanged});
  final ApiClient api;
  final AppData data;
  final Future<void> Function() onChanged;

  Future<void> showRouteForm(BuildContext context) async {
    final name = TextEditingController();
    final from = TextEditingController();
    final to = TextEditingController();
    final distance = TextEditingController();
    String status = 'OPEN';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(14, 8, 14, MediaQuery.of(context).viewInsets.bottom + 14),
          child: ListView(
            shrinkWrap: true,
            children: [
              const PageTitle('Thêm tuyến cứu hộ', 'Cập nhật tuyến tiếp cận nạn nhân và điểm sơ tán'),
              const SizedBox(height: 12),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Tên tuyến')),
              const SizedBox(height: 10),
              TextField(controller: from, decoration: const InputDecoration(labelText: 'Điểm đầu')),
              const SizedBox(height: 10),
              TextField(controller: to, decoration: const InputDecoration(labelText: 'Điểm cuối')),
              const SizedBox(height: 10),
              TextField(controller: distance, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Khoảng cách km')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Trạng thái'),
                items: const ['OPEN', 'CAUTION', 'BLOCKED', 'CLOSED'].map((s) => DropdownMenuItem(value: s, child: Text(statusLabel(s)))).toList(),
                onChanged: (v) => setSheetState(() => status = v ?? status),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () async {
                  if (name.text.trim().isEmpty) return;
                  await api.createRoute({
                    'name': name.text.trim(),
                    'from_location': from.text.trim(),
                    'to_location': to.text.trim(),
                    'distance_km': double.tryParse(distance.text),
                    'status': status,
                  });
                  await onChanged();
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.add_road),
                label: const Text('Tạo tuyến'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> updateRouteStatus(Map<String, dynamic> route, String status) async {
    await api.updateRoute(valueOf(route, 'id'), {'status': status});
    await onChanged();
  }

  Future<void> deleteRoute(BuildContext context, Map<String, dynamic> route) async {
    final ok = await confirmAction(context, 'Xóa tuyến đường?', 'Tuyến "${valueOf(route, 'name')}" sẽ bị xóa.');
    if (!ok) return;
    await api.deleteRoute(valueOf(route, 'id'));
    await onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return AppList(
      children: [
        const PageTitle('Tuyến đường cứu hộ', 'Tình trạng tuyến tiếp cận nạn nhân và điểm sơ tán'),
        ElevatedButton.icon(onPressed: () => showRouteForm(context), icon: const Icon(Icons.add_road), label: const Text('Thêm tuyến đường')),
        RescueMap(
          title: 'Bản đồ tuyến và điểm hỗ trợ',
          points: [
            ...data.routes.map((r) => MapPoint.fromMap(r, latKey: 'latitude', lngKey: 'longitude', labelKey: 'name', type: MapPointType.route)),
            ...data.safeZones.map((s) => MapPoint.fromMap(s, latKey: 'latitude', lngKey: 'longitude', labelKey: 'name', type: MapPointType.safeZone)),
            ...data.teams.map((t) => MapPoint.fromMap(t, latKey: 'latitude', lngKey: 'longitude', labelKey: 'team_name', type: MapPointType.team)),
          ],
        ),
        if (data.routes.isEmpty)
          const EmptyCard(icon: Icons.route, message: 'Chưa có tuyến đường')
        else
          ...data.routes.map((r) => CardBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.route, color: Palette.accent),
                      const SizedBox(width: 8),
                      Expanded(child: Text(valueOf(r, 'name'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                      StatusBadge(status: valueOf(r, 'status')),
                    ]),
                    const SizedBox(height: 8),
                    InfoRow('Từ', valueOf(r, 'start_point')),
                    InfoRow('Đến', valueOf(r, 'end_point')),
                    InfoRow('Mức an toàn', valueOf(r, 'safety_level')),
                    Text(valueOf(r, 'note'), style: const TextStyle(color: Palette.secondary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final status in const ['OPEN', 'CAUTION', 'BLOCKED', 'CLOSED'])
                          TextButton(onPressed: () => updateRouteStatus(r, status), child: Text(statusLabel(status))),
                        TextButton.icon(
                          style: TextButton.styleFrom(foregroundColor: Palette.danger),
                          onPressed: () => deleteRoute(context, r),
                          icon: const Icon(Icons.delete),
                          label: const Text('Xóa'),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}

class DamsScreen extends StatelessWidget {
  const DamsScreen({super.key, required this.data});
  final AppData data;

  @override
  Widget build(BuildContext context) {
    return AppList(
      children: [
        const PageTitle('Đập/Hồ chứa', 'Theo dõi mực nước và trạng thái vận hành'),
        if (data.dams.isEmpty)
          const EmptyCard(icon: Icons.water_drop, message: 'Chưa có dữ liệu hồ chứa')
        else
          ...data.dams.map((d) => CardBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.water_drop, color: Palette.accent),
                      const SizedBox(width: 8),
                      Expanded(child: Text(valueOf(d, 'name'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                      StatusBadge(status: valueOf(d, 'status')),
                    ]),
                    const SizedBox(height: 8),
                    InfoRow('Mực hiện tại', '${valueOf(d, 'current_level_m')} m'),
                    InfoRow('Mức cảnh báo', '${valueOf(d, 'warning_level_m')} m'),
                    InfoRow('Dung tích', '${valueOf(d, 'current_volume_percent')}%'),
                    Text(valueOf(d, 'note'), style: const TextStyle(color: Palette.secondary)),
                  ],
                ),
              )),
      ],
    );
  }
}

class DamageReportsScreen extends StatelessWidget {
  const DamageReportsScreen({super.key, required this.data});
  final AppData data;

  @override
  Widget build(BuildContext context) {
    return AppList(
      children: [
        const PageTitle('Báo cáo thiệt hại', 'Tổng hợp báo cáo nhà cửa, đường sá, nông nghiệp'),
        if (data.damageReports.isEmpty)
          const EmptyCard(icon: Icons.description, message: 'Chưa có báo cáo thiệt hại')
        else
          ...data.damageReports.map((r) => CardBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.description, color: Palette.warning),
                      const SizedBox(width: 8),
                      Expanded(child: Text(valueOf(r, 'damage_type'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                      LevelBadge(level: valueOf(r, 'severity')),
                    ]),
                    const SizedBox(height: 8),
                    InfoRow('Người báo cáo', valueOf(r, 'reporter_name')),
                    InfoRow('Khu vực', valueOf(r, 'area_name')),
                    Text(valueOf(r, 'description'), style: const TextStyle(color: Palette.secondary)),
                  ],
                ),
              )),
      ],
    );
  }
}

class SafeZonesScreen extends StatelessWidget {
  const SafeZonesScreen({super.key, required this.data, this.api, this.onChanged});
  final AppData data;
  final ApiClient? api;
  final Future<void> Function()? onChanged;

  bool get canEdit => api != null && onChanged != null;

  Future<void> showSafeZoneForm(BuildContext context) async {
    final name = TextEditingController();
    final address = TextEditingController();
    final capacity = TextEditingController(text: '100');
    final contact = TextEditingController();
    final phone = TextEditingController();
    String status = 'AVAILABLE';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(14, 8, 14, MediaQuery.of(context).viewInsets.bottom + 14),
          child: ListView(
            shrinkWrap: true,
            children: [
              const PageTitle('Thêm điểm sơ tán', 'Cập nhật nơi tiếp nhận người dân an toàn'),
              const SizedBox(height: 12),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Tên điểm')),
              const SizedBox(height: 10),
              TextField(controller: address, decoration: const InputDecoration(labelText: 'Địa chỉ')),
              const SizedBox(height: 10),
              TextField(controller: capacity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sức chứa')),
              const SizedBox(height: 10),
              TextField(controller: contact, decoration: const InputDecoration(labelText: 'Người liên hệ')),
              const SizedBox(height: 10),
              TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Số điện thoại')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Trạng thái'),
                items: const ['AVAILABLE', 'FULL', 'CLOSED', 'INACTIVE'].map((s) => DropdownMenuItem(value: s, child: Text(statusLabel(s)))).toList(),
                onChanged: (v) => setSheetState(() => status = v ?? status),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () async {
                  if (name.text.trim().isEmpty) return;
                  await api!.createSafeZone({
                    'name': name.text.trim(),
                    'address': address.text.trim(),
                    'capacity': int.tryParse(capacity.text) ?? 0,
                    'current_people': 0,
                    'contact_person': contact.text.trim(),
                    'contact_phone': phone.text.trim(),
                    'status': status,
                  });
                  await onChanged!();
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.add),
                label: const Text('Tạo điểm sơ tán'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> updateSafeZoneStatus(Map<String, dynamic> zone, String status) async {
    await api!.updateSafeZone(valueOf(zone, 'id'), {'status': status});
    await onChanged!();
  }

  Future<void> deleteSafeZone(BuildContext context, Map<String, dynamic> zone) async {
    final ok = await confirmAction(context, 'Xóa điểm sơ tán?', 'Điểm "${valueOf(zone, 'name')}" sẽ bị xóa.');
    if (!ok) return;
    await api!.deleteSafeZone(valueOf(zone, 'id'));
    await onChanged!();
  }

  @override
  Widget build(BuildContext context) {
    return AppList(
      children: [
        const PageTitle('Điểm sơ tán', 'Sức chứa, liên hệ và tình trạng còn chỗ'),
        if (canEdit) ElevatedButton.icon(onPressed: () => showSafeZoneForm(context), icon: const Icon(Icons.add), label: const Text('Thêm điểm sơ tán')),
        RescueMap(
          title: 'Bản đồ điểm sơ tán',
          points: data.safeZones
              .map((s) => MapPoint.fromMap(s, latKey: 'latitude', lngKey: 'longitude', labelKey: 'name', type: MapPointType.safeZone))
              .toList(),
        ),
        ...data.safeZones.map((s) => CardBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield, color: Palette.accent),
                      const SizedBox(width: 8),
                      Expanded(child: Text(valueOf(s, 'name'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                      StatusBadge(status: valueOf(s, 'status')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(valueOf(s, 'address'), style: const TextStyle(color: Palette.secondary)),
                  const SizedBox(height: 8),
                  InfoRow('Sức chứa', '${valueOf(s, 'current_people')}/${valueOf(s, 'capacity')} người'),
                  InfoRow('Liên hệ', '${valueOf(s, 'contact_person')} · ${valueOf(s, 'contact_phone')}'),
                  if (canEdit) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final status in const ['AVAILABLE', 'FULL', 'CLOSED'])
                          TextButton(onPressed: () => updateSafeZoneStatus(s, status), child: Text(statusLabel(status))),
                        TextButton.icon(
                          style: TextButton.styleFrom(foregroundColor: Palette.danger),
                          onPressed: () => deleteSafeZone(context, s),
                          icon: const Icon(Icons.delete),
                          label: const Text('Xóa'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            )),
      ],
    );
  }
}



class TeamsScreen extends StatelessWidget {
  const TeamsScreen({super.key, required this.api, required this.data, required this.onChanged});
  final ApiClient api;
  final AppData data;
  final Future<void> Function() onChanged;

  Future<void> showTeamForm(BuildContext context) async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final leader = TextEditingController();
    final members = TextEditingController(text: '4');
    String status = 'AVAILABLE';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(14, 8, 14, MediaQuery.of(context).viewInsets.bottom + 14),
          child: ListView(
            shrinkWrap: true,
            children: [
              const PageTitle('Thêm đội cứu hộ', 'Tạo nhanh lực lượng điều phối trên mobile'),
              const SizedBox(height: 12),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Tên đội')),
              const SizedBox(height: 10),
              TextField(controller: leader, decoration: const InputDecoration(labelText: 'Trưởng đội')),
              const SizedBox(height: 10),
              TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Điện thoại')),
              const SizedBox(height: 10),
              TextField(controller: members, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số thành viên')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Trạng thái'),
                items: const ['AVAILABLE', 'BUSY', 'OFFLINE', 'INACTIVE'].map((s) => DropdownMenuItem(value: s, child: Text(statusLabel(s)))).toList(),
                onChanged: (v) => setSheetState(() => status = v ?? status),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () async {
                  if (name.text.trim().isEmpty) return;
                  await api.createTeam({
                    'team_name': name.text.trim(),
                    'leader_name': leader.text.trim(),
                    'phone': phone.text.trim(),
                    'member_count': int.tryParse(members.text) ?? 0,
                    'status': status,
                  });
                  await onChanged();
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.add),
                label: const Text('Tạo đội'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> updateTeamStatus(Map<String, dynamic> team, String status) async {
    await api.updateTeam(valueOf(team, 'id'), {'status': status});
    await onChanged();
  }

  Future<void> deleteTeam(BuildContext context, Map<String, dynamic> team) async {
    final ok = await confirmAction(context, 'Xóa đội cứu hộ?', 'Đội "${valueOf(team, 'team_name')}" sẽ bị xóa.');
    if (!ok) return;
    await api.deleteTeam(valueOf(team, 'id'));
    await onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return AppList(
      children: [
        const PageTitle('Đội cứu hộ', 'Trạng thái lực lượng và phương tiện'),
        ElevatedButton.icon(onPressed: () => showTeamForm(context), icon: const Icon(Icons.add), label: const Text('Thêm đội cứu hộ')),
        ...data.teams.map((t) => CardBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.groups, color: Palette.success),
                      const SizedBox(width: 8),
                      Expanded(child: Text(valueOf(t, 'team_name'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                      StatusBadge(status: valueOf(t, 'status')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InfoRow('Trưởng đội', valueOf(t, 'leader_name')),
                  InfoRow('Điện thoại', valueOf(t, 'phone')),
                  InfoRow('Thành viên', '${valueOf(t, 'member_count')} người'),
                  InfoRow('Phương tiện', valueOf(t, 'vehicle_type', fallback: '-')),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final status in const ['AVAILABLE', 'BUSY', 'OFFLINE'])
                        TextButton(onPressed: () => updateTeamStatus(t, status), child: Text(statusLabel(status))),
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: Palette.danger),
                        onPressed: () => deleteTeam(context, t),
                        icon: const Icon(Icons.delete),
                        label: const Text('Xóa'),
                      ),
                    ],
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
