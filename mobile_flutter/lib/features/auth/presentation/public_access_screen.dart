import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/data/data.dart';
import 'package:mobile_flutter/features/auth/presentation/login_screen.dart';
import 'package:mobile_flutter/features/auth/presentation/register_screen.dart';
import 'package:mobile_flutter/features/citizen/presentation/sos_screen.dart';

class PublicAccessScreen extends StatefulWidget {
  const PublicAccessScreen({
    super.key,
    required this.api,
    required this.db,
    required this.onRefresh,
    required this.onLogin,
    required this.onRegister,
  });

  final ApiClient api;
  final Map<String, dynamic> db;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String emailOrPhone, String password) onLogin;
  final Future<void> Function(Map<String, dynamic> payload) onRegister;

  @override
  State<PublicAccessScreen> createState() => _PublicAccessScreenState();
}

class _PublicAccessScreenState extends State<PublicAccessScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final data = AppData(widget.db);
    if (tab == 0) {
      return LoginScreen(
        onLogin: widget.onLogin,
        onOpenRegister: () => setState(() => tab = 1),
        onOpenSos: () => setState(() => tab = 2),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tab == 1 ? 'Đăng ký người dân' : 'SOS khẩn cấp'),
        actions: [
          IconButton(onPressed: widget.onRefresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: tab == 1
          ? RegisterScreen(data: data, onRegister: widget.onRegister)
          : SOSScreen(
              api: widget.api,
              user: const {},
              profile: null,
              data: data,
              onSubmitted: widget.onRefresh,
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tab,
        selectedItemColor: Palette.accent,
        unselectedItemColor: Palette.muted,
        onTap: (value) => setState(() => tab = value),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.login), label: 'Đăng nhập'),
          BottomNavigationBarItem(icon: Icon(Icons.person_add), label: 'Đăng ký'),
          BottomNavigationBarItem(icon: Icon(Icons.sos), label: 'SOS'),
        ],
      ),
    );
  }
}
