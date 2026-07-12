import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/core/core.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onLogin,
    this.darkMode = false,
    this.onToggleTheme,
    this.onOpenRegister,
    this.onOpenSos,
  });

  final Future<void> Function(String emailOrPhone, String password) onLogin;
  final bool darkMode;
  final Future<void> Function()? onToggleTheme;
  final VoidCallback? onOpenRegister;
  final VoidCallback? onOpenSos;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool showPassword = false;

  final demoAccounts = const [
    ('Admin', 'admin@floodguard.vn', 'admin123', Palette.accent),
    ('Đội cứu hộ', 'doicuuho1@floodguard.vn', 'rescue123', Palette.success),
    ('Người dân', 'nguoidan1@gmail.com', 'citizen123', Color(0xff6b5a45)),
  ];

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập email/số điện thoại và mật khẩu'),
        ),
      );
      return;
    }
    setState(() => loading = true);
    try {
      await widget.onLogin(email.text.trim(), password.text);
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

  void showForgotPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quên mật khẩu'),
        content: const Text(
          'Vui lòng liên hệ quản trị viên hoặc gọi đường dây hỗ trợ để đặt lại mật khẩu.\n\nĐường dây hỗ trợ: 1800 xxxx\nEmail: support@rescuevn.vn',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(22),
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 28),
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Palette.sidebar,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.health_and_safety,
                          color: Palette.accent,
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'CỨU HỘ VIỆT NAM',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xfff0ece5),
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Cảnh báo khẩn cấp, SOS GPS và điều phối cứu hộ cho người dân trên toàn Việt Nam.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Palette.muted, height: 1.55),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'Đăng nhập',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vui lòng đăng nhập để tiếp tục',
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.phone),
                    labelText: 'Email hoặc số điện thoại',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: !showPassword,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock),
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
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: loading ? null : submit,
                  icon: loading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: Text(loading ? 'Đang đăng nhập...' : 'Đăng nhập'),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: showForgotPassword,
                    child: const Text('Quên mật khẩu?'),
                  ),
                ),
                if (widget.onOpenRegister != null ||
                    widget.onOpenSos != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (widget.onOpenRegister != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.onOpenRegister,
                            icon: const Icon(Icons.person_add),
                            label: const Text('Đăng ký'),
                          ),
                        ),
                      if (widget.onOpenRegister != null &&
                          widget.onOpenSos != null)
                        const SizedBox(width: 10),
                      if (widget.onOpenSos != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Palette.danger,
                            ),
                            onPressed: widget.onOpenSos,
                            icon: const Icon(Icons.sos),
                            label: const Text('SOS nhanh'),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                const SectionLabel('Tài khoản thử nghiệm'),
                const SizedBox(height: 8),
                ...demoAccounts.map(
                  (acc) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        backgroundColor: Theme.of(context).cardTheme.color,
                        side: BorderSide(color: Theme.of(context).dividerColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(12),
                      ),
                      onPressed: () {
                        email.text = acc.$2;
                        password.text = acc.$3;
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            acc.$1,
                            style: TextStyle(
                              color: acc.$4,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            acc.$2,
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (widget.onToggleTheme != null)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filledTonal(
                  tooltip: widget.darkMode
                      ? 'Chuyển giao diện sáng'
                      : 'Chuyển giao diện tối',
                  onPressed: widget.onToggleTheme,
                  icon: Icon(
                    widget.darkMode ? Icons.light_mode : Icons.dark_mode,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
