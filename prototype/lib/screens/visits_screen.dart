import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
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
    final history = widget.store.history.where(_match).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Электронный сервисбук', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const Text('Только успешно реализованные заказ-наряды. Можно скачать PDF.', style: TextStyle(color: vagMuted)),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Поиск по работам и запчастям'),
            onChanged: (v) => setState(() => q = v),
          ),
          const SizedBox(height: 12),
          if (history.isEmpty) const Text('Пока нет закрытых заказ-нарядов', style: TextStyle(color: vagMuted)),
          ...history.map((v) => _tile(context, v, df)),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, Visit v, DateFormat df) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(v.serviceTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${v.carPlate} · ${v.branchName}\n${df.format(v.when)}'
          '${v.works.isNotEmpty ? '\nРаботы: ${v.works.join(', ')}' : ''}',
          style: const TextStyle(color: vagMuted),
        ),
        isThreeLine: true,
        trailing: Text(v.amount != null ? '${v.amount} ₽' : 'PDF', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: vagRed)),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => WorkOrderScreen(store: widget.store, visit: v))),
      ),
    );
  }
}

class WorkOrderScreen extends StatelessWidget {
  const WorkOrderScreen({super.key, required this.store, required this.visit});
  final MockStore store;
  final Visit visit;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM yyyy, HH:mm', 'ru');
    return Scaffold(
      appBar: AppBar(title: Text('Заказ-наряд № ${visit.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(visit.serviceTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 6),
          Text('${visit.carPlate} · ${visit.branchName}', style: const TextStyle(color: vagMuted)),
          Text(df.format(visit.when), style: const TextStyle(color: vagMuted)),
          if (visit.amount != null) Text('${visit.amount} ₽', style: const TextStyle(fontWeight: FontWeight.w800, color: vagRed, fontSize: 18)),
          const SizedBox(height: 16),
          const Text('Работы', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          if (visit.works.isEmpty) const Text('—', style: TextStyle(color: vagMuted)),
          ...visit.works.map((w) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $w'))),
          const SizedBox(height: 12),
          const Text('Запчасти и материалы', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          if (visit.parts.isEmpty) const Text('—', style: TextStyle(color: vagMuted)),
          ...visit.parts.map((w) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $w'))),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              try {
                await store.shareVisitPdf(visit);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                }
              }
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Скачать PDF'),
          ),
        ],
      ),
    );
  }
}
