import 'package:flutter/material.dart';
import '../../models/rescue_request.dart';

class RequestDetailScreen extends StatelessWidget {
  final RescueRequest request;
  const RequestDetailScreen({super.key, required this.request});

  static const statuses = [
    'Đã gửi yêu cầu',
    'Đang chờ xác nhận',
    'Đã phân công',
    'Đội cứu hộ đang di chuyển',
    'Đã đến nơi',
    'Đang xử lý',
    'Hoàn thành',
    'Hủy yêu cầu',
  ];

  int _statusIndex(String status) {
    final index = statuses.indexOf(status);
    return index < 0 ? 1 : index;
  }

  @override
  Widget build(BuildContext context) {
    final current = _statusIndex(request.status);
    return Scaffold(
      appBar: AppBar(title: Text('Chi tiết ${request.id}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(request.emergencyType, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(request.description),
          const SizedBox(height: 12),
          Text('Địa chỉ: ${request.address}'),
          Text('GPS: ${request.latitude}, ${request.longitude}'),
          Text('Ưu tiên: ${request.priorityLevel}'),
          const Divider(height: 32),
          const Text('Trạng thái xử lý', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...List.generate(statuses.length, (index) {
            final done = index <= current;
            return ListTile(
              leading: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? Colors.green : Colors.grey),
              title: Text(statuses[index]),
            );
          }),
        ],
      ),
    );
  }
}
