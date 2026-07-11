import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/core/core.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onLogin,
    this.onOpenRegister,
    this.onOpenSos,
  });

  final Future<void> Function(String emailOrPhone, String password) onLogin;
  final VoidCallback? onOpenRegister;
  final VoidCallback? onOpenSos;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController(text: 'admin123');
  bool loading = false;
  bool showPassword = false;

  final demoAccounts = const [
    (
      'Admin / Dieu phoi vien',
      'admin@floodguard.vn',
      'admin123',
      Palette.accent,
    ),
    ('Doi cuu ho', 'doicuuho1@floodguard.vn', 'rescue123', Palette.success),
    ('Nguoi dan', 'nguoidan1@gmail.com', 'citizen123', Color(0xff6b5a45)),
  ];

  Future<void> submit() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.bgBase,
      body: SafeArea(
        child: ListView(
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
                    'CUU HO VIET NAM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xfff0ece5),
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Canh bao khan cap, SOS GPS va dieu phoi cuu ho cho nguoi dan tren toan Viet Nam.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Palette.muted, height: 1.55),
                  ),
                ],
              ),
            ),
            const Text(
              'Dang nhap',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Palette.text,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Vui long dang nhap de tiep tuc',
              style: TextStyle(color: Palette.muted),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.phone),
                labelText: 'Email hoac so dien thoai',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: password,
              obscureText: !showPassword,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock),
                labelText: 'Mat khau',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => showPassword = !showPassword),
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
              label: Text(loading ? 'Dang dang nhap...' : 'Dang nhap'),
            ),
            if (widget.onOpenRegister != null || widget.onOpenSos != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (widget.onOpenRegister != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onOpenRegister,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Dang ky'),
                      ),
                    ),
                  if (widget.onOpenRegister != null && widget.onOpenSos != null)
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
            const SectionLabel('Tai khoan thu nghiem'),
            const SizedBox(height: 8),
            ...demoAccounts.map(
              (acc) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    backgroundColor: Palette.bgSurface,
                    side: const BorderSide(color: Palette.border),
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
                        '${acc.$2}  |  ${acc.$3}',
                        style: const TextStyle(
                          color: Palette.muted,
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
      ),
    );
  }
}
