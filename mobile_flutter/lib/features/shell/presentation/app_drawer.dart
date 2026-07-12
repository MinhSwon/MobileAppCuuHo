import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';
import 'package:mobile_flutter/core/core.dart';
import 'package:mobile_flutter/features/shell/presentation/app_menu_item.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.title,
    required this.subtitle,
    required this.user,
    required this.items,
    required this.selected,
    required this.onSelect,
    required this.onLogout,
  });

  final String title;
  final String subtitle;
  final Map<String, dynamic> user;
  final List<AppMenuItem> items;
  final int selected;
  final ValueChanged<int> onSelect;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    String? currentSection;

    return Drawer(
      backgroundColor: Palette.sidebar,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.health_and_safety,
                      color: Palette.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xfffdf9f3),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Palette.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Palette.accent,
                    child: Text(
                      valueOf(
                        user,
                        'full_name',
                        fallback: '?',
                      ).characters.first,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          valueOf(user, 'full_name'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xffd8d0c8),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          valueOf(user, 'role'),
                          style: const TextStyle(
                            color: Palette.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0x22ffffff)),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final showSection = currentSection != item.section;
                  currentSection = item.section;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showSection)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
                          child: Text(
                            item.section.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xff6b6360),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ListTile(
                        dense: true,
                        minLeadingWidth: 24,
                        leading: Icon(
                          item.icon,
                          color: index == selected
                              ? const Color(0xffe8e0d5)
                              : const Color(0xffb8afa5),
                          size: 18,
                        ),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            color: index == selected
                                ? const Color(0xffe8e0d5)
                                : const Color(0xffb8afa5),
                            fontSize: 13,
                            fontWeight: index == selected
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                        selected: index == selected,
                        selectedTileColor: const Color(0x1fffffff),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          onSelect(index);
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await onLogout();
              },
              icon: const Icon(Icons.logout, color: Palette.muted),
              label: const Text(
                'Đăng xuất',
                style: TextStyle(color: Palette.muted),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
