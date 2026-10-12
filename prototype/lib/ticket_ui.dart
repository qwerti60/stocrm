import 'package:flutter/material.dart';
import 'package:stocrm_mobile_app/theme.dart';

String ticketStatusLabel(String status, {String fallback = ''}) {
  if (fallback.isNotEmpty) return fallback;
  switch (status) {
    case 'done':
      return 'Отработана';
    case 'processing':
      return 'В работе';
    default:
      return 'Новая';
  }
}

Color ticketStatusColor(String status) {
  switch (status) {
    case 'done':
      return const Color(0xFF2E7D32);
    case 'processing':
      return const Color(0xFF1565C0);
    default:
      return vagRed;
  }
}

Widget ticketStatusChip(String status, {String label = ''}) {
  final text = ticketStatusLabel(status, fallback: label);
  final color = ticketStatusColor(status);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
  );
}
