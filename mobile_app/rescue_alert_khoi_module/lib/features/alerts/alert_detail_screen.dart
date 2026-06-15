import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/alert_model.dart';
import '../../services/alert_service.dart';

class AlertDetailScreen extends StatefulWidget {
  final AlertModel alert;

  const AlertDetailScreen({super.key, required this.alert});

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  final _service = AlertService();
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  late Future<AlertModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getAlertById(widget.alert.id);
  }

  void _reload() {
    setState(() => _future = _service.getAlertById(widget.alert.id));
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
      appBar: AppBar(title: const Text('Chi tiết cảnh báo')),
      body: FutureBuilder<AlertModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error.toString().replaceFirst('Exception: ', ''),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final alert = snapshot.data ?? widget.alert;
          final severityColor = _severityColor(alert.severityLevel);
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text('Mức độ: ${alert.severityText}'),
                      backgroundColor: severityColor.withAlpha(32),
                      labelStyle: TextStyle(
                        color: severityColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Chip(label: Text(alert.alertType)),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoRow(label: 'Khu vực', value: alert.area),
                _InfoRow(
                  label: 'Thời gian',
                  value: _dateFormat.format(alert.createdAt),
                ),
                const Divider(height: 32),
                Text(alert.content, style: const TextStyle(fontSize: 16)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? 'Chưa có' : value)),
        ],
      ),
    );
  }
}
