import 'dart:async';

import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/splash_screen.dart';
import 'package:mobile_flutter/app/theme/app_theme.dart';
import 'package:mobile_flutter/core/utils/data_helpers.dart';
import 'package:mobile_flutter/data/api/api_client.dart';
import 'package:mobile_flutter/data/storage/simple_session_store.dart';
import 'package:mobile_flutter/features/auth/presentation/public_access_screen.dart';
import 'package:mobile_flutter/features/shell/presentation/role_shell.dart';

class RescueVNApp extends StatefulWidget {
  const RescueVNApp({super.key});

  @override
  State<RescueVNApp> createState() => _RescueVNAppState();
}

class _RescueVNAppState extends State<RescueVNApp> with WidgetsBindingObserver {
  late final ApiClient api;
  final settingsStore = SimpleSessionStore();
  Map<String, dynamic>? user;
  Map<String, dynamic>? profile;
  Map<String, dynamic> db = {};
  bool booting = true;
  bool syncing = false;
  bool darkMode = false;
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    api = ApiClient();
    _restore();
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && user != null) {
      refreshDb(silent: true);
      _configurePolling();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      refreshTimer?.cancel();
      refreshTimer = null;
    }
  }

  Future<void> _restore() async {
    darkMode = await settingsStore.read(key: 'themeMode') == 'dark';
    await api.restoreToken();
    user = await api.readJson('currentUser');
    profile = await api.readJson('currentProfile');
    try {
      await refreshDb(silent: true);
    } catch (_) {
      db = {};
    }
    _configurePolling();
    setState(() => booting = false);
  }

  void _configurePolling() {
    refreshTimer?.cancel();
    refreshTimer = null;
    if (user == null) return;
    refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => refreshDb(silent: true),
    );
  }

  Future<void> refreshDb({bool silent = false}) async {
    if (syncing) return;
    if (mounted) setState(() => syncing = true);
    try {
      final data = await api.fetchDb();
      if (mounted) setState(() => db = data);
    } catch (err) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không đồng bộ được dữ liệu: $err')),
        );
      }
    } finally {
      if (mounted) setState(() => syncing = false);
    }
  }

  Future<void> handleLogin(String emailOrPhone, String password) async {
    final result = await api.login(emailOrPhone, password);
    user = mapOf(result['user']);
    profile = mapOf(result['profile']);
    await refreshDb();
    _configurePolling();
    setState(() {});
  }

  Future<void> handleRegister(Map<String, dynamic> payload) async {
    final result = await api.register(payload);
    user = mapOf(result['user']);
    profile = mapOf(result['profile']);
    await refreshDb();
    _configurePolling();
    setState(() {});
  }

  Future<void> handleLogout() async {
    final currentTheme = darkMode ? 'dark' : 'light';
    await api.logout();
    await settingsStore.write(key: 'themeMode', value: currentTheme);
    refreshTimer?.cancel();
    refreshTimer = null;
    setState(() {
      user = null;
      profile = null;
      db = {};
    });
  }

  Future<void> toggleTheme() async {
    final next = !darkMode;
    setState(() => darkMode = next);
    await settingsStore.write(key: 'themeMode', value: next ? 'dark' : 'light');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cứu Hộ Việt Nam',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      home: booting
          ? const SplashScreen()
          : user == null
          ? PublicAccessScreen(
              api: api,
              db: db,
              darkMode: darkMode,
              onToggleTheme: toggleTheme,
              onRefresh: refreshDb,
              onLogin: handleLogin,
              onRegister: handleRegister,
            )
          : RoleShell(
              api: api,
              user: user!,
              profile: profile,
              db: db,
              darkMode: darkMode,
              onToggleTheme: toggleTheme,
              onRefresh: refreshDb,
              onLogout: handleLogout,
            ),
    );
  }
}
