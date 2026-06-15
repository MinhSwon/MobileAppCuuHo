import 'package:flutter/material.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/citizen/citizen_home_screen.dart';
import 'features/citizen/sos_form_screen.dart';
import 'features/citizen/request_history_screen.dart';
import 'features/alerts/alert_list_screen.dart';

void main() {
  runApp(const RescueAlertApp());
}

class RescueAlertApp extends StatelessWidget {
  const RescueAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rescue Alert - Khoi Module',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/citizen/home': (_) => const CitizenHomeScreen(),
        '/citizen/sos': (_) => const SosFormScreen(),
        '/citizen/requests': (_) => const RequestHistoryScreen(),
        '/citizen/alerts': (_) => const AlertListScreen(),
      },
    );
  }
}
