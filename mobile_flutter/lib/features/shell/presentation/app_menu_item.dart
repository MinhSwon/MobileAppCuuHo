import 'package:flutter/material.dart';

class AppMenuItem {
  const AppMenuItem(this.label, this.icon, this.section);
  final String label;
  final IconData icon;
  final String section;

  String get shortLabel {
    if (label.contains('Yêu cầu')) return 'Yêu cầu';
    if (label.contains('Cảnh báo')) return 'Cảnh báo';
    if (label.contains('Nhiệm vụ')) return 'Nhiệm vụ';
    if (label.contains('Điểm')) return 'Sơ tán';
    if (label.contains('Tổng')) return 'Tổng quan';
    return label.split(' ').first;
  }
}
