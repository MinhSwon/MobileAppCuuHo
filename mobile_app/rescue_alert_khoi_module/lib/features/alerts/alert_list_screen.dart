import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  late Future<List<AlertModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getAlerts();
  }

  Future<void> _refresh() async {
    setState(() => _future = _service.getAlerts());
    try {
      await _future;
    } catch (_) {}
  }

  Color _severityColor(String severity) {
    switch (AlertModel.normalizeSeverity(severity)) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.deepOrange;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cảnh báo cho người dân')),
      body: FutureBuilder<List<AlertModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString().replaceFirst(
                'Exception: ',
                '',
              ),
              onRetry: _refresh,
            );
          }

          final alerts = snapshot.data ?? [];
          if (alerts.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: const [
                  SizedBox(height: 180),
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 56,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Center(child: Text('Không có cảnh báo')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final alert = alerts[index];
                final severityColor = _severityColor(alert.severityLevel);
                return Card(
                  child: ListTile(
                    leading: Icon(Icons.warning_amber, color: severityColor),
                    title: Text(alert.title),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(alert.area),
                          Text(_dateFormat.format(alert.createdAt)),
                        ],
                      ),
                    ),
                    isThreeLine: true,
                    trailing: Chip(
                      label: Text(alert.severityText),
                      backgroundColor: severityColor.withAlpha(32),
                      labelStyle: TextStyle(
                        color: severityColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AlertDetailScreen(alert: alert),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
