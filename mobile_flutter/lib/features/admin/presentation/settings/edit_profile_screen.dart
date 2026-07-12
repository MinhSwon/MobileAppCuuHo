import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/core/core.dart';
import 'package:mobile_flutter/data/data.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.api,
    required this.user,
    this.profile,
    required this.onSaved,
  });

  final ApiClient api;
  final Map<String, dynamic> user;
  final Map<String, dynamic>? profile;
  final Future<void> Function() onSaved;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // Profile fields
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final peopleCtrl = TextEditingController();
  final elderlyCtrl = TextEditingController();
  final childrenCtrl = TextEditingController();
  final disabledCtrl = TextEditingController();
  final medicalCtrl = TextEditingController();

  // Password fields
  final oldPwCtrl = TextEditingController();
  final newPwCtrl = TextEditingController();
  final confirmPwCtrl = TextEditingController();
  bool showOldPw = false;
  bool showNewPw = false;
  bool showConfirmPw = false;

  bool saving = false;
  bool changingPw = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    // Điền thông tin hiện tại
    nameCtrl.text = valueOf(widget.user, 'full_name');
    phoneCtrl.text = valueOf(widget.user, 'phone');
    final p = widget.profile;
    if (p != null) {
      addressCtrl.text = valueOf(p, 'address_detail');
      peopleCtrl.text = valueOf(p, 'household_size', fallback: '1');
      elderlyCtrl.text = valueOf(p, 'elderly_count', fallback: '0');
      childrenCtrl.text = valueOf(p, 'children_count', fallback: '0');
      disabledCtrl.text = valueOf(p, 'disabled_count', fallback: '0');
      medicalCtrl.text = valueOf(p, 'medical_notes', fallback: '');
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    nameCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    peopleCtrl.dispose();
    elderlyCtrl.dispose();
    childrenCtrl.dispose();
    disabledCtrl.dispose();
    medicalCtrl.dispose();
    oldPwCtrl.dispose();
    newPwCtrl.dispose();
    confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> saveProfile() async {
    if (nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập họ tên')));
      return;
    }
    setState(() => saving = true);
    try {
      final userId = valueOf(widget.user, 'id');
      final result = await widget.api.updateProfile(userId, {
        'full_name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'address_detail': addressCtrl.text.trim(),
        'household_size': int.tryParse(peopleCtrl.text) ?? 1,
        'elderly_count': int.tryParse(elderlyCtrl.text) ?? 0,
        'children_count': int.tryParse(childrenCtrl.text) ?? 0,
        'disabled_count': int.tryParse(disabledCtrl.text) ?? 0,
        'medical_notes': medicalCtrl.text.trim(),
      });
      final updatedUser = mapOf(result['user']);
      final updatedProfile = mapOf(result['profile']);
      if (updatedUser.isNotEmpty) {
        widget.user
          ..clear()
          ..addAll(updatedUser);
      }
      if (widget.profile != null && updatedProfile.isNotEmpty) {
        widget.profile!
          ..clear()
          ..addAll(updatedProfile);
      }
      await widget.onSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật hồ sơ thành công'),
            backgroundColor: Palette.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Palette.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> changePassword() async {
    if (oldPwCtrl.text.isEmpty ||
        newPwCtrl.text.isEmpty ||
        confirmPwCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ các trường mật khẩu'),
        ),
      );
      return;
    }
    if (newPwCtrl.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu mới phải có ít nhất 8 ký tự')),
      );
      return;
    }
    if (newPwCtrl.text != confirmPwCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu xác nhận không khớp')),
      );
      return;
    }
    setState(() => changingPw = true);
    try {
      final userId = valueOf(widget.user, 'id');
      await widget.api.updatePassword(userId, oldPwCtrl.text, newPwCtrl.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã đổi mật khẩu thành công'),
            backgroundColor: Palette.success,
          ),
        );
        oldPwCtrl.clear();
        newPwCtrl.clear();
        confirmPwCtrl.clear();
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Palette.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => changingPw = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Thông tin'),
            Tab(icon: Icon(Icons.lock), text: 'Mật khẩu'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // Tab 1: Thông tin cá nhân
          ListView(
            padding: const EdgeInsets.all(14),
            children: [
              const PageTitle('Thông tin cá nhân', 'Cập nhật hồ sơ của bạn'),
              const SizedBox(height: 14),
              CardBox(
                child: Column(
                  children: [
                    TextField(
                      controller: nameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên *',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ cụ thể',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: peopleCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Số người trong hộ',
                        prefixIcon: Icon(Icons.group),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: elderlyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Người già',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: childrenCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Trẻ em',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: disabledCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Khuyết tật',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: medicalCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú y tế (tiểu đường, huyết áp, ...)',
                        prefixIcon: Icon(Icons.medical_information),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: saving ? null : saveProfile,
                        icon: saving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(saving ? 'Đang lưu...' : 'Lưu thay đổi'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Tab 2: Đổi mật khẩu
          ListView(
            padding: const EdgeInsets.all(14),
            children: [
              const PageTitle('Đổi mật khẩu', 'Bảo vệ tài khoản của bạn'),
              const SizedBox(height: 14),
              CardBox(
                child: Column(
                  children: [
                    TextField(
                      controller: oldPwCtrl,
                      obscureText: !showOldPw,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu hiện tại',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showOldPw ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => showOldPw = !showOldPw),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newPwCtrl,
                      obscureText: !showNewPw,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu mới (tối thiểu 8 ký tự)',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showNewPw ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => showNewPw = !showNewPw),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPwCtrl,
                      obscureText: !showConfirmPw,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => changingPw ? null : changePassword(),
                      decoration: InputDecoration(
                        labelText: 'Xác nhận mật khẩu mới',
                        prefixIcon: const Icon(Icons.lock_clock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showConfirmPw
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => showConfirmPw = !showConfirmPw),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: changingPw ? null : changePassword,
                        icon: changingPw
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.key),
                        label: Text(
                          changingPw ? 'Đang đổi...' : 'Đổi mật khẩu',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              CardBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      icon: Icons.info_outline,
                      title: 'Lưu ý bảo mật',
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '• Mật khẩu mới phải có ít nhất 8 ký tự\n'
                      '• Không dùng mật khẩu dễ đoán (123456, qwerty...)\n'
                      '• Không chia sẻ mật khẩu với người khác\n'
                      '• Đổi mật khẩu định kỳ 3–6 tháng',
                      style: TextStyle(height: 1.7, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
