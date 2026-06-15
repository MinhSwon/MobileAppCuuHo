import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'citizen@gmail.com');
  final _passwordController = TextEditingController(text: '123456');
  final _authService = AuthService();
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await _authService.login(_emailController.text, _passwordController.text);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/citizen/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.health_and_safety, size: 80, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Rescue Alert', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu', border: OutlineInputBorder())),
                const SizedBox(height: 20),
                FilledButton(onPressed: _loading ? null : _login, child: Text(_loading ? 'Đang đăng nhập...' : 'Đăng nhập')),
                TextButton(onPressed: () => Navigator.pushNamed(context, '/register'), child: const Text('Tạo tài khoản người dân')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
