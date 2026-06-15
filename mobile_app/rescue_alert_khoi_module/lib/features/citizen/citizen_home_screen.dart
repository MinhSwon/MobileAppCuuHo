import 'package:flutter/material.dart';

class CitizenHomeScreen extends StatelessWidget {
  const CitizenHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trang chủ người dân'), actions: [IconButton(onPressed: () => Navigator.pushReplacementNamed(context, '/login'), icon: const Icon(Icons.logout))]),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Xin chào, Nguyễn Nhật Khôi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Khi gặp nguy hiểm, hãy nhấn nút SOS để gửi yêu cầu cứu hộ kèm vị trí GPS.'),
            const SizedBox(height: 32),
            SizedBox(
              height: 150,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                onPressed: () => Navigator.pushNamed(context, '/citizen/sos'),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Icon(Icons.sos, size: 64, color: Colors.white), Text('SOS KHẨN CẤP', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white))],
                ),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(onPressed: () => Navigator.pushNamed(context, '/citizen/requests'), icon: const Icon(Icons.history), label: const Text('Lịch sử & trạng thái cứu hộ')),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: () => Navigator.pushNamed(context, '/citizen/alerts'), icon: const Icon(Icons.warning), label: const Text('Cảnh báo khẩn cấp')),
          ],
        ),
      ),
    );
  }
}
