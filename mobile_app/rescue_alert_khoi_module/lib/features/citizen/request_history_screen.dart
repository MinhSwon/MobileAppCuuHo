import 'package:flutter/material.dart';
import '../../models/rescue_request.dart';
import '../../services/rescue_request_service.dart';
import 'request_detail_screen.dart';

class RequestHistoryScreen extends StatefulWidget {
  const RequestHistoryScreen({super.key});

  @override
  State<RequestHistoryScreen> createState() => _RequestHistoryScreenState();
}

class _RequestHistoryScreenState extends State<RequestHistoryScreen> {
  final _service = RescueRequestService();
  late Future<List<RescueRequest>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getMyRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử yêu cầu cứu hộ')),
      body: FutureBuilder<List<RescueRequest>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
          final requests = snapshot.data ?? [];
          if (requests.isEmpty) return const Center(child: Text('Chưa có yêu cầu cứu hộ'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = requests[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.sos, color: Colors.red),
                  title: Text(item.emergencyType),
                  subtitle: Text('${item.status}\n${item.address}'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestDetailScreen(request: item))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
