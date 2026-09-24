import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/theme.dart';

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key, required this.store, this.visit});
  final MockStore store;
  final Visit? visit;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM, HH:mm', 'ru');
    final ready = store.visits.where((v) => v.isReady);
    final current = visit ?? (ready.isEmpty ? store.nextVisit : ready.first);
    final steps = (current?.steps.isNotEmpty == true) ? current!.steps : store.repairSteps;
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
                  Text(
                    store.activeCar?.title ?? current?.carPlate ?? 'Авто из заявки',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  Text(store.activeCar?.plate ?? current?.carPlate ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
                  const SizedBox(height: 8),
                  Text(
                    current == null
                        ? 'Нет открытой заявки в CRM'
                        : '${current.status} · ${current.branchName}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    current?.isReady == true ? 'Ваша машина готова!' : 'в работе  →  выполнено  →  машина готова',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            store.crmLive
                ? 'Статус из воронки 1097. Poller раз в ~90 сек. Push «Ваша машина готова!» при Выполнен / Успешно / готов раньше.'
                : 'Смена статуса в STOCRM приходит в приложение. Для готовности — «Ваша машина готова!»',
            style: const TextStyle(color: vagMuted, height: 1.35),
          ),
          if (current?.works.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text('Работы: ${current!.works.join(', ')}', style: const TextStyle(color: vagMuted)),
          ],
          const SizedBox(height: 12),
          ...steps.map((s) {
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
                        subtitle: Text(
                          '${s.at.year > 1971 ? df.format(s.at) : ''}${s.detail != null ? '\n${s.detail}' : ''}'.trim(),
                          style: const TextStyle(color: vagMuted),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (store.crmLive) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                await store.testReadyPush();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ваша машина готова!')));
                }
              },
              child: const Text('Проверить уведомление «машина готова»'),
            ),
          ],
        ],
      ),
    );
  }
}
