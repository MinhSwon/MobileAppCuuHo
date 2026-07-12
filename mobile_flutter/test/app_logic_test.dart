import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/core/core.dart';
import 'package:mobile_flutter/data/data.dart';
import 'package:mobile_flutter/features/features.dart';

void main() {
  test('status and level labels are localized', () {
    expect(statusLabel('PENDING'), 'Chờ tiếp nhận');
    expect(statusLabel('RESCUED'), 'Đã cứu');
    expect(levelLabel('EMERGENCY'), 'Khẩn cấp');
  });

  test('map point parses coordinate and useful details', () {
    final point = MapPoint.fromMap(
      {
        'full_name': 'Nguyễn Thị Mai',
        'phone': '0956789012',
        'area_name': 'Hà Nội',
        'address_detail': '45 Nguyễn Chí Thanh',
        'emergency_level': 'HIGH',
        'status': 'PENDING',
        'latitude': 21.0285,
        'longitude': 105.8542,
      },
      latKey: 'latitude',
      lngKey: 'longitude',
      labelKey: 'full_name',
      type: MapPointType.request,
    );

    expect(point.label, 'Nguyễn Thị Mai');
    expect(point.typeLabel, 'Yêu cầu cứu hộ');
    expect(point.position?.latitude, 21.0285);
    expect(point.details['Điện thoại'], '0956789012');
    expect(point.details['Mức độ'], 'HIGH');
  });

  testWidgets('rescue map renders selected point information and legend', (
    tester,
  ) async {
    final points = [
      MapPoint.fromMap(
        {
          'name': 'Điểm sơ tán Hà Nội',
          'address': 'Trường THCS Hà Nội',
          'status': 'AVAILABLE',
          'latitude': 21.0285,
          'longitude': 105.8542,
        },
        latKey: 'latitude',
        lngKey: 'longitude',
        labelKey: 'name',
        type: MapPointType.safeZone,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RescueMap(
            title: 'Bản đồ kiểm thử',
            points: points,
            compact: true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Bản đồ kiểm thử'), findsOneWidget);
    expect(find.text('Điểm sơ tán Hà Nội'), findsWidgets);
    expect(find.text('Điểm sơ tán'), findsWidgets);
    expect(find.textContaining('Tọa độ:'), findsOneWidget);
  });

  testWidgets(
    'SOS area picker defaults to the first available area and can change',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SOSScreen(
              api: ApiClient(),
              user: const {
                'id': 'u1',
                'full_name': 'Son',
                'phone': '094512356',
              },
              profile: const {},
              data: AppData({
                'areas': [
                  {'id': 'area-1', 'old_name': 'Area 1'},
                  {'id': 'area-2', 'old_name': 'Area 2'},
                ],
              }),
              onSubmitted: () async {},
            ),
          ),
        ),
      );

      expect(find.text('Area 1'), findsOneWidget);

      await tester.tap(find.text('Area 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Area 2').last);
      await tester.pumpAndSettle();

      expect(find.text('Area 2'), findsOneWidget);
    },
  );

  testWidgets('SOS area picker stays enabled when API areas are unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SOSScreen(
            api: ApiClient(),
            user: const {'id': 'u1', 'full_name': 'Son', 'phone': '094512356'},
            profile: const {},
            data: AppData(const {}),
            onSubmitted: () async {},
          ),
        ),
      ),
    );

    expect(find.text('H\u00e0 N\u1ed9i'), findsOneWidget);

    await tester.tap(find.text('H\u00e0 N\u1ed9i'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('\u0110\u00e0 N\u1eb5ng').last);
    await tester.pumpAndSettle();

    expect(find.text('\u0110\u00e0 N\u1eb5ng'), findsOneWidget);
  });
}
