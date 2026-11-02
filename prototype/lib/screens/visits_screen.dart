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
  bool loading = true;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStore);
    widget.store.refreshVisits().whenComplete(() {
      if (mounted) setState(() => loading = false);
    });
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
    super.dispose();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

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
          const Text(
            'Успешно реализованные и закрытые заказ-наряды (выполнен / готов). Можно открыть сделку и скачать PDF.',
            style: TextStyle(color: vagMuted),
          ),
          const SizedBox(height: 12),
          if (loading) const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: vagRed, strokeWidth: 2))),
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
          '${v.works.isNotEmpty ? '\n${v.works.take(3).join(' · ')}' : ''}'
          '${v.parts.isNotEmpty ? '\nЗапчасти: ${v.parts.take(2).join(', ')}' : ''}',
          style: const TextStyle(color: vagMuted),
        ),
        isThreeLine: true,
        trailing: Text(v.amount != null ? '${v.amount} ₽' : 'PDF', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: vagRed)),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => WorkOrderScreen(store: widget.store, visit: v))),
      ),
    );
  }
}

class WorkOrderScreen extends StatefulWidget {
  const WorkOrderScreen({super.key, required this.store, required this.visit});
  final MockStore store;
  final Visit visit;

  @override
  State<WorkOrderScreen> createState() => _WorkOrderScreenState();
}

class _WorkOrderScreenState extends State<WorkOrderScreen> {
  late Visit _visit;
  bool loading = true;
  final _pdfKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _visit = widget.visit;
    widget.store.fetchVisitDetail(_visit.id).then((v) {
      if (mounted) {
        setState(() {
          if (v != null) _visit = v;
          loading = false;
        });
      }
    });
  }

  Rect? _shareOrigin() {
    final box = _pdfKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final offset = box.localToGlobal(Offset.zero);
    return offset & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM yyyy, HH:mm', 'ru');
    final v = _visit;
    return Scaffold(
      appBar: AppBar(title: Text('Сделка #${v.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (loading) const Padding(padding: EdgeInsets.only(bottom: 12), child: LinearProgressIndicator(color: vagRed, minHeight: 2)),
          Text(v.serviceTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 6),
          Text('${v.carPlate} · ${v.branchName}', style: const TextStyle(color: vagMuted)),
          Text(df.format(v.when), style: const TextStyle(color: vagMuted)),
          if (v.amount != null) Text('${v.amount} ₽', style: const TextStyle(fontWeight: FontWeight.w800, color: vagRed, fontSize: 18)),
          const SizedBox(height: 16),
          const Text('Работы', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          if (v.works.isEmpty) const Text('—', style: TextStyle(color: vagMuted)),
          ...v.works.map((w) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $w'))),
          const SizedBox(height: 12),
          const Text('Запчасти и материалы', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          if (v.parts.isEmpty) const Text('—', style: TextStyle(color: vagMuted)),
          ...v.parts.map((w) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $w'))),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: _pdfKey,
            onPressed: loading
                ? null
                : () async {
                    try {
                      await widget.store.shareVisitPdf(v, shareOrigin: _shareOrigin());
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
