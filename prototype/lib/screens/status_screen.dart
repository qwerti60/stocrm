import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/theme.dart';

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key, required this.store});
  final MockStore store;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM, HH:mm', 'ru');
    final next = store.nextVisit;
    return Scaffold(
      appBar: AppBar(title: const Text('Статус автомобиля')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: vagRed,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.activeCar?.title ?? 'Авто из заявки', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  Text(store.activeCar?.plate ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
                  const SizedBox(height: 8),
                  Text(
                    next == null ? 'Сейчас: в работе (демо)' : '${next.serviceTitle} · ${next.branchName}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  const Text('в работе  →  выполнено  →  машина готова', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Смена статуса в STOCRM приходит push, для готовности — «Ваша машина готова!»', style: TextStyle(color: vagMuted, height: 1.35)),
          const SizedBox(height: 12),
          ...store.repairSteps.map((s) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(s.done ? Icons.check_circle : Icons.radio_button_unchecked, color: s.done ? Colors.white : vagRed),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Card(
                      child: ListTile(
                        title: Text(s.title, style: TextStyle(fontWeight: FontWeight.w700, color: s.done ? Colors.white : vagRed)),
                        subtitle: Text('${df.format(s.at)}${s.detail != null ? '\n${s.detail}' : ''}', style: const TextStyle(color: vagMuted)),
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
