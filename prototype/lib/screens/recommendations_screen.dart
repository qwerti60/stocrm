import 'package:flutter/material.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/screens/booking_flow.dart';
import 'package:stocrm_mobile_app/theme.dart';
import 'package:stocrm_mobile_app/widgets/app_page_scaffold.dart';
import 'package:stocrm_mobile_app/widgets/shell_page_title.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key, required this.store, this.filterCar, this.inShell = false});
  final MockStore store;
  final Vehicle? filterCar;
  final bool inShell;

  @override
  Widget build(BuildContext context) {
    final list = filterCar == null ? store.recommendations : store.recommendationsForCar(filterCar!);
    final grouped = <String, List<RepairRec>>{};
    for (final r in list) {
      final key = r.car.isEmpty ? 'Авто не указано' : '${r.car}${r.plate.isNotEmpty ? ' · ${r.plate}' : ''}';
      grouped.putIfAbsent(key, () => []).add(r);
    }
    final listBody = ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (inShell) const ShellPageTitle(title: 'Рекомендации по ремонту'),
          const Text('Рекомендации привязаны к автомобилю. Лампа на главной горит, пока есть активные.', style: TextStyle(color: vagMuted)),
          const SizedBox(height: 12),
          if (list.isEmpty)
            Text(
              filterCar == null ? 'Активных рекомендаций нет.' : 'Для ${filterCar!.make} ${filterCar!.model} рекомендаций пока нет.',
              style: const TextStyle(color: vagMuted),
            ),
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
      );
    if (inShell) {
      return Scaffold(backgroundColor: vagSurface, body: listBody);
    }
    final title = filterCar == null
        ? 'Рекомендации по ремонту'
        : 'Рекомендации · ${filterCar!.make} ${filterCar!.model}';
    return AppPageScaffold(store: store, title: title, body: listBody);
  }
}
