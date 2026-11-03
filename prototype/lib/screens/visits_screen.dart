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

  static final _money = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);

  String _formatMoney(double? value) {
    if (value == null) return '';
    if (value == value.roundToDouble()) return _money.format(value.round());
    return '${NumberFormat('#,##0.00', 'ru_RU').format(value).replaceAll('\u00a0', ' ')} ₽';
  }

  bool _isMetaLine(VisitLineItem item) {
    final n = item.name.toLowerCase();
    return n.startsWith('оплата:') || n.startsWith('пробег:') || n.contains('состав работ в crm');
  }

  List<VisitLineItem> get _workRows =>
      _visit.workLines.isNotEmpty ? _visit.workLines : [for (final w in _visit.works) VisitLineItem(name: w)];

  List<VisitLineItem> get _partRows {
    final src = _visit.partLines.isNotEmpty ? _visit.partLines : [for (final p in _visit.parts) VisitLineItem(name: p)];
    return src.where((x) => !_isMetaLine(x)).toList();
  }

  List<VisitLineItem> get _metaRows {
    final src = _visit.partLines.isNotEmpty ? _visit.partLines : [for (final p in _visit.parts) VisitLineItem(name: p)];
    return src.where(_isMetaLine).toList();
  }

  double? _sectionSum(List<VisitLineItem> rows) {
    var total = 0.0;
    var any = false;
    for (final r in rows) {
      if (r.sum != null && r.sum! > 0) {
        total += r.sum!;
        any = true;
      }
    }
    return any ? total : null;
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM yyyy, HH:mm', 'ru');
    final v = _visit;
    final works = _workRows.where((x) => !_isMetaLine(x)).toList();
    final parts = _partRows;
    final meta = _metaRows;
    final worksTotal = _sectionSum(works);
    final partsTotal = _sectionSum(parts);

    return Scaffold(
      appBar: AppBar(title: Text('Сделка #${v.id}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          if (loading) const Padding(padding: EdgeInsets.only(bottom: 12), child: LinearProgressIndicator(color: vagRed, minHeight: 2)),
          _DealHeroCard(
            title: v.serviceTitle,
            plate: v.carPlate,
            branch: v.branchName,
            when: df.format(v.when),
            amount: v.amount,
            mileage: v.mileage,
            metaLines: meta,
          ),
          const SizedBox(height: 20),
          _DealSection(
            icon: Icons.build_circle_outlined,
            title: 'Работы',
            count: works.length,
            footerSum: worksTotal,
            emptyHint: 'Список работ появится после синхронизации с CRM',
            child: works.isEmpty
                ? null
                : Column(
                    children: [
                      for (var i = 0; i < works.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 52, color: vagBorder),
                        _DealLineTile(index: i + 1, item: works[i], formatMoney: _formatMoney),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          _DealSection(
            icon: Icons.inventory_2_outlined,
            title: 'Запчасти и материалы',
            count: parts.length,
            footerSum: partsTotal,
            emptyHint: 'Запчасти не переданы через API — уточните у сервиса',
            child: parts.isEmpty
                ? null
                : Column(
                    children: [
                      for (var i = 0; i < parts.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 52, color: vagBorder),
                        _DealLineTile(index: i + 1, item: parts[i], formatMoney: _formatMoney, partsStyle: true),
                      ],
                    ],
                  ),
          ),
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

class _DealHeroCard extends StatelessWidget {
  const _DealHeroCard({
    required this.title,
    required this.plate,
    required this.branch,
    required this.when,
    this.amount,
    this.mileage,
    this.metaLines = const [],
  });

  final String title;
  final String plate;
  final String branch;
  final String when;
  final int? amount;
  final int? mileage;
  final List<VisitLineItem> metaLines;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: vagCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: vagBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: vagInk)),
          if (plate.isNotEmpty || branch.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              [if (plate.isNotEmpty) plate, if (branch.isNotEmpty) branch].join(' · '),
              style: const TextStyle(color: vagMutedInk, fontWeight: FontWeight.w500),
            ),
          ],
          Text(when, style: const TextStyle(color: vagMutedInk, fontSize: 13)),
          if (amount != null) ...[
            const SizedBox(height: 14),
            Text('Итого', style: TextStyle(color: vagMutedInk.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w600)),
            Text(money.format(amount), style: const TextStyle(fontWeight: FontWeight.w800, color: vagRed, fontSize: 26, height: 1.1)),
          ],
          if (mileage != null && mileage! > 0) ...[
            const SizedBox(height: 10),
            _InfoChip(icon: Icons.speed_outlined, label: 'Пробег ${mileage!} км'),
          ],
          if (metaLines.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in metaLines)
                  _InfoChip(
                    icon: m.name.toLowerCase().startsWith('оплата') ? Icons.payments_outlined : Icons.info_outline,
                    label: m.name,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: vagSurface, borderRadius: BorderRadius.circular(10), border: Border.all(color: vagBorder)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: vagRed),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: vagInk)),
          ),
        ],
      ),
    );
  }
}

class _DealSection extends StatelessWidget {
  const _DealSection({
    required this.icon,
    required this.title,
    required this.count,
    required this.emptyHint,
    this.footerSum,
    this.child,
  });

  final IconData icon;
  final String title;
  final int count;
  final String emptyHint;
  final double? footerSum;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 22, color: vagRed),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: vagRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('$count', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: vagRed)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (child == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: vagCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: vagBorder),
            ),
            child: Text(emptyHint, style: const TextStyle(color: vagMutedInk, height: 1.35)),
          )
        else
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: vagCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: vagBorder),
            ),
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: child),
          ),
        if (footerSum != null && footerSum! > 0) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Подитог: ${money.format(footerSum)}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: vagMutedInk, fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }
}

class _DealLineTile extends StatelessWidget {
  const _DealLineTile({
    required this.index,
    required this.item,
    required this.formatMoney,
    this.partsStyle = false,
  });

  final int index;
  final VisitLineItem item;
  final String Function(double?) formatMoney;
  final bool partsStyle;

  String? _subtitle() {
    final qty = item.qty;
    final unit = item.unit ?? (partsStyle ? 'шт' : 'н/ч');
    final price = item.price;
    if (qty != null && price != null) {
      final q = qty == qty.roundToDouble() ? qty.toStringAsFixed(0) : qty.toStringAsFixed(2);
      return '$q $unit × ${formatMoney(price)}';
    }
    if (qty != null) {
      final q = qty == qty.roundToDouble() ? qty.toStringAsFixed(0) : qty.toStringAsFixed(2);
      return '$q $unit';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final sub = _subtitle();
    final sumText = item.sum != null && item.sum! > 0 ? formatMoney(item.sum) : '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: vagSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: vagBorder),
            ),
            child: Text('$index', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: vagMutedInk)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, color: vagInk, height: 1.25)),
                if (sub != null) ...[
                  const SizedBox(height: 3),
                  Text(sub, style: const TextStyle(fontSize: 12, color: vagMutedInk)),
                ],
                if (item.meta != null && item.meta!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(item.meta!, style: const TextStyle(fontSize: 12, color: vagMutedInk, fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
          if (sumText.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(sumText, style: const TextStyle(fontWeight: FontWeight.w800, color: vagInk, fontSize: 14)),
          ],
        ],
      ),
    );
  }
}
