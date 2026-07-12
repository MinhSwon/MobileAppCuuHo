import 'dart:async';

import 'package:flutter/material.dart';

import 'package:mobile_flutter/core/core.dart';
import 'package:mobile_flutter/data/data.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.api,
    required this.data,
    required this.onRegister,
  });

  final ApiClient api;
  final AppData data;
  final Future<void> Function(Map<String, dynamic> payload) onRegister;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final otp = TextEditingController();
  final password = TextEditingController();
  final address = TextEditingController();
  final people = TextEditingController(text: '1');
  final elderly = TextEditingController(text: '0');
  final children = TextEditingController(text: '0');
  final disabled = TextEditingController(text: '0');
  final medicalNotes = TextEditingController();
  String? areaId;
  String? otpToken;
  String otpStatus = '';
  bool showPassword = false;
  bool loading = false;
  bool sendingOtp = false;
  bool verifyingOtp = false;
  Timer? _otpTimer;
  int _otpCountdown = 0;

  Future<void> sendOtp() async {
    final value = phone.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số điện thoại')),
      );
      return;
    }
    final vnPhone = RegExp(r'^(0|\+84)[0-9]{8,10}$');
    if (!vnPhone.hasMatch(value.replaceAll(' ', ''))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số điện thoại không hợp lệ')),
      );
      return;
    }
    setState(() {
      sendingOtp = true;
      otpToken = null;
      otpStatus = '';
    });
    try {
      final result = await widget.api.sendRegisterOtp(value);
      final devOtp = valueOf(result, 'devOtp');
      setState(() {
        otpStatus = devOtp.isEmpty
            ? 'Đã gửi mã OTP qua SMS'
            : 'Mã OTP demo: $devOtp';
      });
      _otpTimer?.cancel();
      _otpCountdown = 60;
      _otpTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() {
          if (_otpCountdown > 0) {
            _otpCountdown--;
          } else {
            t.cancel();
          }
        });
      });
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => sendingOtp = false);
    }
  }

  @override
  void dispose() {
    _otpTimer?.cancel();
    super.dispose();
  }

  Future<void> verifyOtp() async {
    if (phone.text.trim().isEmpty || otp.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số điện thoại và OTP')),
      );
      return;
    }
    setState(() => verifyingOtp = true);
    try {
      final result = await widget.api.verifyRegisterOtp(
        phone.text.trim(),
        otp.text.trim(),
      );
      setState(() {
        otpToken = valueOf(result, 'otpToken');
        otpStatus = 'Số điện thoại đã được xác thực';
      });
    } catch (err) {
      setState(() => otpToken = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => verifyingOtp = false);
    }
  }

  Future<void> submit() async {
    if (name.text.trim().isEmpty ||
        phone.text.trim().isEmpty ||
        password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng nhập họ tên, số điện thoại và mật khẩu tối thiểu 6 ký tự',
          ),
        ),
      );
      return;
    }
    if (otpToken == null || otpToken!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng xác thực OTP trước khi đăng ký'),
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
        'otp_token': otpToken,
        'area_id': areaId,
        'address_detail': address.text.trim(),
        'household_size': int.tryParse(people.text) ?? 1,
        'elderly_count': int.tryParse(elderly.text) ?? 0,
        'children_count': int.tryParse(children.text) ?? 0,
        'disabled_count': int.tryParse(disabled.text) ?? 0,
        'medical_notes': medicalNotes.text.trim(),
      });
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    areaId ??= widget.data.areas.isEmpty
        ? null
        : valueOf(widget.data.areas.first, 'id');

    return AppList(
      children: [
        const PageTitle(
          'Tạo tài khoản người dân',
          'Dùng để gửi SOS, theo dõi yêu cầu và nhận cảnh báo theo khu vực',
        ),
        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: name,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Họ và tên'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: otp,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Mã OTP SMS',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: _otpCountdown > 0
                        ? 'Gửi lại sau ${_otpCountdown}s'
                        : 'Gửi OTP',
                    onPressed: sendingOtp || _otpCountdown > 0 ? null : sendOtp,
                    icon: sendingOtp
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sms),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Xác thực OTP',
                    onPressed: verifyingOtp ? null : verifyOtp,
                    icon: verifyingOtp
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            otpToken == null
                                ? Icons.verified_outlined
                                : Icons.verified,
                          ),
                  ),
                ],
              ),
              if (otpStatus.isNotEmpty) ...[
                const SizedBox(height: 8),
                AlertPanel(
                  title: 'SMS OTP',
                  message: otpStatus,
                  color: otpToken == null ? Colors.orange : Colors.green,
                  icon: otpToken == null ? Icons.sms : Icons.verified,
                ),
                if (_otpCountdown > 0)
                  Text(
                    'Gửi lại OTP sau $_otpCountdown giây',
                    style: const TextStyle(color: Colors.orange, fontSize: 13),
                  ),
              ],
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
                  labelText: 'Mật khẩu',
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => showPassword = !showPassword),
                    icon: Icon(
                      showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: areaId,
                decoration: const InputDecoration(labelText: 'Khu vực'),
                items: widget.data.areas
                    .map(
                      (a) => DropdownMenuItem(
                        value: valueOf(a, 'id'),
                        child: Text(valueOf(a, 'old_name')),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => areaId = v),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: address,
                decoration: const InputDecoration(labelText: 'Địa chỉ cụ thể'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: people,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số người trong hộ',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: elderly,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Người già'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: children,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Trẻ em'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: disabled,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Khuyết tật',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: medicalNotes,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Ghi chú y tế'),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: loading ? null : submit,
                icon: loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add),
                label: Text(loading ? 'Đang đăng ký...' : 'Tạo tài khoản'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
