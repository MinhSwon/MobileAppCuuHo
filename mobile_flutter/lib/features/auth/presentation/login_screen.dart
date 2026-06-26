import 'package:flutter/material.dart';

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
  final emailOrPhone = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool showPassword = false;

  Future<void> submit() async {
    setState(() => loading = true);
    try {
      await widget.onLogin(emailOrPhone.text.trim(), password.text);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Dang nhap')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Dang nhap de tiep tuc su dung RescueVN.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: emailOrPhone,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email hoac so dien thoai',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: password,
            obscureText: !showPassword,
            decoration: InputDecoration(
              labelText: 'Mat khau',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: () => setState(() => showPassword = !showPassword),
                icon: Icon(
                  showPassword ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: loading ? null : submit,
            child: Text(loading ? 'Dang dang nhap...' : 'Dang nhap'),
          ),
          if (widget.onOpenRegister != null || widget.onOpenSos != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (widget.onOpenRegister != null)
                  OutlinedButton(
                    onPressed: widget.onOpenRegister,
                    child: const Text('Dang ky'),
                  ),
                if (widget.onOpenSos != null)
                  OutlinedButton(
                    onPressed: widget.onOpenSos,
                    child: const Text('SOS nhanh'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
