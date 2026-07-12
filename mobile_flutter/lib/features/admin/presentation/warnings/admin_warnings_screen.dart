import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/core/core.dart';
import 'package:mobile_flutter/data/data.dart';

import 'package:mobile_flutter/features/admin/presentation/shared/admin_dialogs.dart';

class AdminWarnings extends StatefulWidget {
  const AdminWarnings({super.key, required this.api, required this.data, required this.onChanged});
  final ApiClient api;
  final AppData data;
  final Future<void> Function() onChanged;

  @override
  State<AdminWarnings> createState() => _AdminWarningsState();
}

class _AdminWarningsState extends State<AdminWarnings> {
  final title = TextEditingController();
  final content = TextEditingController();
  String level = 'HIGH';
  String? areaId;

  Future<void> createWarning() async {
    if (title.text.isEmpty || content.text.isEmpty || areaId == null) return;
    final area = firstWhere(widget.data.areas, 'id', areaId);
    await widget.api.createWarning({
      'title': title.text,
      'content': content.text,
      'level': level,
      'area_id': areaId,
      'area_name': valueOf(area, 'old_name'),
      'status': 'PUBLISHED',
      'start_time': DateTime.now().toIso8601String(),
      'end_time': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
    });
    title.clear();
    content.clear();
    await widget.onChanged();
  }

  Future<void> updateWarningStatus(Map<String, dynamic> warning, String status) async {
    await widget.api.updateWarning(valueOf(warning, 'id'), {'status': status});
    await widget.onChanged();
  }

  Future<void> deleteWarning(Map<String, dynamic> warning) async {
    final ok = await confirmAction(context, 'Xóa cảnh báo?', 'Cảnh báo "${valueOf(warning, 'title')}" sẽ bị xóa khỏi hệ thống.');
    if (!ok) return;
    await widget.api.deleteWarning(valueOf(warning, 'id'));
    await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    areaId ??= widget.data.areas.isEmpty ? null : valueOf(widget.data.areas.first, 'id');
    return AppList(
      children: [
        const PageTitle('Cảnh báo', 'Tạo nhanh và theo dõi cảnh báo đang phát'),
        CardBox(
          child: Column(
            children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Tiêu đề cảnh báo')),
              const SizedBox(height: 10),
              TextField(controller: content, maxLines: 3, decoration: const InputDecoration(labelText: 'Nội dung')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: areaId,
                decoration: const InputDecoration(labelText: 'Khu vực'),
                items: widget.data.areas.map((a) => DropdownMenuItem(value: valueOf(a, 'id'), child: Text(valueOf(a, 'old_name')))).toList(),
                onChanged: (v) => setState(() => areaId = v),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: ['LOW', 'MEDIUM', 'HIGH', 'EMERGENCY'].map((l) => ChoiceChip(label: Text(levelLabel(l)), selected: level == l, onSelected: (_) => setState(() => level = l))).toList(),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(onPressed: createWarning, icon: const Icon(Icons.campaign), label: const Text('Phát cảnh báo')),
            ],
          ),
        ),
        ...widget.data.warnings.map((w) => WarningCard(
              warning: w,
              actions: [
                if (valueOf(w, 'status') != 'PUBLISHED')
                  TextButton.icon(
                    onPressed: () => updateWarningStatus(w, 'PUBLISHED'),
                    icon: const Icon(Icons.publish),
                    label: const Text('Phát'),
                  ),
                if (valueOf(w, 'status') != 'EXPIRED')
                  TextButton.icon(
                    onPressed: () => updateWarningStatus(w, 'EXPIRED'),
                    icon: const Icon(Icons.timer_off),
                    label: const Text('Hết hạn'),
                  ),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Palette.danger),
                  onPressed: () => deleteWarning(w),
                  icon: const Icon(Icons.delete),
                  label: const Text('Xóa'),
                ),
              ],
            )),
      ],
    );
  }
}

class WarningsScreen extends StatelessWidget {
  const WarningsScreen({super.key, required this.data});
  final AppData data;

  @override
  Widget build(BuildContext context) {
    final warnings = data.warnings.where((w) => w['status'] == 'PUBLISHED').toList();
    return AppList(
      children: [
        const PageTitle('Cảnh báo khẩn cấp', 'Theo dõi tình hình theo khu vực'),
        if (warnings.isEmpty)
          const EmptyCard(icon: Icons.campaign, message: 'Không có cảnh báo đang hoạt động')
        else
          ...warnings.map((w) => WarningCard(warning: w)),
      ],
    );
  }
}
