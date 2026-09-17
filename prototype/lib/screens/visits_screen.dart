import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/screens/status_screen.dart';
import 'package:stocrm_mobile_app/theme.dart';

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key, required this.store});
  final MockStore store;

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  String q = '';

  bool _match(Visit v) {
    if (q.isEmpty) return true;
    final s = '${v.serviceTitle} ${v.branchName} ${v.works.join(' ')} ${v.parts.join(' ')}'.toLowerCase();
    return s.contains(q.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM yyyy, HH:mm', 'ru');
    final upcoming = widget.store.upcoming.where(_match).toList();
    final history = widget.store.history.where(_match).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Сервисбук', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Поиск по работам и запчастям'),
            onChanged: (v) => setState(() => q = v),
          ),
          const SizedBox(height: 12),
          const Text('Предстоящие', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          if (upcoming.isEmpty) const Text('Нет активных записей', style: TextStyle(color: vagMuted)),
          ...upcoming.map((v) => _tile(context, v, df, upcoming: true)),
          const SizedBox(height: 16),
          const Text('Закрытые заказ-наряды', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          ...history.map((v) => _tile(context, v, df, upcoming: false)),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, Visit v, DateFormat df, {required bool upcoming}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(v.serviceTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${v.carPlate} · ${v.branchName}\n${df.format(v.when)}'
          '${v.mileage != null ? '\nПробег ${v.mileage} км' : ''}'
          '${v.works.isNotEmpty ? '\nРаботы: ${v.works.join(', ')}' : ''}'
          '${v.parts.isNotEmpty ? '\nЗапчасти: ${v.parts.join(', ')}' : ''}',
          style: const TextStyle(color: vagMuted),
        ),
        isThreeLine: true,
        trailing: Text(
          v.amount != null ? '${v.amount} ₽\n${v.status}' : v.status,
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: upcoming ? vagRed : Colors.white),
        ),
        onTap: upcoming ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StatusScreen(store: widget.store))) : null,
      ),
    );
  }
}
