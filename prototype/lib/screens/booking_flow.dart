import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stocrm_mobile_app/data/mock.dart';

class BookingFlow extends StatefulWidget {
  const BookingFlow({super.key, required this.store, this.initialService, this.initialBranch});
  final MockStore store;
  final ServiceItem? initialService;
  final Branch? initialBranch;

  @override
  State<BookingFlow> createState() => _BookingFlowState();
}

class _BookingFlowState extends State<BookingFlow> {
  int step = 0;
  ServiceItem? service;
  Branch? branch;
  DateTime day = DateTime.now().add(const Duration(days: 1));
  DateTime? slot;
  final commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    service = widget.initialService;
    branch = widget.initialBranch;
    if (service != null) step = 1;
    if (service != null && branch != null) step = 2;
  }

  @override
  void dispose() {
    commentCtrl.dispose();
    super.dispose();
  }

  void next() {
    if (step < 3) setState(() => step++);
  }

  void back() {
    if (step > 0) {
      setState(() => step--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> confirm() async {
    if (service == null || branch == null || slot == null) return;
    widget.store.addVisit(service: service!, branch: branch!, when: slot!, car: widget.store.activeCar);
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Заявка в STOCRM'),
        content: Text(
          'Создадим сделку через /offer/new/with_contact\n'
          '${widget.store.activeCar.plate} · ${service!.title}\n'
          '${branch!.name} · ${DateFormat('d MMM, HH:mm', 'ru').format(slot!)}\n\n'
          'Источник: Онлайн-запись. Приёмка увидит карточку в воронке.',
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Понятно'))],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Услуга', 'Филиал', 'Время', 'Подтверждение'];
    return Scaffold(
      appBar: AppBar(
        title: Text('Запись · ${titles[step]}'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: back),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: List.generate(4, (i) {
                final on = i <= step;
                return Expanded(
                  child: Container(
                    height: 5,
                    margin: EdgeInsets.only(right: i == 3 ? 0 : 6),
                    decoration: BoxDecoration(
                      color: on ? const Color(0xFFEA580C) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(child: _body()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton(
                onPressed: _canNext ? (step == 3 ? confirm : next) : null,
                child: SizedBox(
                  width: double.infinity,
                  child: Center(child: Text(step == 3 ? 'Отправить в STOCRM' : 'Далее')),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _canNext {
    switch (step) {
      case 0:
        return service != null;
      case 1:
        return branch != null;
      case 2:
        return slot != null;
      default:
        return true;
    }
  }

  Widget _body() {
    switch (step) {
      case 0:
        return ListView(
          padding: const EdgeInsets.all(16),
          children: widget.store.services
              .map((s) => _choice(
                    selected: service?.id == s.id,
                    title: s.title,
                    subtitle: s.priceFrom == 0 ? 'по осмотру' : 'от ${s.priceFrom} ₽ · ${s.durationMin} мин',
                    onTap: () => setState(() => service = s),
                  ))
              .toList(),
        );
      case 1:
        return ListView(
          padding: const EdgeInsets.all(16),
          children: widget.store.branches
              .map((b) => _choice(
                    selected: branch?.id == b.id,
                    title: '${b.name} · ${b.distanceKm} км',
                    subtitle: '${b.address}\n${b.hours}',
                    onTap: () => setState(() => branch = b),
                  ))
              .toList(),
        );
      case 2:
        final df = DateFormat('EEE d MMM', 'ru');
        final days = List.generate(7, (i) => DateTime.now().add(Duration(days: i + 1)));
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final d = days[i];
                  final on = d.day == day.day && d.month == day.month;
                  return ChoiceChip(
                    label: Text(df.format(d)),
                    selected: on,
                    onSelected: (_) => setState(() {
                      day = d;
                      slot = null;
                    }),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.store.slotsFor(day).map((t) {
                final on = slot == t;
                return ChoiceChip(
                  label: Text(DateFormat('HH:mm').format(t)),
                  selected: on,
                  onSelected: (_) => setState(() => slot = t),
                );
              }).toList(),
            ),
          ],
        );
      default:
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.store.activeCar.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    Text(widget.store.activeCar.plate),
                    const SizedBox(height: 10),
                    Text(service?.title ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(branch?.name ?? ''),
                    if (slot != null) Text(DateFormat('d MMMM, HH:mm', 'ru').format(slot!)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Комментарий для приёмки',
                hintText: 'Стук справа, замена масла 5W-40…',
              ),
            ),
          ],
        );
    }
  }

  Widget _choice({required bool selected, required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      color: selected ? const Color(0xFFFFF7ED) : Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: Icon(selected ? Icons.check_circle : Icons.circle_outlined, color: selected ? const Color(0xFFEA580C) : Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
