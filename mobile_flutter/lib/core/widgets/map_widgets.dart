import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/core/config/map_config.dart';
import 'package:mobile_flutter/core/utils/data_helpers.dart';
import 'package:mobile_flutter/core/widgets/cards.dart';
import 'package:mobile_flutter/core/widgets/layout_widgets.dart';

enum MapPointType { request, victim, team, safeZone, route }

class MapPoint {
  const MapPoint({
    required this.label,
    required this.type,
    this.details = const {},
    this.position,
  });

  final String label;
  final MapPointType type;
  final Map<String, String> details;
  final LatLng? position;

  static MapPoint fromMap(
    Map<String, dynamic> map, {
    required String latKey,
    required String lngKey,
    required String labelKey,
    required MapPointType type,
  }) {
    final lat = double.tryParse(valueOf(map, latKey));
    final lng = double.tryParse(valueOf(map, lngKey));
    return MapPoint(
      label: valueOf(map, labelKey, fallback: type.name),
      type: type,
      details: _detailsFor(map, type),
      position: lat == null || lng == null ? null : LatLng(lat, lng),
    );
  }

  static Map<String, String> _detailsFor(
    Map<String, dynamic> map,
    MapPointType type,
  ) {
    final pairs = <String, String>{};
    void add(String label, String key, {String fallback = ''}) {
      final value = valueOf(map, key, fallback: fallback);
      if (value.isNotEmpty && value != 'null') pairs[label] = value;
    }

    switch (type) {
      case MapPointType.request:
        add('Điện thoại', 'phone');
        add('Khu vực', 'area_name');
        add('Địa chỉ', 'address_detail');
        add('Mức độ', 'emergency_level');
        add('Trạng thái', 'status');
        add('Số người', 'number_of_people');
      case MapPointType.victim:
        add('Điện thoại', 'victim_phone');
        add('Địa chỉ', 'victim_address');
        add('Đội xử lý', 'team_name');
        add('Trạng thái', 'status');
      case MapPointType.team:
        add('Trưởng đội', 'leader_name');
        add('Điện thoại', 'phone');
        add('Khu vực', 'area_name');
        add('Phương tiện', 'vehicle_type');
        add('Trạng thái', 'status');
      case MapPointType.safeZone:
        add('Địa chỉ', 'address');
        add('Liên hệ', 'contact_person');
        add('Điện thoại', 'contact_phone');
        add('Sức chứa', 'capacity');
        add('Hiện có', 'current_people');
        add('Trạng thái', 'status');
      case MapPointType.route:
        add('Từ', 'start_point');
        add('Đến', 'end_point');
        add('Mức an toàn', 'safety_level');
        add('Trạng thái', 'status');
        add('Ghi chú', 'note');
    }
    return pairs;
  }

  String get typeLabel {
    return switch (type) {
      MapPointType.request => 'Yêu cầu cứu hộ',
      MapPointType.victim => 'Vị trí nạn nhân',
      MapPointType.team => 'Đội cứu hộ',
      MapPointType.safeZone => 'Điểm sơ tán',
      MapPointType.route => 'Tuyến đường',
    };
  }

  Color get color {
    return switch (type) {
      MapPointType.request => Palette.danger,
      MapPointType.victim => Palette.danger,
      MapPointType.team => Palette.accent,
      MapPointType.safeZone => Palette.success,
      MapPointType.route => Palette.warning,
    };
  }

  IconData get icon {
    return switch (type) {
      MapPointType.request => Icons.sos,
      MapPointType.victim => Icons.person_pin_circle,
      MapPointType.team => Icons.groups,
      MapPointType.safeZone => Icons.shield,
      MapPointType.route => Icons.route,
    };
  }
}

class RescueMap extends StatefulWidget {
  const RescueMap({
    super.key,
    required this.title,
    required this.points,
    this.compact = false,
  });

  final String title;
  final List<MapPoint> points;
  final bool compact;

  @override
  State<RescueMap> createState() => _RescueMapState();
}

class _RescueMapState extends State<RescueMap> {
  final mapController = MapController();
  MapPoint? selectedPoint;

