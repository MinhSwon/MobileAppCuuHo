import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/core/core.dart';
import 'package:mobile_flutter/data/data.dart';
import 'package:mobile_flutter/features/rescue/presentation/mission_timeline.dart';

class MissionDetailScreen extends StatefulWidget {
  const MissionDetailScreen({
    super.key,
    required this.api,
    required this.user,
    required this.data,
    required this.mission,
    required this.onChanged,
  });

  final ApiClient api;
  final Map<String, dynamic> user;
  final AppData data;
  final Map<String, dynamic> mission;
  final Future<void> Function() onChanged;

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  bool loading = false;
  String locationStatus = '';

  List<Map<String, dynamic>> get logs {
    final missionId = valueOf(widget.mission, 'id');
    final items = widget.data.missionStatusLogs
        .where((log) => valueOf(log, 'mission_id') == missionId)
        .toList();
    items.sort(
      (a, b) => valueOf(b, 'created_at').compareTo(valueOf(a, 'created_at')),
    );
    return items;
  }

  Future<void> updateStatus(String status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cập nhật ${statusLabel(status)}?'),
        content: Text(
          'Nhiệm vụ của ${valueOf(widget.mission, 'victim_name')} sẽ chuyển sang trạng thái này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => loading = true);
    try {
      final location = await LocationService.current();
      final extraData = <String, dynamic>{};
      if (location.hasLocation) {
        extraData.addAll(location.location!.toMissionPayload());
      }
      setState(() {
        locationStatus = location.hasLocation
            ? 'Đã cập nhật GPS: ${location.location!.latitude.toStringAsFixed(5)}, ${location.location!.longitude.toStringAsFixed(5)}'
            : 'Không có GPS: ${location.message}';
      });
      await widget.api.updateMissionStatus(
        valueOf(widget.mission, 'id'),
        status,
        widget.user,
        extraData: extraData,
        note: 'Đội cứu hộ cập nhật: ${statusLabel(status)}',
      );
      await widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã cập nhật ${statusLabel(status)}')),
        );
        // Không pop — ở lại màn hình để xem timeline mới nhất
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không cập nhật được nhiệm vụ: $err')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể gọi số $phone')));
      }
    }
  }

  Future<void> copyContact(String value, String label) async {
    if (value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã sao chép $label')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mission = widget.mission;
    final phone = valueOf(mission, 'victim_phone');
    final address = valueOf(mission, 'victim_address');
    final lat = valueOf(mission, 'victim_latitude');
    final lng = valueOf(mission, 'victim_longitude');
    final coordinates = lat.isEmpty || lng.isEmpty ? '' : '$lat,$lng';
    final terminal = [
      'RESCUED',
      'TRANSFERRED_SAFEZONE',
      'COMPLETED',
      'CANCELLED',
      'UNREACHABLE',
      'FALSE_ALARM',
    ].contains(valueOf(mission, 'status'));

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết nhiệm vụ')),
      body: AppList(
        children: [
          PageTitle(
            valueOf(mission, 'victim_name', fallback: 'Nạn nhân'),
            statusLabel(valueOf(mission, 'status')),
          ),
          MissionCard(mission: mission),
          const SectionHeader(
            icon: Icons.contact_phone,
            title: 'Liên hệ & vị trí',
          ),
          CardBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoRow('Điện thoại', phone.isEmpty ? '-' : phone),
                InfoRow('Địa chỉ', address.isEmpty ? '-' : address),
                InfoRow('Tọa độ', coordinates.isEmpty ? '-' : coordinates),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (phone.isNotEmpty)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Palette.success,
                        ),
                        onPressed: () => callPhone(phone),
                        icon: const Icon(Icons.call),
                        label: const Text('Gọi ngay'),
                      ),
                    OutlinedButton.icon(
                      onPressed: phone.isEmpty
                          ? null
                          : () => copyContact(phone, 'số điện thoại'),
                      icon: const Icon(Icons.phone),
                      label: const Text('Sao chép SĐT'),
                    ),
                    OutlinedButton.icon(
                      onPressed: address.isEmpty
                          ? null
                          : () => copyContact(address, 'địa chỉ'),
                      icon: const Icon(Icons.location_on),
                      label: const Text('Sao chép địa chỉ'),
                    ),
                    OutlinedButton.icon(
                      onPressed: coordinates.isEmpty
                          ? null
                          : () => copyContact(coordinates, 'tọa độ'),
                      icon: const Icon(Icons.my_location),
                      label: const Text('Sao chép tọa độ'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SectionHeader(icon: Icons.timeline, title: 'Tiến độ xử lý'),
          if (locationStatus.isNotEmpty)
            AlertPanel(
              title: 'GPS đội cứu hộ',
              message: locationStatus,
              color: locationStatus.startsWith('Đã cập nhật')
                  ? Palette.success
                  : Palette.warning,
              icon: Icons.my_location,
            ),
          MissionTimeline(
            logs: logs,
            currentStatus: valueOf(mission, 'status'),
          ),
          if (!terminal) ...[
            const SectionHeader(
              icon: Icons.published_with_changes,
              title: 'Cập nhật trạng thái',
            ),
            CardBox(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final status in const [
                    'ACCEPTED',
                    'MOVING',
                    'NEAR_VICTIM',
                    'ARRIVED_CONFIRMED',
                    'RESCUING',
                    'NEED_SUPPORT',
                    'UNREACHABLE',
                    'FALSE_ALARM',
                    'RESCUED',
                    'TRANSFERRED_SAFEZONE',
                  ])
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusColor(status),
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: loading ? null : () => updateStatus(status),
                      child: Text(statusLabel(status)),
                    ),
                ],
              ),
            ),
          ] else
            const AlertPanel(
              title: 'Nhiệm vụ đã kết thúc',
              message:
                  'Nhiệm vụ này không còn trong luồng cập nhật hiện trường.',
              color: Palette.success,
              icon: Icons.check_circle,
            ),
        ],
      ),
    );
  }
}
