import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';

class AppList extends StatelessWidget {
  const AppList({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemBuilder: (_, i) => children[i],
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemCount: children.length,
    );
  }
}

class CardBox extends StatelessWidget {
  const CardBox({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(margin: EdgeInsets.zero, child: Padding(padding: const EdgeInsets.all(14), child: child));
  }
}

class PageTitle extends StatelessWidget {
  const PageTitle(this.title, this.subtitle, {super.key});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Palette.text)),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: Palette.muted)),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(children: [Icon(icon, color: Palette.accent, size: 18), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))]);
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: const TextStyle(color: Palette.muted, fontSize: 11, letterSpacing: .9, fontWeight: FontWeight.w800));
}

class AlertPanel extends StatelessWidget {
  const AlertPanel({super.key, required this.title, required this.message, required this.color, required this.icon});
  final String title;
  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)), Text(message, style: const TextStyle(color: Colors.white))])),
        ],
      ),
    );
  }
}
