import 'package:flutter/material.dart';
import '../../models/alert_model.dart';

class AlertDetailScreen extends StatelessWidget {
  final AlertModel alert;
  const AlertDetailScreen({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết cảnh báo')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Chip(label: Text('Mức độ: ${alert.severityLevel}')),
            const SizedBox(height: 8),
            Text('Khu vực: ${alert.area}'),
            Text('Loại cảnh báo: ${alert.alertType}'),
            const Divider(height: 32),
            Text(alert.content, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
