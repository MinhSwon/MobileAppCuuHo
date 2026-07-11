import 'dart:async';

import 'package:flutter/material.dart';

import 'package:mobile_flutter/data/api/api_client.dart';
import 'package:mobile_flutter/features/auth/presentation/public_access_screen.dart';
import 'package:mobile_flutter/features/shell/presentation/role_shell.dart';
import 'package:mobile_flutter/core/utils/data_helpers.dart';
import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/app/splash_screen.dart';

class RescueVNApp extends StatefulWidget {
  const RescueVNApp({super.key});

  @override
  State<RescueVNApp> createState() => _RescueVNAppState();
}

class _RescueVNAppState extends State<RescueVNApp> with WidgetsBindingObserver {
  late final ApiClient api;
  Map<String, dynamic>? user;
  Map<String, dynamic>? profile;
  Map<String, dynamic> db = {};
  bool booting = true;
  bool syncing = false;
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
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      refreshTimer?.cancel();
      refreshTimer = null;
    }
  }

  Future<void> _restore() async {
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
    refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => refreshDb(silent: true));
  }

  Future<void> refreshDb({bool silent = false}) async {
    if (syncing) return;
    if (mounted) setState(() => syncing = true);
    try {
      final data = await api.fetchDb();
      if (mounted) setState(() => db = data);
    } catch (err) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không đồng bộ được dữ liệu: $err')));
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
    await api.logout();
    refreshTimer?.cancel();
    refreshTimer = null;
    setState(() {
      user = null;
      profile = null;
      db = {};
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cứu Hộ Việt Nam',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Palette.accent,
          primary: Palette.accent,
          error: Palette.danger,
          surface: Palette.elevated,
        ),
        scaffoldBackgroundColor: Palette.bgBase,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Palette.sidebar,
          foregroundColor: Color(0xfffdf9f3),
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Palette.elevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Palette.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Palette.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Palette.accent, width: 1.4),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Palette.accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            minimumSize: const Size(44, 46),
          ),
        ),
        cardTheme: CardThemeData(
          color: Palette.elevated,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Palette.border),
          ),
        ),
      ),
      home: booting
          ? const SplashScreen()
          : user == null
              ? PublicAccessScreen(
                  api: api,
                  db: db,
                  onRefresh: refreshDb,
                  onLogin: handleLogin,
                  onRegister: handleRegister,
                )
              : RoleShell(
                  api: api,
                  user: user!,
                  profile: profile,
                  db: db,
                  onRefresh: refreshDb,
                  onLogout: handleLogout,
                ),
    );
  }
}
