import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/core/core.dart';
import 'package:mobile_flutter/data/data.dart';

class VulnerableHouseholdsScreen extends StatelessWidget {
  const VulnerableHouseholdsScreen({super.key, required this.api, required this.data, required this.onChanged});
  final ApiClient api;
  final AppData data;
  final Future<void> Function() onChanged;

  Future<void> showHouseholdForm(BuildContext context) async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final address = TextEditingController();
    final people = TextEditingController(text: '1');
    final notes = TextEditingController();
    String priority = 'MEDIUM';
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
              const PageTitle('Thêm hộ ưu tiên', 'Ghi nhận hộ cần hỗ trợ đặc biệt khi sơ tán/cứu hộ'),
              const SizedBox(height: 12),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Tên chủ hộ')),
              const SizedBox(height: 10),
              TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Số điện thoại')),
              const SizedBox(height: 10),
              TextField(controller: address, decoration: const InputDecoration(labelText: 'Địa chỉ')),
              const SizedBox(height: 10),
              TextField(controller: people, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số người')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: priority,
                decoration: const InputDecoration(labelText: 'Mức ưu tiên'),
                items: const ['LOW', 'MEDIUM', 'HIGH', 'EMERGENCY'].map((s) => DropdownMenuItem(value: s, child: Text(levelLabel(s)))).toList(),
                onChanged: (v) => setSheetState(() => priority = v ?? priority),
              ),
              const SizedBox(height: 10),
              TextField(controller: notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Ghi chú')),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () async {
                  if (name.text.trim().isEmpty) return;
                  await api.createVulnerableHousehold({
                    'full_name': name.text.trim(),
                    'phone': phone.text.trim(),
                    'address_detail': address.text.trim(),
                    'household_size': int.tryParse(people.text) ?? 1,
                    'priority_level': priority,
                    'notes': notes.text.trim(),
                  });
                  await onChanged();
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.add_home),
                label: const Text('Tạo hộ ưu tiên'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> updatePriority(Map<String, dynamic> household, String priority) async {
    await api.updateVulnerableHousehold(valueOf(household, 'id'), {'priority_level': priority});
    await onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return AppList(
      children: [
        const PageTitle('Hộ dễ tổn thương', 'Ưu tiên người già, trẻ em, khuyết tật và bệnh nền'),
        ElevatedButton.icon(onPressed: () => showHouseholdForm(context), icon: const Icon(Icons.add_home), label: const Text('Thêm hộ ưu tiên')),
        if (data.households.isEmpty)
          const EmptyCard(icon: Icons.home, message: 'Chưa có hộ ưu tiên')
        else
          ...data.households.map((h) => CardBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.home, color: Palette.warning),
                      const SizedBox(width: 8),
                      Expanded(child: Text(valueOf(h, 'household_name'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                      BadgePill(label: 'Ưu tiên ${valueOf(h, 'priority_level')}', bg: Palette.warning.withValues(alpha: .14), fg: Palette.warning),
                    ]),
                    const SizedBox(height: 8),
                    InfoRow('Khu vực', valueOf(h, 'area_name')),
                    InfoRow('Số người', valueOf(h, 'household_size')),
                    Text(valueOf(h, 'note'), style: const TextStyle(color: Palette.secondary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final priority in const ['MEDIUM', 'HIGH', 'EMERGENCY'])
                          TextButton(onPressed: () => updatePriority(h, priority), child: Text(levelLabel(priority))),
                      ],
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}