  @override
  Widget build(BuildContext context) {
    final validPoints = widget.points
        .where((point) => point.position != null)
        .toList();
    if (validPoints.isEmpty) {
      return CardBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(icon: Icons.map, title: widget.title),
            const SizedBox(height: 10),
            const Text(
              'Chưa có dữ liệu tọa độ để hiển thị bản đồ.',
              style: TextStyle(color: Palette.muted),
            ),
          ],
        ),
      );
    }

    final selected = _selectedOrPrimary(validPoints);
    final focusPoints = _focusPoints(validPoints);
    final center = _centerOf(focusPoints);
    final initialZoom = focusPoints.length == 1 ? 13.5 : 8.5;
    return CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(icon: Icons.map, title: widget.title),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: widget.compact ? 190 : 280,
              child: FlutterMap(
                key: ValueKey(_pointsSignature(validPoints)),
                mapController: mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: initialZoom,
                  minZoom: 4,
                  maxZoom: 18,
                ),
                children: [
                  TileLayer(
                    urlTemplate: mapTileUrl,
                    userAgentPackageName: mapUserAgent,
                  ),
                  MarkerLayer(
                    markers: validPoints.map((point) {
                      final isSelected = _samePoint(selected, point);
                      return Marker(
                        point: point.position!,
                        width: isSelected ? 54 : 44,
                        height: isSelected ? 54 : 44,
                        child: GestureDetector(
                          onTap: () => _focusOn(point),
                          child: Tooltip(
                            message: '${point.typeLabel}: ${point.label}',
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              decoration: BoxDecoration(
                                color: point.color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: isSelected ? 4 : 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected
                                        ? point.color.withValues(alpha: .45)
                                        : const Color(0x33000000),
                                    blurRadius: isSelected ? 16 : 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                point.icon,
                                color: Colors.white,
                                size: isSelected ? 24 : 20,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          MapInfoPanel(point: selected),
          const SizedBox(height: 10),
          MapLegend(
            types: validPoints.map((point) => point.type).toSet().toList(),
          ),
          if (!widget.compact) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: validPoints.take(8).map((point) {
                return ActionChip(
                  avatar: Icon(point.icon, color: point.color, size: 16),
                  label: Text(point.label),
                  backgroundColor: point.color.withValues(alpha: .12),
                  side: BorderSide(color: point.color.withValues(alpha: .18)),
                  onPressed: () => _focusOn(point),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  LatLng _centerOf(List<MapPoint> points) {
    final lat =
        points
            .map((point) => point.position!.latitude)
            .reduce((a, b) => a + b) /
        points.length;
    final lng =
        points
            .map((point) => point.position!.longitude)
            .reduce((a, b) => a + b) /
        points.length;
    return LatLng(lat, lng);
  }

  void _focusOn(MapPoint point) {
    final position = point.position;
    if (position == null) return;
    setState(() => selectedPoint = point);
    mapController.move(position, 15);
  }

  List<MapPoint> _focusPoints(List<MapPoint> points) {
    final emergencyPoints = points
        .where(
          (point) =>
              [MapPointType.request, MapPointType.victim].contains(point.type),
        )
        .toList();
    return emergencyPoints.isEmpty ? points : emergencyPoints;
  }

  MapPoint _selectedOrPrimary(List<MapPoint> points) {
    final selected = selectedPoint;
    if (selected != null) {
      for (final point in points) {
        if (_samePoint(selected, point)) return point;
      }
    }
    final focusPoints = _focusPoints(points);
    return focusPoints.first;
  }

  bool _samePoint(MapPoint a, MapPoint b) {
    return a.type == b.type &&
        a.label == b.label &&
        a.position?.latitude == b.position?.latitude &&
        a.position?.longitude == b.position?.longitude;
  }

  String _pointsSignature(List<MapPoint> points) {
    return points
        .map(
          (point) =>
              '${point.type.name}:${point.label}:${point.position!.latitude.toStringAsFixed(6)},${point.position!.longitude.toStringAsFixed(6)}',
        )
        .join('|');
  }
}

class MapInfoPanel extends StatelessWidget {
  const MapInfoPanel({super.key, required this.point});
  final MapPoint point;

  @override
  Widget build(BuildContext context) {
    final position = point.position;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: point.color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: point.color.withValues(alpha: .18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(point.icon, color: point.color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  point.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              BadgePill(
                label: point.typeLabel,
                bg: point.color.withValues(alpha: .14),
                fg: point.color,
              ),
            ],
          ),
          if (position != null) ...[
            const SizedBox(height: 6),
            Text(
              'Tọa độ: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
              style: const TextStyle(color: Palette.muted, fontSize: 12),
            ),
          ],
          if (point.details.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...point.details.entries
                .take(6)
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 86,
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              color: Palette.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _displayValue(entry.value),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  String _displayValue(String value) {
    if ([
      'PENDING',
      'ASSIGNED',
      'ACCEPTED',
      'MOVING',
      'RESCUING',
      'RESCUED',
      'AVAILABLE',
      'BUSY',
      'FULL',
    ].contains(value)) {
      return statusLabel(value);
    }
    if (['LOW', 'MEDIUM', 'HIGH', 'EMERGENCY'].contains(value)) {
      return levelLabel(value);
    }
    return value;
  }
}

class MapLegend extends StatelessWidget {
  const MapLegend({super.key, required this.types});
  final List<MapPointType> types;

  @override
  Widget build(BuildContext context) {
    final entries = types.map((type) => _LegendEntry(type)).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: Palette.bgSurface,
            border: Border.all(color: Palette.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(entry.icon, color: entry.color, size: 16),
              const SizedBox(width: 5),
              Text(
                entry.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Palette.secondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _LegendEntry {
  _LegendEntry(this.type);
  final MapPointType type;

  int get order => switch (type) {
    MapPointType.request => 0,
    MapPointType.victim => 1,
    MapPointType.team => 2,
    MapPointType.safeZone => 3,
    MapPointType.route => 4,
  };

  String get label => MapPoint(label: '', type: type).typeLabel;
  Color get color => MapPoint(label: '', type: type).color;
  IconData get icon => MapPoint(label: '', type: type).icon;
}
