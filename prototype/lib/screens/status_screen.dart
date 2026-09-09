import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stocrm_mobile_app/data/mock.dart';

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key, required this.store});
  final MockStore store;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM, HH:mm', 'ru');
    final next = store.nextVisit;
    return Scaffold(
      appBar: AppBar(title: const Text('Статус ремонта')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: const Color(0xFF0B1F33),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.activeCar.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  Text(store.activeCar.plate, style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
                  const SizedBox(height: 8),
                  Text(
                    next == null ? 'Сейчас на посту: диагностика + колодки (демо)' : '${next.serviceTitle} · ${next.branchName}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Лента статусов заказ-наряда. В бою — из STOCRM / webhook.', style: TextStyle(height: 1.35)),
          const SizedBox(height: 12),
          ...store.repairSteps.map((s) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Icon(s.done ? Icons.check_circle : Icons.radio_button_unchecked, color: s.done ? const Color(0xFF10B981) : const Color(0xFFEA580C)),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Card(
                      child: ListTile(
                        title: Text(s.title, style: TextStyle(fontWeight: FontWeight.w700, color: s.done ? null : const Color(0xFFEA580C))),
                        subtitle: Text('${df.format(s.at)}${s.detail != null ? '\n${s.detail}' : ''}'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
