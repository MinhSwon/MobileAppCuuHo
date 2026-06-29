import 'package:flutter/material.dart';

import 'package:mobile_flutter/core/core.dart';
import 'package:mobile_flutter/data/data.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.data,
    required this.onRegister,
  });

  final AppData data;
  final Future<void> Function(Map<String, dynamic> payload) onRegister;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final address = TextEditingController();
  final people = TextEditingController(text: '1');
  final elderly = TextEditingController(text: '0');
  final children = TextEditingController(text: '0');
  final disabled = TextEditingController(text: '0');
  final medicalNotes = TextEditingController();

  String? areaId;
  bool showPassword = false;
  bool loading = false;

  Future<void> submit() async {
    if (name.text.trim().isEmpty ||
        phone.text.trim().isEmpty ||
        password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui long nhap ho ten, so dien thoai va mat khau toi thieu 6 ky tu',
          ),
        ),
      );
      return;
    }

    setState(() => loading = true);
    try {
      await widget.onRegister({
        'full_name': name.text.trim(),
        'phone': phone.text.trim(),
        'email': email.text.trim(),
        'password': password.text,
        'area_id': areaId,
        'address_detail': address.text.trim(),
        'household_size': int.tryParse(people.text) ?? 1,
        'elderly_count': int.tryParse(elderly.text) ?? 0,
        'children_count': int.tryParse(children.text) ?? 0,
        'disabled_count': int.tryParse(disabled.text) ?? 0,
        'medical_notes': medicalNotes.text.trim(),
      });
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    areaId ??=
        widget.data.areas.isEmpty
            ? null
            : valueOf(widget.data.areas.first, 'id');

    return AppList(
      children: [
        const PageTitle(
          'Tao tai khoan nguoi dan',
          'Gui SOS, theo doi yeu cau va nhan canh bao theo khu vuc',
        ),
        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: name,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Ho va ten'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'So dien thoai'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: password,
                obscureText: !showPassword,
                decoration: InputDecoration(
                  labelText: 'Mat khau',
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => showPassword = !showPassword);
                    },
                    icon: Icon(
                      showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: areaId,
                decoration: const InputDecoration(labelText: 'Khu vuc'),
                items:
                    widget.data.areas
                        .map(
                          (area) => DropdownMenuItem(
                            value: valueOf(area, 'id'),
                            child: Text(valueOf(area, 'old_name')),
                          ),
                        )
                        .toList(),
                onChanged: (value) => setState(() => areaId = value),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: address,
                decoration: const InputDecoration(
                  labelText: 'Dia chi cu the',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: people,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'So nguoi trong ho',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: elderly,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Nguoi gia'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: children,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Tre em'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: disabled,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Khuyet tat',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: medicalNotes,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Ghi chu y te'),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: loading ? null : submit,
                icon:
                    loading
                        ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.person_add),
                label: Text(
                  loading ? 'Dang dang ky...' : 'Tao tai khoan',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
