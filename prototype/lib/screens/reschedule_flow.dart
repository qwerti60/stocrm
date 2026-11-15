import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/theme.dart';
import 'package:stocrm_mobile_app/widgets/app_page_scaffold.dart';

class RescheduleFlow extends StatefulWidget {
  const RescheduleFlow({super.key, required this.store, required this.visit});

  final MockStore store;
  final Visit visit;

  @override
  State<RescheduleFlow> createState() => _RescheduleFlowState();
}

class _RescheduleFlowState extends State<RescheduleFlow> {
  int step = 0;
  Branch? branch;
  DateTime day = DateTime.now().add(const Duration(days: 1));
  DateTime? slot;
  List<SlotOption> crmSlots = [];
  bool slotsLoading = false;
  String? slotsHint;
  bool sending = false;
  String? error;

  @override
  void initState() {
    super.initState();
    final bid = widget.visit.branchId;
    if (bid != null && bid.isNotEmpty) {
      for (final b in widget.store.branches) {
        if (b.id == bid) {
          branch = b;
          break;
        }
      }
    }
    branch ??= widget.store.branches.where((b) => b.name == widget.visit.branchName).firstOrNull;
    if (branch != null) step = 1;
    day = widget.visit.when.isAfter(DateTime.now()) ? widget.visit.when : DateTime.now().add(const Duration(days: 1));
  }

  void next() {
    if (step < 2) {
      setState(() => step++);
      if (step == 1) loadSlots();
    }
  }

  void back() {
    if (step > 0) {
      setState(() => step--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> loadSlots() async {
    final b = branch;
    if (b == null) return;
    setState(() {
      slotsLoading = true;
      slotsHint = null;
    });
    try {
      final list = await widget.store.fetchSlots(day, b.id);
      if (!mounted) return;
      setState(() {
        crmSlots = list;
        slotsLoading = false;
        slotsHint = 'Свободные окна по календарю филиала. После переноса менеджер может перезвонить для подтверждения.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        crmSlots = [];
        slotsLoading = false;
        slotsHint = 'Не удалось загрузить слоты. Попробуйте другую дату.';
      });
    }
  }

  Future<void> confirm() async {
    if (branch == null || slot == null || sending) return;
    setState(() {
      sending = true;
      error = null;
    });
    try {
      final msg = await widget.store.rescheduleBookingRemote(
        widget.visit.id,
        when: slot!,
        branchId: branch!.id,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Запись обновлена'),
          content: Text(msg),
          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Понятно'))],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        sending = false;
        error = '$e';
      });
    }
  }

  bool get _canNext {
    if (step == 0) return branch != null;
    if (step == 1) return slot != null;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Филиал', 'Время', 'Подтверждение'];
    final df = DateFormat('d MMMM, HH:mm', 'ru');
    return AppPageScaffold(
      store: widget.store,
      title: 'Перенос · ${titles[step]}',
      showBack: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: vagInk),
        onPressed: back,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Сделка №${widget.visit.id} · было ${df.format(widget.visit.when)}',
              style: const TextStyle(color: vagMuted, fontSize: 12),
            ),
          ),
          Expanded(child: _body()),
          if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(error!, style: const TextStyle(color: vagRed)),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton(
                onPressed: (!_canNext || sending) ? null : (step == 2 ? confirm : next),
                child: SizedBox(
                  width: double.infinity,
                  child: Center(child: Text(sending ? 'Сохраняем…' : (step == 2 ? 'Подтвердить перенос' : 'Далее'))),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    switch (step) {
      case 0:
        return ListView(
          padding: const EdgeInsets.all(16),
          children: widget.store.branches
              .map((b) => Card(
                    color: branch?.id == b.id ? vagRed.withValues(alpha: 0.12) : vagCard,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(b.address.isNotEmpty ? b.address : b.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(b.name, style: const TextStyle(color: vagMuted)),
                      trailing: Icon(branch?.id == b.id ? Icons.check_circle : Icons.circle_outlined, color: vagRed),
                      onTap: () => setState(() {
                        branch = b;
                        slot = null;
                      }),
                    ),
                  ))
              .toList(),
        );
      case 1:
        final dfDay = DateFormat('EEE d MMM', 'ru');
        final days = List.generate(7, (i) => DateTime.now().add(Duration(days: i + 1)));
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(slotsHint ?? '', style: const TextStyle(color: vagMuted, fontSize: 12)),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final d = days[i];
                  final on = d.day == day.day && d.month == day.month;
                  return ChoiceChip(
                    label: Text(dfDay.format(d)),
                    selected: on,
                    onSelected: (_) {
                      setState(() {
                        day = d;
                        slot = null;
                      });
                      loadSlots();
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            if (slotsLoading) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
            if (!slotsLoading && crmSlots.isEmpty)
              const Text('На этот день свободных окон нет.', style: TextStyle(color: vagMuted)),
            if (!slotsLoading)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: crmSlots.map((s) {
                  final on = slot == s.at;
                  return ChoiceChip(
                    label: Text(s.label),
                    selected: on,
                    onSelected: (_) => setState(() => slot = s.at),
                  );
                }).toList(),
              ),
          ],
        );
      default:
        final df = DateFormat('d MMMM, HH:mm', 'ru');
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.visit.serviceTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    Text(widget.visit.carPlate, style: const TextStyle(color: vagMuted)),
                    const SizedBox(height: 10),
                    Text(branch?.address.isNotEmpty == true ? branch!.address : (branch?.name ?? ''), style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (slot != null) Text('Новое время: ${df.format(slot!)}'),
                    Text('Было: ${df.format(widget.visit.when)}', style: const TextStyle(color: vagMuted, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        );
    }
  }
}