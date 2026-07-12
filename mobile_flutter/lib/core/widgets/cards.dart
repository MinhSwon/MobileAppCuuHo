import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/core/utils/data_helpers.dart';
import 'package:mobile_flutter/core/widgets/layout_widgets.dart';
import 'package:mobile_flutter/core/widgets/map_widgets.dart';

Future<void> makePhoneCall(BuildContext context, String phone) async {
  final trimmed = phone.trim();
  if (trimmed.isEmpty) return;
  final uri = Uri(scheme: 'tel', path: trimmed);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể gọi số $trimmed')));
    }
  }
}

class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.white70),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class GridStats extends StatelessWidget {
  const GridStats({super.key, required this.items});
  final List<StatItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (_, i) {
        final item = items[i];
        return CardBox(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        color: Palette.muted,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      item.value,
                      style: TextStyle(
                        color: item.color,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, color: item.color, size: 19),
              ),
            ],
          ),
        );
      },
    );
  }
}

class StatItem {
  StatItem(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class RequestCard extends StatelessWidget {
  const RequestCard({
    super.key,
    required this.request,
    this.actions = const [],
  });
  final Map<String, dynamic> request;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sos, color: Palette.danger),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  valueOf(request, 'full_name'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              StatusBadge(status: valueOf(request, 'status')),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              LevelBadge(level: valueOf(request, 'emergency_level')),
              Text(
                '📍 ${valueOf(request, 'area_name')}',
                style: const TextStyle(color: Palette.secondary),
              ),
              Text(
                '☎ ${valueOf(request, 'phone')}',
                style: const TextStyle(color: Palette.accent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            valueOf(request, 'address_detail'),
            style: const TextStyle(color: Palette.secondary),
          ),
          if (valueOf(request, 'description').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(valueOf(request, 'description')),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, children: actions),
          ],
        ],
      ),
    );
  }
}

class MissionCard extends StatelessWidget {
  const MissionCard({
    super.key,
    required this.mission,
    this.actions = const [],
  });
  final Map<String, dynamic> mission;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_rounded, color: Palette.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  valueOf(mission, 'victim_name'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              StatusBadge(status: valueOf(mission, 'status')),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '📍 ${valueOf(mission, 'victim_address')}',
            style: const TextStyle(color: Palette.secondary),
          ),
          Text(
            '☎ ${valueOf(mission, 'victim_phone')}',
            style: const TextStyle(color: Palette.accent),
          ),
          Text(
            'Đội: ${valueOf(mission, 'team_name')}',
            style: const TextStyle(color: Palette.secondary),
          ),
          const SizedBox(height: 10),
          RescueMap(
            title: 'Vị trí nhiệm vụ',
            compact: true,
            points: [
              MapPoint.fromMap(
                mission,
                latKey: 'victim_latitude',
                lngKey: 'victim_longitude',
                labelKey: 'victim_name',
                type: MapPointType.victim,
              ),
              MapPoint.fromMap(
                mission,
                latKey: 'current_rescuer_latitude',
                lngKey: 'current_rescuer_longitude',
                labelKey: 'team_name',
                type: MapPointType.team,
              ),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: actions),
            ),
          ],
        ],
      ),
    );
  }
}

class WarningCard extends StatelessWidget {
  const WarningCard({
    super.key,
    required this.warning,
    this.actions = const [],
  });
  final Map<String, dynamic> warning;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final level = valueOf(warning, 'level');
    final color = levelColor(level);
    return CardBox(
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        padding: const EdgeInsets.only(left: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.campaign, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    valueOf(warning, 'title'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                LevelBadge(level: level),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              valueOf(warning, 'content'),
              style: const TextStyle(color: Palette.secondary, height: 1.45),
            ),
            const SizedBox(height: 6),
            Text(
              'Khu vực: ${valueOf(warning, 'area_name')}',
              style: const TextStyle(color: Palette.muted, fontSize: 12),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return BadgePill(
      label: statusLabel(status),
      bg: color.withValues(alpha: .14),
      fg: color,
    );
  }
}

class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, required this.level});
  final String level;
  @override
  Widget build(BuildContext context) => BadgePill(
    label: levelLabel(level),
    bg: levelColor(level).withValues(alpha: .14),
    fg: levelColor(level),
  );
}

class BadgePill extends StatelessWidget {
  const BadgePill({
    super.key,
    required this.label,
    required this.bg,
    required this.fg,
  });
  final String label;
  final Color bg;
  final Color fg;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 11),
    ),
  );
}

class ToggleChip extends StatelessWidget {
  const ToggleChip(this.label, this.value, this.onChanged, {super.key});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => FilterChip(
    label: Text(label),
    selected: value,
    onSelected: onChanged,
    selectedColor: Palette.accentLight,
  );
}

class EmptyCard extends StatelessWidget {
  const EmptyCard({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;
  @override
  Widget build(BuildContext context) => CardBox(
    child: Column(
      children: [
        Icon(icon, size: 38, color: Palette.success),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).hintColor),
        ),
      ],
    ),
  );
}

class PhoneCard extends StatelessWidget {
  const PhoneCard({super.key, required this.label, required this.phone});
  final String label;
  final String phone;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => makePhoneCall(context, phone),
        child: CardBox(
          child: Row(
            children: [
              const Icon(Icons.phone, color: Palette.danger),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(color: Palette.muted)),
                    Text(
                      phone,
                      style: const TextStyle(
                        color: Palette.danger,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Nhấn để gọi',
                      style: TextStyle(
                        color: Palette.danger.withValues(alpha: .6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.call, color: Palette.danger, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 94,
          child: Text(
            label,
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
