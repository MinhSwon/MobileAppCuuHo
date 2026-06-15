import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/rescue_request.dart';
import '../../services/rescue_request_service.dart';

class RequestDetailScreen extends StatefulWidget {
  final RescueRequest request;

  const RequestDetailScreen({super.key, required this.request});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  final _service = RescueRequestService();
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  late Future<RescueRequest> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getRequestById(widget.request.id);
  }

  void _reload() {
    setState(() => _future = _service.getRequestById(widget.request.id));
  }

  Color _statusColor(String status) {
    switch (RescueRequest.normalizeStatus(status)) {
      case 'completed':
        return Colors.green;
      case 'canceled':
        return Colors.red;
      case 'submitted':
      case 'pending':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Yêu cầu ${widget.request.id}')),
      body: FutureBuilder<RescueRequest>(
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

          final request = snapshot.data ?? widget.request;
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  request.emergencyType,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text(request.statusText),
                      backgroundColor: _statusColor(
                        request.status,
                      ).withAlpha(32),
                      labelStyle: TextStyle(
                        color: _statusColor(request.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Chip(label: Text('Ưu tiên: ${request.priorityText}')),
                  ],
                ),
                const SizedBox(height: 12),
                Text(request.description),
                const Divider(height: 32),
                _InfoRow(label: 'Địa chỉ', value: request.address),
                _InfoRow(
                  label: 'Latitude',
                  value: request.latitude.toStringAsFixed(6),
                ),
                _InfoRow(
                  label: 'Longitude',
                  value: request.longitude.toStringAsFixed(6),
                ),
                _InfoRow(
                  label: 'Thời gian gửi',
                  value: _dateFormat.format(request.createdAt),
                ),
                const Divider(height: 32),
                const Text(
                  'Trạng thái xử lý',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _StatusTimeline(request: request),
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
            width: 110,
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

class _StatusTimeline extends StatelessWidget {
  final RescueRequest request;

  const _StatusTimeline({required this.request});

  @override
  Widget build(BuildContext context) {
    final currentIndex = request.statusIndex;
    final isCanceled =
        RescueRequest.normalizeStatus(request.status) == 'canceled';

    // Status: hien thi du 8 moc xu ly theo tai lieu phan M2.
    return Column(
      children: List.generate(RescueRequest.statusSteps.length, (index) {
        final status = RescueRequest.statusSteps[index];
        final isCurrent = index == currentIndex;
        final isDone = isCanceled
            ? index == 0 || isCurrent
            : index <= currentIndex;
        final color = isCurrent && isCanceled
            ? Colors.red
            : isDone
            ? Colors.green
            : Colors.grey;

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: color,
          ),
          title: Text(
            RescueRequest.statusLabel(status),
            style: TextStyle(
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent && isCanceled ? Colors.red : null,
            ),
          ),
        );
      }),
    );
  }
}
