import 'package:flutter/material.dart';

import '../../models/rescue_request.dart';
import '../../services/location_service.dart';
import '../../services/rescue_request_service.dart';

class SosFormScreen extends StatefulWidget {
  const SosFormScreen({super.key});

  @override
  State<SosFormScreen> createState() => _SosFormScreenState();
}

class _SosFormScreenState extends State<SosFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _requestService = RescueRequestService();
  final _locationService = LocationService();

  String _emergencyType = 'Tai nạn giao thông';
  String _priorityLevel = 'high';
  double? _latitude;
  double? _longitude;
  bool _loadingLocation = false;
  bool _submitting = false;

  static const List<String> _emergencyTypes = [
    'Tai nạn giao thông',
    'Cấp cứu y tế',
    'Ngập nước',
    'Sạt lở',
    'Mất tích',
    'Khác',
  ];

  Future<void> _getLocation() async {
    setState(() => _loadingLocation = true);
    try {
      // GPS: xin quyen, kiem tra GPS va lay toa do hien tai.
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_cleanError(e))));
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _submitSos() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng lấy vị trí GPS trước khi gửi SOS'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      // API: tao yeu cau cuu ho moi voi day du field theo phan M2.
      final id = await _requestService.createRequest(
        emergencyType: _emergencyType,
        description: _descriptionController.text.trim(),
        latitude: _latitude!,
        longitude: _longitude!,
        address: _addressController.text.trim(),
        priorityLevel: _priorityLevel,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Gửi SOS thành công'),
          content: Text(
            'Mã yêu cầu: $id\nTrạng thái ban đầu: ${RescueRequest.statusLabel('submitted')}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.pushReplacementNamed(context, '/citizen/requests');
              },
              child: const Text('Xem trạng thái'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_cleanError(e))));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _required(String? value, String label) {
    if ((value ?? '').trim().isEmpty) return 'Vui lòng nhập $label';
    return null;
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gửi SOS khẩn cấp')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _emergencyType,
                decoration: const InputDecoration(
                  labelText: 'emergency_type',
                  prefixIcon: Icon(Icons.emergency_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _emergencyTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: _submitting
                    ? null
                    : (value) => setState(() => _emergencyType = value!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                validator: (value) => _required(value, 'mô tả tình trạng'),
                decoration: const InputDecoration(
                  labelText: 'description',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                textInputAction: TextInputAction.done,
                validator: (value) => _required(value, 'địa chỉ'),
                decoration: const InputDecoration(
                  labelText: 'address',
                  prefixIcon: Icon(Icons.place_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _priorityLevel,
                decoration: const InputDecoration(
                  labelText: 'priority_level',
                  prefixIcon: Icon(Icons.priority_high),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Thấp')),
                  DropdownMenuItem(value: 'medium', child: Text('Trung bình')),
                  DropdownMenuItem(value: 'high', child: Text('Cao')),
                  DropdownMenuItem(value: 'urgent', child: Text('Khẩn cấp')),
                ],
                onChanged: _submitting
                    ? null
                    : (value) => setState(() => _priorityLevel = value!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _LocationBox(
                      label: 'latitude',
                      value: _latitude == null
                          ? 'Chưa có'
                          : _latitude!.toStringAsFixed(6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LocationBox(
                      label: 'longitude',
                      value: _longitude == null
                          ? 'Chưa có'
                          : _longitude!.toStringAsFixed(6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed:
                    _loadingLocation || _submitting ? null : _getLocation,
                icon: _loadingLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  _loadingLocation ? 'Đang lấy vị trí...' : 'Lấy vị trí GPS',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _submitting ? null : _submitSos,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_submitting ? 'Đang gửi...' : 'Gửi yêu cầu SOS'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationBox extends StatelessWidget {
  final String label;
  final String value;

  const _LocationBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
