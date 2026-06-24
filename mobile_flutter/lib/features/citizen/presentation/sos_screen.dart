import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/core/core.dart';
import 'package:mobile_flutter/data/data.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key, required this.api, required this.user, required this.profile, required this.data, required this.onSubmitted});

  final ApiClient api;
  final Map<String, dynamic> user;
  final Map<String, dynamic>? profile;
  final AppData data;
  final Future<void> Function() onSubmitted;

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final people = TextEditingController(text: '1');
  final desc = TextEditingController();
  String level = 'HIGH';
  String? areaId;
  bool elderly = false;
  bool children = false;
  bool disabled = false;
  bool medical = false;
  bool supplies = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    name.text = valueOf(widget.user, 'full_name');
    phone.text = valueOf(widget.user, 'phone');
    address.text = valueOf(widget.profile, 'address_detail');
    final profileAreaId = valueOf(widget.profile, 'area_id');
    areaId = profileAreaId.isEmpty
        ? widget.data.areas
            .map((area) => valueOf(area, 'id'))
            .where((id) => id.isNotEmpty)
            .firstOrNull
        : profileAreaId;
    people.text = valueOf(widget.profile, 'household_size', fallback: '1');
    elderly = int.tryParse(valueOf(widget.profile, 'elderly_count', fallback: '0'))! > 0;
    children = int.tryParse(valueOf(widget.profile, 'children_count', fallback: '0'))! > 0;
    disabled = int.tryParse(valueOf(widget.profile, 'disabled_count', fallback: '0'))! > 0;
  }

  Future<void> submit() async {
    if (areaId == null || areaId!.isEmpty || name.text.isEmpty || phone.text.isEmpty || address.text.isEmpty || desc.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền đủ thông tin bắt buộc')));
      return;
    }
    setState(() => loading = true);
    final area = firstWhere(widget.data.areas, 'id', areaId);
    try {
      await widget.api.createRescueRequest({
        'full_name': name.text,
        'phone': phone.text,
        'area_id': areaId,
        'area_name': valueOf(area, 'old_name'),
        'address_detail': address.text,
        'description': desc.text,
        'number_of_people': int.tryParse(people.text) ?? 1,
        'emergency_level': level,
        'has_elderly': elderly,
        'has_children': children,
        'has_disabled': disabled,
        'has_medical_case': medical,
        'need_food_water': supplies,
        'user_id': valueOf(widget.user, 'id'),
      });
      await widget.onSubmitted();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi yêu cầu cứu hộ')));
        desc.clear();
      }
    } catch (err) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không gửi được yêu cầu: $err')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppList(
      children: [
        const PageTitle('Gửi yêu cầu cứu hộ', 'Điền thông tin để đội cứu hộ tiếp cận nhanh nhất'),
        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Mức độ khẩn cấp'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['LOW', 'MEDIUM', 'HIGH', 'EMERGENCY'].map((item) {
                  return ChoiceChip(
                    label: Text(levelLabel(item)),
                    selected: level == item,
                    selectedColor: levelColor(item).withValues(alpha: .18),
                    onSelected: (_) => setState(() => level = item),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Họ và tên')),
              const SizedBox(height: 10),
              TextField(controller: phone, decoration: const InputDecoration(labelText: 'Số điện thoại')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: areaId,
                decoration: const InputDecoration(labelText: 'Khu vực'),
                items: widget.data.areas.map((a) => DropdownMenuItem(value: valueOf(a, 'id'), child: Text(valueOf(a, 'old_name')))).toList(),
                onChanged: (v) => setState(() => areaId = v),
              ),
              const SizedBox(height: 10),
              TextField(controller: people, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số người cần cứu')),
              const SizedBox(height: 10),
              TextField(controller: address, decoration: const InputDecoration(labelText: 'Địa chỉ cụ thể')),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: [
                  ToggleChip('Người già', elderly, (v) => setState(() => elderly = v)),
                  ToggleChip('Trẻ em', children, (v) => setState(() => children = v)),
                  ToggleChip('Khuyết tật', disabled, (v) => setState(() => disabled = v)),
                  ToggleChip('Cấp cứu', medical, (v) => setState(() => medical = v)),
                  ToggleChip('Cần tiếp tế', supplies, (v) => setState(() => supplies = v)),
                ],
              ),
              const SizedBox(height: 10),
              TextField(controller: desc, maxLines: 4, decoration: const InputDecoration(labelText: 'Mô tả tình trạng')),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Palette.danger),
                onPressed: loading ? null : submit,
                icon: const Icon(Icons.send),
                label: Text(loading ? 'Đang gửi...' : 'Gửi yêu cầu cứu hộ ngay'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
