import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/screens/status_screen.dart';

class VisitsScreen extends StatelessWidget {
  const VisitsScreen({super.key, required this.store});
  final MockStore store;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM yyyy, HH:mm', 'ru');
    return Scaffold(
      appBar: AppBar(title: const Text('Визиты', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const Text('Сервисная книжка: предстоящие записи и закрытые заказ-наряды из STOCRM.'),
          const SizedBox(height: 12),
          Text('Предстоящие', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (store.upcoming.isEmpty) const Text('Нет активных записей'),
          ...store.upcoming.map((v) => _tile(context, v, df, upcoming: true)),
          const SizedBox(height: 16),
          Text('История', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...store.history.map((v) => _tile(context, v, df, upcoming: false)),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, Visit v, DateFormat df, {required bool upcoming}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(v.serviceTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${v.carPlate}\n${v.branchName} · ${df.format(v.when)}${v.works.isNotEmpty ? '\n${v.works.join(' · ')}' : ''}'),
        isThreeLine: true,
        trailing: Text(
          v.amount != null ? '${v.amount} ₽\n${v.status}' : v.status,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        onTap: upcoming ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StatusScreen(store: store))) : null,
        onLongPress: upcoming && v.status != 'отменена'
            ? () {
                store.cancelVisit(v.id);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Запись отменена (в бою — статус сделки в STOCRM)')));
              }
            : null,
      ),
    );
  }
}
