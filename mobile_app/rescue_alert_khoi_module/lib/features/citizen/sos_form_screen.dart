import 'package:flutter/material.dart';
import '../../services/location_service.dart';
import '../../services/rescue_request_service.dart';

class SosFormScreen extends StatefulWidget {
  const SosFormScreen({super.key});

  @override
  State<SosFormScreen> createState() => _SosFormScreenState();
}

class _SosFormScreenState extends State<SosFormScreen> {
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _requestService = RescueRequestService();
  final _locationService = LocationService();

  String _emergencyType = 'Tai nạn giao thông';
  String _priorityLevel = 'high';
  double? _latitude;
  double? _longitude;
  bool _loadingLocation = false;
  bool _submitting = false;

  Future<void> _getLocation() async {
    setState(() => _loadingLocation = true);
    try {
      final pos = await _locationService.getCurrentPosition();
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _submitSos() async {
    if (_description.text.trim().isEmpty || _latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập mô tả và lấy vị trí GPS')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final id = await _requestService.createRequest(
        emergencyType: _emergencyType,
        description: _description.text.trim(),
        latitude: _latitude!,
        longitude: _longitude!,
        address: _address.text.trim(),
        priorityLevel: _priorityLevel,
      );
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Gửi SOS thành công'),
          content: Text('Mã yêu cầu: $id\nTrạng thái ban đầu: Đang chờ xác nhận'),
          actions: [TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('OK'))],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gửi SOS khẩn cấp')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<String>(
            value: _emergencyType,
            decoration: const InputDecoration(labelText: 'Loại sự cố', border: OutlineInputBorder()),
            items: ['Tai nạn giao thông', 'Lũ lụt', 'Sạt lở', 'Mất tích', 'Khác'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _emergencyType = v!),
          ),
          const SizedBox(height: 12),
          TextField(controller: _description, maxLines: 3, decoration: const InputDecoration(labelText: 'Mô tả tình trạng', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _address, decoration: const InputDecoration(labelText: 'Địa chỉ mô tả thêm', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _priorityLevel,
            decoration: const InputDecoration(labelText: 'Mức độ ưu tiên', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'low', child: Text('Thấp')),
              DropdownMenuItem(value: 'medium', child: Text('Trung bình')),
              DropdownMenuItem(value: 'high', child: Text('Cao')),
              DropdownMenuItem(value: 'urgent', child: Text('Khẩn cấp')),
            ],
            onChanged: (v) => setState(() => _priorityLevel = v!),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: _loadingLocation ? null : _getLocation, icon: const Icon(Icons.my_location), label: Text(_loadingLocation ? 'Đang lấy vị trí...' : 'Lấy vị trí GPS')),
          if (_latitude != null && _longitude != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Latitude: $_latitude\nLongitude: $_longitude')),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: _submitting ? null : _submitSos, icon: const Icon(Icons.send), label: Text(_submitting ? 'Đang gửi...' : 'Gửi yêu cầu SOS')),
        ],
      ),
    );
  }
}
