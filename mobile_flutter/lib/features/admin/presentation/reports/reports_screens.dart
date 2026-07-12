import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/core/core.dart';
import 'package:mobile_flutter/data/data.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key, required this.data});
  final AppData data;

  @override
  Widget build(BuildContext context) {
    final total = data.requests.length;
    final pending = data.requests.where((r) => r['status'] == 'PENDING').length;
    final verifying = data.requests
        .where((r) => ['VERIFYING', 'SUSPICIOUS'].contains(r['status']))
        .length;
    final verified = data.requests
        .where((r) => r['status'] == 'VERIFIED')
        .length;
    final done = data.requests
        .where((r) => ['RESCUED', 'TRANSFERRED_SAFEZONE'].contains(r['status']))
        .length;
    final spam = data.requests
        .where(
          (r) => ['SPAM', 'CANCELLED', 'FALSE_ALARM'].contains(r['status']),
        )
        .length;

    // Tính tổng số lượng người yếu thế cần hỗ trợ trong các yêu cầu chưa hoàn thành
    int totalElderly = 0;
    int totalChildren = 0;
    int totalDisabled = 0;
    for (final r in data.openRequests) {
      totalElderly +=
          int.tryParse(valueOf(r, 'elderly_count', fallback: '0')) ?? 0;
      totalChildren +=
          int.tryParse(valueOf(r, 'children_count', fallback: '0')) ?? 0;
      totalDisabled +=
          int.tryParse(valueOf(r, 'disabled_count', fallback: '0')) ?? 0;
    }

    return AppList(
      children: [
        const PageTitle(
          'Thống kê & Báo cáo',
          'Tổng hợp số liệu điều phối thời gian thực',
        ),
        GridStats(
          items: [
            StatItem('Yêu cầu SOS', '$total', Icons.sos, Palette.danger),
            StatItem(
              'Chưa xử lý',
              '$pending',
              Icons.hourglass_empty,
              Palette.warning,
            ),
            StatItem('Đã cứu hộ', '$done', Icons.check_circle, Palette.success),
            StatItem(
              'Đội cứu hộ',
              '${data.teams.length}',
              Icons.groups,
              Palette.accent,
            ),
          ],
        ),
        const SizedBox(height: 8),
        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                icon: Icons.pie_chart,
                title: 'Phân bố trạng thái cứu hộ',
              ),
              const SizedBox(height: 14),
              // Custom horizontal bar chart
              if (total > 0) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 24,
                    child: Row(
                      children: [
                        if (pending > 0)
                          Expanded(
                            flex: pending,
                            child: Container(
                              color: Palette.warning,
                              child: Center(
                                child: Text(
                                  '${(pending / total * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (verifying + verified > 0)
                          Expanded(
                            flex: verifying + verified,
                            child: Container(
                              color: Palette.accent,
                              child: Center(
                                child: Text(
                                  '${((verifying + verified) / total * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (done > 0)
                          Expanded(
                            flex: done,
                            child: Container(
                              color: Palette.success,
                              child: Center(
                                child: Text(
                                  '${(done / total * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (spam > 0)
                          Expanded(
                            flex: spam,
                            child: Container(
                              color: Palette.muted,
                              child: Center(
                                child: Text(
                                  '${(spam / total * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Legend
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildLegendItem('Chờ xử lý ($pending)', Palette.warning),
                    _buildLegendItem(
                      'Đang xử lý (${verifying + verified})',
                      Palette.accent,
                    ),
                    _buildLegendItem('Đã hoàn tất ($done)', Palette.success),
                    _buildLegendItem('Tin rác/Hủy ($spam)', Palette.muted),
                  ],
                ),
              ] else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Chưa có dữ liệu để lập biểu đồ',
                      style: TextStyle(color: Palette.muted),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                icon: Icons.people_outline,
                title: 'Đối tượng cần hỗ trợ khẩn cấp',
              ),
              const SizedBox(height: 10),
              const Text(
                'Thống kê số lượng người thuộc nhóm yếu thế trong các yêu cầu đang chờ cứu hộ:',
                style: TextStyle(fontSize: 13, color: Palette.secondary),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildVulnerableCol(
                    Icons.elderly,
                    'Người già',
                    totalElderly,
                    Colors.amber,
                  ),
                  _buildVulnerableCol(
                    Icons.child_care,
                    'Trẻ em',
                    totalChildren,
                    Colors.blue,
                  ),
                  _buildVulnerableCol(
                    Icons.accessible,
                    'Khuyết tật',
                    totalDisabled,
                    Colors.deepOrange,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SectionHeader(icon: Icons.map, title: 'Thống kê theo khu vực'),
        if (data.areas.isEmpty)
          const EmptyCard(icon: Icons.map, message: 'Chưa có dữ liệu khu vực')
        else
          ...data.areas.map((a) {
            final requestsInArea = data.requests
                .where((r) => valueOf(r, 'area_id') == valueOf(a, 'id'))
                .toList();
            final count = requestsInArea.length;
            final solved = requestsInArea
                .where(
                  (r) =>
                      ['RESCUED', 'TRANSFERRED_SAFEZONE'].contains(r['status']),
                )
                .length;

            return CardBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          valueOf(a, 'old_name'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      BadgePill(
                        label: '$count yêu cầu',
                        bg: Palette.accentLight,
                        fg: Palette.accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (count > 0) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: solved / count,
                        backgroundColor: Palette.muted.withValues(alpha: .2),
                        color: Palette.success,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tỷ lệ hoàn thành:',
                          style: TextStyle(fontSize: 11, color: Palette.muted),
                        ),
                        Text(
                          '${(solved / count * 100).toStringAsFixed(0)}% ($solved/$count)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Palette.success,
                          ),
                        ),
                      ],
                    ),
                  ] else
                    const Text(
                      'Khu vực an toàn, không có sự cố.',
                      style: TextStyle(fontSize: 12, color: Palette.muted),
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildVulnerableCol(
    IconData icon,
    String label,
    int count,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Palette.muted)),
        const SizedBox(height: 2),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}

class ActivityLogsScreen extends StatelessWidget {
  const ActivityLogsScreen({super.key, required this.data});
  final AppData data;

  @override
  Widget build(BuildContext context) {
    // Sắp xếp nhật ký mới nhất lên đầu
    final sortedLogs = [...data.activityLogs]
      ..sort((a, b) {
        final aTime = DateTime.tryParse(valueOf(a, 'created_at'));
        final bTime = DateTime.tryParse(valueOf(b, 'created_at'));
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

    return AppList(
      children: [
        const PageTitle(
          'Nhật ký hoạt động',
          'Lịch sử thao tác điều hành hệ thống',
        ),
        if (sortedLogs.isEmpty)
          const EmptyCard(
            icon: Icons.history,
            message: 'Chưa có nhật ký hoạt động',
          )
        else
          ...sortedLogs.map(
            (l) => CardBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Palette.accent,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          valueOf(l, 'action'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Người thực hiện: ${valueOf(l, 'user_name', fallback: 'HỆ THỐNG')}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Thời gian: ${formatDate(valueOf(l, 'created_at'))}',
                    style: const TextStyle(color: Palette.muted, fontSize: 11),
                  ),
                  if (valueOf(l, 'note').isNotEmpty) ...[
                    const Divider(height: 12),
                    Text(
                      valueOf(l, 'note'),
                      style: const TextStyle(
                        color: Palette.secondary,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class AIAssistantScreen extends StatelessWidget {
  const AIAssistantScreen({super.key, required this.data});
  final AppData data;

  // Thuật toán AI tính điểm ưu tiên Triage
  int _calculatePriority(Map<String, dynamic> r) {
    int score = 0;

    // 1. Mức độ khẩn cấp (Emergency Level)
    final level = valueOf(r, 'emergency_level');
    if (level == 'EMERGENCY') {
      score += 45;
    } else if (level == 'HIGH') {
      score += 30;
    } else if (level == 'MEDIUM') {
      score += 15;
    } else {
      score += 5;
    }

    // 2. Nhóm đối tượng yếu thế
    final elderly =
        int.tryParse(valueOf(r, 'elderly_count', fallback: '0')) ?? 0;
    final children =
        int.tryParse(valueOf(r, 'children_count', fallback: '0')) ?? 0;
    final disabled =
        int.tryParse(valueOf(r, 'disabled_count', fallback: '0')) ?? 0;
    final totalMembers =
        int.tryParse(valueOf(r, 'household_size', fallback: '1')) ?? 1;

    score += disabled * 20; // Khuyết tật cộng điểm cao nhất
    score += elderly * 15;
    score += children * 10;

    if (totalMembers > 4) {
      score += 5; // Gia đình đông người
    }

    // 3. Ghi chú y tế khẩn cấp
    final medical = valueOf(r, 'medical_notes');
    if (medical.isNotEmpty && medical != '-' && medical != 'Không') {
      score += 15;
    }

    // 4. Thời gian chờ đợi (tạo lúc nào)
    final createdAtStr = valueOf(r, 'created_at');
    final createdAt = DateTime.tryParse(createdAtStr);
    if (createdAt != null) {
      final diffMin = DateTime.now().difference(createdAt).inMinutes;
      // Cộng 0.1 điểm cho mỗi phút chờ đợi, tối đa 30 điểm
      final timeBonus = (diffMin * 0.1).clamp(0.0, 30.0).toInt();
      score += timeBonus;
    }

    return score;
  }

  // Tạo lý do giải thích cho điểm số ưu tiên của AI
  String _getExplanation(Map<String, dynamic> r, int score) {
    final level = valueOf(r, 'emergency_level');
    final elderly =
        int.tryParse(valueOf(r, 'elderly_count', fallback: '0')) ?? 0;
    final children =
        int.tryParse(valueOf(r, 'children_count', fallback: '0')) ?? 0;
    final disabled =
        int.tryParse(valueOf(r, 'disabled_count', fallback: '0')) ?? 0;
    final medical = valueOf(r, 'medical_notes');

    final reasons = <String>[];
    reasons.add('Mức khẩn cấp ${statusLabel(level)}');

    if (disabled > 0) {
      reasons.add('$disabled người khuyết tật (+${disabled * 20}đ)');
    }
    if (elderly > 0) {
      reasons.add('$elderly người già (+${elderly * 15}đ)');
    }
    if (children > 0) {
      reasons.add('$children trẻ em (+${children * 10}đ)');
    }
    if (medical.isNotEmpty && medical != '-' && medical != 'Không') {
      reasons.add('Có bệnh lý/y tế đặc biệt (+15đ)');
    }

    return 'Chỉ số ưu tiên: $score điểm.\nLý do: ${reasons.join(', ')}.';
  }

  @override
  Widget build(BuildContext context) {
    // Lọc các yêu cầu chưa được cứu hộ hoàn tất
    final activeRequests = data.requests
        .where(
          (r) => [
            'PENDING',
            'VERIFYING',
            'VERIFIED',
            'SUSPICIOUS',
          ].contains(r['status']),
        )
        .toList();

    // Tính điểm và sắp xếp theo điểm ưu tiên giảm dần
    final prioritizedRequests =
        activeRequests.map((r) {
            final score = _calculatePriority(r);
            return {
              'request': r,
              'score': score,
              'explanation': _getExplanation(r, score),
            };
          }).toList()
          ..sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    final urgent = prioritizedRequests.isNotEmpty
        ? prioritizedRequests.first
        : null;
    final urgentReq = urgent != null
        ? urgent['request'] as Map<String, dynamic>
        : null;
    final urgentExpl = urgent != null ? urgent['explanation'] as String : '';
    final availableTeams = data.teams
        .where((t) => t['status'] == 'AVAILABLE')
        .toList();

    return AppList(
      children: [
        const PageTitle(
          'Trợ lý AI Triage',
          'Tự động phân tích & đề xuất ưu tiên điều phối',
        ),
        if (urgentReq != null) ...[
          AlertPanel(
            title: 'ĐỀ XUẤT ƯU TIÊN SỐ 1',
            message:
                'Nạn nhân: ${valueOf(urgentReq, 'full_name')}\n'
                'Khu vực: ${valueOf(urgentReq, 'area_name')}\n'
                '$urgentExpl',
            color: Palette.danger,
            icon: Icons.psychology,
          ),
        ] else
          const AlertPanel(
            title: 'HỆ THỐNG AN TOÀN',
            message: 'Hiện tại không có yêu cầu cứu hộ nào đang chờ xử lý.',
            color: Palette.success,
            icon: Icons.check_circle_outline,
          ),

        const SectionHeader(
          icon: Icons.tips_and_updates,
          title: 'Khuyến nghị vận hành nhanh',
        ),
        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoRow(
                'Lực lượng sẵn sàng',
                '${availableTeams.length} đội cứu hộ đang AVAILABLE',
              ),
              InfoRow(
                'Điểm sơ tán còn chỗ',
                '${data.safeZones.where((s) => s['status'] == 'AVAILABLE').length} điểm',
              ),
              InfoRow(
                'Tuyến đường an toàn',
                '${data.routes.where((r) => r['status'] == 'OPEN').length} tuyến',
              ),
            ],
          ),
        ),

        const SectionHeader(
          icon: Icons.format_list_numbered,
          title: 'Danh sách đề xuất ưu tiên (AI Triage)',
        ),
        if (prioritizedRequests.isEmpty)
          const EmptyCard(
            icon: Icons.assignment_turned_in,
            message: 'Không có yêu cầu cần cứu hộ',
          )
        else
          ...prioritizedRequests.take(5).map((item) {
            final r = item['request'] as Map<String, dynamic>;
            final score = item['score'] as int;
            final exp = item['explanation'] as String;
            final areaId = valueOf(r, 'area_id');

            // Tìm đội cứu hộ đề xuất (ưu tiên đội AVAILABLE ở cùng khu vực)
            final suggestedTeam = availableTeams.firstWhere(
              (t) => valueOf(t, 'area_id') == areaId,
              orElse: () =>
                  availableTeams.isNotEmpty ? availableTeams.first : {},
            );

            return CardBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          valueOf(r, 'full_name'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: score >= 60
                              ? Palette.danger.withValues(alpha: .15)
                              : Palette.warning.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: score >= 60
                                ? Palette.danger
                                : Palette.warning,
                          ),
                        ),
                        child: Text(
                          'Ưu tiên: $score',
                          style: TextStyle(
                            color: score >= 60 ? Palette.danger : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '📍 Khu vực: ${valueOf(r, 'area_name')} · Địa chỉ: ${valueOf(r, 'address_detail')}',
                    style: const TextStyle(
                      color: Palette.secondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(exp, style: const TextStyle(fontSize: 13, height: 1.3)),
                  if (valueOf(r, 'description').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Palette.muted.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Nội dung SOS: "${valueOf(r, 'description')}"',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  if (suggestedTeam.isNotEmpty) ...[
                    const Divider(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.groups,
                          size: 18,
                          color: Palette.success,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'AI đề xuất: Đội ${valueOf(suggestedTeam, 'team_name')} (${valueOf(suggestedTeam, 'leader_name')})',
                            style: const TextStyle(
                              color: Palette.success,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }
}
