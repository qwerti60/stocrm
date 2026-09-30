import 'package:flutter/material.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/screens/booking_flow.dart';
import 'package:stocrm_mobile_app/theme.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key, required this.store});
  final MockStore store;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<RepairRec>>{};
    for (final r in store.recommendations) {
      final key = r.car.isEmpty ? 'Авто не указано' : '${r.car}${r.plate.isNotEmpty ? ' · ${r.plate}' : ''}';
      grouped.putIfAbsent(key, () => []).add(r);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Рекомендации по ремонту', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Рекомендации привязаны к автомобилю. Лампа на главной горит, пока есть активные.', style: TextStyle(color: vagMuted)),
          const SizedBox(height: 12),
          if (store.recommendations.isEmpty)
            const Text('Активных рекомендаций нет.', style: TextStyle(color: vagMuted)),
          for (final entry in grouped.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.directions_car, color: vagRed, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w800))),
                  CircleAvatar(radius: 10, backgroundColor: vagRed, child: Text('${entry.value.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
                ],
              ),
            ),
            ...entry.value.map(
              (r) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.tips_and_updates, color: vagRed),
                  title: Text(r.title),
                  subtitle: r.subtitle.isEmpty ? null : Text(r.subtitle, style: const TextStyle(color: vagMuted)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookingFlow(store: store))),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
