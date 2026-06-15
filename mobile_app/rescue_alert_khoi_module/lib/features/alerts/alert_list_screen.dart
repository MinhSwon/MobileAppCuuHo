import 'package:flutter/material.dart';
import '../../models/alert_model.dart';
import '../../services/alert_service.dart';
import 'alert_detail_screen.dart';

class AlertListScreen extends StatefulWidget {
  const AlertListScreen({super.key});

  @override
  State<AlertListScreen> createState() => _AlertListScreenState();
}

class _AlertListScreenState extends State<AlertListScreen> {
  final _service = AlertService();
  late Future<List<AlertModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cảnh báo khẩn cấp')),
      body: FutureBuilder<List<AlertModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
          final alerts = snapshot.data ?? [];
          if (alerts.isEmpty) return const Center(child: Text('Không có cảnh báo'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.warning_amber, color: Colors.orange),
                  title: Text(alert.title),
                  subtitle: Text('${alert.area} • Mức độ: ${alert.severityLevel}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AlertDetailScreen(alert: alert))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
