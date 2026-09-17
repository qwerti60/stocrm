import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stocrm_mobile_app/data/mock.dart';
import 'package:stocrm_mobile_app/theme.dart';

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
  Vehicle? car;
  Branch? branch;
  DateTime day = DateTime.now().add(const Duration(days: 1));
  DateTime? slot;
  ServiceItem? service;
  final commentCtrl = TextEditingController();
  bool sending = false;
  String? error;

  @override
  void initState() {
    super.initState();
    car = widget.store.activeCar;
    service = widget.initialService;
    branch = widget.initialBranch;
    if (branch != null) step = 1;
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
    if (branch == null || slot == null || sending) return;
    final title = service?.title ?? (commentCtrl.text.trim().isEmpty ? 'Запись на сервис' : commentCtrl.text.trim());
    final extra = commentCtrl.text.trim();
    final comment = extra.isEmpty || extra == title ? title : '$title\n$extra';
    final carId = int.tryParse(car?.id ?? '');
    if (widget.store.crmLive) {
      setState(() {
        sending = true;
        error = null;
      });
      try {
        final res = await widget.store.bookRemote(
          comment: comment,
          carId: carId != null && carId > 0 ? carId : null,
          branchId: branch!.id,
          when: DateFormat('d MMMM yyyy, HH:mm', 'ru').format(slot!),
        );
        widget.store.addVisit(
          serviceTitle: title,
          branch: branch!,
          when: slot!,
          car: car ??
              Vehicle(id: '', plate: 'уточнит менеджер', make: 'Авто', model: 'из заявки', year: 0, mileage: 0),
        );
        await widget.store.refreshVisits();
        if (!mounted) return;
        final oid = res?['offer_id'];
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: vagCard,
            title: const Text('Заявка в STOCRM'),
            content: Text(
              oid == null
                  ? 'Ожидайте подтверждения звонка или сообщения.'
                  : 'Сделка № $oid в воронке «Неразобранное». Ожидайте звонка или сообщения.',
            ),
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
      return;
    }
    widget.store.addVisit(
      serviceTitle: title,
      branch: branch!,
      when: slot!,
      car: car ?? Vehicle(id: '', plate: 'уточнит менеджер', make: 'Авто', model: 'из заявки', year: 0, mileage: 0),
    );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: vagCard,
        title: const Text('Вы записаны'),
        content: const Text('Локальный прототип: BFF не ответил, заявка только в приложении. Поднимите сервер, чтобы писать в STOCRM.'),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Понятно'))],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Авто', 'Филиал', 'Время', 'Подтверждение'];
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
                      color: on ? vagRed : const Color(0xFF2A2A2E),
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
                onPressed: (!_canNext || sending) ? null : (step == 3 ? confirm : next),
                child: SizedBox(
                  width: double.infinity,
                  child: Center(child: Text(sending ? 'Отправка…' : (step == 3 ? 'Отправить заявку' : 'Далее'))),
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
        return car != null || widget.store.cars.isEmpty;
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
        if (widget.store.cars.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('В карточке CRM нет авто — заявку отправим без машины, менеджер уточнит.', style: TextStyle(color: vagMuted)),
              const SizedBox(height: 12),
              _choice(
                selected: true,
                title: 'Записаться без авто',
                subtitle: 'Контакт уже есть в STOCRM по телефону',
                onTap: () {},
              ),
            ],
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: widget.store.cars
              .map((c) => _choice(
                    selected: car?.id == c.id,
                    title: '${c.make} ${c.model}',
                    subtitle: '${c.plate} · ${c.mileage} км',
                    onTap: () => setState(() => car = c),
                  ))
              .toList(),
        );
      case 1:
        return ListView(
          padding: const EdgeInsets.all(16),
          children: widget.store.branches
              .map((b) => _choice(
                    selected: branch?.id == b.id,
                    title: '${b.name}${b.distanceKm > 0 ? ' · ${b.distanceKm} км' : ''}',
                    subtitle: '${b.address}\n${b.hours}',
                    onTap: () => setState(() {
                      branch = b;
                      slot = null;
                    }),
                  ))
              .toList(),
        );
      case 2:
        final df = DateFormat('EEE d MMM', 'ru');
        final days = List.generate(7, (i) => DateTime.now().add(Duration(days: i + 1)));
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Разное число слотов по дням и филиалам', style: TextStyle(color: vagMuted, fontSize: 12)),
            const SizedBox(height: 10),
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
              children: widget.store.slotsFor(day, branchId: branch?.id).map((t) {
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
                    Text(car?.title.isNotEmpty == true ? car!.title : 'Авто уточнит менеджер', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    Text(car?.plate ?? 'без госномера', style: const TextStyle(color: vagMuted)),
                    const SizedBox(height: 10),
                    Text(branch?.name ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (slot != null) Text(DateFormat('d MMMM, HH:mm', 'ru').format(slot!)),
                    if (service != null) Text(service!.title, style: const TextStyle(color: vagRed)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Услуга (по желанию)', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: widget.store.services.map((s) {
                final on = service?.id == s.id;
                return ChoiceChip(
                  label: Text(s.title, style: const TextStyle(fontSize: 11)),
                  selected: on,
                  onSelected: (_) => setState(() => service = on ? null : s),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Комментарий',
                hintText: 'Стук справа, замена масла 5W-40…',
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: const TextStyle(color: vagRed)),
            ],
          ],
        );
    }
  }

  Widget _choice({required bool selected, required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      color: selected ? const Color(0xFF3A0A10) : vagCard,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: const TextStyle(color: vagMuted)),
        trailing: Icon(selected ? Icons.check_circle : Icons.circle_outlined, color: selected ? vagRed : vagMuted),
        onTap: onTap,
      ),
    );
  }
}
